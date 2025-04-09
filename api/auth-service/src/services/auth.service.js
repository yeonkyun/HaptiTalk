const httpStatus = require('http-status');
const User = require('../models/user.model');
const tokenService = require('./token.service');
const logger = require('../utils/logger');
const {v4: uuidv4} = require('uuid');

const MAX_LOGIN_ATTEMPTS = 5;
const LOCK_TIME_MINUTES = 30;

const authService = {
    /**
     * Register a new user
     * @param {Object} userData - User registration data
     * @returns {Object} - Created user object
     */
    register: async (userData) => {
        try {
            // Check if user with email already exists
            const existingUser = await User.findByEmail(userData.email);
            if (existingUser) {
                const error = new Error('Email already registered');
                error.statusCode = httpStatus.CONFLICT;
                throw error;
            }

            // Create verification token
            const verificationToken = uuidv4();

            // Create new user
            const user = await User.create({
                email: userData.email,
                password_hash: userData.password,
                verification_token: verificationToken,
                is_active: true,
                is_verified: false
            });

            return {
                id: user.id,
                email: user.email,
                is_verified: user.is_verified,
                verification_token: user.verification_token
            };
        } catch (error) {
            logger.error('Error registering user:', error);
            throw error;
        }
    },

    /**
     * Login with email and password
     * @param {string} email - User email
     * @param {string} password - User password
     * @param {Object} deviceInfo - User device information
     * @returns {Object} - User object and tokens
     */
    login: async (email, password, deviceInfo) => {
        try {
            // Find user by email
            const user = await User.findByEmail(email);
            if (!user) {
                const error = new Error('Invalid email or password');
                error.statusCode = httpStatus.UNAUTHORIZED;
                throw error;
            }

            // Check if account is locked
            if (user.locked_until && user.locked_until > new Date()) {
                const error = new Error('Account is locked. Try again later');
                error.statusCode = httpStatus.FORBIDDEN;
                error.lockUntil = user.locked_until;
                throw error;
            }

            // Verify password
            const isPasswordValid = await user.validPassword(password);
            if (!isPasswordValid) {
                // Increment login attempts
                await User.incrementLoginAttempts(user.id);

                // Check if account should be locked
                if (user.login_attempts + 1 >= MAX_LOGIN_ATTEMPTS) {
                    await User.lockAccount(user.id, LOCK_TIME_MINUTES);
                    const error = new Error(`Account locked due to too many failed attempts. Try again after ${LOCK_TIME_MINUTES} minutes`);
                    error.statusCode = httpStatus.FORBIDDEN;
                    throw error;
                }

                const error = new Error('Invalid email or password');
                error.statusCode = httpStatus.UNAUTHORIZED;
                throw error;
            }

            // Password is valid, reset login attempts
            await User.resetLoginAttempts(user.id);

            // Update last login timestamp
            await user.update({last_login: new Date()});

            // Generate auth tokens
            const tokens = await tokenService.generateAuthTokens(user);

            return {
                user: {
                    id: user.id,
                    email: user.email,
                    is_verified: user.is_verified
                },
                tokens
            };
        } catch (error) {
            logger.error('Error during login:', error);
            throw error;
        }
    },

    /**
     * Logout user
     * @param {string} accessToken - JWT access token
     * @param {string} refreshToken - JWT refresh token
     */
    logout: async (accessToken, refreshToken) => {
        try {
            // Revoke tokens
            await Promise.all([
                tokenService.revokeAccessToken(accessToken),
                tokenService.revokeRefreshToken(refreshToken)
            ]);
        } catch (error) {
            logger.error('Error during logout:', error);
            throw error;
        }
    },

    /**
     * Refresh auth tokens
     * @param {string} refreshToken - JWT refresh token
     * @returns {Object} - New access and refresh tokens
     */
    refreshAuth: async (refreshToken) => {
        try {
            // Verify refresh token
            const refreshTokenPayload = await tokenService.verifyRefreshToken(refreshToken);

            // Get user
            const user = await User.findByPk(refreshTokenPayload.sub);
            if (!user) {
                throw new Error('User not found');
            }

            // Revoke old refresh token
            await tokenService.revokeRefreshToken(refreshToken);

            // Generate new tokens
            const tokens = await tokenService.generateAuthTokens(user);

            return tokens;
        } catch (error) {
            logger.error('Error refreshing auth:', error);
            throw error;
        }
    },

    /**
     * Verify email
     * @param {string} verificationToken - Email verification token
     * @returns {Object} - Updated user
     */
    verifyEmail: async (verificationToken) => {
        try {
            // Find user with verification token
            const user = await User.findOne({where: {verification_token: verificationToken}});
            if (!user) {
                const error = new Error('Invalid or expired verification token');
                error.statusCode = httpStatus.BAD_REQUEST;
                throw error;
            }

            // Update user
            await user.update({
                is_verified: true,
                verification_token: null
            });

            return {
                id: user.id,
                email: user.email,
                is_verified: true
            };
        } catch (error) {
            logger.error('Error verifying email:', error);
            throw error;
        }
    },

    /**
     * Request password reset
     * @param {string} email - User email
     * @returns {Object} - Reset token info
     */
    requestPasswordReset: async (email) => {
        try {
            // Find user by email
            const user = await User.findByEmail(email);
            if (!user) {
                // For security, don't reveal that email doesn't exist
                return {message: 'If your email is registered, you will receive a password reset link'};
            }

            // Generate reset token
            const resetToken = uuidv4();
            const resetTokenExpires = new Date(Date.now() + 3600000); // 1 hour

            // Update user
            await user.update({
                reset_token: resetToken,
                reset_token_expires_at: resetTokenExpires
            });

            return {
                email: user.email,
                resetToken,
                expiresAt: resetTokenExpires
            };
        } catch (error) {
            logger.error('Error requesting password reset:', error);
            throw error;
        }
    },

    /**
     * Reset password
     * @param {string} resetToken - Password reset token
     * @param {string} newPassword - New password
     * @returns {Object} - Updated user
     */
    resetPassword: async (resetToken, newPassword) => {
        try {
            // Find user with reset token
            const user = await User.findOne({
                where: {
                    reset_token: resetToken,
                    reset_token_expires_at: {[sequelize.Op.gt]: new Date()}
                }
            });

            if (!user) {
                const error = new Error('Invalid or expired reset token');
                error.statusCode = httpStatus.BAD_REQUEST;
                throw error;
            }

            // Update user password
            await user.update({
                password_hash: newPassword,
                reset_token: null,
                reset_token_expires_at: null,
                login_attempts: 0,
                locked_until: null
            });

            return {
                id: user.id,
                email: user.email
            };
        } catch (error) {
            logger.error('Error resetting password:', error);
            throw error;
        }
    }
};

module.exports = authService;