const mongoose = require('mongoose');

const recommendationSchema = new mongoose.Schema({
  type: String,
  stocks: [String],
  updatedAt: String
}, { collection: 'recommendations' });

module.exports = mongoose.model('Recommendation', recommendationSchema);
