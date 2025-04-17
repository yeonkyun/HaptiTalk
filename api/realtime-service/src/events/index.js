const sessionHandler = require('./session.handler');
const feedbackHandler = require('./feedback.handler');
const analysisHandler = require('./analysis.handler');
const logger = require('../utils/logger');

module.exports = (io, redisClient, pubSub) => {
    // 클라이언트 연결 처리
    io.on('connection', (socket) => {
        const {user} = socket;

        logger.info(`사용자 ${user.id} 연결됨 (소켓 ID: ${socket.id})`);

        // 연결 상태 모니터링을 위한 ping_check 핸들러
        socket.on('ping_check', (data, callback) => {
            try {
                if (callback && typeof callback === 'function') {
                    callback({
                        status: 'ok',
                        timestamp: Date.now(),
                        received: data.timestamp,
                        socketId: socket.id
                    });
                }
            } catch (error) {
                logger.error(`ping_check 응답 오류: ${error.message}`);
            }
        });

        // 사용자 세션 관리
        sessionHandler(io, socket, redisClient);

        // 피드백 이벤트 처리
        feedbackHandler(io, socket, redisClient);

        // 분석 데이터 처리
        analysisHandler(io, socket, redisClient);

        // 핑/퐁 처리 (클라이언트 지연 시간 측정용)
        socket.on('ping', (data) => {
            // 메시지 체크 및 에러 방지
            const messageId = data && data.message_id ? data.message_id : `ping_${Date.now()}`;
            
            socket.emit('pong', {
                timestamp: Date.now(),
                server_time: new Date().toISOString(),
                message_id: `pong_${Date.now()}`,
                in_reply_to: messageId
            });
        });

        // 연결 종료 처리 - ConnectionManager로 이관
        socket.on('disconnect', () => {
            logger.info(`사용자 ${user?.id || '알 수 없음'} 소켓 연결 종료됨 (소켓 ID: ${socket.id})`);
        });
        
        // 클라이언트 측 연결 상태 정보 수집
        socket.on('connection_stats', (stats) => {
            try {
                if (stats && typeof stats === 'object') {
                    // 연결 통계 저장 (선택적)
                    redisClient.hset(
                        `socket:stats:${socket.id}`,
                        'lastReported', Date.now(),
                        'reconnectAttempts', stats.reconnectAttempts || 0,
                        'latency', stats.latency || 0,
                        'transport', stats.transport || socket.conn.transport.name
                    ).catch(err => logger.error(`연결 통계 저장 오류: ${err.message}`));
                    
                    logger.debug(`클라이언트 연결 상태: ${socket.id}, 지연시간=${stats.latency}ms, 재연결=${stats.reconnectAttempts}회`);
                }
            } catch (error) {
                logger.error(`연결 통계 처리 오류: ${error.message}`);
            }
        });
        
        // 메시지 배치 수신 처리
        socket.on('message_batch', (messages) => {
            try {
                if (Array.isArray(messages)) {
                    for (const msg of messages) {
                        if (msg && msg.event) {
                            // 각 메시지 유형에 맞게 처리
                            const handlers = socket.eventHandlers || {};
                            const handler = handlers[msg.event];
                            
                            if (handler && typeof handler === 'function') {
                                handler(msg.data);
                            }
                        }
                    }
                }
            } catch (error) {
                logger.error(`메시지 배치 처리 오류: ${error.message}`);
            }
        });
    });
};