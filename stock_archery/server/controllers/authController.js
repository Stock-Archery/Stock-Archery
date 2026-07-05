const axios = require('axios');
const User = require('../models/User');
const UserAlertAccess = require('../models/UserAlertAccess');

exports.sendOtp = async (req, res) => {
  const { phoneNumber } = req.body;
  if (!phoneNumber) {
    return res.status(400).json({ message: 'Phone number is required' });
  }

  try {
    const apiKey = process.env.TWOFACTOR_API_KEY;
    const url = `https://2factor.in/API/V1/${apiKey}/SMS/${phoneNumber}/AUTOGEN2/`;
    console.log(`📡 Requesting 2Factor OTP for ${phoneNumber}...`);
    const response = await axios.get(url);

    if (response.data && response.data.Status === "Success") {
      const otp = response.data.OTP;
      console.log(`🔑 Received 6-digit OTP from 2Factor for ${phoneNumber}: ${otp}`);
      res.json({
        success: true,
        message: 'OTP sent successfully via 2Factor',
        otp: otp
      });
    } else {
      console.error("❌ 2Factor API Error:", response.data);
      res.status(500).json({
        success: false,
        message: response.data ? response.data.Details : 'Failed to send OTP via 2factor'
      });
    }
  } catch (err) {
    console.error("❌ Failed to request OTP from 2Factor:", err.message);
    res.status(500).json({
      success: false,
      message: 'OTP service connection failed',
      error: err.message
    });
  }
};

exports.syncUser = async (req, res) => {
  const { name, phoneNumber, location } = req.body;
  const { uid, email } = req.user;

  if (!email) {
    return res.status(400).json({ message: 'Email is required from auth credentials' });
  }

  try {
    // Find or create the user
    let user = await User.findOne({ firebaseUid: uid });

    if (!user) {
      // If it's a new signup, validate that all required fields are present
      if (!name || !phoneNumber || !location) {
        return res.status(400).json({ message: 'Name, phone number, and location are required for new registration' });
      }

      user = new User({
        firebaseUid: uid,
        name,
        email,
        phoneNumber,
        location,
        isPremium: false
      });
      await user.save();
      console.log(`👤 New user registered and synced in MongoDB: ${email}`);
    } else {
      // If the user already exists, update their profile fields optionally if provided
      const updateData = {};
      if (name) updateData.name = name;
      if (phoneNumber) updateData.phoneNumber = phoneNumber;
      if (location) updateData.location = location;

      if (Object.keys(updateData).length > 0) {
        user = await User.findOneAndUpdate(
          { firebaseUid: uid },
          { $set: updateData },
          { new: true }
        );
      }
      console.log(`🔄 User logged in and synced: ${email}`);
    }

    // Find or create user alert access permissions
    let alertAccess = await UserAlertAccess.findOne({ firebaseUid: uid });
    if (!alertAccess) {
      alertAccess = new UserAlertAccess({
        firebaseUid: uid,
        isSOB_alert_premium: false,
        isXaud_alert_premium: false,
        isCrypto_alert_premium: false
      });
      await alertAccess.save();
      console.log(`🛡️ Initialized default alert access for: ${email}`);
    } else {
      // Check expirations dynamically
      const now = new Date();
      let accessUpdated = false;

      if (alertAccess.isSOB_alert_premium && alertAccess.SOB_alert_expiresAt && alertAccess.SOB_alert_expiresAt < now) {
        alertAccess.isSOB_alert_premium = false;
        accessUpdated = true;
      }
      if (alertAccess.isXaud_alert_premium && alertAccess.Xaud_alert_expiresAt && alertAccess.Xaud_alert_expiresAt < now) {
        alertAccess.isXaud_alert_premium = false;
        accessUpdated = true;
      }
      if (alertAccess.isCrypto_alert_premium && alertAccess.Crypto_alert_expiresAt && alertAccess.Crypto_alert_expiresAt < now) {
        alertAccess.isCrypto_alert_premium = false;
        accessUpdated = true;
      }

      if (accessUpdated) {
        await alertAccess.save();
        console.log(`⏰ Automatically expired some alert subscriptions for: ${email}`);
      }
    }

    res.json({
      status: "success",
      user: {
        firebaseUid: user.firebaseUid,
        name: user.name,
        email: user.email,
        phoneNumber: user.phoneNumber,
        location: user.location,
        isPremium: user.isPremium,
        premiumExpiresAt: user.premiumExpiresAt
      },
      alertAccess: {
        isSOB_alert_premium: alertAccess.isSOB_alert_premium,
        SOB_alert_expiresAt: alertAccess.SOB_alert_expiresAt,
        isXaud_alert_premium: alertAccess.isXaud_alert_premium,
        Xaud_alert_expiresAt: alertAccess.Xaud_alert_expiresAt,
        isCrypto_alert_premium: alertAccess.isCrypto_alert_premium,
        Crypto_alert_expiresAt: alertAccess.Crypto_alert_expiresAt
      }
    });
  } catch (err) {
    console.error('Error syncing user:', err);
    res.status(500).json({ message: 'User sync failed', error: err.message });
  }
};
