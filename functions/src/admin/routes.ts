import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import express from "express";
import cors from "cors";

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
const app = express();

app.use(cors({ origin: true }));
app.use(express.json());

/**
 * Middleware: verify Firebase ID token and check admin role.
 */
async function requireAdmin(
  req: express.Request,
  res: express.Response,
  next: express.NextFunction
): Promise<void> {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith("Bearer ")) {
    res.status(401).json({ error: "Unauthorized" });
    return;
  }

  const idToken = authHeader.split("Bearer ")[1];
  try {
    const decoded = await admin.auth().verifyIdToken(idToken);
    const adminDoc = await db.collection("admins").doc(decoded.uid).get();
    if (!adminDoc.exists) {
      res.status(403).json({ error: "Forbidden: not an admin" });
      return;
    }
    (req as any).adminUser = { ...decoded, role: adminDoc.data()?.role };
    next();
  } catch {
    res.status(401).json({ error: "Invalid token" });
  }
}

// Apply admin middleware to all routes
app.use(requireAdmin);

/**
 * GET /admin/users — List users with pagination.
 */
app.get("/users", async (req, res) => {
  try {
    const limit = Math.min(parseInt(req.query.limit as string) || 20, 100);
    const startAfter = req.query.startAfter as string | undefined;

    let query = db.collection("users").orderBy("createdAt", "desc").limit(limit);
    if (startAfter) {
      const startDoc = await db.collection("users").doc(startAfter).get();
      if (startDoc.exists) {
        query = query.startAfter(startDoc);
      }
    }

    const snapshot = await query.get();
    const users = snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
    res.json({ users, count: users.length });
  } catch (error) {
    functions.logger.error("Error listing users:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

/**
 * GET /admin/users/:id — User detail.
 */
app.get("/users/:id", async (req, res) => {
  try {
    const doc = await db.collection("users").doc(req.params.id).get();
    if (!doc.exists) {
      res.status(404).json({ error: "User not found" });
      return;
    }
    res.json({ id: doc.id, ...doc.data() });
  } catch (error) {
    functions.logger.error("Error getting user:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

/**
 * GET /admin/users/:id/purchases — Purchase history.
 */
app.get("/users/:id/purchases", async (req, res) => {
  try {
    const snapshot = await db
      .collection("users")
      .doc(req.params.id)
      .collection("purchases")
      .orderBy("purchaseDate", "desc")
      .get();
    const purchases = snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
    res.json({ purchases });
  } catch (error) {
    functions.logger.error("Error getting purchases:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

/**
 * GET /admin/design-usage — Global design analytics.
 */
app.get("/design-usage", async (req, res) => {
  try {
    const snapshot = await db.collection("designUsageLogs").get();
    const usageMap: Record<string, { count: number; lastUsed: any }> = {};

    snapshot.docs.forEach((doc) => {
      const data = doc.data();
      const designId = data.designId;
      if (!usageMap[designId]) {
        usageMap[designId] = { count: 0, lastUsed: data.timestamp };
      }
      usageMap[designId].count++;
      if (data.timestamp > usageMap[designId].lastUsed) {
        usageMap[designId].lastUsed = data.timestamp;
      }
    });

    const usage = Object.entries(usageMap)
      .map(([designId, stats]) => ({ designId, ...stats }))
      .sort((a, b) => b.count - a.count);

    res.json({ usage });
  } catch (error) {
    functions.logger.error("Error getting design usage:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

/**
 * POST /admin/users/:id/disable — Soft ban.
 */
app.post("/users/:id/disable", async (req, res) => {
  try {
    const { disabled } = req.body;
    await db.collection("users").doc(req.params.id).update({ disabled: !!disabled });
    await admin.auth().updateUser(req.params.id, { disabled: !!disabled });
    res.json({ success: true, disabled: !!disabled });
  } catch (error) {
    functions.logger.error("Error disabling user:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

/**
 * DELETE /admin/users/:id — Delete user and all data.
 */
app.delete("/users/:id", async (req, res) => {
  try {
    const uid = req.params.id;

    // Delete subcollections
    const subcollections = ["cards", "purchases", "entitlements"];
    for (const sub of subcollections) {
      const snapshot = await db.collection("users").doc(uid).collection(sub).get();
      const batch = db.batch();
      snapshot.docs.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();
    }

    // Delete user document
    await db.collection("users").doc(uid).delete();

    // Delete from Firebase Auth
    await admin.auth().deleteUser(uid);

    // Delete design usage logs
    const logsSnapshot = await db
      .collection("designUsageLogs")
      .where("userId", "==", uid)
      .get();
    const logsBatch = db.batch();
    logsSnapshot.docs.forEach((doc) => logsBatch.delete(doc.ref));
    await logsBatch.commit();

    res.json({ success: true });
  } catch (error) {
    functions.logger.error("Error deleting user:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

export const adminApi = functions.https.onRequest(app);
