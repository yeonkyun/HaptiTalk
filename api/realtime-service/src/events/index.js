const sessionHandler = require('./session.handler');
const feedbackHandler = require('./feedback.handler');
const analysisHandler = require('./analysis.handler');
const logger = require('../utils/logger');

module.exports = (io, redisClient) => {
    // Redis Pub/Sub 채널 구독
    const redisSub = redisClient.duplicate();

    // 피드백 채널 구독
    redisSub.psubscribe('feedback:channel:*');

    // 분석 이벤트 채널 구독
    redisSub.psubscribe('analysis:events:*');

    // Redis 메시지 수신 시 처리
    redisSub.on('pmessage', (pattern, channel, message) => {
        try {
            const payload = JSON.parse(message);

            if (pattern === 'feedback:channel:*') {
                const sessionId = channel.split(':')[2];
                io.to(`session:${sessionId}`).emit('feedback', payload);
                logger.debug(`피드백 전달: 세션 ${sessionId}`);
            } else if (pattern === 'analysis:events:*') {
                const sessionId = channel.split(':')[2];
                io.to(`session:${sessionId}`).emit('analysis_update', payload);
                logger.debug(`분석 업데이트 전달: 세션 ${sessionId}`);
            }
        } catch (error) {
            logger.error(`Redis 메시지 처리 오류: ${error.message}`);
        }
    });

    // 클라이언트 연결 처리
    io.on('connection', (socket) => {
        const {user} = socket;

        logger.info(`사용자 ${user.id} 연결됨 (소켓 ID: ${socket.id})`);

        // 사용자 세션 관리
        sessionHandler(io, socket, redisClient);

        // 피드백 이벤트 처리
        feedbackHandler(io, socket, redisClient);

        // 분석 데이터 처리
        analysisHandler(io, socket, redisClient);

        // 핑/퐁 처리
        socket.on('ping', (data) => {
            socket.emit('pong', {
                timestamp: new Date().toISOString(),
                server_time: new Date().toISOString(),
                message_id: data.message_id,
                in_reply_to: data.message_id
            });
        });

        // 연결 종료 처리
        socket.on('disconnect', async () => {
            try {
                // 사용자 연결 정보 제거
                if (user) {
                    // 현재 세션 확인
                    const sessionId = await redisClient.hget(`connections:user:${user.id}`, 'sessionId');

                    if (sessionId) {
                        // 세션 참여 상태 제거
                        await redisClient.srem(`session:participants:${sessionId}`, user.id);

                        // 다른 참가자들에게 참가자 퇴장 알림
                        socket.to(`session:${sessionId}`).emit('participant_left', {
                            userId: user.id,
                            timestamp: new Date().toISOString()
                        });
                    }

                    // 연결 정보 제거
                    await redisClient.hdel(`connections:user:${user.id}`, 'sessionId');
                    await redisClient.del(`connections:device:${socket.id}`);
                }

                logger.info(`사용자 ${user?.id || '알 수 없음'} 연결 종료됨 (소켓 ID: ${socket.id})`);
            } catch (error) {
                logger.error(`연결 종료 처리 오류: ${error.message}`);
            }
        });
    });
};