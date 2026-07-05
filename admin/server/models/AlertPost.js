import mongoose from "mongoose";

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
    imageBase64: {
      type: String,
      required: true,
    },
  },
  { timestamps: true, collection: "alert_posts" }
);

const AlertPost = mongoose.model("AlertPost", alertPostSchema);

export default AlertPost;
