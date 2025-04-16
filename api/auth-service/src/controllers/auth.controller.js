const httpStatus = require('http-status');
const authService = require('../services/auth.service');
const emailService = require('../services/email.service');
const tokenService = require('../services/token.service');
const logger = require('../utils/logger');

const authController = {
    /**
     * Register a new user
     * @param {Object} req - Express request object
     * @param {Object} res - Express response object
     * @param {Function} next - Express next function
     */
    register: async (req, res, next) => {
        try {
            const {email, password, device_info} = req.body;

            // Register user
            const newUser = await authService.register({email, password});

            // Send verification email
            // This is a placeholder - implement email service as needed
            if (newUser.verification_token) {
                await emailService.sendVerificationEmail(
                    newUser.email,
                    newUser.verification_token
                );
            }

            // Return response
            return res.status(httpStatus.CREATED).json({
                success: true,
                data: {
                    user: {
                        id: newUser.id,
                        email: newUser.email,
                        is_verified: newUser.is_verified
                    }
                },
                message: 'Registration successful. Please verify your email.'
            });
        } catch (error) {
            next(error);
        }
    },

    /**
     * Login user
     * @param {Object} req - Express request object
     * @param {Object} res - Express response object
     * @param {Function} next - Express next function
     */
    login: async (req, res, next) => {
        try {
            const {email, password, device_info} = req.body;

            // Login user
            const {user, tokens} = await authService.login(email, password, device_info);

            // Return response
            return res.status(httpStatus.OK).json({
                success: true,
                data: {
                    user,
                    access_token: tokens.access.token,
                    refresh_token: tokens.refresh.token,
                    expires_in: Math.floor((tokens.access.expires - new Date()) / 1000)
                },
                message: 'Login successful'
            });
        } catch (error) {
            next(error);
        }
    },

    /**
     * Logout user
     * @param {Object} req - Express request object
     * @param {Object} res - Express response object
     * @param {Function} next - Express next function
     */
    logout: async (req, res, next) => {
        try {
            const authHeader = req.headers.authorization;
            const accessToken = authHeader.split(' ')[1];
            const {refresh_token} = req.body;

            // Logout user
            await authService.logout(accessToken, refresh_token);

            // Return response
            return res.status(httpStatus.OK).json({
                success: true,
                message: 'Logout successful'
            });
        } catch (error) {
            next(error);
        }
    },

    /**
     * Refresh token
     * @param {Object} req - Express request object
     * @param {Object} res - Express response object
     * @param {Function} next - Express next function
     */
    refreshToken: async (req, res, next) => {
        try {
            const {refresh_token} = req.body;

            // Refresh token
            const tokens = await authService.refreshAuth(refresh_token);

            // Return response
            return res.status(httpStatus.OK).json({
                success: true,
                data: {
                    access_token: tokens.access.token,
                    refresh_token: tokens.refresh.token,
                    expires_in: Math.floor((tokens.access.expires - new Date()) / 1000)
                },
                message: 'Token refreshed successfully'
            });
        } catch (error) {
            next(error);
        }
    },

    /**
     * Check token status
     * @param {Object} req - Express request object
     * @param {Object} res - Express response object
     * @param {Function} next - Express next function
     */
    checkTokenStatus: async (req, res, next) => {
        try {
            const authHeader = req.headers.authorization;
            
            if (!authHeader || !authHeader.startsWith('Bearer ')) {
                return res.status(httpStatus.BAD_REQUEST).json({
                    success: false,
                    message: 'Access token is required'
                });
            }
            
            const token = authHeader.split(' ')[1];
            
            // Check token status
            const status = await tokenService.checkTokenStatus(token);
            
            return res.status(httpStatus.OK).json({
                success: true,
                data: status
            });
        } catch (error) {
            next(error);
        }
    },
    
    /**
     * Proactively refresh token
     * @param {Object} req - Express request object
     * @param {Object} res - Express response object
     * @param {Function} next - Express next function
     */
    proactiveTokenRefresh: async (req, res, next) => {
        try {
            const authHeader = req.headers.authorization;
            
            if (!authHeader || !authHeader.startsWith('Bearer ')) {
                return res.status(httpStatus.BAD_REQUEST).json({
                    success: false,
                    message: 'Access token is required'
                });
            }
            
            const token = authHeader.split(' ')[1];
            
            // Try to refresh token proactively
            const newToken = await tokenService.proactiveTokenRefresh(token);
            
            if (!newToken) {
                return res.status(httpStatus.OK).json({
                    success: true,
                    data: {
                        refreshed: false,
                        message: 'Token refresh not needed'
                    }
                });
            }
            
            return res.status(httpStatus.OK).json({
                success: true,
                data: {
                    refreshed: true,
                    access_token: newToken.token,
                    expires_in: Math.floor((newToken.expires - new Date()) / 1000)
                },
                message: 'Token refreshed proactively'
            });
        } catch (error) {
            next(error);
        }
    },

    /**
     * Verify email
     * @param {Object} req - Express request object
     * @param {Object} res - Express response object
     * @param {Function} next - Express next function
     */
    verifyEmail: async (req, res, next) => {
        try {
            const {token} = req.query;

            if (!token) {
                return res.status(httpStatus.BAD_REQUEST).json({
                    success: false,
                    message: 'Verification token is required'
                });
            }

            // Verify email
            const user = await authService.verifyEmail(token);

            // Return response
            return res.status(httpStatus.OK).json({
                success: true,
                data: {
                    user
                },
                message: 'Email verified successfully'
            });
        } catch (error) {
            next(error);
        }
    },

    /**
     * Request password reset
     * @param {Object} req - Express request object
     * @param {Object} res - Express response object
     * @param {Function} next - Express next function
     */
    forgotPassword: async (req, res, next) => {
        try {
            const {email} = req.body;

            if (!email) {
                return res.status(httpStatus.BAD_REQUEST).json({
                    success: false,
                    message: 'Email is required'
                });
            }

            // Request password reset
            const result = await authService.requestPasswordReset(email);

            // Send password reset email
            if (result.resetToken) {
                await emailService.sendPasswordResetEmail(
                    result.email,
                    result.resetToken
                );
            }

            // Return response (always the same for security)
            return res.status(httpStatus.OK).json({
                success: true,
                message: 'If your email is registered, you will receive a password reset link'
            });
        } catch (error) {
            // Return the same response even if there's an error (for security)
            return res.status(httpStatus.OK).json({
                success: true,
                message: 'If your email is registered, you will receive a password reset link'
            });
        }
    },

    /**
     * Reset password
     * @param {Object} req - Express request object
     * @param {Object} res - Express response object
     * @param {Function} next - Express next function
     */
    resetPassword: async (req, res, next) => {
        try {
            const {token, password} = req.body;

            if (!token || !password) {
                return res.status(httpStatus.BAD_REQUEST).json({
                    success: false,
                    message: 'Token and password are required'
                });
            }

            // Reset password
            const user = await authService.resetPassword(token, password);

            // Return response
            return res.status(httpStatus.OK).json({
                success: true,
                data: {
                    user
                },
                message: 'Password reset successfully'
            });
        } catch (error) {
            next(error);
        }
    }
};

module.exports = authController;