const express = require('express');
const {body} = require('express-validator');
const {verifyToken} = require('../middleware/auth.middleware');
const settingsController = require('../controllers/settings.controller');

const router = express.Router();

// 설정 조회
router.get('/settings', verifyToken, settingsController.getSettings);

// 설정 업데이트
router.patch(
    '/settings',
    verifyToken,
    [
        body('notification_enabled')
            .optional()
            .isBoolean()
            .withMessage('알림 활성화 여부는 불리언 값이어야 합니다.'),
        body('haptic_strength')
            .optional()
            .isInt({min: 1, max: 10})
            .withMessage('햅틱 강도는 1-10 사이의 정수여야 합니다.'),
        body('analysis_level')
            .optional()
            .isIn(['basic', 'standard', 'advanced'])
            .withMessage('분석 수준은 basic, standard, advanced 중 하나여야 합니다.'),
        body('audio_retention_days')
            .optional()
            .isInt({min: 1, max: 90})
            .withMessage('오디오 보관 일수는 1-90 사이의 정수여야 합니다.'),
        body('data_anonymization_level')
            .optional()
            .isIn(['basic', 'standard', 'complete'])
            .withMessage('데이터 익명화 수준은 basic, standard, complete 중 하나여야 합니다.'),
        body('default_mode')
            .optional()
            .isIn(['dating', 'interview', 'business', 'coaching'])
            .withMessage('기본 모드는 dating, interview, business, coaching 중 하나여야 합니다.'),
        body('theme')
            .optional()
            .isIn(['light', 'dark', 'system'])
            .withMessage('테마는 light, dark, system 중 하나여야 합니다.'),
        body('language')
            .optional()
            .isLength({min: 2, max: 10})
            .withMessage('언어 코드는 2-10자 사이여야 합니다.')
    ],
    settingsController.updateSettings
);

module.exports = router;