const express = require('express');
const { body } = require('express-validator');
const { verifyToken } = require('../middleware/auth.middleware');
const profileController = require('../controllers/profile.controller');

const router = express.Router();

// 프로필 조회
router.get('/profile', verifyToken, profileController.getProfile);

// 프로필 업데이트
router.patch(
    '/profile',
    verifyToken,
    [
        body('username')
            .optional()
            .isLength({ min: 3, max: 50 })
            .withMessage('사용자명은 3-50자 사이여야 합니다.'),
        body('first_name')
            .optional()
            .isLength({ max: 100 })
            .withMessage('이름은 최대 100자까지 입력 가능합니다.'),
        body('last_name')
            .optional()
            .isLength({ max: 100 })
            .withMessage('성은 최대 100자까지 입력 가능합니다.'),
        body('birth_date')
            .optional()
            .isDate()
            .withMessage('유효한 날짜 형식이 아닙니다.'),
        body('gender')
            .optional()
            .isLength({ max: 20 })
            .withMessage('성별은 최대 20자까지 입력 가능합니다.'),
        body('profile_image_url')
            .optional()
            .isURL()
            .withMessage('유효한 URL 형식이 아닙니다.'),
        body('bio')
            .optional()
            .isLength({ max: 1000 })
            .withMessage('자기소개는 최대 1000자까지 입력 가능합니다.')
    ],
    profileController.updateProfile
);

module.exports = router;