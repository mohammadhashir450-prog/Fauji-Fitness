const express = require("express");
const router = express.Router();
const authController = require("../controllers/auth-controller");

// Registration route
router.post("/register", authController.register);

// Login route
router.post("/login", authController.login);

// Google Sign-In verification route
router.post("/google-verify", authController.verifyGoogleToken);

// User information route
router.get("/me", authController.me);

module.exports = router;
