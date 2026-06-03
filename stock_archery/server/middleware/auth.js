const { admin } = require('../config/firebase');

async function requireAuth(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ message: 'Authorization token missing' });
  }

  const token = authHeader.split('Bearer ')[1];

  try {
    if (admin.apps.length > 0) {
      const decodedToken = await admin.auth().verifyIdToken(token);
      req.user = decodedToken;
      next();
    } else {
      console.warn("⚠️ Firebase Admin not initialized. Falling back to development mock check.");
      if (token.startsWith("mock-uid-")) {
        const uid = token.replace("mock-uid-", "");
        req.user = { uid, email: `${uid}@mock.com` };
        return next();
      }
      return res.status(401).json({ message: 'Firebase Admin not configured. Please add firebase-service-account.json' });
    }
  } catch (err) {
    console.error("Token verification failed:", err);
    return res.status(401).json({ message: 'Invalid or expired authorization token', error: err.message });
  }
}

module.exports = requireAuth;
