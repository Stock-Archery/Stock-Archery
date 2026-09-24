const AlertPost = require('../models/AlertPost');

exports.getAlertsByCategory = async (req, res) => {
  const { category } = req.params;

  if (!['SOB', 'XAUD', 'Crypto'].includes(category)) {
    return res
      .status(400)
      .json({ status: 'error', message: 'category must be SOB, XAUD, or Crypto' });
  }

  try {
    // Only serve alerts from the last 7 days — older alerts are hidden from the app.
    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    // imageFileId is internal (the admin server uses it to delete the image
    // from ImageKit), so it isn't sent to the app. Clients show `imageUrl`
    // and fall back to the legacy `imageBase64` on posts not yet migrated.
    const alerts = await AlertPost.find({
      category,
      createdAt: { $gte: sevenDaysAgo },
    })
      .select('-imageFileId')
      .sort({ createdAt: -1 });
    res.json(alerts);
  } catch (err) {
    console.error('Error fetching alerts:', err.message);
    res.status(500).json({ message: 'Failed to fetch alerts' });
  }
};
