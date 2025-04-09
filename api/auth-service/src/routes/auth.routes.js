const express = require('express');
const authController = require('../controllers/auth.controller');
const {validate, authValidation} = require('../middleware/validation.middleware');
const {authenticate} = require('../middleware/auth.middleware');

const router = express.Router();

// Register a new user
router.post(
    '/register',
    validate(authValidation.register),
    authController.register
);

// Login
router.post(
    '/login',
    validate(authValidation.login),
    authController.login
);

// Logout (requires authentication)
router.post(
    '/logout',
    authenticate,
    authController.logout
);

// Refresh token
router.post(
    '/refresh',
    validate(authValidation.refreshToken),
    authController.refreshToken
);

// Verify email
router.get(
    '/verify-email',
    authController.verifyEmail
);

// Request password reset
router.post(
    '/forgot-password',
    authController.forgotPassword
);

// Reset password
router.post(
    '/reset-password',
    authController.resetPassword
);

module.exports = router;