const Recommendation = require('../models/Recommendation');

exports.getRecommendations = async (req, res) => {
  try {
    const data = await Recommendation.findOne({ type: 'current_recommendations' });
    if (data) {
      res.json(data.stocks);
    } else {
      res.status(404).json({ message: 'No recommendations found' });
    }
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
};
