import User from "../models/User.js";

export const searchUser = async (req, res) => {
  const { query } = req.query;

  if (!query || query.trim().length === 0) {
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
      return res.status(404).json({ status: "error", message: "User not found" });
    }

    res.json({ status: "success", user });
  } catch (err) {
    console.error("Error searching user:", err.message);
    res.status(500).json({ status: "error", message: "Failed to search user" });
  }
};

export const updateUserAlertAccess = async (req, res) => {
  const { firebaseUid } = req.params;
  const { isSOB_alert_premium, isXaud_alert_premium, isCrypto_alert_premium } = req.body;

  try {
    const user = await User.findOne({ firebaseUid });
    if (!user) {
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

    res.json({
      status: "success",
      message: "User alert access updated successfully",
      user,
    });
  } catch (err) {
    console.error("Error updating user alert access:", err.message);
    res.status(500).json({ status: "error", message: "Failed to update alert access" });
  }
};
