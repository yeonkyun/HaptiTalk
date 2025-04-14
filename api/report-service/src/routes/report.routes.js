const express = require('express');
const {body} = require('express-validator');
const {authenticate} = require('../middleware/auth.middleware');
const {validate} = require('../middleware/validation.middleware');
const reportController = require('../controllers/report.controller');

const router = express.Router();

// 세션별 리포트 생성
router.post(
    '/generate/:sessionId',
    authenticate,
    validate([
        body('format').optional().isString().isIn(['json', 'pdf']),
        body('includeCharts').optional().isBoolean(),
        body('detailLevel').optional().isString().isIn(['basic', 'detailed', 'comprehensive'])
    ]),
    reportController.generateReport
);

// 세션별 리포트 조회
router.get(
    '/:reportId',
    authenticate,
    reportController.getReportById
);

// 사용자별 리포트 목록 조회
router.get(
    '/',
    authenticate,
    reportController.getReportsByUser
);

// 리포트 PDF 내보내기
router.get(
    '/:reportId/export',
    authenticate,
    reportController.exportReportPdf
);

// 세션 간 비교 리포트 생성
router.post(
    '/compare',
    authenticate,
    validate([
        body('sessionIds').isArray().notEmpty(),
        body('metrics').optional().isArray()
    ]),
    reportController.compareReports
);

module.exports = router;