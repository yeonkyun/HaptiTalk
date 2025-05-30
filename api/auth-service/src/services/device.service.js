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
            let isUpdate = false;
            
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
                
                isUpdate = true;
                
                logger.info(`기기 정보 업데이트 성공: ${device.id}`, {
                    userId,
                    deviceType: device.device_type,
                    deviceName: device.device_name,
                    isWatch: device.is_watch
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
                
                logger.info(`새 기기 등록 성공: ${device.id}`, {
                    userId,
                    deviceType: device.device_type,
                    deviceName: device.device_name,
                    deviceModel: device.device_model,
                    isWatch: device.is_watch
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
            const devices = await Device.findAllByUser(userId);
            
            logger.info(`사용자 기기 목록 조회 성공: ${userId}`, {
                deviceCount: devices.length,
                watchCount: devices.filter(d => d.is_watch).length
            });
            
            return devices;
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
                logger.warn(`기기 조회 실패 - 존재하지 않는 기기: ${deviceId}`);
                throw new Error('Device not found');
            }
            
            logger.debug(`기기 조회 성공: ${deviceId}`, {
                userId: device.user_id,
                deviceType: device.device_type,
                deviceName: device.device_name
            });
            
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
                logger.warn(`기기 업데이트 실패 - 존재하지 않는 기기: ${deviceId}`);
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

            logger.info(`기기 업데이트 성공: ${deviceId}`, {
                userId: device.user_id,
                updatedFields: Object.keys(updateData),
                deviceName: device.device_name
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
                logger.warn(`기기 삭제 실패 - 존재하지 않는 기기: ${deviceId}`);
                throw new Error('Device not found');
            }

            // Check if any watch is paired with this device
            const watches = await Device.findWatchesForDevice(deviceId);

            // Unlink paired watches before deletion
            for (const watch of watches) {
                await watch.update({paired_device_id: null});
                logger.info(`페어링 해제됨: 워치 ${watch.id} <-> 기기 ${deviceId}`);
            }

            const deletedDeviceInfo = {
                userId: device.user_id,
                deviceType: device.device_type,
                deviceName: device.device_name,
                unpairedWatches: watches.length
            };

            await device.destroy();
            
            logger.info(`기기 삭제 성공: ${deviceId}`, deletedDeviceInfo);

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
                logger.warn(`기기 페어링 실패 - 모바일 기기 없음: ${mobileDeviceId}`);
                throw new Error('Mobile device not found');
            }

            const watchDevice = await Device.findByPk(watchDeviceId);
            if (!watchDevice) {
                logger.warn(`기기 페어링 실패 - 워치 기기 없음: ${watchDeviceId}`);
                throw new Error('Watch device not found');
            }

            // Verify both devices belong to the same user
            if (mobileDevice.user_id !== watchDevice.user_id) {
                logger.warn(`기기 페어링 실패 - 사용자 불일치: ${mobileDevice.user_id} vs ${watchDevice.user_id}`);
                throw new Error('Devices must belong to the same user');
            }

            // Update watch device with paired ID
            await watchDevice.update({
                paired_device_id: mobileDeviceId,
                is_watch: true
            });

            logger.info(`기기 페어링 성공: ${watchDeviceId} <-> ${mobileDeviceId}`, {
                userId: mobileDevice.user_id,
                mobileDeviceName: mobileDevice.device_name,
                watchDeviceName: watchDevice.device_name
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
                logger.warn(`기기 페어링 해제 실패 - 워치 기기 없음: ${watchDeviceId}`);
                throw new Error('Watch device not found');
            }

            const previousPairedDevice = watchDevice.paired_device_id;

            await watchDevice.update({
                paired_device_id: null
            });

            logger.info(`기기 페어링 해제 성공: ${watchDeviceId}`, {
                userId: watchDevice.user_id,
                watchDeviceName: watchDevice.device_name,
                previousPairedDevice
            });

            return watchDevice;
        } catch (error) {
            logger.error('Error unpairing devices:', error);
            throw error;
        }
    }
};

module.exports = deviceService;