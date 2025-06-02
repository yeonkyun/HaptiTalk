const express = require('express');
const reportRoutes = require('./report.routes');
const statsRoutes = require('./stats.routes');
const progressRoutes = require('./progress.routes');

const router = express.Router();

router.use('/', reportRoutes);
router.use('/stats', statsRoutes);
router.use('/progress', progressRoutes);

module.exports = router;