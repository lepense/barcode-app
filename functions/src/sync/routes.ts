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
 * Middleware: verify Firebase ID token.
 */
async function requireAuth(
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
    (req as any).user = decoded;
    next();
  } catch {
    res.status(401).json({ error: "Invalid token" });
  }
}

app.use(requireAuth);

/**
 * GET /sync/pull — Pull cards and entitlements from server.
 */
app.get("/pull", async (req, res) => {
  try {
    const uid = (req as any).user.uid;
    const since = req.query.since as string | undefined;

    // Get user profile
    const userDoc = await db.collection("users").doc(uid).get();

    // Get cards (optionally filtered by updatedAt)
    let cardsQuery: FirebaseFirestore.Query = db
      .collection("users")
      .doc(uid)
      .collection("cards")
      .orderBy("updatedAt", "desc");

    if (since) {
      cardsQuery = cardsQuery.where("updatedAt", ">", new Date(since));
    }

    const cardsSnapshot = await cardsQuery.get();
    const cards = cardsSnapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));

    // Get entitlements
    const entDoc = await db
      .collection("users")
      .doc(uid)
      .collection("entitlements")
      .doc("current")
      .get();

    res.json({
      user: userDoc.exists ? { id: userDoc.id, ...userDoc.data() } : null,
      cards,
      entitlements: entDoc.exists ? entDoc.data() : null,
    });
  } catch (error) {
    functions.logger.error("Error pulling sync data:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

/**
 * POST /sync/push — Push cards from client to server.
 * Uses last-write-wins conflict resolution.
 */
app.post("/push", async (req, res) => {
  try {
    const uid = (req as any).user.uid;
    const { cards } = req.body;

    if (!Array.isArray(cards)) {
      res.status(400).json({ error: "cards must be an array" });
      return;
    }

    const results: Array<{ localId: string; remoteId: string; status: string }> = [];

    for (const card of cards) {
      const { localId, remoteId, merchantName, barcodeType, barcodeValueEncrypted, coverDesignId, updatedAt } = card;

      if (remoteId) {
        // Update existing card — last-write-wins
        const existingRef = db.collection("users").doc(uid).collection("cards").doc(remoteId);
        const existing = await existingRef.get();

        if (existing.exists) {
          const serverUpdatedAt = existing.data()?.updatedAt?.toDate?.() || new Date(0);
          const clientUpdatedAt = new Date(updatedAt);

          if (clientUpdatedAt > serverUpdatedAt) {
            await existingRef.update({
              merchantName,
              barcodeType,
              barcodeValueEncrypted,
              coverDesignId: coverDesignId || null,
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            results.push({ localId, remoteId, status: "updated" });
          } else {
            results.push({ localId, remoteId, status: "skipped_server_newer" });
          }
        } else {
          results.push({ localId, remoteId, status: "not_found" });
        }
      } else {
        // New card — create on server
        const newDoc = await db.collection("users").doc(uid).collection("cards").add({
          merchantName,
          barcodeType,
          barcodeValueEncrypted,
          coverDesignId: coverDesignId || null,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        results.push({ localId, remoteId: newDoc.id, status: "created" });
      }
    }

    res.json({ results });
  } catch (error) {
    functions.logger.error("Error pushing sync data:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

export const syncApi = functions.https.onRequest(app);
