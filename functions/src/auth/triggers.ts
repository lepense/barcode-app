import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Initialize admin SDK (only once across all files)
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * Triggered when a new user is created in Firebase Auth.
 * Creates a corresponding user document in Firestore.
 */
export const onUserCreated = functions.auth.user().onCreate(async (user) => {
  const { uid, email, displayName, photoURL } = user;

  // Determine sign-in provider
  const providerData = user.providerData;
  let provider = "email";
  if (providerData.length > 0) {
    const providerId = providerData[0].providerId;
    if (providerId === "google.com") provider = "google";
    else if (providerId === "apple.com") provider = "apple";
  }

  await db.collection("users").doc(uid).set({
    email: email || null,
    displayName: displayName || null,
    photoUrl: photoURL || null,
    provider,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    lastLogin: admin.firestore.FieldValue.serverTimestamp(),
    platform: "unknown", // Updated on first app login
    disabled: false,
    defaultCoverDesignId: null,
  });

  // Create empty entitlements document
  await db.collection("users").doc(uid).collection("entitlements").doc("current").set({
    proLifetime: false,
    purchasedPacks: [],
    photoOverlayCount: 0,
  });

  functions.logger.info(`User document created for ${uid}`);
});

/**
 * Triggered when a user is deleted from Firebase Auth.
 * Cleans up all user data from Firestore.
 */
export const onUserDeleted = functions.auth.user().onDelete(async (user) => {
  const { uid } = user;

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

  // Delete design usage logs for this user
  const logsSnapshot = await db
    .collection("designUsageLogs")
    .where("userId", "==", uid)
    .get();
  const logsBatch = db.batch();
  logsSnapshot.docs.forEach((doc) => logsBatch.delete(doc.ref));
  await logsBatch.commit();

  functions.logger.info(`User data cleaned up for ${uid}`);
});
