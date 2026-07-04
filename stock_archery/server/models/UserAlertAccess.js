const mongoose = require('mongoose');

const userAlertAccessSchema = new mongoose.Schema({
  firebaseUid: {
    type: String,
    required: true,
    unique: true,
    index: true
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
  }
}, {
  timestamps: true,
  collection: 'user_alert_access'
});

module.exports = mongoose.model('UserAlertAccess', userAlertAccessSchema);
