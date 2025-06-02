const { body } = require('express-validator');

/**
 * 햅틱 패턴 생성 유효성 검사
 */
const createPattern = [
    body('id')
        .isString().withMessage('패턴 ID는 문자열이어야 합니다.')
        .isLength({ min: 2, max: 50 }).withMessage('패턴 ID는 2~50자 사이여야 합니다.')
        .matches(/^[A-Za-z0-9_-]+$/).withMessage('패턴 ID는 영문자, 숫자, 언더스코어, 하이픈만 사용 가능합니다.'),

    body('name')
        .isString().withMessage('패턴 이름은 문자열이어야 합니다.')
        .isLength({ min: 2, max: 100 }).withMessage('패턴 이름은 2~100자 사이여야 합니다.'),

    body('description')
        .optional()
        .isString().withMessage('패턴 설명은 문자열이어야 합니다.'),

    body('pattern_data')
        .isObject().withMessage('패턴 데이터는 객체여야 합니다.'),

    body('pattern_data.vibrations')
        .isArray().withMessage('진동 데이터는 배열이어야 합니다.'),

    body('pattern_data.vibrations.*.duration')
        .isInt({ min: 0 }).withMessage('진동 지속 시간은 0 이상의 정수여야 합니다.'),

    body('pattern_data.vibrations.*.intensity')
        .isInt({ min: 0, max: 10 }).withMessage('진동 강도는 0~10 사이의 정수여야 합니다.'),

    body('category')
        .isString().withMessage('카테고리는 문자열이어야 합니다.')
        .isIn(['pace', 'emotion', 'alert', 'listening', 'etc']).withMessage('유효하지 않은 카테고리입니다.'),

    body('intensity_default')
        .optional()
        .isInt({ min: 1, max: 10 }).withMessage('기본 강도는 1~10 사이의 정수여야 합니다.'),

    body('duration_ms')
        .optional()
        .isInt({ min: 50, max: 2000 }).withMessage('지속 시간은 50~2000 사이의 정수(밀리초)여야 합니다.'),
];

/**
 * 햅틱 패턴 업데이트 유효성 검사
 */
const updatePattern = [
    body('name')
        .optional()
        .isString().withMessage('패턴 이름은 문자열이어야 합니다.')
        .isLength({ min: 2, max: 100 }).withMessage('패턴 이름은 2~100자 사이여야 합니다.'),

    body('description')
        .optional()
        .isString().withMessage('패턴 설명은 문자열이어야 합니다.'),

    body('pattern_data')
        .optional()
        .isObject().withMessage('패턴 데이터는 객체여야 합니다.'),

    body('pattern_data.vibrations')
        .optional()
        .isArray().withMessage('진동 데이터는 배열이어야 합니다.'),

    body('pattern_data.vibrations.*.duration')
        .optional()
        .isInt({ min: 0 }).withMessage('진동 지속 시간은 0 이상의 정수여야 합니다.'),

    body('pattern_data.vibrations.*.intensity')
        .optional()
        .isInt({ min: 0, max: 10 }).withMessage('진동 강도는 0~10 사이의 정수여야 합니다.'),

    body('category')
        .optional()
        .isString().withMessage('카테고리는 문자열이어야 합니다.')
        .isIn(['pace', 'emotion', 'alert', 'listening', 'etc']).withMessage('유효하지 않은 카테고리입니다.'),

    body('intensity_default')
        .optional()
        .isInt({ min: 1, max: 10 }).withMessage('기본 강도는 1~10 사이의 정수여야 합니다.'),

    body('duration_ms')
        .optional()
        .isInt({ min: 50, max: 2000 }).withMessage('지속 시간은 50~2000 사이의 정수(밀리초)여야 합니다.'),

    body('is_active')
        .optional()
        .isBoolean().withMessage('활성화 여부는 불리언이어야 합니다.'),
];

module.exports = {
    createPattern,
    updatePattern
};