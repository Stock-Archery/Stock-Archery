const axios = require('axios');
const User = require('../models/User');
// Import Firebase Admin for Realtime Database synchronization
const { admin } = require('../config/firebase');

exports.sendOtp = async (req, res) => {
  const { phoneNumber } = req.body;
  console.log(`[log] ─────────────────────────────────────────`);
  console.log(`[log] sendOtp → Incoming request`);
  console.log(`[log] sendOtp → phoneNumber: ${phoneNumber}`);
  console.log(`[log] sendOtp → TWOFACTOR_API_KEY exists: ${!!process.env.TWOFACTOR_API_KEY}`);
  console.log(`[log] sendOtp → API URL: https://2factor.in/API/V1/${process.env.TWOFACTOR_API_KEY ? process.env.TWOFACTOR_API_KEY.substring(0, 8) + '...' : 'MISSING'}/SMS/${phoneNumber}/AUTOGEN2/`);

  if (!phoneNumber) {
    console.log(`[log] sendOtp ✗ Phone number missing`);
    return res.status(400).json({ message: 'Phone number is required' });
  }

  try {
    const apiKey = process.env.TWOFACTOR_API_KEY;
    const url = `https://2factor.in/API/V1/${apiKey}/SMS/${phoneNumber}/AUTOGEN2/`;
    console.log(`[log] sendOtp → Calling 2Factor API...`);
    const startTime = Date.now();
    const response = await axios.get(url);
    const elapsed = Date.now() - startTime;

    console.log(`[log] sendOtp ← 2Factor responded in ${elapsed}ms`);
    console.log(`[log] sendOtp ← Status: ${response.data?.Status}`);
    console.log(`[log] sendOtp ← Full response: ${JSON.stringify(response.data)}`);

    if (response.data && response.data.Status === "Success") {
      const otp = response.data.OTP;
      console.log(`[log] sendOtp ✓ OTP sent successfully: ${otp}`);
      res.json({
        success: true,
        message: 'OTP sent successfully via 2Factor',
        otp: otp
      });
    } else {
      console.log(`[log] sendOtp ✗ 2Factor API error: ${JSON.stringify(response.data)}`);
      res.status(500).json({
        success: false,
        message: response.data ? response.data.Details : 'Failed to send OTP via 2factor'
      });
    }
  } catch (err) {
    console.log(`[log] sendOtp ✗ Exception after ${Date.now()}ms`);
    console.log(`[log] sendOtp ✗ Error message: ${err.message}`);
    if (err.response) {
      console.log(`[log] sendOtp ✗ HTTP status: ${err.response.status}`);
      console.log(`[log] sendOtp ✗ Response data: ${JSON.stringify(err.response.data)}`);
    } else if (err.code) {
      console.log(`[log] sendOtp ✗ Error code: ${err.code}`);
    }
    res.status(500).json({
      success: false,
      message: 'OTP service connection failed',
      error: err.message
    });
  }
};

