const admin = require('firebase-admin');

const initFirebase = () => {
  try {
    let credentials = null;
    let databaseURL = "https://stock-archery-99-default-rtdb.firebaseio.com";

    // 1. Try loading from environment variables
    if (process.env.FIREBASE_PRIVATE_KEY && process.env.FIREBASE_CLIENT_EMAIL && process.env.FIREBASE_PROJECT_ID) {
      credentials = {
        projectId: process.env.FIREBASE_PROJECT_ID,
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
        privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
      };
      if (process.env.FIREBASE_DATABASE_URL) {
        databaseURL = process.env.FIREBASE_DATABASE_URL;
      }
      console.log("ℹ️ Loading Firebase Admin credentials from environment variables");
    } else {
      // 2. Fall back to local service account JSON file
      try {
        const serviceAccount = require('../firebase-service-account.json');
        if (serviceAccount.project_id && serviceAccount.project_id !== "YOUR_PROJECT_ID") {
          credentials = {
            projectId: serviceAccount.project_id,
            clientEmail: serviceAccount.client_email,
            privateKey: serviceAccount.private_key,
          };
          console.log("ℹ️ Loading Firebase Admin credentials from firebase-service-account.json");
        }
      } catch (fileErr) {
        // File not found or invalid
      }
    }

    if (credentials) {
      admin.initializeApp({
        credential: admin.credential.cert(credentials),
        databaseURL: databaseURL
      });
      console.log("✅ Firebase Admin SDK initialized successfully");
    } else {
      console.warn("⚠️ Firebase Admin credentials not found in env or json file. Firebase verification will run in DEVELOPMENT fallback mode.");
    }
  } catch (err) {
    console.warn("⚠️ Firebase Admin SDK could not load credentials. Running in DEVELOPMENT fallback mode:", err.message);
  }
};

module.exports = { admin, initFirebase };
