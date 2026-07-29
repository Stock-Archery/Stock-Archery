const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  firebaseUid: {
    type: String,
    required: true,
    unique: true,
    index: true
  },
  name: {
    type: String,
    required: true,
    trim: true
  },
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true,
    trim: true
  },
  phoneNumber: {
    type: String,
    required: true,
    unique: true,
    trim: true
  },
  location: {
    type: String,
    required: true,
    trim: true
  },
  occupation: {
    type: String,
    enum: ['student', 'businessman', 'others'],
    default: null
  },
  occupationDetail: {
    type: String,
    trim: true,
    default: null
  },
  gender: {
    type: String,
    enum: ['male', 'female', 'others'],
    default: null
  },
  isPremium: {
    type: Boolean,
    default: false
  },
  premiumExpiresAt: {
    type: Date,
    default: null
  },
  isSOB_alert_premium: {
    type: Boolean,
    default: false
  },
  SOB_alert_expiresAt: {
    type: Date,
    default: null
  },
  isXaud_alert_premium: {
    type: Boolean,
    default: false
  },
  Xaud_alert_expiresAt: {
    type: Date,
    default: null
  },
  isCrypto_alert_premium: {
    type: Boolean,
    default: false
  },
  Crypto_alert_expiresAt: {
    type: Date,
    default: null
  },
  fcmTokens: [{
    token: { type: String, required: true },
    deviceId: { type: String, required: true },
    platform: { type: String },
    isActive: { type: Boolean, default: true },
    updatedAt: { type: Date, default: Date.now }
  }]
}, {
  timestamps: true,
  collection: 'users'
});

module.exports = mongoose.model('User', userSchema);
