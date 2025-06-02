/**
 * WebSocket 클라이언트
 * 자동 재연결 및 메시지 큐 기능을 갖춘 클라이언트 라이브러리
 * 
 * 실시간 클라이언트 측 코드에서 사용하는 라이브러리로
 * 이 파일은 실제로 서버에서 실행되지 않고, 클라이언트 측에서 사용됩니다.
 * 실시간 서비스 성능 개선을 위해 클라이언트 측 구현을 함께 제공합니다.
 */

class WebSocketClient {
  constructor(url, options = {}) {
    this.url = url;
    this.options = {
      reconnectInterval: options.reconnectInterval || 1000,
      maxReconnectInterval: options.maxReconnectInterval || 30000,
      reconnectDecay: options.reconnectDecay || 1.5,
      maxReconnectAttempts: options.maxReconnectAttempts || 0, // 0 = unlimited
      autoConnect: options.autoConnect !== false,
      debug: options.debug || false,
      ...options
    };
    
    this.socket = null;
    this.reconnectAttempts = 0;
    this.reconnectTimer = null;
    this.currentReconnectInterval = this.options.reconnectInterval;
    this.listeners = new Map();
    this.messageQueue = [];
    this.connected = false;
    this.intentionallyClosed = false;
    
    if (this.options.autoConnect) {
      this.connect();
    }
  }
  
  /**
   * WebSocket 연결
   */
  connect() {
    if (this.socket && (this.socket.readyState === WebSocket.CONNECTING || this.socket.readyState === WebSocket.OPEN)) {
      this._debug('WebSocket 이미 연결되어 있거나 연결 중입니다.');
      return;
    }
    
    this._debug(`WebSocket 연결 시도: ${this.url}`);
    this.intentionallyClosed = false;
    
    try {
      this.socket = new WebSocket(this.url);
      
      this.socket.onopen = (event) => {
        this._debug('WebSocket 연결됨');
        this.connected = true;
        this.reconnectAttempts = 0;
        this.currentReconnectInterval = this.options.reconnectInterval;
        
        // 연결 이벤트 발생
        this._emit('open', event);
        
        // 연결 이후 큐에 쌓인 메시지 전송
        this._processQueue();
      };
      
      this.socket.onmessage = (event) => {
        let data = event.data;
        
        try {
          if (typeof data === 'string') {
            data = JSON.parse(data);
          }
        } catch (error) {
          // 파싱 실패 시 원본 데이터 사용
        }
        
        this._emit('message', data);
      };
      
      this.socket.onclose = (event) => {
        this._debug(`WebSocket 연결 종료: 코드=${event.code}, 이유=${event.reason}`);
        this.connected = false;
        
        // 의도적으로 종료한 경우가 아니면 재연결 시도
        if (!this.intentionallyClosed) {
          this._reconnect();
        }
        
        this._emit('close', event);
      };
      
      this.socket.onerror = (error) => {
        this._debug('WebSocket 오류:', error);
        this._emit('error', error);
      };
    } catch (error) {
      this._debug('WebSocket 생성 오류:', error);
      this._reconnect();
    }
  }
  
  /**
   * WebSocket 연결 종료
   */
  disconnect() {
    this._debug('WebSocket 연결 종료 요청');
    this.intentionallyClosed = true;
    
    if (this.reconnectTimer) {
      clearTimeout(this.reconnectTimer);
      this.reconnectTimer = null;
    }
    
    if (this.socket) {
      if (this.socket.readyState === WebSocket.OPEN) {
        this.socket.close(1000, 'Closed by client');
      }
      this.socket = null;
    }
    
    this.connected = false;
  }
  
  /**
   * 이벤트 핸들러 등록
   * @param {string} event 이벤트 이름
   * @param {Function} callback 콜백 함수
   */
  on(event, callback) {
    if (!this.listeners.has(event)) {
      this.listeners.set(event, []);
    }
    
    this.listeners.get(event).push(callback);
    return this;
  }
  
  /**
   * 이벤트 핸들러 제거
   * @param {string} event 이벤트 이름
   * @param {Function} callback 콜백 함수
   */
  off(event, callback) {
    if (!this.listeners.has(event)) {
      return this;
    }
    
    if (!callback) {
      // 이벤트의 모든 리스너 제거
      this.listeners.delete(event);
    } else {
      // 특정 콜백만 제거
      const callbacks = this.listeners.get(event).filter(cb => cb !== callback);
      if (callbacks.length === 0) {
        this.listeners.delete(event);
      } else {
        this.listeners.set(event, callbacks);
      }
    }
    
    return this;
  }
  
  /**
   * 메시지 전송
   * @param {string} event 이벤트 이름
   * @param {any} data 전송할 데이터
   * @param {boolean} queue 연결이 없는 경우 큐에 저장할지 여부
   * @returns {boolean} 전송 성공 여부
   */
  send(event, data, queue = true) {
    const payload = {
      event,
      data,
      timestamp: Date.now()
    };
    
    if (this.connected && this.socket && this.socket.readyState === WebSocket.OPEN) {
      try {
        this.socket.send(JSON.stringify(payload));
        return true;
      } catch (error) {
        this._debug(`메시지 전송 오류: ${error.message}`);
        
        if (queue) {
          this._queueMessage(payload);
        }
        
        return false;
      }
    } else if (queue) {
      this._debug('연결이 없어 메시지를 큐에 저장합니다.');
      this._queueMessage(payload);
      return false;
    }
    
    return false;
  }
  
