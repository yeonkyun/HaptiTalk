const httpStatus = require('http-status');
const logger = require('../utils/logger');

/**
 * Error handler middleware
 * @param {Object} err - Error object
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 * @param {Function} next - Express next function
 */
const errorHandler = (err, req, res, next) => {
    let statusCode = err.statusCode || httpStatus.INTERNAL_SERVER_ERROR;
    let message = err.message || 'Internal Server Error';
    let errorDetails = process.env.NODE_ENV === 'development' ? err.stack : undefined;

    // Specific error handling
    if (err.name === 'SequelizeValidationError') {
        statusCode = httpStatus.BAD_REQUEST;
        message = 'Validation Error';
        const errors = err.errors.map(e => ({
            field: e.path,
            message: e.message
        }));

        return res.status(statusCode).json({
            success: false,
            message,
            errors
        });
    }

    // Handle Sequelize unique constraint error
    if (err.name === 'SequelizeUniqueConstraintError') {
        statusCode = httpStatus.CONFLICT;
        message = 'Duplicate Entry';
        const errors = err.errors.map(e => ({
            field: e.path,
            message: e.message
        }));

        return res.status(statusCode).json({
            success: false,
            message,
            errors
        });
    }

    // Log error
    logger.error(`Error: ${statusCode} - ${message}`, {
        error: err.message,
        stack: err.stack,
        url: req.originalUrl,
        method: req.method
    });

    // Send response
    return res.status(statusCode).json({
        success: false,
        message,
        error: err.message,
        ...(errorDetails && {stack: errorDetails})
    });
};

module.exports = errorHandler;