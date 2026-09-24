import mongoose from "mongoose";

// NOTE: stock_archery/server/models/AlertPost.js reads this same collection
// and must keep the same fields.
const alertPostSchema = new mongoose.Schema(
  {
    category: {
      type: String,
      required: true,
      enum: ["SOB", "XAUD", "Crypto"],
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
    // ImageKit's id for the file, so it can be deleted with the alert.
    imageFileId: {
      type: String,
      default: null,
    },
    // LEGACY: posts created before ImageKit stored the image inline as base64.
    // New code never writes this. scripts/migrate-alert-images.js moves the
    // remaining ones to ImageKit; until then clients fall back to it.
    imageBase64: {
      type: String,
      default: null,
    },
  },
  { timestamps: true, collection: "alert_posts" }
);

const AlertPost = mongoose.model("AlertPost", alertPostSchema);

export default AlertPost;
