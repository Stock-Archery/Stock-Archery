const axios = require('axios');
const User = require('../models/User');
// Import Firebase Admin for Realtime Database synchronization
const { admin } = require('../config/firebase');

// In-memory store for OTP sessions (phone → { sessionId, createdAt, otp })
// In production, use Redis with TTL
const otpSessions = new Map();

// Cleanup expired sessions every 5 minutes
setInterval(() => {
  const now = Date.now();
  for (const [phone, session] of otpSessions) {
    if (now - session.createdAt > 5 * 60 * 1000) {
      otpSessions.delete(phone);
    }
  }
}, 5 * 60 * 1000);

exports.sendOtp = async (req, res) => {
  const { phoneNumber } = req.body;
  console.log(`[log] ─────────────────────────────────────────`);
  console.log(`[log] sendOtp → Incoming request`);
  console.log(`[log] sendOtp → phoneNumber: ${phoneNumber}`);
  console.log(`[log] sendOtp → TWOFACTOR_API_KEY exists: ${!!process.env.TWOFACTOR_API_KEY}`);

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
      const sessionId = response.data.Details; // 2Factor returns sessionId in Details field

      // Store session for verification
      otpSessions.set(phoneNumber, {
        sessionId,
        otp,
        createdAt: Date.now(),
      });
      console.log(`[log] sendOtp ✓ Stored session for ${phoneNumber}, sessionId: ${sessionId}`);

      res.json({
        success: true,
        message: 'OTP sent successfully via 2Factor',
        otp: otp, // Dev mode: return OTP for testing
        sessionId: sessionId, // Dev mode: return sessionId for testing
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

exports.verifyOtp = async (req, res) => {
  const { phoneNumber, otp } = req.body;
  console.log(`[log] ─────────────────────────────────────────`);
  console.log(`[log] verifyOtp → Incoming request`);
  console.log(`[log] verifyOtp → phoneNumber: ${phoneNumber}`);
  console.log(`[log] verifyOtp → otp: ${otp}`);

  if (!phoneNumber || !otp) {
    console.log(`[log] verifyOtp ✗ Missing fields`);
    return res.status(400).json({ message: 'Phone number and OTP are required' });
  }

  // Check if session exists
  const session = otpSessions.get(phoneNumber);
  if (!session) {
    console.log(`[log] verifyOtp ✗ No session found for ${phoneNumber}`);
    return res.status(400).json({ message: 'OTP session expired. Please request a new OTP.' });
  }

  try {
    const apiKey = process.env.TWOFACTOR_API_KEY;
    const url = `https://2factor.in/API/V1/${apiKey}/SMS/VERIFY/${session.sessionId}/${otp}`;
    console.log(`[log] verifyOtp → Calling 2Factor VERIFY API...`);
    const startTime = Date.now();
    const response = await axios.get(url);
    const elapsed = Date.now() - startTime;

    console.log(`[log] verifyOtp ← 2Factor responded in ${elapsed}ms`);
    console.log(`[log] verifyOtp ← Full response: ${JSON.stringify(response.data)}`);

    if (response.data && response.data.Status === "Success") {
      console.log(`[log] verifyOtp ✓ OTP verified successfully`);

      // Find user by phone number
      const user = await User.findOne({ phoneNumber: phoneNumber.trim() });
      if (!user) {
        console.log(`[log] verifyOtp ✗ No user found with phone: ${phoneNumber}`);
        otpSessions.delete(phoneNumber);
        return res.status(404).json({
          success: false,
          message: 'No account found with this phone number. Please sign up first.'
        });
      }

      console.log(`[log] verifyOtp ✓ User found: ${user.email}, firebaseUid: ${user.firebaseUid}`);

      // Generate Firebase custom token
      let customToken = null;
      if (admin.apps.length > 0) {
        try {
          customToken = await admin.auth().createCustomToken(user.firebaseUid);
          console.log(`[log] verifyOtp ✓ Custom token generated for ${user.firebaseUid}`);
        } catch (tokenErr) {
          console.log(`[log] verifyOtp ✗ Failed to generate custom token: ${tokenErr.message}`);
          // Fallback: return user data without custom token
        }
      } else {
        console.log(`[log] verifyOtp → Firebase Admin not initialized, returning user data only`);
      }

      // Cleanup session
      otpSessions.delete(phoneNumber);

      res.json({
        success: true,
        message: 'OTP verified successfully',
        customToken: customToken,
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
          Crypto_alert_expiresAt: user.Crypto_alert_expiresAt,
        }
      });
    } else {
      console.log(`[log] verifyOtp ✗ OTP verification failed: ${JSON.stringify(response.data)}`);
      res.status(400).json({
        success: false,
        message: 'Invalid OTP. Please try again.'
      });
    }
  } catch (err) {
    console.log(`[log] verifyOtp ✗ Exception: ${err.message}`);
    if (err.response) {
      console.log(`[log] verifyOtp ✗ HTTP status: ${err.response.status}`);
      console.log(`[log] verifyOtp ✗ Response data: ${JSON.stringify(err.response.data)}`);
    }
    res.status(500).json({
      success: false,
      message: 'OTP verification failed',
      error: err.message
    });
  }
};

exports.verifyOtpOnly = async (req, res) => {
  const { phoneNumber, otp } = req.body;
  console.log(`[log] ─────────────────────────────────────────`);
  console.log(`[log] verifyOtpOnly → phoneNumber: ${phoneNumber}, otp: ${otp}`);
  console.log(`[log] verifyOtpOnly → sessions in memory: ${otpSessions.size}`);

  if (!phoneNumber || !otp) {
    return res.status(400).json({ message: 'Phone number and OTP are required' });
  }

  const session = otpSessions.get(phoneNumber);
  if (!session) {
    console.log(`[log] verifyOtpOnly ✗ No session for ${phoneNumber}`);
    return res.status(400).json({ message: 'OTP session expired. Please request a new OTP.' });
  }

  console.log(`[log] verifyOtpOnly → Found session, sessionId: ${session.sessionId}`);

  try {
    const apiKey = process.env.TWOFACTOR_API_KEY;
    const url = `https://2factor.in/API/V1/${apiKey}/SMS/VERIFY/${session.sessionId}/${otp}`;
    console.log(`[log] verifyOtpOnly → Calling 2Factor VERIFY...`);
    console.log(`[log] verifyOtpOnly → URL: https://2factor.in/API/V1/${apiKey.substring(0, 8)}.../SMS/VERIFY/${session.sessionId}/${otp}`);
    const startTime = Date.now();
    const response = await axios.get(url);
    const elapsed = Date.now() - startTime;

    console.log(`[log] verifyOtpOnly ← 2Factor responded in ${elapsed}ms`);
    console.log(`[log] verifyOtpOnly ← Full response: ${JSON.stringify(response.data)}`);

    if (response.data && response.data.Status === "Success") {
      otpSessions.delete(phoneNumber);
      console.log(`[log] verifyOtpOnly ✓ OTP verified for ${phoneNumber}`);
      res.json({ success: true, message: 'OTP verified' });
    } else {
      console.log(`[log] verifyOtpOnly ✗ 2Factor returned non-success: ${JSON.stringify(response.data)}`);
      res.status(400).json({ success: false, message: 'Invalid OTP' });
    }
  } catch (err) {
    console.log(`[log] verifyOtpOnly ✗ Exception: ${err.message}`);
    if (err.response) {
      console.log(`[log] verifyOtpOnly ✗ 2Factor HTTP status: ${err.response.status}`);
      console.log(`[log] verifyOtpOnly ✗ 2Factor response data: ${JSON.stringify(err.response.data)}`);
    }
    res.status(500).json({ success: false, message: 'OTP verification failed', error: err.message });
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
