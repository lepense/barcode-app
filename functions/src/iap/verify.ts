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
 * POST /iap/verify — Verify purchase receipt and update entitlements.
 */
app.post("/verify", async (req, res) => {
  try {
    const uid = (req as any).user.uid;
    // receiptData is accepted but full server-side verification is a TODO
    const { sku, platform, transactionId } = req.body;

    if (!sku || !platform || !transactionId) {
      res.status(400).json({ error: "Missing required fields: sku, platform, transactionId" });
      return;
    }

    // Idempotency check: has this transaction already been processed?
    const existingPurchase = await db
      .collection("users")
      .doc(uid)
      .collection("purchases")
      .where("transactionId", "==", transactionId)
      .get();

    if (!existingPurchase.empty) {
      res.json({ success: true, message: "Purchase already verified", duplicate: true });
      return;
    }

    // TODO: Implement actual receipt verification
    // - Google Play: use Google Play Developer API
    // - App Store: use App Store Server API
    //
    // For now, we trust the client (placeholder for Phase 6 implementation)

    // Record purchase
    await db.collection("users").doc(uid).collection("purchases").add({
      sku,
      platform,
      transactionId,
      purchaseDate: admin.firestore.FieldValue.serverTimestamp(),
      status: "active",
    });

    // Update entitlements based on SKU
    const entitlementRef = db
      .collection("users")
      .doc(uid)
      .collection("entitlements")
      .doc("current");

    if (sku === "pro_lifetime") {
      await entitlementRef.set({ proLifetime: true }, { merge: true });
    } else if (sku.startsWith("pack_")) {
      await entitlementRef.update({
        purchasedPacks: admin.firestore.FieldValue.arrayUnion(sku),
      });
    }

    // Log event
    await db.collection("designUsageLogs").add({
      userId: uid,
      designId: sku,
      action: "pro_purchased",
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    res.json({ success: true, message: "Purchase verified and entitlements updated" });
  } catch (error) {
    functions.logger.error("Error verifying purchase:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

export const iapApi = functions.https.onRequest(app);
