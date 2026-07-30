import User from "../models/User.js";

export const searchUser = async (req, res) => {
  const { query } = req.query;
  console.log(`[log] GET /users/search — query: "${query}"`);

  if (!query || query.trim().length === 0) {
    console.log("[log] GET /users/search — 400: empty query");
    return res.status(400).json({ status: "error", message: "Query parameter is required" });
  }

  try {
    const user = await User.findOne({
      $or: [
        { email: query.trim().toLowerCase() },
        { phoneNumber: query.trim() },
      ],
    });

    if (!user) {
      console.log(`[log] GET /users/search — 404: no user found for "${query}"`);
      return res.status(404).json({ status: "error", message: "User not found" });
    }

    console.log(`[log] GET /users/search — 200: found user ${user.email} (${user.firebaseUid})`);
    res.json({ status: "success", user });
  } catch (err) {
    console.error("[log] GET /users/search — 500:", err.message);
    res.status(500).json({ status: "error", message: "Failed to search user" });
  }
};

export const updateUserAlertAccess = async (req, res) => {
  const { firebaseUid } = req.params;
  const { isSOB_alert_premium, isXaud_alert_premium, isCrypto_alert_premium } = req.body;
  console.log(`[log] PUT /users/alert-access/${firebaseUid} — body:`, JSON.stringify(req.body));

  try {
    const user = await User.findOne({ firebaseUid });
    if (!user) {
      console.log(`[log] PUT /users/alert-access/${firebaseUid} — 404: user not found`);
      return res.status(404).json({ status: "error", message: "User not found" });
    }

    const now = new Date();
    const oneYear = 365 * 24 * 60 * 60 * 1000;

    if (isSOB_alert_premium !== undefined) {
      user.isSOB_alert_premium = isSOB_alert_premium;
      user.SOB_alert_expiresAt = isSOB_alert_premium ? new Date(now.getTime() + oneYear) : null;
    }

    if (isXaud_alert_premium !== undefined) {
      user.isXaud_alert_premium = isXaud_alert_premium;
      user.Xaud_alert_expiresAt = isXaud_alert_premium ? new Date(now.getTime() + oneYear) : null;
    }

    if (isCrypto_alert_premium !== undefined) {
      user.isCrypto_alert_premium = isCrypto_alert_premium;
      user.Crypto_alert_expiresAt = isCrypto_alert_premium ? new Date(now.getTime() + oneYear) : null;
    }

    await user.save();
    console.log(`[log] PUT /users/alert-access/${firebaseUid} — 200: updated successfully`);

    res.json({
      status: "success",
      message: "User alert access updated successfully",
      user,
    });
  } catch (err) {
    console.error(`[log] PUT /users/alert-access/${firebaseUid} — 500:`, err.message);
    res.status(500).json({ status: "error", message: "Failed to update alert access" });
  }
};
