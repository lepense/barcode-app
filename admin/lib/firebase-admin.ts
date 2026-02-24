import { initializeApp, getApps, cert, type ServiceAccount } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { getAuth } from "firebase-admin/auth";

function getFirebaseAdmin() {
  if (getApps().length > 0) {
    return {
      db: getFirestore(),
      auth: getAuth(),
    };
  }

  // In production, use service account from env variable
  const serviceAccount = process.env.FIREBASE_SERVICE_ACCOUNT_KEY
    ? JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY) as ServiceAccount
    : undefined;

  const app = initializeApp(
    serviceAccount ? { credential: cert(serviceAccount) } : undefined
  );

  return {
    db: getFirestore(app),
    auth: getAuth(app),
  };
}

export const { db, auth } = getFirebaseAdmin();
