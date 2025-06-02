const express = require('express');
const profileRoutes = require('./profile.routes');
const settingsRoutes = require('./settings.routes');

const router = express.Router();

// 라우트 통합
router.use(profileRoutes);
router.use(settingsRoutes);

module.exports = router;