const Device = require('../models/device.model');
const logger = require('../utils/logger');

const deviceService = {
    /**
     * Register a new device
     * @param {string} userId - User ID
     * @param {Object} deviceData - Device information
     * @returns {Object} - Created device
     */
    registerDevice: async (userId, deviceData) => {
        try {
            // Check if device with same token exists
            let device = null;
            if (deviceData.device_token) {
                device = await Device.findByUserDeviceToken(userId, deviceData.device_token);
            }

            if (device) {
                // Update existing device
                await device.update({
                    device_name: deviceData.device_name || device.device_name,
                    device_model: deviceData.device_model || device.device_model,
                    os_version: deviceData.os_version || device.os_version,
                    app_version: deviceData.app_version || device.app_version,
                    is_watch: deviceData.is_watch || device.is_watch,
                    paired_device_id: deviceData.paired_device_id || device.paired_device_id,
                    last_active: new Date()
                });
            } else {
                // Create new device
                device = await Device.create({
                    user_id: userId,
                    device_type: deviceData.device_type,
                    device_token: deviceData.device_token,
                    device_name: deviceData.device_name,
                    device_model: deviceData.device_model,
                    os_version: deviceData.os_version,
                    app_version: deviceData.app_version,
                    is_watch: deviceData.is_watch || false,
                    paired_device_id: deviceData.paired_device_id
                });
            }

            return device;
        } catch (error) {
            logger.error('Error registering device:', error);
            throw error;
        }
    },

    /**
     * Get all devices for a user
     * @param {string} userId - User ID
     * @returns {Array} - List of devices
     */
    getUserDevices: async (userId) => {
        try {
            return await Device.findAllByUser(userId);
        } catch (error) {
            logger.error('Error getting user devices:', error);
            throw error;
        }
    },

    /**
     * Get device by ID
     * @param {string} deviceId - Device ID
     * @returns {Object} - Device
     */
    getDevice: async (deviceId) => {
        try {
            const device = await Device.findByPk(deviceId);
            if (!device) {
                throw new Error('Device not found');
            }
            return device;
        } catch (error) {
            logger.error('Error getting device:', error);
            throw error;
        }
    },

    /**
     * Update device
     * @param {string} deviceId - Device ID
     * @param {Object} updateData - Update data
     * @returns {Object} - Updated device
     */
    updateDevice: async (deviceId, updateData) => {
        try {
            const device = await Device.findByPk(deviceId);
            if (!device) {
                throw new Error('Device not found');
            }

            await device.update({
                device_name: updateData.device_name !== undefined ? updateData.device_name : device.device_name,
                device_token: updateData.device_token !== undefined ? updateData.device_token : device.device_token,
                device_model: updateData.device_model !== undefined ? updateData.device_model : device.device_model,
                os_version: updateData.os_version !== undefined ? updateData.os_version : device.os_version,
                app_version: updateData.app_version !== undefined ? updateData.app_version : device.app_version,
                paired_device_id: updateData.paired_device_id !== undefined ? updateData.paired_device_id : device.paired_device_id,
                last_active: new Date()
            });

            return device;
        } catch (error) {
            logger.error('Error updating device:', error);
            throw error;
        }
    },

    /**
     * Delete device
     * @param {string} deviceId - Device ID
     * @returns {boolean} - Deletion success
     */
    deleteDevice: async (deviceId) => {
        try {
            const device = await Device.findByPk(deviceId);
            if (!device) {
                throw new Error('Device not found');
            }

            // Check if any watch is paired with this device
            const watches = await Device.findWatchesForDevice(deviceId);

            // Unlink paired watches before deletion
            for (const watch of watches) {
                await watch.update({paired_device_id: null});
            }

            await device.destroy();
            return true;
        } catch (error) {
            logger.error('Error deleting device:', error);
            throw error;
        }
    },

    /**
     * Pair a watch with mobile device
     * @param {string} mobileDeviceId - Mobile device ID
     * @param {string} watchDeviceId - Watch device ID
     * @returns {Object} - Paired devices
     */
    pairDevices: async (mobileDeviceId, watchDeviceId) => {
        try {
            const mobileDevice = await Device.findByPk(mobileDeviceId);
            if (!mobileDevice) {
                throw new Error('Mobile device not found');
            }

            const watchDevice = await Device.findByPk(watchDeviceId);
            if (!watchDevice) {
                throw new Error('Watch device not found');
            }

            // Verify both devices belong to the same user
            if (mobileDevice.user_id !== watchDevice.user_id) {
                throw new Error('Devices must belong to the same user');
            }

            // Update watch device with paired ID
            await watchDevice.update({
                paired_device_id: mobileDeviceId,
                is_watch: true
            });

            return {
                mobileDevice,
                watchDevice
            };
        } catch (error) {
            logger.error('Error pairing devices:', error);
            throw error;
        }
    },

    /**
     * Unpair devices
     * @param {string} watchDeviceId - Watch device ID
     * @returns {Object} - Unpaired device
     */
    unpairDevices: async (watchDeviceId) => {
        try {
            const watchDevice = await Device.findByPk(watchDeviceId);
            if (!watchDevice) {
                throw new Error('Watch device not found');
            }

            await watchDevice.update({
                paired_device_id: null
            });

            return watchDevice;
        } catch (error) {
            logger.error('Error unpairing devices:', error);
            throw error;
        }
    }
};

module.exports = deviceService;