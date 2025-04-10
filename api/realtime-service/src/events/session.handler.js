const logger = require('../utils/logger');
const sessionService = require('../services/session.service');

module.exports = (io, socket, redisClient) => {
    // 세션 입장
    socket.on('join_session', async (data) => {
        try {
            const {sessionId} = data;
            const {user} = socket;

            logger.info(`사용자 ${user.id}가 세션 ${sessionId} 입장 시도`);

            // 세션 유효성 검증
            const isValid = await sessionService.validateSession(sessionId, user.id, redisClient);

            if (!isValid) {
                socket.emit('error', {
                    type: 'session_error',
                    message: '세션에 접근할 수 없습니다'
                });
                return;
            }

            // 세션 룸에 참여
            socket.join(`session:${sessionId}`);

            // 세션 참여 상태 저장
            await redisClient.sadd(`session:participants:${sessionId}`, user.id);

            // 세션 연결 정보 저장
            await redisClient.hset(`connections:user:${user.id}`, 'sessionId', sessionId);
            await redisClient.hset(`connections:device:${socket.id}`, 'userId', user.id);

            // 세션 상태 조회
            const sessionStatus = await sessionService.getSessionStatus(sessionId, redisClient);

            // 세션 입장 알림
            socket.emit('session_joined', {
                sessionId,
                status: sessionStatus,
                message: '세션에 성공적으로 참여했습니다'
            });

            // 다른 참가자들에게 새 참가자 알림
            socket.to(`session:${sessionId}`).emit('participant_joined', {
                userId: user.id,
                timestamp: new Date().toISOString()
            });

            logger.info(`사용자 ${user.id}가 세션 ${sessionId}에 성공적으로 참여함`);
        } catch (error) {
            logger.error(`세션 참여 오류: ${error.message}`);
            socket.emit('error', {
                type: 'session_error',
                message: '세션 참여 중 오류가 발생했습니다'
            });
        }
    });

    // 세션 나가기
    socket.on('leave_session', async (data) => {
        try {
            const {sessionId} = data;
            const {user} = socket;

            // 세션 룸에서 나가기
            socket.leave(`session:${sessionId}`);

            // 세션 참여 상태 제거
            await redisClient.srem(`session:participants:${sessionId}`, user.id);

            // 세션 연결 정보 제거
            await redisClient.hdel(`connections:user:${user.id}`, 'sessionId');

            // 다른 참가자들에게 참가자 퇴장 알림
            socket.to(`session:${sessionId}`).emit('participant_left', {
                userId: user.id,
                timestamp: new Date().toISOString()
            });

            logger.info(`사용자 ${user.id}가 세션 ${sessionId}에서 나감`);
        } catch (error) {
            logger.error(`세션 나가기 오류: ${error.message}`);
        }
    });

    // 세션 상태 요청
    socket.on('get_session_status', async (data) => {
        try {
            const {sessionId} = data;
            const sessionStatus = await sessionService.getSessionStatus(sessionId, redisClient);

            socket.emit('session_status', sessionStatus);
        } catch (error) {
            logger.error(`세션 상태 조회 오류: ${error.message}`);
            socket.emit('error', {
                type: 'session_error',
                message: '세션 상태 조회 중 오류가 발생했습니다'
            });
        }
    });
};