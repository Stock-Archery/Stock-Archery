const admin = require('firebase-admin');

const initFirebase = () => {
  try {
    // We navigate one directory up because the file is in the server/ directory
    const serviceAccount = require('../firebase-service-account.json');
    if (serviceAccount.project_id && serviceAccount.project_id !== "YOUR_PROJECT_ID") {
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        databaseURL: "https://stock-archery-99-default-rtdb.firebaseio.com"
      });
      console.log("✅ Firebase Admin SDK initialized successfully");
    } else {
      console.warn("⚠️ firebase-service-account.json contains placeholder values. Firebase verification will run in DEVELOPMENT fallback mode.");
    }
  } catch (err) {
    console.warn("⚠️ Firebase Admin SDK could not load credentials. Running in DEVELOPMENT fallback mode.");
  }
};

module.exports = { admin, initFirebase };
