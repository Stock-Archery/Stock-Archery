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
    trim: true
  },
  location: {
    type: String,
    required: true,
    trim: true
  },
  isPremium: {
    type: Boolean,
    default: false
  },
  premiumExpiresAt: {
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
