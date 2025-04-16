const httpStatus = require('http-status');
const Device = require('../models/device.model');
const tokenService = require('../services/token.service');
const logger = require('../utils/logger');

const authMiddleware = {
    /**
     * Authenticate request with JWT
     * @param {Object} req - Express request object
     * @param {Object} res - Express response object
     * @param {Function} next - Express next function
     */
    authenticate: async (req, res, next) => {
        try {
            // Get token from header
            const authHeader = req.headers.authorization;
            if (!authHeader || !authHeader.startsWith('Bearer ')) {
                return res.status(httpStatus.UNAUTHORIZED).json({
                    success: false,
                    message: 'Access token is required',
                    error: 'Authorization header is missing or invalid'
                });
            }

            const token = authHeader.split(' ')[1];

            // Verify token
            const tokenVerification = await tokenService.verifyAccessToken(token);
            
            // Check if token is expiring soon
            if (tokenVerification.status === 'expiring_soon') {
                // Token is valid but expiring soon
                // We'll still process the request but add a header to notify the client
                res.set('X-Token-Expiring-Soon', 'true');
                res.set('X-Token-Expires-In', tokenVerification.expiresIn.toString());
            }

            // Attach user to request
            req.user = {
                id: tokenVerification.payload.sub,
                email: tokenVerification.payload.email
            };

            next();
        } catch (error) {
            logger.error('Authentication error:', error);

            let status = httpStatus.UNAUTHORIZED;
            let message = 'Not authorized to access this resource';
            let errorResponse = {
                success: false,
                message,
                error: error.message
            };

            if (error.message === 'Token expired') {
                message = 'Access token expired';
                errorResponse = {
                    success: false,
                    message,
                    error: error.message,
                    code: 'token_expired',
                    needsRefresh: true
                };
            } else if (error.message === 'Invalid token') {
                message = 'Invalid access token';
            }

            return res.status(status).json(errorResponse);
        }
    },

    /**
     * Verify device ownership
     * @param {Object} req - Express request object
     * @param {Object} res - Express response object
     * @param {Function} next - Express next function
     */
    verifyDeviceOwnership: async (req, res, next) => {
        try {
            const deviceId = req.params.deviceId || req.body.deviceId;
            const device = await Device.findByPk(deviceId);

            if (!device) {
                return res.status(httpStatus.NOT_FOUND).json({
                    success: false,
                    message: 'Device not found',
                    error: 'The requested device does not exist'
                });
            }

            if (device.user_id !== req.user.id) {
                return res.status(httpStatus.FORBIDDEN).json({
                    success: false,
                    message: 'Forbidden',
                    error: 'You do not have permission to access this device'
                });
            }

            next();
        } catch (error) {
            logger.error('Device ownership verification error:', error);
            return res.status(httpStatus.INTERNAL_SERVER_ERROR).json({
                success: false,
                message: 'Failed to verify device ownership',
                error: error.message
            });
        }
    }
};

module.exports = authMiddleware;