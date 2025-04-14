const express = require('express');
const patternRoutes = require('./pattern.routes');
const settingRoutes = require('./setting.routes');
const historyRoutes = require('./history.routes');
const feedbackRoutes = require('./feedback.routes');

const router = express.Router();

// 각 라우트 통합
router.use('/haptic-patterns', patternRoutes);
router.use('/settings', settingRoutes);
router.use('/history', historyRoutes);
router.use('/', feedbackRoutes); // 실시간 피드백 생성 등

module.exports = router;