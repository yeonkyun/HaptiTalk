const express = require('express');
const { authenticate } = require('../middleware/auth.middleware');
const progressController = require('../controllers/progress.controller');

const router = express.Router();

// 사용자 발전 추이 조회
router.get(
    '/trend',
    authenticate,
    progressController.getProgressTrend
);

// 상황별 발전 추이 조회
router.get(
    '/trend/:contextType',
    authenticate,
    progressController.getContextProgressTrend
);

// 발전 추이 요약 조회
router.get(
    '/summary',
    authenticate,
    progressController.getProgressSummary
);

module.exports = router;