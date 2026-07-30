const { admin } = require('../config/firebase');

async function requireAuth(req, res, next) {
  const authHeader = req.headers.authorization;
  console.log(`[log] auth middleware → ${req.method} ${req.originalUrl}`);
  console.log(`[log] auth middleware → Authorization header exists: ${!!authHeader}`);

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    console.log(`[log] auth middleware ✗ No Bearer token`);
    return res.status(401).json({ message: 'Authorization token missing' });
  }

  const token = authHeader.split('Bearer ')[1];
  console.log(`[log] auth middleware → Token prefix: ${token.substring(0, 20)}...`);
  console.log(`[log] auth middleware → Firebase apps count: ${admin.apps.length}`);

  try {
    if (admin.apps.length > 0) {
      console.log(`[log] auth middleware → Verifying Firebase ID token...`);
      const decodedToken = await admin.auth().verifyIdToken(token);
      console.log(`[log] auth middleware ✓ Token verified. uid: ${decodedToken.uid}, email: ${decodedToken.email}`);
      req.user = decodedToken;
      next();
    } else {
      console.log(`[log] auth middleware → Firebase Admin not initialized, checking mock fallback`);
      if (token.startsWith("mock-uid-")) {
        const uid = token.replace("mock-uid-", "");
        console.log(`[log] auth middleware ✓ Mock mode accepted for uid: ${uid}`);
        req.user = { uid, email: `${uid}@mock.com` };
        return next();
      }
      console.log(`[log] auth middleware ✗ No Firebase Admin and not a mock token`);
      return res.status(401).json({ message: 'Firebase Admin not configured. Please add firebase-service-account.json' });
    }
  } catch (err) {
    console.log(`[log] auth middleware ✗ Token verification failed: ${err.message}`);
    return res.status(401).json({ message: 'Invalid or expired authorization token', error: err.message });
  }
}

module.exports = requireAuth;
