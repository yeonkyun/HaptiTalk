const { io } = require('socket.io-client');
require('dotenv').config();

// 테스트 설정
const TOKEN = process.env.ACCESS_TOKEN || 'your_test_token_here'; // 환경변수에서 토큰 가져오기
const SESSION_ID = process.env.REALTIME_SESSION_ID || 'test_session_id'; // 환경변수에서 세션 ID 가져오기
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
  
  // 세션 참여 요청
  console.log(`세션 ${SESSION_ID}에 참여 요청`);
  socket.emit('join_session', {
    sessionId: SESSION_ID
  });
});

// 세션 참여 성공
socket.on('session_joined', (data) => {
  console.log('세션 참여 성공:', data);
  
  // 세션 상태 요청
  socket.emit('get_session_status', {
    sessionId: SESSION_ID
  });
  
  // 피드백 요청 테스트 추가
  console.log('피드백 요청 전송');
  socket.emit('feedback_request', {
    sessionId: SESSION_ID,
    context: {
      speaking_pace: 4.2,
      volume: 72.5,
      current_emotion: 'joy',
      interaction_state: 'user_speaking'
    }
  });
  
  // 5초 후 세션 나가기 (30초에서 5초로 단축)
  setTimeout(() => {
    console.log(`세션 ${SESSION_ID}에서 나가기 요청`);
    socket.emit('leave_session', {
      sessionId: SESSION_ID
    });
    
    // 세션 나간 후 1초 후 연결 종료
    setTimeout(() => {
      socket.disconnect();
      console.log('연결 종료');
      process.exit(0); // 프로세스 종료 추가
    }, 1000);
  }, 5000);
});

// 세션 상태 응답
socket.on('session_status', (data) => {
  console.log('세션 상태:', data);
});

// 피드백 수신 핸들러 추가
socket.on('feedback', (data) => {
  console.log('피드백 수신:', data);
});

// 참가자 이벤트
socket.on('participant_joined', (data) => {
  console.log('새 참가자 입장:', data);
});

socket.on('participant_left', (data) => {
  console.log('참가자 퇴장:', data);
});

// 오류 메시지
socket.on('error', (data) => {
  console.error('오류 메시지 수신:', data);
});

// 연결 오류
socket.on('connect_error', (error) => {
  console.error('연결 오류:', error.message);
});

// 10초 후 강제 종료 추가
setTimeout(() => {
  console.log('타임아웃으로 종료');
  process.exit(1);
}, 10000); 