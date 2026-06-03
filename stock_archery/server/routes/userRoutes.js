const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const requireAuth = require('../middleware/auth');

router.post('/device/register', requireAuth, userController.registerDevice);
router.post('/device/unregister', requireAuth, userController.unregisterDevice);

module.exports = router;
