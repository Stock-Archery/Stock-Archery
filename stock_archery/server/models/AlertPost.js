const mongoose = require('mongoose');

// NOTE: admin/server/models/AlertPost.js writes this same collection and must
// keep the same fields. This server only reads it.
const alertPostSchema = new mongoose.Schema(
  {
    category: {
      type: String,
      required: true,
      enum: ['SOB', 'XAUD', 'Crypto'],
    },
    text: {
      type: String,
      required: true,
      trim: true,
    },
    // The alert's image lives in ImageKit; only its link is stored here.
    imageUrl: {
      type: String,
      default: null,
    },
    // ImageKit's id for the file (used by the admin server to delete it).
    imageFileId: {
      type: String,
      default: null,
    },
    // LEGACY: posts created before ImageKit stored the image inline as base64.
    // Not required anymore — new posts never have it.
    imageBase64: {
      type: String,
      default: null,
    },
  },
  { timestamps: true, collection: 'alert_posts' }
);

module.exports = mongoose.model('AlertPost', alertPostSchema);
