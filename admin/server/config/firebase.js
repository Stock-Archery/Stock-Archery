import admin from "firebase-admin";

const initFirebase = () => {
  console.log("[log] Initializing Firebase Admin SDK...");
  try {
    const { FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, FIREBASE_PRIVATE_KEY, FIREBASE_DATABASE_URL } = process.env;

    if (FIREBASE_PROJECT_ID && FIREBASE_CLIENT_EMAIL && FIREBASE_PRIVATE_KEY) {
      admin.initializeApp({
        credential: admin.credential.cert({
          projectId: FIREBASE_PROJECT_ID,
          clientEmail: FIREBASE_CLIENT_EMAIL,
          privateKey: FIREBASE_PRIVATE_KEY.replace(/\\n/g, "\n"),
        }),
        databaseURL: FIREBASE_DATABASE_URL || "https://stock-archery-99-default-rtdb.firebaseio.com",
      });
      console.log("[log] Firebase Admin SDK initialized successfully");
    } else {
      console.warn("[log] Firebase credentials missing — notifications disabled");
    }
  } catch (err) {
    console.warn("[log] Firebase Admin SDK init failed:", err.message);
  }
};

export { admin, initFirebase };
