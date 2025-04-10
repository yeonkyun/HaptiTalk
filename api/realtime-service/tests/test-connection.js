const { io } = require('socket.io-client');
require('dotenv').config();

// JWT 세션 토큰 (실제 토큰으로 교체 필요)
const TOKEN = 'your_test_token_here'; 

// 연결 설정
const socket = io('http://localhost:3001', {
  path: '/socket.io/',
  auth: {
    token: TOKEN
  }
});

// 연결 이벤트
socket.on('connect', () => {
  console.log('연결 성공!', socket.id);
  
  // 연결 성공 후 핑 전송
  socket.emit('ping', {
    message_id: `ping_${Date.now()}`
  });
});

// 연결 오류
socket.on('connect_error', (error) => {
  console.error('연결 오류:', error.message);
});

// 서버에서 오는 이벤트 리스닝
socket.on('pong', (data) => {
  console.log('Pong 수신:', data);
});

// 오류 메시지
socket.on('error', (data) => {
  console.error('오류 메시지 수신:', data);
});

// 5초 후 연결 종료
setTimeout(() => {
  socket.disconnect();
  console.log('연결 종료');
}, 5000); 