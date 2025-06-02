const { io } = require('socket.io-client');
require('dotenv').config();

// 테스트 설정
const TOKEN = process.env.ACCESS_TOKEN || 'your_test_token_here'; // 유효한 JWT 토큰
const SESSION_ID = process.env.REALTIME_SESSION_ID || `test_data_session_${Date.now()}`; // 고유한 세션 ID

console.log('실시간 서비스 데이터 전송 테스트 시작...');
console.log('----------------------------------------');
console.log(`세션 ID: ${SESSION_ID}`);

// 테스트 상태
const testState = {
  feedbackReceived: 0,
  analysisReceived: 0,
  messagesQueued: [],
  messagesSent: 0,
  forcedDisconnection: false,
  queuedMessagesSentAfterReconnect: false
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
  reconnectionDelayMax: 5000
});

// 연결 이벤트
socket.on('connect', () => {
  console.log('연결 성공!', socket.id);
  
  // 메시지 큐가 남아있는지 확인
  if (testState.forcedDisconnection && testState.messagesQueued.length > 0) {
    console.log(`\n재연결 후 큐에 있는 ${testState.messagesQueued.length}개 메시지 처리 중...`);
    
    // 큐에 있는 메시지 전송
    sendQueuedMessages();
    testState.queuedMessagesSentAfterReconnect = true;
  } else {
    // 세션 참여 요청
    socket.emit('join_session', {
      sessionId: SESSION_ID
    });
  }
});

// 재연결 이벤트
socket.io.on('reconnect_attempt', (attempt) => {
  console.log(`재연결 시도 #${attempt}`);
});

socket.io.on('reconnect', () => {
  console.log('재연결 성공!');
});

// 세션 참여 성공
socket.on('session_joined', (data) => {
  console.log('세션 참여 성공:', data);
  
  // 연속적인 음성 특성 데이터 전송 (3초 간격으로 5개)
  sendSpeechFeatures(5);
  
  // 10초 후 강제 연결 종료 및 메시지 큐 테스트
  setTimeout(() => {
    console.log('\n강제 연결 종료 및 메시지 큐 테스트 시작...');
    
    // 먼저 연결 종료 상태 기록
    testState.forcedDisconnection = true;
    
    // 연결 강제 종료
    socket.io.engine.close();
    
    // 연결이 끊긴 상태에서 메시지 전송 시도 (큐에 저장됨)
    console.log('연결이 끊긴 상태에서 메시지 전송 시도 (큐 테스트)');
    
    for (let i = 0; i < 3; i++) {
      const textData = {
        sessionId: SESSION_ID,
        timestamp: new Date().toISOString(),
        speakerId: 'user',
        text: `테스트 메시지 #${i} - 연결 끊김 상태에서 전송됨`,
        startTime: `00:00:${20 + i}`,
        endTime: `00:00:${25 + i}`,
        message_id: `text_${Date.now()}_${i}`
      };
      
      // 메시지 큐에 추가
      testState.messagesQueued.push(textData);
      
      // 전송 시도 (내부적으로 큐에 저장됨)
      socket.emit('text_segment', textData);
      console.log(`메시지 큐 테스트 #${i} 전송 시도`);
    }
  }, 10000);
  
  // 25초 후 테스트 종료
  setTimeout(() => {
    showTestSummary();
    socket.disconnect();
    console.log('연결 종료');
    process.exit(0);
  }, 25000);
});

// 피드백 수신
socket.on('feedback', (data) => {
  console.log('피드백 수신:', data);
  testState.feedbackReceived++;
  
  // 피드백 수신 확인 전송
  socket.emit('feedback_ack', {
    feedbackId: data.feedback_id || data.id,
    receivedAt: new Date().toISOString()
  });
});

// 분석 결과 수신
socket.on('analysis_update', (data) => {
  console.log('분석 결과 수신:', data);
  testState.analysisReceived++;
});

// 오류 메시지
socket.on('error', (data) => {
  console.error('오류 메시지 수신:', data);
});

// 재연결 오류
socket.io.on('reconnect_error', (error) => {
  console.error('재연결 오류:', error.message);
});

// 음성 특성 데이터 전송 함수
function sendSpeechFeatures(count = 1, interval = 3000) {
  let sent = 0;
  
  function sendNext() {
    if (sent >= count) return;
    
    const speechData = {
      sessionId: SESSION_ID,
      timestamp: new Date().toISOString(),
      features: {
        pitch: {
          mean: 120.5 + (sent * 2),
          min: 80.2 - (sent * 1.5),
          max: 180.3 + (sent * 1.8),
          variance: 45.2 + (sent * 0.5)
        },
        volume: {
          mean: 65.4 + (sent * 0.8),
          min: 45.2 + (sent * 0.3),
          max: 85.3 + (sent * 1.2),
          variance: 12.5 + (sent * 0.2)
        },
        speech_rate: 3.2 + (sent * 0.1),
        pause_count: 4 + (sent % 3)
      },
      message_id: `speech_${Date.now()}_${sent}`
    };
    
    console.log(`음성 특성 데이터 #${sent} 전송:`, 
      `음높이=${speechData.features.pitch.mean.toFixed(1)}, ` +
      `음량=${speechData.features.volume.mean.toFixed(1)}, ` + 
      `속도=${speechData.features.speech_rate.toFixed(1)}`);
    
    socket.emit('speech_features', speechData);
    testState.messagesSent++;
    
    sent++;
    
    // 3초 후 다음 텍스트 데이터 전송
    if (sent < count) {
      setTimeout(sendNext, interval);
    } else {
      // 모든 음성 데이터 전송 후 텍스트 데이터 한 개 전송
      const textData = {
        sessionId: SESSION_ID,
        timestamp: new Date().toISOString(),
        speakerId: 'user',
        text: '안녕하세요, 이것은 테스트 메시지입니다.',
        startTime: '00:00:10',
        endTime: '00:00:15',
        message_id: `text_${Date.now()}`
      };
      
      console.log('\n텍스트 데이터 전송:', textData.text);
      socket.emit('text_segment', textData);
      testState.messagesSent++;
      
      // 피드백 요청 전송
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
        
        console.log('\n피드백 요청 전송');
        socket.emit('request_feedback', feedbackRequest);
        testState.messagesSent++;
      }, 2000);
    }
  }
  
  // 첫 번째 데이터 전송 시작
  sendNext();
}

// 큐에 있는 메시지 전송
function sendQueuedMessages() {
  for (const message of testState.messagesQueued) {
    socket.emit('text_segment', message);
    console.log(`큐에 있던 메시지 재전송: ${message.text}`);
  }
}

// 테스트 결과 요약
function showTestSummary() {
  console.log('\n----------------------------------------');
  console.log('테스트 결과 요약:');
  console.log(`- 전송된 메시지: ${testState.messagesSent}개`);
  console.log(`- 큐에 저장된 메시지: ${testState.messagesQueued.length}개`);
  console.log(`- 재연결 후 큐 메시지 전송: ${testState.queuedMessagesSentAfterReconnect ? '성공' : '실패'}`);
  console.log(`- 피드백 수신: ${testState.feedbackReceived}개`);
  console.log(`- 분석 결과 수신: ${testState.analysisReceived}개`);
  console.log('----------------------------------------');
}

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