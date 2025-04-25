const { io } = require('socket.io-client');
require('dotenv').config();

// 테스트 설정
const TOKEN = process.env.ACCESS_TOKEN || 'your_test_token_here'; // 환경변수에서 토큰 가져오기
const SESSION_ID = process.env.REALTIME_SESSION_ID || `test_session_${Date.now()}`; // 고유한 기본 세션 ID 생성

console.log('실시간 서비스 세션 테스트 시작...');
console.log('------------------------------');
console.log(`세션 ID: ${SESSION_ID}`);

// 테스트 상태
const testState = {
  isInSession: false,
  reconnected: false,
  messagesBatched: [],
  feedbackReceived: false
};

// 연결 설정
const socket = io('http://localhost:3001', {
  path: '/socket.io/',
  auth: {
    token: TOKEN
  },
  reconnection: true,
  reconnectionAttempts: 5,
  reconnectionDelay: 1000,
  reconnectionDelayMax: 5000,
  timeout: 20000
});

// 연결 이벤트
socket.on('connect', () => {
  console.log('연결 성공!', socket.id);
  
  if (!testState.isInSession) {
    // 최초 연결 시 세션 참여 요청
    console.log(`세션 ${SESSION_ID}에 참여 요청`);
    socket.emit('join_session', {
      sessionId: SESSION_ID
    });
  } else if (testState.reconnected) {
    // 재연결 시 세션 다시 참여하지 않음 (자동 복구 확인)
    console.log('재연결 완료, 세션 참여 상태 확인...');
    socket.emit('get_session_status', {
      sessionId: SESSION_ID
    });
  }
});

// 재연결 시도 이벤트
socket.io.on('reconnect_attempt', (attempt) => {
  console.log(`재연결 시도 #${attempt}`);
});

// 재연결 성공 이벤트
socket.io.on('reconnect', () => {
  console.log('재연결 성공!');
  testState.reconnected = true;
});

// 세션 참여 성공
socket.on('session_joined', (data) => {
  console.log('세션 참여 성공:', data);
  testState.isInSession = true;
  
  // 세션 상태 요청
  socket.emit('get_session_status', {
    sessionId: SESSION_ID
  });
  
  // 메시지 배치 테스트 - 10개 메시지를 빠르게 전송
  console.log('\n메시지 배치 처리 테스트 시작...');
  for (let i = 0; i < 10; i++) {
    const message = {
      sessionId: SESSION_ID,
      context: {
        index: i,
        speaking_pace: 3.5 + (i * 0.1),
        volume: 70 + i,
        timestamp: Date.now()
      }
    };
    testState.messagesBatched.push(message);
    
    // 메시지 즉시 전송
    socket.emit('feedback_request', message);
    console.log(`배치 메시지 #${i} 전송됨`);
  }
  
  // 3초 후 단일 피드백 요청
  setTimeout(() => {
    console.log('\n단일 피드백 요청 전송');
    socket.emit('feedback_request', {
      sessionId: SESSION_ID,
      context: {
        speaking_pace: 4.2,
        volume: 72.5,
        current_emotion: 'joy',
        interaction_state: 'user_speaking'
      }
    });
  }, 3000);
  
  // 10초 후 강제 연결 종료 테스트
  setTimeout(() => {
    console.log('\n강제 연결 종료 및 자동 재연결 테스트...');
    socket.io.engine.close();
  }, 10000);
  
  // 20초 후 세션 나가기
  setTimeout(() => {
    if (testState.isInSession) {
      console.log(`\n세션 ${SESSION_ID}에서 나가기 요청`);
      socket.emit('leave_session', {
        sessionId: SESSION_ID
      });
    }
    
    // 세션 나간 후 1초 후 연결 종료
    setTimeout(() => {
      socket.disconnect();
      console.log('\n연결 종료');
      
      console.log('\n테스트 결과 요약:');
      console.log(`- 세션 참여 성공: ${testState.isInSession}`);
      console.log(`- 재연결 발생: ${testState.reconnected}`);
      console.log(`- 배치 메시지 전송: ${testState.messagesBatched.length}개`);
      console.log(`- 피드백 수신: ${testState.feedbackReceived ? '성공' : '실패'}`);
      
      process.exit(0); // 프로세스 종료
    }, 1000);
  }, 20000);
});

// 세션 상태 응답
socket.on('session_status', (data) => {
  console.log('세션 상태:', data);
  if (testState.reconnected && data.isActive) {
    console.log('세션 상태가 재연결 후에도 유지됨을 확인! ✓');
  }
});

// 피드백 수신 핸들러
socket.on('feedback', (data) => {
  console.log('피드백 수신:', data);
  testState.feedbackReceived = true;
  
  // 피드백 수신 확인 응답
  socket.emit('feedback_ack', {
    feedbackId: data.id || data.feedback_id,
    receivedAt: new Date().toISOString()
  });
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

// 프로세스 중단 신호 처리
process.on('SIGINT', () => {
  socket.disconnect();
  console.log('\n테스트가 중단되었습니다.');
  process.exit(0);
});

// 30초 후 강제 종료 (타임아웃 안전장치)
setTimeout(() => {
  console.log('\n타임아웃으로 종료');
  socket.disconnect();
  process.exit(1);
}, 30000); 