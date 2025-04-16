const express = require('express');
const deviceController = require('../controllers/device.controller');
const {validate, deviceValidation} = require('../middleware/validation.middleware');
const {authenticate, verifyDeviceOwnership} = require('../middleware/auth.middleware');
const {verifyServiceToken, restrictToServices} = require('../middleware/service-auth.middleware');

const router = express.Router();

// All device routes require authentication
router.use(authenticate);

// Get all devices for authenticated user
router.get(
    '/',
    deviceController.getUserDevices
);

// Register a new device
router.post(
    '/',
    validate(deviceValidation.registerDevice),
    deviceController.registerDevice
);

// Get device by ID
router.get(
    '/:deviceId',
    verifyDeviceOwnership,
    deviceController.getDevice
);

// Update device
router.patch(
    '/:deviceId',
    verifyDeviceOwnership,
    validate(deviceValidation.updateDevice),
    deviceController.updateDevice
);

// Delete device
router.delete(
    '/:deviceId',
    verifyDeviceOwnership,
    deviceController.deleteDevice
);

// Pair mobile device with watch
router.post(
    '/:deviceId/pair',
    verifyDeviceOwnership,
    validate(deviceValidation.pairDevices),
    deviceController.pairDevices
);

// Unpair devices
router.post(
    '/:deviceId/unpair',
    verifyDeviceOwnership,
    deviceController.unpairDevices
);

// 서비스 인증 테스트용 엔드포인트
router.get(
    '/service-auth-test',
    verifyServiceToken,
    restrictToServices(['session-service-id', 'realtime-service-id']),
    (req, res) => {
        res.status(200).json({
            success: true,
            message: '서비스 인증 성공',
            service: req.service
        });
    }
);

module.exports = router;