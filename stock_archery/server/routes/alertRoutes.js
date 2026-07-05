const express = require('express');
const router = express.Router();
const alertController = require('../controllers/alertController');

router.get('/:category', alertController.getAlertsByCategory);

module.exports = router;
