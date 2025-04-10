const { io } = require('socket.io-client');
require('dotenv').config();

// 테스트 설정
const TOKEN = 'your_test_token_here'; // 유효한 JWT 토큰
const SESSION_ID = 'test_session_id'; // 테스트 세션 ID

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
  socket.emit('join_session', {
    sessionId: SESSION_ID
  });
});

// 세션 참여 성공
socket.on('session_joined', (data) => {
  console.log('세션 참여 성공:', data);
  
  // 음성 특성 데이터 전송 (예시)
  const speechData = {
    sessionId: SESSION_ID,
    timestamp: new Date().toISOString(),
    features: {
      pitch: {
        mean: 120.5,
        min: 80.2,
        max: 180.3,
        variance: 45.2
      },
      volume: {
        mean: 65.4,
        min: 45.2,
        max: 85.3,
        variance: 12.5
      },
      speech_rate: 3.2,
      pause_count: 4
    },
    message_id: `speech_${Date.now()}`
  };
  
  console.log('음성 특성 데이터 전송:', speechData);
  socket.emit('speech_features', speechData);
  
  // 3초 후 텍스트 데이터 전송
  setTimeout(() => {
    const textData = {
      sessionId: SESSION_ID,
      timestamp: new Date().toISOString(),
      speakerId: 'user',
      text: '안녕하세요, 이것은 테스트 메시지입니다.',
      startTime: '00:00:10',
      endTime: '00:00:15',
      message_id: `text_${Date.now()}`
    };
    
    console.log('텍스트 데이터 전송:', textData);
    socket.emit('text_segment', textData);
  }, 3000);
  
  // 5초 후 피드백 요청
  setTimeout(() => {
    const feedbackRequest = {
      sessionId: SESSION_ID,
      context: {
        current_speaking_pace: 4.2,
        current_volume: 72.5,
        current_emotion: 'joy'
      },
      message_id: `feedback_req_${Date.now()}`
    };
    
    console.log('피드백 요청:', feedbackRequest);
    socket.emit('request_feedback', feedbackRequest);
  }, 5000);
});

// 피드백 수신
socket.on('feedback', (data) => {
  console.log('피드백 수신:', data);
  
  // 피드백 수신 확인 전송
  socket.emit('feedback_ack', {
    feedbackId: data.feedback_id || data.id,
    receivedAt: new Date().toISOString()
  });
});

// 분석 결과 수신
socket.on('analysis_update', (data) => {
  console.log('분석 결과 수신:', data);
});

// 오류 메시지
socket.on('error', (data) => {
  console.error('오류 메시지 수신:', data);
});

// 60초 후 연결 종료
setTimeout(() => {
  socket.disconnect();
  console.log('연결 종료');
}, 60000); 