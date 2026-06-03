const User = require('../models/User');

exports.registerDevice = async (req, res) => {
  const { token, deviceId, platform } = req.body;
  const { uid } = req.user;

  if (!token || !deviceId) {
    return res.status(400).json({ message: 'Token and deviceId are required' });
  }

  try {
    const user = await User.findOne({ firebaseUid: uid });
    if (!user) return res.status(404).json({ message: 'User not found' });

    const existingTokenIndex = user.fcmTokens.findIndex(t => t.deviceId === deviceId);

    if (existingTokenIndex > -1) {
      // Update existing device
      user.fcmTokens[existingTokenIndex].token = token;
      user.fcmTokens[existingTokenIndex].platform = platform || user.fcmTokens[existingTokenIndex].platform;
      user.fcmTokens[existingTokenIndex].isActive = true;
      user.fcmTokens[existingTokenIndex].updatedAt = new Date();
    } else {
      // Add new device
      user.fcmTokens.push({
        token,
        deviceId,
        platform,
        isActive: true,
        updatedAt: new Date()
      });
    }

    await user.save();
    res.json({ status: 'success', message: 'Device registered successfully' });
  } catch (err) {
    console.error('Error registering device:', err);
    res.status(500).json({ message: 'Failed to register device', error: err.message });
  }
};

exports.unregisterDevice = async (req, res) => {
  const { deviceId } = req.body;
  const { uid } = req.user;

  if (!deviceId) return res.status(400).json({ message: 'deviceId is required' });

  try {
    const user = await User.findOne({ firebaseUid: uid });
    if (!user) return res.status(404).json({ message: 'User not found' });

    const existingTokenIndex = user.fcmTokens.findIndex(t => t.deviceId === deviceId);
    if (existingTokenIndex > -1) {
      user.fcmTokens[existingTokenIndex].isActive = false;
      user.fcmTokens[existingTokenIndex].updatedAt = new Date();
      await user.save();
    }

    res.json({ status: 'success', message: 'Device unregistered successfully' });
  } catch (err) {
    console.error('Error unregistering device:', err);
    res.status(500).json({ message: 'Failed to unregister device', error: err.message });
  }
};
