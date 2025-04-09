const httpStatus = require('http-status');
const deviceService = require('../services/device.service');
const logger = require('../utils/logger');

const deviceController = {
    /**
     * Register a new device
     * @param {Object} req - Express request object
     * @param {Object} res - Express response object
     * @param {Function} next - Express next function
     */
    registerDevice: async (req, res, next) => {
        try {
            const userId = req.user.id;
            const deviceData = req.body;

            // Register device
            const device = await deviceService.registerDevice(userId, deviceData);

            // Return response
            return res.status(httpStatus.CREATED).json({
                success: true,
                data: {
                    device
                },
                message: 'Device registered successfully'
            });
        } catch (error) {
            next(error);
        }
    },

    /**
     * Get all user devices
     * @param {Object} req - Express request object
     * @param {Object} res - Express response object
     * @param {Function} next - Express next function
     */
    getUserDevices: async (req, res, next) => {
        try {
            const userId = req.user.id;

            // Get user devices
            const devices = await deviceService.getUserDevices(userId);

            // Return response
            return res.status(httpStatus.OK).json({
                success: true,
                data: {
                    devices
                },
                message: 'Devices retrieved successfully'
            });
        } catch (error) {
            next(error);
        }
    },

    /**
     * Get device by ID
     * @param {Object} req - Express request object
     * @param {Object} res - Express response object
     * @param {Function} next - Express next function
     */
    getDevice: async (req, res, next) => {
        try {
            const {deviceId} = req.params;

            // Get device
            const device = await deviceService.getDevice(deviceId);

            // Return response
            return res.status(httpStatus.OK).json({
                success: true,
                data: {
                    device
                },
                message: 'Device retrieved successfully'
            });
        } catch (error) {
            next(error);
        }
    },

    /**
     * Update device
     * @param {Object} req - Express request object
     * @param {Object} res - Express response object
     * @param {Function} next - Express next function
     */
    updateDevice: async (req, res, next) => {
        try {
            const {deviceId} = req.params;
            const updateData = req.body;

            // Update device
            const device = await deviceService.updateDevice(deviceId, updateData);

            // Return response
            return res.status(httpStatus.OK).json({
                success: true,
                data: {
                    device
                },
                message: 'Device updated successfully'
            });
        } catch (error) {
            next(error);
        }
    },

    /**
     * Delete device
     * @param {Object} req - Express request object
     * @param {Object} res - Express response object
     * @param {Function} next - Express next function
     */
    deleteDevice: async (req, res, next) => {
        try {
            const {deviceId} = req.params;

            // Delete device
            await deviceService.deleteDevice(deviceId);

            // Return response
            return res.status(httpStatus.OK).json({
                success: true,
                message: 'Device deleted successfully'
            });
        } catch (error) {
            next(error);
        }
    },

    /**
     * Pair devices
     * @param {Object} req - Express request object
     * @param {Object} res - Express response object
     * @param {Function} next - Express next function
     */
    pairDevices: async (req, res, next) => {
        try {
            const {deviceId} = req.params; // Mobile device ID
            const {watch_device_id} = req.body; // Watch device ID

            // Pair devices
            const result = await deviceService.pairDevices(deviceId, watch_device_id);

            // Return response
            return res.status(httpStatus.OK).json({
                success: true,
                data: {
                    mobile_device: result.mobileDevice,
                    watch_device: result.watchDevice
                },
                message: 'Devices paired successfully'
            });
        } catch (error) {
            next(error);
        }
    },

    /**
     * Unpair devices
     * @param {Object} req - Express request object
     * @param {Object} res - Express response object
     * @param {Function} next - Express next function
     */
    unpairDevices: async (req, res, next) => {
        try {
            const {deviceId} = req.params; // Watch device ID

            // Unpair devices
            const device = await deviceService.unpairDevices(deviceId);

            // Return response
            return res.status(httpStatus.OK).json({
                success: true,
                data: {
                    device
                },
                message: 'Device unpaired successfully'
            });
        } catch (error) {
            next(error);
        }
    }
};

module.exports = deviceController;