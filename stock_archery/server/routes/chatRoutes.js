const express = require('express');
const router = express.Router();
const chatController = require('../controllers/chatController');
const requireAuth = require('../middleware/auth');

router.post('/chat', requireAuth, chatController.chat);
router.post('/chart-analysis', requireAuth, chatController.chartAnalysis);

module.exports = router;
