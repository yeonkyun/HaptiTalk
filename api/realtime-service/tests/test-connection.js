const { io } = require('socket.io-client');
require('dotenv').config();

// JWT 세션 토큰 (실제 토큰으로 교체 필요)
const TOKEN = process.env.ACCESS_TOKEN || 'your_test_token_here'; 

// 테스트 통계
const stats = {
  reconnectAttempts: 0,
  messagesSent: 0,
  messagesReceived: 0,
  pingResults: []
};

// 연결 설정
const socket = io('http://localhost:3001', {
  path: '/socket.io/',
  auth: {
    token: TOKEN
  },
  reconnection: true,            // 재연결 활성화
  reconnectionAttempts: 5,       // 최대 재연결 시도 횟수
  reconnectionDelay: 1000,       // 첫 재연결 지연 시간 (ms)
  reconnectionDelayMax: 5000,    // 최대 재연결 지연 시간 (ms)
  timeout: 20000,                // 연결 타임아웃 (ms)
  transports: ['websocket']      // WebSocket 전송 방식 강제
});

console.log('실시간 서비스 연결 테스트 시작...');
console.log('------------------------------');

// 연결 이벤트
socket.on('connect', () => {
  console.log('연결 성공!', socket.id);
  console.log('전송 방식:', socket.io.engine.transport.name);
  
  // 연결 통계 전송
  socket.emit('connection_stats', {
    reconnectAttempts: stats.reconnectAttempts,
    latency: stats.pingResults.length > 0 ? 
      stats.pingResults.reduce((sum, val) => sum + val, 0) / stats.pingResults.length : 
      0,
    transport: socket.io.engine.transport.name
  });
  stats.messagesSent++;
  
  // 연결 성공 후 핑 전송
  sendPing();
});

// 재연결 이벤트
socket.io.on('reconnect_attempt', (attempt) => {
  stats.reconnectAttempts = attempt;
  console.log(`재연결 시도 #${attempt}`);
});

socket.io.on('reconnect', (attempt) => {
  console.log(`${attempt}번째 시도 후 재연결 성공!`);
});

socket.io.on('reconnect_error', (error) => {
  console.error('재연결 오류:', error.message);
});

socket.io.on('reconnect_failed', () => {
  console.error('최대 재연결 시도 횟수를 초과했습니다.');
});

// 연결 오류
socket.on('connect_error', (error) => {
  console.error('연결 오류:', error.message);
});

// 서버에서 오는 이벤트 리스닝
socket.on('pong', (data) => {
  const latency = Date.now() - parseInt(data.in_reply_to.split('_')[1]);
  stats.pingResults.push(latency);
  stats.messagesReceived++;
  console.log(`Pong 수신: 지연 시간 = ${latency}ms, 서버 시간 = ${data.server_time}`);
});

// 오류 메시지
socket.on('error', (data) => {
  console.error('오류 메시지 수신:', data);
  stats.messagesReceived++;
});

// 핑 전송 함수
function sendPing() {
  const pingId = `ping_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`;
  socket.emit('ping', { message_id: pingId });
  stats.messagesSent++;
  console.log('Ping 전송:', pingId);
}

// 30초 동안 5초마다 핑 보내기
let pingInterval = setInterval(sendPing, 5000);

// 테스트 요약 표시
function showStats() {
  console.log('\n------------------------------');
  console.log('테스트 결과 요약:');
  console.log(`- 재연결 시도: ${stats.reconnectAttempts}회`);
  console.log(`- 전송 메시지: ${stats.messagesSent}개`);
  console.log(`- 수신 메시지: ${stats.messagesReceived}개`);
  
  if (stats.pingResults.length > 0) {
    const avgLatency = stats.pingResults.reduce((sum, val) => sum + val, 0) / stats.pingResults.length;
    const minLatency = Math.min(...stats.pingResults);
    const maxLatency = Math.max(...stats.pingResults);
    
    console.log(`- 평균 지연 시간: ${avgLatency.toFixed(2)}ms`);
    console.log(`- 최소 지연 시간: ${minLatency}ms`);
    console.log(`- 최대 지연 시간: ${maxLatency}ms`);
  }
  console.log('------------------------------');
}

// 30초 후 연결 종료
setTimeout(() => {
  clearInterval(pingInterval);
  showStats();
  
  console.log('연결 종료 중...');
  socket.disconnect();
}, 30000);

// 강제 연결 종료 및 재연결 테스트 (10초 후 실행)
setTimeout(() => {
  console.log('\n강제 연결 종료 테스트...');
  socket.io.engine.close();
}, 10000);

// 프로세스 중단 신호 처리
process.on('SIGINT', () => {
  clearInterval(pingInterval);
  socket.disconnect();
  console.log('\n테스트가 중단되었습니다.');
  process.exit(0);
});

// 35초 후 프로세스 종료 (타임아웃 안전장치)
setTimeout(() => {
  process.exit(0);
}, 35000); 