  /**
   * 연결 상태 확인
   * @returns {boolean} 연결 상태
   */
  isConnected() {
    return this.connected && this.socket && this.socket.readyState === WebSocket.OPEN;
  }
  
  /**
   * 연결 상태 코드 반환
   * @returns {number} 연결 상태 코드 (0: CONNECTING, 1: OPEN, 2: CLOSING, 3: CLOSED, -1: 소켓 없음)
   */
  getState() {
    return this.socket ? this.socket.readyState : -1;
  }
  
  /**
   * 지연 시간 측정
   * @returns {Promise<number>} 지연 시간 (밀리초)
   */
  async ping() {
    return new Promise((resolve, reject) => {
      if (!this.isConnected()) {
        reject(new Error('WebSocket이 연결되어 있지 않습니다.'));
        return;
      }
      
      const start = Date.now();
      const messageId = `ping_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`;
      
      const onPong = (data) => {
        if (data && data.event === 'pong' && data.data && data.data.in_reply_to === messageId) {
          const latency = Date.now() - start;
          this.off('message', onPong);
          resolve(latency);
        }
      };
      
      this.on('message', onPong);
      
      // 5초 후 타임아웃
      setTimeout(() => {
        this.off('message', onPong);
        reject(new Error('Ping 타임아웃'));
      }, 5000);
      
      this.send('ping', { message_id: messageId }, false);
    });
  }
  
  /**
   * 재연결 시도
   * @private
   */
  _reconnect() {
    if (this.intentionallyClosed) {
      return;
    }
    
    if (this.reconnectTimer) {
      clearTimeout(this.reconnectTimer);
    }
    
    this.reconnectAttempts++;
    
    // 최대 재연결 시도 횟수 확인
    if (this.options.maxReconnectAttempts > 0 && this.reconnectAttempts > this.options.maxReconnectAttempts) {
      this._debug(`최대 재연결 시도 횟수(${this.options.maxReconnectAttempts})에 도달했습니다.`);
      this._emit('reconnect_failed', null);
      return;
    }
    
    // 지수 백오프를 적용한 재연결 간격 계산
    this.currentReconnectInterval = Math.min(
      this.currentReconnectInterval * this.options.reconnectDecay,
      this.options.maxReconnectInterval
    );
    
    this._debug(`${this.currentReconnectInterval}ms 후 재연결 시도 (${this.reconnectAttempts}번째)`);
    this._emit('reconnect_attempt', this.reconnectAttempts);
    
    this.reconnectTimer = setTimeout(() => {
      this._debug(`재연결 시도 중... (${this.reconnectAttempts}번째)`);
      this.connect();
    }, this.currentReconnectInterval);
  }
  
  /**
   * 메시지 큐에 추가
   * @param {object} payload 전송할 페이로드
   * @private
   */
  _queueMessage(payload) {
    // 큐 최대 크기 제한 (100개)
    if (this.messageQueue.length >= 100) {
      this.messageQueue.shift(); // 가장 오래된 메시지 제거
    }
    
    this.messageQueue.push(payload);
    this._debug(`메시지 큐 크기: ${this.messageQueue.length}`);
  }
  
  /**
   * 큐에 있는 메시지 처리
   * @private
   */
  _processQueue() {
    if (this.messageQueue.length === 0) {
      return;
    }
    
    this._debug(`${this.messageQueue.length}개의 메시지를 큐에서 처리합니다.`);
    
    // 큐에 있는 메시지 복사 후 초기화
    const queuedMessages = [...this.messageQueue];
    this.messageQueue = [];
    
    // 메시지 전송
    for (const payload of queuedMessages) {
      try {
        if (this.socket && this.socket.readyState === WebSocket.OPEN) {
          this.socket.send(JSON.stringify(payload));
        } else {
          // 연결이 끊어진 경우 다시 큐에 추가
          this._queueMessage(payload);
          break;
        }
      } catch (error) {
        this._debug(`큐 메시지 전송 오류: ${error.message}`);
        this._queueMessage(payload);
        break;
      }
    }
  }
  
  /**
   * 이벤트 발생
   * @param {string} event 이벤트 이름
   * @param {any} data 이벤트 데이터
   * @private
   */
  _emit(event, data) {
    if (!this.listeners.has(event)) {
      return;
    }
    
    for (const callback of this.listeners.get(event)) {
      try {
        callback(data);
      } catch (error) {
        this._debug(`이벤트 핸들러 오류 (${event}): ${error.message}`);
      }
    }
  }
  
  /**
   * 디버그 로깅
   * @private
   */
  _debug(...args) {
    if (this.options.debug) {
      console.log('[WebSocketClient]', ...args);
    }
  }
}

// Node.js 환경에서 사용할 경우
if (typeof module !== 'undefined' && module.exports) {
  module.exports = WebSocketClient;
}

// 브라우저 환경에서 사용할 경우
if (typeof window !== 'undefined') {
  window.WebSocketClient = WebSocketClient;
} 