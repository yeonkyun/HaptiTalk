const express = require('express');
const authController = require('../controllers/auth.controller');
const serviceAuthController = require('../controllers/service-auth.controller');
const {validate, authValidation, serviceAuthValidation} = require('../middleware/validation.middleware');
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

// Token status check
router.get(
    '/token/status',
    authController.checkTokenStatus
);

// Proactive token refresh
router.post(
    '/token/proactive-refresh',
    authController.proactiveTokenRefresh
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

// 서비스 간 통신을 위한 토큰 발급
router.post(
    '/service-token',
    validate(serviceAuthValidation.generateToken),
    serviceAuthController.generateServiceToken
);

// 서비스 토큰 검증
router.post(
    '/service-token/verify',
    validate(serviceAuthValidation.verifyToken),
    serviceAuthController.verifyServiceToken
);

// 서비스 토큰 폐기
router.post(
    '/service-token/revoke',
    validate(serviceAuthValidation.revokeToken),
    serviceAuthController.revokeServiceToken
);

module.exports = router;