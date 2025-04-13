const { body } = require('express-validator');

/**
 * 실시간 피드백 생성 유효성 검사
 */
const generateFeedback = [
    body('session_id')
        .isString().withMessage('세션 ID는 문자열이어야 합니다.')
        .isLength({ min: 36, max: 36 }).withMessage('세션 ID는 36자여야 합니다.'),

    body('context')
        .isObject().withMessage('컨텍스트는 객체여야 합니다.'),

    body('context.current_speaking_pace')
        .optional()
        .isFloat({ min: 0 }).withMessage('말하기 속도는 0 이상의 숫자여야 합니다.'),

    body('context.current_volume')
        .optional()
        .isFloat({ min: 0, max: 100 }).withMessage('음량은 0~100 사이의 숫자여야 합니다.'),

    body('context.current_emotion')
        .optional()
        .isString().withMessage('감정은 문자열이어야 합니다.'),

    body('context.interaction_state')
        .optional()
        .isString().withMessage('상호작용 상태는 문자열이어야 합니다.')
        .isIn(['user_speaking', 'other_speaking', 'silence', 'overlapping']).withMessage('유효하지 않은 상호작용 상태입니다.'),

    body('context.silence_duration')
        .optional()
        .isFloat({ min: 0 }).withMessage('침묵 지속 시간은 0 이상의 숫자여야 합니다.'),

    body('context.interest_level')
        .optional()
        .isFloat({ min: 0, max: 1 }).withMessage('관심도는 0~1 사이의 숫자여야 합니다.'),

    body('context.previous_interest_level')
        .optional()
        .isFloat({ min: 0, max: 1 }).withMessage('이전 관심도는 0~1 사이의 숫자여야 합니다.'),

    body('device_id')
        .isString().withMessage('기기 ID는 문자열이어야 합니다.')
        .isLength({ min: 36, max: 36 }).withMessage('기기 ID는 36자여야 합니다.'),
];

/**
 * 피드백 수신 확인 유효성 검사
 */
const acknowledgeFeedback = [
    body('received_at')
        .optional()
        .isISO8601().withMessage('수신 시간은 ISO 8601 형식의 날짜여야 합니다.'),

    body('user_action')
        .optional()
        .isString().withMessage('사용자 액션은 문자열이어야 합니다.')
        .isIn(['acknowledged', 'ignored']).withMessage('유효하지 않은 사용자 액션입니다.'),
];

module.exports = {
    generateFeedback,
    acknowledgeFeedback
};