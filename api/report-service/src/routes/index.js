const express = require('express');
const reportRoutes = require('./report.routes');
const statsRoutes = require('./stats.routes');
const progressRoutes = require('./progress.routes');
const analyticsRoutes = require('./analytics.routes');

const router = express.Router();

router.use('/', reportRoutes);
router.use('/stats', statsRoutes);
router.use('/progress', progressRoutes);
router.use('/analytics', analyticsRoutes);

module.exports = router;