const admin = require('firebase-admin');
const path = require('path');

let firebaseApp;

function initializeFirebase() {
  if (firebaseApp) return firebaseApp;

  if (admin.apps.length) {
    firebaseApp = admin.app();
    return firebaseApp;
  }

  const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH
    ? path.resolve(process.env.FIREBASE_SERVICE_ACCOUNT_PATH)
    : path.resolve(process.cwd(), 'firebase-service-account.json');

  // Prefer explicit credentials file for local/dev setups
  const serviceAccount = require(serviceAccountPath);

  firebaseApp = admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    databaseURL: process.env.FIREBASE_DATABASE_URL || undefined,
    projectId: process.env.FIREBASE_PROJECT_ID || serviceAccount.project_id,
  });

  return firebaseApp;
}

function getAuth() {
  return initializeFirebase().auth();
}

function getFirestore() {
  return initializeFirebase().firestore();
}

module.exports = {
  initializeFirebase,
  getAuth,
  getFirestore,
  admin,
};
