const express = require('express');
const { validate } = require('../middleware/validation.middleware');
const { authenticateJWT } = require('../middleware/auth.middleware');
const settingController = require('../controllers/setting.controller');
const settingValidation = require('../utils/validators/setting.validator');

const router = express.Router();

// 사용자 설정 라우트 - 인증 필요
router.get(
    '/',
    authenticateJWT,
    settingController.getUserSettings
);

router.patch(
    '/',
    authenticateJWT,
    validate(settingValidation.updateSettings),
    settingController.updateUserSettings
);

module.exports = router;