const express = require('express');
const briefingController = require('./briefing.controller');

const router = express.Router();

/**
 * @route POST /webhook/update-briefing-config
 * Updates the briefing configuration (topics/tickers)
 */
router.post('/update-briefing-config', briefingController.updateConfig);

module.exports = router;