exports.syncUser = async (req, res) => {
  const { name, phoneNumber, location, occupation, occupationDetail, gender } = req.body;
  const { uid, email } = req.user;

  console.log(`[log] syncUser → uid: ${uid}, email: ${email}`);
  console.log(`[log] syncUser → body: ${JSON.stringify({ name, phoneNumber, location, occupation, occupationDetail, gender })}`);

  if (!email) {
    console.log(`[log] syncUser ✗ Email missing from token`);
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

      // Check if phone number is already registered to another user
      const existingPhoneUser = await User.findOne({ phoneNumber: phoneNumber.trim() });
      if (existingPhoneUser) {
        return res.status(409).json({ message: 'This phone number is already registered with another account' });
      }

      user = new User({
        firebaseUid: uid,
        name,
        email,
        phoneNumber,
        location,
        occupation: occupation || null,
        occupationDetail: occupationDetail || null,
        gender: gender || null,
        isPremium: false,
        isSOB_alert_premium: false,
        SOB_alert_expiresAt: null,
        isXaud_alert_premium: false,
        Xaud_alert_expiresAt: null,
        isCrypto_alert_premium: false,
        Crypto_alert_expiresAt: null
      });
      await user.save();
      console.log(`👤 New user registered and synced in MongoDB: ${email}`);
    } else {
      // If the user already exists, update their profile fields optionally if provided
      const updateData = {};
      if (name) updateData.name = name;
      if (phoneNumber) {
        // Check if the new phone number is already taken by another user
        const existingPhoneUser = await User.findOne({
          phoneNumber: phoneNumber.trim(),
          firebaseUid: { $ne: uid }
        });
        if (existingPhoneUser) {
          return res.status(409).json({ message: 'This phone number is already registered with another account' });
        }
        updateData.phoneNumber = phoneNumber;
      }
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

    // Check expirations dynamically
    const now = new Date();
    let accessUpdated = false;

    // Ensure all premium access fields exist for older users in database
    if (user._doc && user._doc.isSOB_alert_premium === undefined) { user.isSOB_alert_premium = false; accessUpdated = true; }
    if (user._doc && user._doc.SOB_alert_expiresAt === undefined) { user.SOB_alert_expiresAt = null; accessUpdated = true; }
    if (user._doc && user._doc.isXaud_alert_premium === undefined) { user.isXaud_alert_premium = false; accessUpdated = true; }
    if (user._doc && user._doc.Xaud_alert_expiresAt === undefined) { user.Xaud_alert_expiresAt = null; accessUpdated = true; }
    if (user._doc && user._doc.isCrypto_alert_premium === undefined) { user.isCrypto_alert_premium = false; accessUpdated = true; }
    if (user._doc && user._doc.Crypto_alert_expiresAt === undefined) { user.Crypto_alert_expiresAt = null; accessUpdated = true; }

    if (user.isSOB_alert_premium && user.SOB_alert_expiresAt && user.SOB_alert_expiresAt < now) {
      user.isSOB_alert_premium = false;
      accessUpdated = true;
    }
    if (user.isXaud_alert_premium && user.Xaud_alert_expiresAt && user.Xaud_alert_expiresAt < now) {
      user.isXaud_alert_premium = false;
      accessUpdated = true;
    }
    if (user.isCrypto_alert_premium && user.Crypto_alert_expiresAt && user.Crypto_alert_expiresAt < now) {
      user.isCrypto_alert_premium = false;
      accessUpdated = true;
    }



    if (accessUpdated) {
      await user.save();
      console.log(`⏰ Updated alert subscriptions/expirations in MongoDB for: ${email}`);

      // Sync the updated alert premium flags to Firebase Realtime Database (non-blocking)
      if (admin.apps.length > 0) {
        admin.database().ref(`user_alerts/${uid}`).set({
          isSOB_alert_premium: user.isSOB_alert_premium,
          isXaud_alert_premium: user.isXaud_alert_premium,
          isCrypto_alert_premium: user.isCrypto_alert_premium,
          updatedAt: new Date().toISOString()
        }).then(() => {
          console.log(`📡 Expiration/Sync alert flags synced to Firebase RTDB for user: ${uid}`);
        }).catch((rtdbErr) => {
          console.error(`❌ Failed to sync updated flags to Firebase RTDB for ${uid}:`, rtdbErr.message);
        });
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
        occupation: user.occupation,
        occupationDetail: user.occupationDetail,
        gender: user.gender,
        isPremium: user.isPremium,
        premiumExpiresAt: user.premiumExpiresAt,
        isSOB_alert_premium: user.isSOB_alert_premium,
        SOB_alert_expiresAt: user.SOB_alert_expiresAt,
        isXaud_alert_premium: user.isXaud_alert_premium,
        Xaud_alert_expiresAt: user.Xaud_alert_expiresAt,
        isCrypto_alert_premium: user.isCrypto_alert_premium,
        Crypto_alert_expiresAt: user.Crypto_alert_expiresAt
      }
    });
  } catch (err) {
    console.error('Error syncing user:', err);
    res.status(500).json({ message: 'User sync failed', error: err.message });
  }
};
