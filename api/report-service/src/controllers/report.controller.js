const { formatResponse } = require('../utils/responseFormatter');
const reportService = require('../services/report.service');
const logger = require('../utils/logger');

const reportController = {
    /**
     * 세션 ID로 리포트 생성
     */
    async generateReport(req, res, next) {
        try {
            const { sessionId } = req.params;
            const { format = 'json', includeCharts = true, detailLevel = 'detailed' } = req.body;
            const userId = req.user.id;

            logger.info(`Generating report for session ${sessionId} by user ${userId}`);

            const report = await reportService.generateSessionReport(
                userId,
                sessionId,
                { format, includeCharts, detailLevel }
            );

            return formatResponse(res, 201, true, report, 'Report generated successfully');
        } catch (error) {
            next(error);
        }
    },

    /**
     * 리포트 ID로 리포트 조회
     */
    async getReportById(req, res, next) {
        try {
            const { reportId } = req.params;
            const userId = req.user.id;

            const report = await reportService.getReportById(userId, reportId);

            return formatResponse(res, 200, true, report, 'Report retrieved successfully');
        } catch (error) {
            next(error);
        }
    },

    /**
     * 사용자별 리포트 목록 조회
     */
    async getReportsByUser(req, res, next) {
        try {
            const userId = req.user.id;
            const { page = 1, limit = 10, sessionType, startDate, endDate } = req.query;

            const reports = await reportService.getReportsByUser(
                userId,
                { page: parseInt(page), limit: parseInt(limit), sessionType, startDate, endDate }
            );

            return formatResponse(res, 200, true, reports, 'Reports retrieved successfully');
        } catch (error) {
            next(error);
        }
    },

    /**
     * 리포트 PDF 내보내기
     */
    async exportReportPdf(req, res, next) {
        try {
            const { reportId } = req.params;
            const userId = req.user.id;

            const pdfBuffer = await reportService.generateReportPdf(userId, reportId);

            res.setHeader('Content-Type', 'application/pdf');
            res.setHeader('Content-Disposition', `attachment; filename=report-${reportId}.pdf`);

            return res.send(pdfBuffer);
        } catch (error) {
            next(error);
        }
    },

    /**
     * 세션 간 비교 리포트 생성
     */
    async compareReports(req, res, next) {
        try {
            const { sessionIds, metrics } = req.body;
            const userId = req.user.id;

            const comparisonReport = await reportService.generateComparisonReport(
                userId,
                sessionIds,
                metrics
            );

            return formatResponse(res, 200, true, comparisonReport, 'Comparison report generated successfully');
        } catch (error) {
            next(error);
        }
    }
};

module.exports = reportController;