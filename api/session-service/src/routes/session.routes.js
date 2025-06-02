const express = require('express');
const {body, param, query} = require('express-validator');
const sessionController = require('../controllers/session.controller');
const authMiddleware = require('../middleware/auth.middleware');
const validationMiddleware = require('../middleware/validation.middleware');
const {SESSION_TYPES} = require('../models/session.model');

const router = express.Router();

/**
 * 세션 라우트 정의
 */

// JWT 토큰 검증 미들웨어 적용
router.use(authMiddleware.verifyToken);

/**
 * @route POST /api/v1/sessions
 * @desc 새 세션 생성
 * @access Private
 */
router.post(
    '/',
    [
        body('title').isString().notEmpty().withMessage('세션 제목은 필수입니다'),
        body('type').isIn(Object.values(SESSION_TYPES)).withMessage('유효한 세션 타입이 아닙니다'),
        body('custom_settings').optional().isObject().withMessage('세션 설정은 객체 형태여야 합니다')
    ],
    validationMiddleware.validate,
    sessionController.createSession
);

/**
 * @route GET /api/v1/sessions
 * @desc 사용자의 세션 목록 조회
 * @access Private
 */
router.get(
    '/',
    [
        query('status').optional().isString().withMessage('유효한 상태 값이 아닙니다'),
        query('type').optional().isIn(Object.values(SESSION_TYPES)).withMessage('유효한 세션 타입이 아닙니다'),
        query('limit').optional().isInt({min: 1, max: 100}).withMessage('limit은 1-100 사이의 정수여야 합니다'),
        query('offset').optional().isInt({min: 0}).withMessage('offset은 0 이상의 정수여야 합니다'),
        query('sort').optional().isString().withMessage('정렬 필드는 문자열이어야 합니다'),
        query('order').optional().isIn(['ASC', 'DESC']).withMessage('정렬 순서는 ASC 또는 DESC여야 합니다')
    ],
    validationMiddleware.validate,
    sessionController.getUserSessions
);

/**
 * @route GET /api/v1/sessions/:id
 * @desc 세션 상세 정보 조회
 * @access Private
 */
router.get(
    '/:id',
    [
        param('id').isUUID(4).withMessage('유효한 세션 ID가 아닙니다'),
        validationMiddleware.validate
    ],
    sessionController.getSession
);

/**
 * @route PUT /api/v1/sessions/:id
 * @desc 세션 정보 업데이트
 * @access Private
 */
router.put(
    '/:id',
    [
        param('id').isUUID(4).withMessage('유효한 세션 ID가 아닙니다'),
        body('title').optional().isString().withMessage('세션 제목은 문자열이어야 합니다'),
        body('status').optional().isString().withMessage('세션 상태는 문자열이어야 합니다'),
        body('settings').optional().isObject().withMessage('세션 설정은 객체 형태여야 합니다'),
        body('metadata').optional().isObject().withMessage('세션 메타데이터는 객체 형태여야 합니다'),
        validationMiddleware.validate
    ],
    sessionController.updateSession
);

/**
 * @route POST /api/v1/sessions/:id/end
 * @desc 세션 종료
 * @access Private
 */
router.post(
    '/:id/end',
    [
        param('id').isUUID(4).withMessage('유효한 세션 ID가 아닙니다'),
        body('summary').optional().isObject().withMessage('세션 요약은 객체 형태여야 합니다'),
        validationMiddleware.validate
    ],
    sessionController.endSession
);

/**
 * @route PUT /api/v1/sessions/:id/summary
 * @desc 세션 요약 정보 업데이트
 * @access Private
 */
router.put(
    '/:id/summary',
    [
        param('id').isUUID(4).withMessage('유효한 세션 ID가 아닙니다'),
        body('summary').isObject().withMessage('세션 요약은 객체 형태여야 합니다'),
        validationMiddleware.validate
    ],
    sessionController.updateSummary
);

/**
 * @route POST /api/v1/sessions/:id/timer/setup
 * @desc 발표 타이머 설정
 * @access Private
 */
router.post(
    '/:id/timer/setup',
    [
        param('id').isUUID(4).withMessage('유효한 세션 ID가 아닙니다'),
        body('duration_minutes').optional().isInt({min: 1, max: 180}).withMessage('발표 시간은 1-180분 사이여야 합니다'),
        body('alerts').optional().isObject().withMessage('알림 설정은 객체 형태여야 합니다'),
        validationMiddleware.validate
    ],
    sessionController.setupTimer
);

/**
 * @route POST /api/v1/sessions/:id/timer/start
 * @desc 타이머 시작
 * @access Private
 */
router.post(
    '/:id/timer/start',
    [
        param('id').isUUID(4).withMessage('유효한 세션 ID가 아닙니다'),
        validationMiddleware.validate
    ],
    sessionController.startTimer
);

/**
 * @route POST /api/v1/sessions/:id/timer/pause
 * @desc 타이머 일시 중지
 * @access Private
 */
router.post(
    '/:id/timer/pause',
    [
        param('id').isUUID(4).withMessage('유효한 세션 ID가 아닙니다'),
        validationMiddleware.validate
    ],
    sessionController.pauseTimer
);

/**
 * @route POST /api/v1/sessions/:id/timer/resume
 * @desc 타이머 재개
 * @access Private
 */
router.post(
    '/:id/timer/resume',
    [
        param('id').isUUID(4).withMessage('유효한 세션 ID가 아닙니다'),
        validationMiddleware.validate
    ],
    sessionController.resumeTimer
);

/**
 * @route POST /api/v1/sessions/:id/timer/reset
 * @desc 타이머 리셋
 * @access Private
 */
router.post(
    '/:id/timer/reset',
    [
        param('id').isUUID(4).withMessage('유효한 세션 ID가 아닙니다'),
        validationMiddleware.validate
    ],
    sessionController.resetTimer
);

/**
 * @route GET /api/v1/sessions/:id/timer
 * @desc 타이머 상태 조회
 * @access Private
 */
router.get(
    '/:id/timer',
    [
        param('id').isUUID(4).withMessage('유효한 세션 ID가 아닙니다'),
        validationMiddleware.validate
    ],
    sessionController.getTimerStatus
);

/**
 * @route POST /api/v1/sessions/validate
 * @desc 세션 유효성 검증
 * @access Private
 */
router.post(
    '/validate',
    [
        body('sessionId').isUUID(4).withMessage('유효한 세션 ID가 아닙니다'),
        body('userId').isUUID(4).withMessage('유효한 사용자 ID가 아닙니다'),
        validationMiddleware.validate
    ],
    sessionController.validateSession
);

/**
 * @route GET /api/v1/sessions/:id/status
 * @desc 세션 상태 조회
 * @access Private
 */
router.get(
    '/:id/status',
    [
        param('id').isUUID(4).withMessage('유효한 세션 ID가 아닙니다'),
        validationMiddleware.validate
    ],
    sessionController.getSessionStatus
);

module.exports = router;