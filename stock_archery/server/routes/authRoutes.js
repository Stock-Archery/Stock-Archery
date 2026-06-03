const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const requireAuth = require('../middleware/auth');

router.post('/send-otp', authController.sendOtp);
router.post('/sync', requireAuth, authController.syncUser);

module.exports = router;
