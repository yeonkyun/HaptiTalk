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
            const payload = await tokenService.verifyAccessToken(token);

            // Attach user to request
            req.user = {
                id: payload.sub,
                email: payload.email
            };

            next();
        } catch (error) {
            logger.error('Authentication error:', error);

            let status = httpStatus.UNAUTHORIZED;
            let message = 'Not authorized to access this resource';

            if (error.message === 'Token expired') {
                message = 'Access token expired';
            } else if (error.message === 'Invalid token') {
                message = 'Invalid access token';
            }

            return res.status(status).json({
                success: false,
                message,
                error: error.message
            });
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