const jwt = require('jsonwebtoken');
const {v4: uuidv4} = require('uuid');
const JWT_CONFIG = require('../config/jwt');
const {redisHelpers} = require('../config/redis');
const logger = require('../utils/logger');

const tokenService = {
    /**
     * Generate access and refresh tokens
     * @param {Object} user - User object
     * @returns {Object} - Access and refresh tokens with expiration
     */
    generateAuthTokens: async (user) => {
        try {
            // Generate token payloads
            const tokenPayload = {
                sub: user.id,
                email: user.email,
                type: 'access'
            };

            const refreshTokenId = uuidv4();
            const refreshPayload = {
                sub: user.id,
                jti: refreshTokenId, // JWT ID for token identification
                type: 'refresh'
            };

            // Generate JWT tokens
            const accessToken = jwt.sign(
                tokenPayload,
                JWT_CONFIG.ACCESS_TOKEN.SECRET,
                {expiresIn: JWT_CONFIG.ACCESS_TOKEN.EXPIRES_IN}
            );

            const refreshToken = jwt.sign(
                refreshPayload,
                JWT_CONFIG.REFRESH_TOKEN.SECRET,
                {expiresIn: JWT_CONFIG.REFRESH_TOKEN.EXPIRES_IN}
            );

            // Decode tokens to get expiration time
            const decodedAccess = jwt.decode(accessToken);
            const decodedRefresh = jwt.decode(refreshToken);

            // Store refresh token in Redis
            const refreshExpirySeconds = Math.floor(decodedRefresh.exp - decodedRefresh.iat);
            await redisHelpers.storeRefreshToken(refreshTokenId, user.id, refreshExpirySeconds);

            return {
                access: {
                    token: accessToken,
                    expires: new Date(decodedAccess.exp * 1000)
                },
                refresh: {
                    token: refreshToken,
                    expires: new Date(decodedRefresh.exp * 1000)
                }
            };
        } catch (error) {
            logger.error('Error generating auth tokens:', error);
            throw new Error('Failed to generate authentication tokens');
        }
    },

    /**
     * Generate session token for real-time connections
     * @param {string} userId - User ID
     * @param {string} sessionId - Session ID
     * @returns {Object} - Session token with expiration
     */
    generateSessionToken: (userId, sessionId) => {
        try {
            const payload = {
                sub: userId,
                session: sessionId,
                type: 'session'
            };

            const sessionToken = jwt.sign(
                payload,
                JWT_CONFIG.SESSION_TOKEN.SECRET,
                {expiresIn: JWT_CONFIG.SESSION_TOKEN.EXPIRES_IN}
            );

            const decoded = jwt.decode(sessionToken);

            return {
                token: sessionToken,
                expires: new Date(decoded.exp * 1000)
            };
        } catch (error) {
            logger.error('Error generating session token:', error);
            throw new Error('Failed to generate session token');
        }
    },

    /**
     * Verify access token
     * @param {string} token - JWT token
     * @returns {Object} - Decoded token payload
     */
    verifyAccessToken: async (token) => {
        try {
            // Check if token is blacklisted
            const isBlacklisted = await redisHelpers.isTokenBlacklisted(token);
            if (isBlacklisted) {
                throw new Error('Token has been revoked');
            }

            return jwt.verify(token, JWT_CONFIG.ACCESS_TOKEN.SECRET);
        } catch (error) {
            if (error.name === 'JsonWebTokenError') {
                throw new Error('Invalid token');
            } else if (error.name === 'TokenExpiredError') {
                throw new Error('Token expired');
            }
            throw error;
        }
    },

    /**
     * Verify refresh token
     * @param {string} token - JWT refresh token
     * @returns {Object} - Decoded token payload
     */
    verifyRefreshToken: async (token) => {
        try {
            const decoded = jwt.verify(token, JWT_CONFIG.REFRESH_TOKEN.SECRET);

            // Check if token type is refresh
            if (decoded.type !== 'refresh') {
                throw new Error('Invalid token type');
            }

            // Check if token exists in Redis
            const userId = await redisHelpers.getUserIdFromRefreshToken(decoded.jti);
            if (!userId) {
                throw new Error('Token not found or expired');
            }

            // Verify that the token belongs to the user
            if (userId !== decoded.sub) {
                throw new Error('Token does not match user');
            }

            return decoded;
        } catch (error) {
            if (error.name === 'JsonWebTokenError') {
                throw new Error('Invalid token');
            } else if (error.name === 'TokenExpiredError') {
                throw new Error('Token expired');
            }
            throw error;
        }
    },

    /**
     * Verify session token
     * @param {string} token - JWT session token
     * @returns {Object} - Decoded token payload
     */
    verifySessionToken: (token) => {
        try {
            const decoded = jwt.verify(token, JWT_CONFIG.SESSION_TOKEN.SECRET);

            // Check if token type is session
            if (decoded.type !== 'session') {
                throw new Error('Invalid token type');
            }

            return decoded;
        } catch (error) {
            if (error.name === 'JsonWebTokenError') {
                throw new Error('Invalid token');
            } else if (error.name === 'TokenExpiredError') {
                throw new Error('Token expired');
            }
            throw error;
        }
    },

    /**
     * Revoke access token (add to blacklist)
     * @param {string} token - JWT token
     */
    revokeAccessToken: async (token) => {
        try {
            const decoded = jwt.decode(token);
            if (!decoded) {
                throw new Error('Invalid token');
            }

            // Add token to blacklist in Redis
            await redisHelpers.blacklistToken(token, decoded.exp);
        } catch (error) {
            logger.error('Error revoking access token:', error);
            throw error;
        }
    },

    /**
     * Revoke refresh token
     * @param {string} token - JWT refresh token
     */
    revokeRefreshToken: async (token) => {
        try {
            const decoded = jwt.decode(token);
            if (!decoded || !decoded.jti) {
                throw new Error('Invalid token');
            }

            // Remove refresh token from Redis
            await redisHelpers.removeRefreshToken(decoded.jti);
        } catch (error) {
            logger.error('Error revoking refresh token:', error);
            throw error;
        }
    }
};

module.exports = tokenService;