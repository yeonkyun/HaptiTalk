const { body } = require('express-validator');

/**
 * 사용자 피드백 설정 업데이트 유효성 검사
 */
const updateSettings = [
    body('haptic_strength')
        .optional()
        .isInt({ min: 1, max: 10 }).withMessage('햅틱 강도는 1~10 사이의 정수여야 합니다.'),

    body('active_patterns')
        .optional()
        .isArray().withMessage('활성 패턴은 배열이어야 합니다.'),

    body('active_patterns.*')
        .optional()
        .isString().withMessage('활성 패턴 ID는 문자열이어야 합니다.')
        .isLength({ min: 2, max: 50 }).withMessage('패턴 ID는 2~50자 사이여야 합니다.'),

    body('priority_threshold')
        .optional()
        .isString().withMessage('우선순위 임계값은 문자열이어야 합니다.')
        .isIn(['low', 'medium', 'high']).withMessage('유효하지 않은 우선순위 임계값입니다.'),

    body('minimum_interval_seconds')
        .optional()
        .isInt({ min: 1, max: 60 }).withMessage('최소 간격은 1~60 사이의 정수(초)여야 합니다.'),

    body('feedback_frequency')
        .optional()
        .isString().withMessage('피드백 빈도는 문자열이어야 합니다.')
        .isIn(['low', 'medium', 'high']).withMessage('유효하지 않은 피드백 빈도입니다.'),

    body('mode_settings')
        .optional()
        .isObject().withMessage('모드 설정은 객체여야 합니다.'),

    body('mode_settings.*.active_patterns')
        .optional()
        .isArray().withMessage('모드별 활성 패턴은 배열이어야 합니다.'),

    body('mode_settings.*.active_patterns.*')
        .optional()
        .isString().withMessage('모드별 활성 패턴 ID는 문자열이어야 합니다.'),

    body('mode_settings.*.priority_threshold')
        .optional()
        .isString().withMessage('모드별 우선순위 임계값은 문자열이어야 합니다.')
        .isIn(['low', 'medium', 'high']).withMessage('유효하지 않은 우선순위 임계값입니다.'),
];

module.exports = {
    updateSettings
};