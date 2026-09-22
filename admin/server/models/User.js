import mongoose from "mongoose";

// Mirrors stock_archery/server/models/User.js — both servers share the
// same `users` collection, so the schemas must stay in sync. Do not add
// admin-only required fields or narrower enums here, or admin writes will
// fail validation on real app-created users.
const userSchema = new mongoose.Schema(
  {
    firebaseUid: { type: String, required: true, unique: true, index: true },
    name: { type: String, required: true, trim: true },
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
    },
    phoneNumber: { type: String, required: true, unique: true, trim: true },
    state: { type: String, required: true, trim: true },
    occupation: {
      type: String,
      enum: [
        "student",
        "business",
        "self_employed",
        "government_job",
        "private_sector_job",
      ],
      default: null,
    },
    tradingExperience: {
      type: String,
      enum: ["beginner", "intermediate", "experienced"],
      default: null,
    },
    gender: {
      type: String,
      enum: ["male", "female", "others"],
      default: null,
    },
    isPremium: { type: Boolean, default: false },
    premiumExpiresAt: { type: Date, default: null },
    isSOB_alert_premium: { type: Boolean, default: false },
    SOB_alert_expiresAt: { type: Date, default: null },
    isXaud_alert_premium: { type: Boolean, default: false },
    Xaud_alert_expiresAt: { type: Date, default: null },
    isCrypto_alert_premium: { type: Boolean, default: false },
    Crypto_alert_expiresAt: { type: Date, default: null },
    fcmTokens: [
      {
        token: { type: String, required: true },
        deviceId: { type: String, required: true },
        platform: { type: String },
        isActive: { type: Boolean, default: true },
        updatedAt: { type: Date, default: Date.now },
      },
    ],
    textChatCount: { type: Number, default: 0 },
    // Free-chat daily limit: textChatCount only means "messages sent today"
    // when this matches the current IST calendar day ("YYYY-MM-DD"); kept
    // here purely so this mirrored schema doesn't reject/strip the field on
    // any future admin-side write — see stock_archery/server/models/User.js.
    textChatCountDate: { type: String, default: null },
  },
  { timestamps: true, collection: "users" }
);

const User = mongoose.model("User", userSchema);

export default User;
