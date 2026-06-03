const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notificationController');
const requireAuth = require('../middleware/auth');

router.post('/test/push', requireAuth, notificationController.testPush);
router.post('/admin/push/broadcast', requireAuth, notificationController.broadcastPush);

module.exports = router;
