const express = require('express');
const {body, param} = require('express-validator');
const {authenticate} = require('../middleware/auth.middleware');
const {validate} = require('../middleware/validation.middleware');
const analyticsController = require('../controllers/analytics.controller');

const router = express.Router();

// 세그먼트 데이터 저장 (30초마다 호출)
router.post(
    '/segments/:sessionId',
    authenticate,
    validate([
        param('sessionId').isUUID().withMessage('유효하지 않은 세션 ID입니다'),
        body('segmentIndex').isInt({min: 0}).withMessage('세그먼트 인덱스는 0 이상의 정수여야 합니다'),
        body('timestamp').isISO8601().withMessage('유효하지 않은 타임스탬프입니다'),
        body('transcription').optional().isString().withMessage('전사 텍스트는 문자열이어야 합니다'),
        body('analysis').optional().isObject().withMessage('분석 데이터는 객체여야 합니다'),
        body('hapticFeedbacks').optional().isArray().withMessage('햅틱 피드백은 배열이어야 합니다'),
        body('suggestedTopics').optional().isArray().withMessage('추천 주제는 배열이어야 합니다')
    ]),
    analyticsController.saveSegment
);

// 세션의 모든 세그먼트 조회
router.get(
    '/segments/:sessionId',
    authenticate,
    validate([
        param('sessionId').isUUID().withMessage('유효하지 않은 세션 ID입니다')
    ]),
    analyticsController.getSegments
);

// 세션 종료 및 최종 분석 데이터 생성
router.post(
    '/:sessionId/finalize',
    authenticate,
    validate([
        param('sessionId').isUUID().withMessage('유효하지 않은 세션 ID입니다'),
        body('sessionType').isString().isIn(['dating', 'interview', 'presentation', 'coaching']).withMessage('유효하지 않은 세션 타입입니다'),
        body('totalDuration').optional().isInt({min: 0}).withMessage('총 시간은 0 이상의 정수여야 합니다')
    ]),
    analyticsController.finalizeSession
);

// 실시간 분석 상태 업데이트 (선택적)
router.patch(
    '/segments/:sessionId/:segmentIndex',
    authenticate,
    validate([
        param('sessionId').isUUID().withMessage('유효하지 않은 세션 ID입니다'),
        param('segmentIndex').isInt({min: 0}).withMessage('세그먼트 인덱스는 0 이상의 정수여야 합니다'),
        body('analysis').optional().isObject().withMessage('분석 데이터는 객체여야 합니다'),
        body('hapticFeedbacks').optional().isArray().withMessage('햅틱 피드백은 배열이어야 합니다')
    ]),
    analyticsController.updateSegment
);

module.exports = router; 