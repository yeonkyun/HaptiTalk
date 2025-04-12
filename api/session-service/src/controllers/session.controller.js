const httpStatus = require('http-status');
const sessionService = require('../services/session.service');
const timerService = require('../services/timer.service');
const logger = require('../utils/logger');

/**
 * 세션 컨트롤러
 * 세션 관련 API 엔드포인트 핸들러 구현
 */
const sessionController = {
    /**
     * 세션 생성
     * POST /api/v1/sessions
     */
    createSession: async (req, res, next) => {
        try {
            const {title, type, custom_settings, device_info, location, participants, tags} = req.body;

            // JWT 인증 미들웨어에서 설정한 사용자 ID 가져오기
            const user_id = req.user.id;

            // 세션 생성 서비스 호출
            const session = await sessionService.createSession({
                user_id,
                title,
                type,
                custom_settings,
                device_info,
                location,
                participants,
                tags
            });

            res.status(httpStatus.CREATED).json({
                success: true,
                data: {
                    id: session.id,
                    title: session.title,
                    type: session.type,
                    status: session.status,
                    created_at: session.created_at
                },
                message: '세션이 성공적으로 생성되었습니다.'
            });
        } catch (error) {
            logger.error('Session creation error:', error);
            next(error);
        }
    },

    /**
     * 세션 정보 조회
     * GET /api/v1/sessions/:id
     */
    getSession: async (req, res, next) => {
        try {
            const {id} = req.params;

            // 세션 조회 서비스 호출
            const session = await sessionService.getSession(id);

            // 사용자 권한 확인 (본인의 세션만 조회 가능)
            if (session.user_id !== req.user.id) {
                return res.status(httpStatus.FORBIDDEN).json({
                    success: false,
                    message: '이 세션에 접근할 권한이 없습니다.'
                });
            }

            res.status(httpStatus.OK).json({
                success: true,
                data: session
            });
        } catch (error) {
            logger.error(`Get session error for ID ${req.params.id}:`, error);
            next(error);
        }
    },

    /**
     * 사용자의 세션 목록 조회
     * GET /api/v1/sessions
     */
    getUserSessions: async (req, res, next) => {
        try {
            const {status, type, limit, offset, sort, order} = req.query;
            const user_id = req.user.id;

            // 세션 목록 조회 서비스 호출
            const {rows: sessions, count} = await sessionService.getUserSessions(user_id, {
                status,
                type,
                limit: limit ? parseInt(limit, 10) : 10,
                offset: offset ? parseInt(offset, 10) : 0,
                sort: sort || 'created_at',
                order: order || 'DESC'
            });

            res.status(httpStatus.OK).json({
                success: true,
                data: {
                    sessions,
                    total: count,
                    limit: limit ? parseInt(limit, 10) : 10,
                    offset: offset ? parseInt(offset, 10) : 0
                }
            });
        } catch (error) {
            logger.error('Get user sessions error:', error);
            next(error);
        }
    },

    /**
     * 세션 정보 업데이트
     * PUT /api/v1/sessions/:id
     */
    updateSession: async (req, res, next) => {
        try {
            const {id} = req.params;
            const updateData = req.body;

            // 먼저 세션 조회하여 사용자 권한 확인
            const session = await sessionService.getSession(id);

            if (session.user_id !== req.user.id) {
                return res.status(httpStatus.FORBIDDEN).json({
                    success: false,
                    message: '이 세션을 업데이트할 권한이 없습니다.'
                });
            }

            // 세션 업데이트 서비스 호출
            const updatedSession = await sessionService.updateSession(id, updateData);

            res.status(httpStatus.OK).json({
                success: true,
                data: updatedSession,
                message: '세션이 성공적으로 업데이트되었습니다.'
            });
        } catch (error) {
            logger.error(`Update session error for ID ${req.params.id}:`, error);
            next(error);
        }
    },

    /**
     * 세션 종료
     * POST /api/v1/sessions/:id/end
     */
    endSession: async (req, res, next) => {
        try {
            const {id} = req.params;
            const {summary} = req.body;

            // 먼저 세션 조회하여 사용자 권한 확인
            const session = await sessionService.getSession(id);

            if (session.user_id !== req.user.id) {
                return res.status(httpStatus.FORBIDDEN).json({
                    success: false,
                    message: '이 세션을 종료할 권한이 없습니다.'
                });
            }

            // 세션 종료 서비스 호출
            const endedSession = await sessionService.endSession(id, summary);

            res.status(httpStatus.OK).json({
                success: true,
                data: {
                    id: endedSession.id,
                    status: endedSession.status,
                    duration: endedSession.duration,
                    end_time: endedSession.end_time
                },
                message: '세션이 성공적으로 종료되었습니다.'
            });
        } catch (error) {
            logger.error(`End session error for ID ${req.params.id}:`, error);
            next(error);
        }
    },

    /**
     * 세션 요약 정보 업데이트
     * PUT /api/v1/sessions/:id/summary
     */
    updateSummary: async (req, res, next) => {
        try {
            const {id} = req.params;
            const {summary} = req.body;

            // 먼저 세션 조회하여 사용자 권한 확인
            const session = await sessionService.getSession(id);

            if (session.user_id !== req.user.id) {
                return res.status(httpStatus.FORBIDDEN).json({
                    success: false,
                    message: '이 세션의 요약 정보를 업데이트할 권한이 없습니다.'
                });
            }

            // 세션 요약 업데이트 서비스 호출
            await sessionService.updateSessionSummary(id, summary);

            res.status(httpStatus.OK).json({
                success: true,
                message: '세션 요약 정보가 성공적으로 업데이트되었습니다.'
            });
        } catch (error) {
            logger.error(`Update summary error for session ID ${req.params.id}:`, error);
            next(error);
        }
    },

    /**
     * 발표 타이머 설정
     * POST /api/v1/sessions/:id/timer/setup
     */
    setupTimer: async (req, res, next) => {
        try {
            const {id} = req.params;
            const timerSettings = req.body;

            // 먼저 세션 조회하여 사용자 권한 확인
            const session = await sessionService.getSession(id);

            if (session.user_id !== req.user.id) {
                return res.status(httpStatus.FORBIDDEN).json({
                    success: false,
                    message: '이 세션의 타이머를 설정할 권한이 없습니다.'
                });
            }

            // 타이머 설정 서비스 호출
            const timerData = await sessionService.setupPresentationTimer(id, timerSettings);

            res.status(httpStatus.OK).json({
                success: true,
                data: timerData,
                message: '발표 타이머가 성공적으로 설정되었습니다.'
            });
        } catch (error) {
            logger.error(`Setup timer error for session ID ${req.params.id}:`, error);
            next(error);
        }
    },

    /**
     * 타이머 시작
     * POST /api/v1/sessions/:id/timer/start
     */
    startTimer: async (req, res, next) => {
        try {
            const {id} = req.params;

            // 먼저 세션 조회하여 사용자 권한 확인
            const session = await sessionService.getSession(id);

            if (session.user_id !== req.user.id) {
                return res.status(httpStatus.FORBIDDEN).json({
                    success: false,
                    message: '이 세션의 타이머를 시작할 권한이 없습니다.'
                });
            }

            // 타이머 시작 서비스 호출
            const timerData = await timerService.startTimer(id);

            res.status(httpStatus.OK).json({
                success: true,
                data: timerData,
                message: '타이머가 시작되었습니다.'
            });
        } catch (error) {
            logger.error(`Start timer error for session ID ${req.params.id}:`, error);
            next(error);
        }
    },

    /**
     * 타이머 일시 중지
     * POST /api/v1/sessions/:id/timer/pause
     */
    pauseTimer: async (req, res, next) => {
        try {
            const {id} = req.params;

            // 먼저 세션 조회하여 사용자 권한 확인
            const session = await sessionService.getSession(id);

            if (session.user_id !== req.user.id) {
                return res.status(httpStatus.FORBIDDEN).json({
                    success: false,
                    message: '이 세션의 타이머를 일시 중지할 권한이 없습니다.'
                });
            }

            // 타이머 일시 중지 서비스 호출
            const timerData = await timerService.pauseTimer(id);

            res.status(httpStatus.OK).json({
                success: true,
                data: timerData,
                message: '타이머가 일시 중지되었습니다.'
            });
        } catch (error) {
            logger.error(`Pause timer error for session ID ${req.params.id}:`, error);
            next(error);
        }
    },

    /**
     * 타이머 재개
     * POST /api/v1/sessions/:id/timer/resume
     */
    resumeTimer: async (req, res, next) => {
        try {
            const {id} = req.params;

            // 먼저 세션 조회하여 사용자 권한 확인
            const session = await sessionService.getSession(id);

            if (session.user_id !== req.user.id) {
                return res.status(httpStatus.FORBIDDEN).json({
                    success: false,
                    message: '이 세션의 타이머를 재개할 권한이 없습니다.'
                });
            }

            // 타이머 재개 서비스 호출
            const timerData = await timerService.resumeTimer(id);

            res.status(httpStatus.OK).json({
                success: true,
                data: timerData,
                message: '타이머가 재개되었습니다.'
            });
        } catch (error) {
            logger.error(`Resume timer error for session ID ${req.params.id}:`, error);
            next(error);
        }
    },

    /**
     * 타이머 리셋
     * POST /api/v1/sessions/:id/timer/reset
     */
    resetTimer: async (req, res, next) => {
        try {
            const {id} = req.params;

            // 먼저 세션 조회하여 사용자 권한 확인
            const session = await sessionService.getSession(id);

            if (session.user_id !== req.user.id) {
                return res.status(httpStatus.FORBIDDEN).json({
                    success: false,
                    message: '이 세션의 타이머를 리셋할 권한이 없습니다.'
                });
            }

            // 타이머 리셋 서비스 호출
            const timerData = await timerService.resetTimer(id);

            res.status(httpStatus.OK).json({
                success: true,
                data: timerData,
                message: '타이머가 리셋되었습니다.'
            });
        } catch (error) {
            logger.error(`Reset timer error for session ID ${req.params.id}:`, error);
            next(error);
        }
    },

    /**
     * 타이머 상태 조회
     * GET /api/v1/sessions/:id/timer
     */
    getTimerStatus: async (req, res, next) => {
        try {
            const {id} = req.params;

            // 먼저 세션 조회하여 사용자 권한 확인
            const session = await sessionService.getSession(id);

            if (session.user_id !== req.user.id) {
                return res.status(httpStatus.FORBIDDEN).json({
                    success: false,
                    message: '이 세션의 타이머 상태를 조회할 권한이 없습니다.'
                });
            }

            // 타이머 상태 조회 서비스 호출
            const timerData = await timerService.getTimerStatus(id);

            res.status(httpStatus.OK).json({
                success: true,
                data: timerData
            });
        } catch (error) {
            logger.error(`Get timer status error for session ID ${req.params.id}:`, error);
            next(error);
        }
    }
};

module.exports = sessionController;