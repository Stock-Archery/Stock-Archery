const express = require('express');
const router = express.Router();
const chatController = require('../controllers/chatController');
const requireAuth = require('../middleware/auth');

router.post('/chat', requireAuth, chatController.chat);
router.post('/chart-analysis', requireAuth, chatController.chartAnalysis);
router.get('/chat/history', requireAuth, chatController.getHistory);
router.delete('/chat/history', requireAuth, chatController.clearHistory);

module.exports = router;
