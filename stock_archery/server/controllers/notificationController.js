const { admin } = require('../config/firebase');
const User = require('../models/User');

// Helper Function: Send Push Notifications & Handle Inactive Tokens
async function sendPushNotification(user, title, body, data = {}) {
  const activeTokens = user.fcmTokens.filter(t => t.isActive).map(t => t.token);

  if (activeTokens.length === 0) {
    console.log(`No active tokens for user ${user.email}.`);
    return { successCount: 0, failureCount: 0 };
  }

  const message = {
    notification: { title, body },
    data,
    tokens: activeTokens
  };

  try {
    const response = await admin.messaging().sendEachForMulticast(message);

    // Check for uninstalled/inactive tokens
    if (response.failureCount > 0) {
      const tokensToRemove = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          const errorCode = resp.error.code;
          if (
            errorCode === 'messaging/invalid-registration-token' ||
            errorCode === 'messaging/registration-token-not-registered'
          ) {
            tokensToRemove.push(activeTokens[idx]);
          }
        }
      });

      if (tokensToRemove.length > 0) {
        console.log(`Deactivating ${tokensToRemove.length} invalid tokens for user ${user.email}`);
        user.fcmTokens.forEach(t => {
          if (tokensToRemove.includes(t.token)) {
            t.isActive = false;
            t.updatedAt = new Date();
          }
        });
        await user.save();
      }
    }

    return response;
  } catch (err) {
    console.error('Push notification failed:', err);
    throw err;
  }
}

exports.testPush = async (req, res) => {
  const { title, body } = req.body;
  const { uid } = req.user;

  try {
    const user = await User.findOne({ firebaseUid: uid });
    if (!user) return res.status(404).json({ message: 'User not found' });

    const response = await sendPushNotification(user, title || 'Test Notification', body || 'This is a test');
    res.json({ status: 'success', response });
  } catch (err) {
    res.status(500).json({ message: 'Push test failed', error: err.message });
  }
};

exports.broadcastPush = async (req, res) => {
  const { title, body } = req.body;

  // NOTE: In production, you should add a check here to ensure req.user is an ADMIN

  const message = {
    notification: {
      title: title || 'Global Alert',
      body: body || 'This is a broadcast message to all users'
    },
    topic: 'all_users'
  };

  try {
    const response = await admin.messaging().send(message);
    res.json({ status: 'success', messageId: response });
  } catch (err) {
    console.error('Broadcast failed:', err);
    res.status(500).json({ message: 'Broadcast failed', error: err.message });
  }
};

exports.sendPushNotification = sendPushNotification;
