import AlertPost from "../models/AlertPost.js";

export const createAlert = async (req, res) => {
  const { category, text, imageBase64 } = req.body;
  console.log(`[log] POST /alerts/create — category: ${category}, text: ${text?.substring(0, 50)}...`);

  if (!category || !text || !imageBase64) {
    console.log("[log] POST /alerts/create — 400: missing required fields");
    return res
      .status(400)
      .json({ status: "error", message: "category, text, and imageBase64 are required" });
  }

  if (!["SOB", "XAUD", "Crypto"].includes(category)) {
    console.log(`[log] POST /alerts/create — 400: invalid category "${category}"`);
    return res
      .status(400)
      .json({ status: "error", message: "category must be SOB, XAUD, or Crypto" });
  }

  try {
    const alert = await AlertPost.create({ category, text, imageBase64 });
    console.log(`[log] POST /alerts/create — 201: alert created, id: ${alert._id}`);
    res.status(201).json({ status: "success", alert });
  } catch (err) {
    console.error("[log] POST /alerts/create — 500:", err.message);
    res.status(500).json({ status: "error", message: "Failed to create alert" });
  }
};

export const getAlertsByCategory = async (req, res) => {
  const { category } = req.params;
  console.log(`[log] GET /alerts/${category}`);

  if (!["SOB", "XAUD", "Crypto"].includes(category)) {
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

  try {
    const deleted = await AlertPost.findByIdAndDelete(id);
    if (!deleted) {
      console.log(`[log] DELETE /alerts/${id} — 404: alert not found`);
      return res.status(404).json({ status: "error", message: "Alert not found" });
    }
    console.log(`[log] DELETE /alerts/${id} — 200: alert deleted`);
    res.json({ status: "success", message: "Alert deleted" });
  } catch (err) {
    console.error(`[log] DELETE /alerts/${id} — 500:`, err.message);
    res.status(500).json({ status: "error", message: "Failed to delete alert" });
  }
};
