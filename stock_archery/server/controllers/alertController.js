const AlertPost = require('../models/AlertPost');

exports.getAlertsByCategory = async (req, res) => {
  const { category } = req.params;

  if (!['SOB', 'XAUD', 'Crypto'].includes(category)) {
    return res
      .status(400)
      .json({ status: 'error', message: 'category must be SOB, XAUD, or Crypto' });
  }

  try {
    const alerts = await AlertPost.find({ category }).sort({ createdAt: 1 });
    res.json(alerts);
  } catch (err) {
    console.error('Error fetching alerts:', err.message);
    res.status(500).json({ message: 'Failed to fetch alerts' });
  }
};
