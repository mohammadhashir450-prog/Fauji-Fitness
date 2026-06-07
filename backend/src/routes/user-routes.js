const express = require('express');
const router = express.Router();
const userController = require('../controllers/user-controller');
const authMiddleware = require('../middlewares/auth-middleware');

// Get current user profile (protected)
router.get('/profile', authMiddleware, userController.getUserProfile);

// Update current user profile (protected)
router.put('/profile', authMiddleware, userController.updateUserProfile);

module.exports = router;
