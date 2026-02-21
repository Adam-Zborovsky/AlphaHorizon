const mongoose = require('mongoose');

const briefingConfigSchema = new mongoose.Schema({
  topics: {
    type: [String],
    default: [],
  },
  tickers: {
    type: [String],
    default: [],
  },
}, {
  timestamps: true,
});

// Since we only have one configuration for now, we'll use a single document
// or just always retrieve the latest.
module.exports = mongoose.model('BriefingConfig', briefingConfigSchema);
