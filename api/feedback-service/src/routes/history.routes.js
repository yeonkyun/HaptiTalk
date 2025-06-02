const express = require('express');
const { authenticateJWT } = require('../middleware/auth.middleware');
const historyController = require('../controllers/history.controller');

const router = express.Router();

// 사용자 피드백 이력 라우트 - 인증 필요
router.get(
    '/',
    authenticateJWT,
    historyController.getFeedbackHistory
);

router.get(
    '/session/:session_id',
    authenticateJWT,
    historyController.getSessionFeedbacks
);

module.exports = router;