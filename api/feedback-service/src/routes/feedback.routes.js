const express = require('express');
const { validate } = require('../middleware/validation.middleware');
const { authenticateJWT } = require('../middleware/auth.middleware');
const feedbackController = require('../controllers/feedback.controller');
const feedbackValidation = require('../utils/validators/feedback.validator');

const router = express.Router();

// 실시간 피드백 라우트 - 인증 필요
router.post(
    '/',
    authenticateJWT,
    validate(feedbackValidation.generateFeedback),
    feedbackController.generateFeedback
);

router.post(
    '/:feedback_id/acknowledge',
    authenticateJWT,
    feedbackController.acknowledgeFeedback
);

module.exports = router;