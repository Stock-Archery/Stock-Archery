import mongoose from "mongoose";
import AlertPost from "../models/AlertPost.js";
import {
  isConfigured,
  normalizeBase64,
  decodedSize,
  detectImageType,
  uploadImage,
  deleteFiles,
  MAX_IMAGE_BYTES,
} from "../services/imagekit.js";

const CATEGORIES = ["SOB", "XAUD", "Crypto"];

export const createAlert = async (req, res) => {
  const { category, text, imageBase64 } = req.body;
  console.log(`[log] POST /alerts/create — category: ${category}, text: ${text?.substring(0, 50)}..., image: ${imageBase64 ? "yes" : "no"}`);

  if (!category || !text) {
    console.log("[log] POST /alerts/create — 400: missing required fields");
    return res
      .status(400)
      .json({ status: "error", message: "category and text are required" });
  }

  if (!CATEGORIES.includes(category)) {
    console.log(`[log] POST /alerts/create — 400: invalid category "${category}"`);
    return res
      .status(400)
      .json({ status: "error", message: "category must be SOB, XAUD, or Crypto" });
  }

  // The image is optional. When there is one it goes to ImageKit and only its
  // link is stored — the base64 is never written to the database.
  let image = null;
  if (imageBase64) {
    if (typeof imageBase64 !== "string") {
      return res.status(400).json({ status: "error", message: "imageBase64 must be a string" });
    }

    const base64 = normalizeBase64(imageBase64);
    const type = detectImageType(base64);
    if (!type) {
      console.log("[log] POST /alerts/create — 400: not a JPEG/PNG/WebP image");
      return res
        .status(400)
        .json({ status: "error", message: "The image must be a JPEG, PNG or WebP file" });
    }
    if (decodedSize(base64) > MAX_IMAGE_BYTES) {
      console.log("[log] POST /alerts/create — 413: image too large");
      return res.status(413).json({
        status: "error",
        message: `The image is too large (max ${MAX_IMAGE_BYTES / (1024 * 1024)} MB)`,
      });
    }
    if (!isConfigured()) {
      console.error("[log] POST /alerts/create — 503: IMAGEKIT_PRIVATE_KEY is not set");
      return res.status(503).json({
        status: "error",
        message: "Image storage is not configured on the server",
      });
    }

    try {
      image = await uploadImage(base64, {
        folder: `/stock-archery/alerts/${category.toLowerCase()}`,
        fileNamePrefix: `alert_${category.toLowerCase()}`,
        type,
      });
    } catch (err) {
      // The image IS the alert: fail loudly so the admin can retry, rather
      // than silently posting text with no chart.
      console.error("[log] POST /alerts/create — 502: ImageKit upload failed:", err.message);
      return res
        .status(502)
        .json({ status: "error", message: "Image upload failed. Please try again." });
    }
  }

  try {
    const alert = await AlertPost.create({
      category,
      text,
      imageUrl: image?.url ?? null,
      imageFileId: image?.fileId ?? null,
    });
    console.log(`[log] POST /alerts/create — 201: alert created, id: ${alert._id}`);
    res.status(201).json({ status: "success", alert });
  } catch (err) {
    console.error("[log] POST /alerts/create — 500:", err.message);
    // The upload succeeded but nothing points at it: don't leave it orphaned.
    if (image) deleteFiles([image.fileId]);
    res.status(500).json({ status: "error", message: "Failed to create alert" });
  }
};

export const getAlertsByCategory = async (req, res) => {
  const { category } = req.params;
  console.log(`[log] GET /alerts/${category}`);

  if (!CATEGORIES.includes(category)) {
    console.log(`[log] GET /alerts/${category} — 400: invalid category`);
    return res
      .status(400)
      .json({ status: "error", message: "category must be SOB, XAUD, or Crypto" });
  }

  try {
    const alerts = await AlertPost.find({ category }).sort({ createdAt: -1 });
    console.log(`[log] GET /alerts/${category} — 200: found ${alerts.length} alerts`);
    res.json({ status: "success", alerts });
  } catch (err) {
    console.error(`[log] GET /alerts/${category} — 500:`, err.message);
    res.status(500).json({ status: "error", message: "Failed to fetch alerts" });
  }
};

export const deleteAlert = async (req, res) => {
  const { id } = req.params;
  console.log(`[log] DELETE /alerts/${id}`);

  if (!mongoose.isValidObjectId(id)) {
    return res.status(400).json({ status: "error", message: "Invalid alert id" });
  }

  try {
    const deleted = await AlertPost.findByIdAndDelete(id);
    if (!deleted) {
      console.log(`[log] DELETE /alerts/${id} — 404: alert not found`);
      return res.status(404).json({ status: "error", message: "Alert not found" });
    }
    // Remove the image from ImageKit too (legacy base64 posts have none).
    if (deleted.imageFileId) deleteFiles([deleted.imageFileId]);
    console.log(`[log] DELETE /alerts/${id} — 200: alert deleted`);
    res.json({ status: "success", message: "Alert deleted" });
  } catch (err) {
    console.error(`[log] DELETE /alerts/${id} — 500:`, err.message);
    res.status(500).json({ status: "error", message: "Failed to delete alert" });
  }
};
