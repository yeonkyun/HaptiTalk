# STT Service

실시간 음성 인식(Speech-to-Text) 서비스입니다. WhisperX를 기반으로 한 고성능 STT 엔진을 사용하여 빠르고 정확한 음성 인식을 제공합니다.

## 기능

- 오디오 파일 STT 변환
- 한국어 최적화
- 단어별 타임스탬프 지원
- **실시간 음성 인식 (WebSocket)**
- 향후 온디바이스 처리 지원 예정

## 기술 스택

- **FastAPI**: 고성능 비동기 웹 프레임워크
- **WhisperX v3.3.4**: 고급 음성 인식 라이브러리
- **PyTorch 2.7.0**: 딥러닝 프레임워크
- **WebSockets**: 실시간 오디오 스트리밍
- **Jetson Orin Nano 8GB**: 온디바이스 처리를 위한 하드웨어

## 설치 방법

### 1. 환경 설정

```bash
# 가상환경 생성 및 활성화
python -m venv venv
source venv/bin/activate  # Linux/Mac
# venv\Scripts\activate    # Windows
```

### 2. PyTorch 설치 (Jetson 사용시)

```bash
# torch-2.7.0
wget https://pypi.jetson-ai-lab.dev/jp6/cu126/+f/6ef/f643c0a7acda9/torch-2.7.0-cp310-cp310-linux_aarch64.whl
pip install torch-2.7.0-cp310-cp310-linux_aarch64.whl

# torchaudio-2.7.0
wget https://pypi.jetson-ai-lab.dev/jp6/cu126/+f/c59/026d500c57366/torchaudio-2.7.0-cp310-cp310-linux_aarch64.whl
pip install torchaudio-2.7.0-cp310-cp310-linux_aarch64.whl

# torchvision-0.22.0
wget https://pypi.jetson-ai-lab.dev/jp6/cu126/+f/daa/bff3a07259968/torchvision-0.22.0-cp310-cp310-linux_aarch64.whl
pip install torchvision-0.22.0-cp310-cp310-linux_aarch64.whl
```

### 3. 의존성 설치

```bash
pip install -r requirements.txt
```

### 4. 환경 변수 설정

`.env` 파일을 생성하고 필요한 환경 변수를 설정하세요.

```bash
cp .env.example .env
# 필요에 따라 .env 파일 수정
```

## 실행 방법

```bash
# 개발 모드로 실행
uvicorn app.main:app --reload

# 또는
python -m app.main
```

## API 문서

서버 실행 후 다음 URL에서 API 문서를 확인할 수 있습니다:

- Swagger UI: http://localhost:8000/api/v1/docs
- ReDoc: http://localhost:8000/api/v1/redoc

## 실시간 STT 테스트

테스트 웹 인터페이스를 통해 실시간 음성 인식을 테스트할 수 있습니다:

http://localhost:8000/test/

## 사용 예시

### 1. 파일 업로드 API

```bash
curl -X POST "http://localhost:8000/api/v1/stt/transcribe" \
  -H "Content-Type: multipart/form-data" \
  -F "audio_file=@/경로/파일명.wav" \
  -F "language=ko" \
  -F "return_timestamps=true"
```

### 2. WebSocket을 통한 실시간 음성 인식

WebSocket 프로토콜을 사용하여 실시간 음성 스트리밍 및 인식이 가능합니다:

```javascript
// WebSocket 연결
const socket = new WebSocket("ws://localhost:8000/api/v1/stt/stream?language=ko");

// 연결 성공 이벤트
socket.onopen = () => {
  console.log("WebSocket 연결 성공");
  // 인식 시작 명령
  socket.send("start");
};

// 메시지 수신 이벤트
socket.onmessage = (event) => {
  const data = JSON.parse(event.data);
  if (data.type === "transcription") {
    console.log("인식 결과:", data.text);
  }
};

// 오디오 데이터 전송 (16kHz, 16-bit PCM, 모노)
socket.send(audioData);

// 인식 종료
socket.send("stop");
```

## 라이선스

이 프로젝트는 MIT 라이선스를 따릅니다. 