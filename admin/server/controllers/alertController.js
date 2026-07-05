import AlertPost from "../models/AlertPost.js";

export const createAlert = async (req, res) => {
  const { category, text, imageBase64 } = req.body;

  if (!category || !text || !imageBase64) {
    return res
      .status(400)
      .json({ status: "error", message: "category, text, and imageBase64 are required" });
  }

  if (!["SOB", "XAUD", "Crypto"].includes(category)) {
    return res
      .status(400)
      .json({ status: "error", message: "category must be SOB, XAUD, or Crypto" });
  }

  try {
    const alert = await AlertPost.create({ category, text, imageBase64 });
    res.status(201).json({ status: "success", alert });
  } catch (err) {
    console.error("Error creating alert:", err.message);
    res.status(500).json({ status: "error", message: "Failed to create alert" });
  }
};

export const getAlertsByCategory = async (req, res) => {
  const { category } = req.params;

  if (!["SOB", "XAUD", "Crypto"].includes(category)) {
    return res
      .status(400)
      .json({ status: "error", message: "category must be SOB, XAUD, or Crypto" });
  }

  try {
    const alerts = await AlertPost.find({ category }).sort({ createdAt: 1 });
    res.json({ status: "success", alerts });
  } catch (err) {
    console.error("Error fetching alerts:", err.message);
    res.status(500).json({ status: "error", message: "Failed to fetch alerts" });
  }
};

export const deleteAlert = async (req, res) => {
  const { id } = req.params;

  try {
    const deleted = await AlertPost.findByIdAndDelete(id);
    if (!deleted) {
      return res.status(404).json({ status: "error", message: "Alert not found" });
    }
    res.json({ status: "success", message: "Alert deleted" });
  } catch (err) {
    console.error("Error deleting alert:", err.message);
    res.status(500).json({ status: "error", message: "Failed to delete alert" });
  }
};
