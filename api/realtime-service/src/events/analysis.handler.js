const logger = require('../utils/logger');

module.exports = (io, socket, redisClient) => {
    // 음성 특성 데이터 수신
    socket.on('speech_features', async (data) => {
        try {
            const {user} = socket;
            const {sessionId, timestamp, features} = data;

            // 분석 요청을 Redis 채널에 발행
            const analysisRequest = {
                type: 'speech_features',
                userId: user.id,
                sessionId,
                timestamp,
                features,
                messageId: data.message_id || `msg_${Date.now()}`
            };

            // analysis:requests 채널로 분석 요청 발행
            await redisClient.publish(
                'analysis:requests',
                JSON.stringify(analysisRequest)
            );

            logger.debug(`음성 특성 데이터 수신: 세션 ${sessionId}, 사용자 ${user.id}`);
        } catch (error) {
            logger.error(`음성 특성 데이터 처리 오류: ${error.message}`);
            socket.emit('error', {
                type: 'analysis_error',
                message: '음성 데이터 처리 중 오류가 발생했습니다',
                originalMessage: data.message_id
            });
        }
    });

    // 텍스트 데이터 수신
    socket.on('text_segment', async (data) => {
        try {
            const {user} = socket;
            const {sessionId, timestamp, speakerId, text, startTime, endTime} = data;

            // 분석 요청을 Redis 채널에 발행
            const analysisRequest = {
                type: 'text_segment',
                userId: user.id,
                sessionId,
                timestamp,
                speakerId,
                text,
                segment: {
                    start: startTime,
                    end: endTime
                },
                messageId: data.message_id || `msg_${Date.now()}`
            };

            // analysis:requests 채널로 분석 요청 발행
            await redisClient.publish(
                'analysis:requests',
                JSON.stringify(analysisRequest)
            );

            logger.debug(`텍스트 데이터 수신: 세션 ${sessionId}, 사용자 ${user.id}`);
        } catch (error) {
            logger.error(`텍스트 데이터 처리 오류: ${error.message}`);
            socket.emit('error', {
                type: 'analysis_error',
                message: '텍스트 데이터 처리 중 오류가 발생했습니다',
                originalMessage: data.message_id
            });
        }
    });
};