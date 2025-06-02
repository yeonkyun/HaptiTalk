const logger = require('../utils/logger');

module.exports = (io, socket, redisClient) => {
    // 피드백 수신 확인
    socket.on('feedback_ack', async (data) => {
        try {
            const {user} = socket;
            const {feedbackId, receivedAt} = data;

            // Redis에 수신 확인 상태 저장
            await redisClient.hset(`feedback:ack:${feedbackId}`, {
                userId: user.id,
                deviceId: user.deviceId,
                receivedAt: receivedAt || new Date().toISOString(),
                status: 'received'
            });

            logger.debug(`피드백 수신 확인: ID ${feedbackId}, 사용자 ${user.id}`);
        } catch (error) {
            logger.error(`피드백 수신 확인 오류: ${error.message}`);
        }
    });

    // 피드백 요청
    socket.on('request_feedback', async (data) => {
        try {
            const {user} = socket;
            const {sessionId, context} = data;

            // 피드백 요청을 Redis 채널에 발행
            const feedbackRequest = {
                userId: user.id,
                sessionId,
                timestamp: new Date().toISOString(),
                context,
                messageId: data.message_id || `msg_${Date.now()}`
            };

            // feedback:requests 채널로 피드백 요청 발행
            await redisClient.publish(
                'feedback:requests',
                JSON.stringify(feedbackRequest)
            );

            logger.debug(`피드백 요청: 세션 ${sessionId}, 사용자 ${user.id}`);
        } catch (error) {
            logger.error(`피드백 요청 오류: ${error.message}`);
            socket.emit('error', {
                type: 'feedback_error',
                message: '피드백 요청 중 오류가 발생했습니다',
                originalMessage: data.message_id
            });
        }
    });
};