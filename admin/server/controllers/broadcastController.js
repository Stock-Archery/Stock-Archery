import { admin } from "../config/firebase.js";

export const broadcastPush = async (req, res) => {
  const { title, body } = req.body;
  console.log(`[log] POST /broadcast — title: "${title}", body: "${body?.substring(0, 80)}..."`);

  if (!title || !body) {
    console.log("[log] POST /broadcast — 400: missing title or body");
    return res.status(400).json({ status: "error", message: "title and body are required" });
  }

  if (!admin.apps.length) {
    console.log("[log] POST /broadcast — 503: Firebase not configured");
    return res.status(503).json({ status: "error", message: "Firebase not configured" });
  }

  try {
    const message = {
      notification: { title, body },
      topic: "all_users",
    };

    console.log("[log] POST /broadcast — sending to FCM topic 'all_users'...");
    const messageId = await admin.messaging().send(message);
    console.log(`[log] POST /broadcast — 200: sent successfully, messageId: ${messageId}`);
    res.json({ status: "success", messageId });
  } catch (err) {
    console.error("[log] POST /broadcast — 500:", err.message);
    res.status(500).json({ status: "error", message: "Broadcast failed" });
  }
};
