const express = require('express');
const {authenticate} = require('../middleware/auth.middleware');
const statsController = require('../controllers/stats.controller');

const router = express.Router();

// 세션 유형별 통계 조회
router.get(
    '/by-session-type',
    authenticate,
    statsController.getStatsBySessionType
);

// 시간별 통계 조회
router.get(
    '/by-timeframe',
    authenticate,
    statsController.getStatsByTimeframe
);

// 피드백 통계 조회
router.get(
    '/feedback',
    authenticate,
    statsController.getFeedbackStats
);

module.exports = router;