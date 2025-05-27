# STT Service

실시간 음성 인식(Speech-to-Text) 서비스입니다. WhisperX를 기반으로 한 고성능 STT 엔진을 사용하여 빠르고 정확한 음성 인식을 제공하며, **시나리오별 말하기 분석**과 **고급 음성 코칭** 기능을 지원합니다.

## 🔥 최신 업데이트 (2025.05.27)

- ✅ **시나리오별 음성 분석**: 소개팅/면접/발표 상황에 맞는 말하기 분석
- ✅ **세그먼트 기반 WPM 계산**: 더 정확한 말하기 속도 측정
- ✅ **말하기 패턴 분류**: 7가지 패턴으로 세분화된 분석
- ✅ **실시간 오디오 시각화**: 고급 주파수 분석 및 파형 표시
- ✅ **60초 자동 버퍼링**: 안정적인 실시간 스트리밍 처리
- ✅ **다국어 음절 분석**: 한국어/일본어/중국어 SPM 지원

## 기능

- 오디오 파일 STT 변환
- 한국어 최적화
- 단어별 타임스탬프 지원
- **실시간 음성 인식 (WebSocket)**
- **시나리오별 음성 분석**
  - 💕 소개팅: 짧은 반응, 빠른 응답 감지
  - 💼 면접: 정확한 발화, 적절한 pause 허용
  - 📊 발표: 표준적인 말하기 속도 분석
- **고급 말하기 속도 분석**
  - **세그먼트 기반 WPM**: 평균/중앙값 WPM으로 더 정확한 속도 측정
  - **말하기 패턴 분류**: 끊어 말하기, 연속적, 일정한 속도 등 7가지 패턴
  - **Pause 상세 분석**: 횟수, 평균/최대 길이, 발화 대비 비율 계산
  - **속도 변동성**: 변동계수(CV), 표준편차를 통한 일관성 측정
  - **언어별 음절 분석**: 한국어/일본어/중국어 SPM (Syllables Per Minute)
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

- **기본 테스트**: http://localhost:8000/test/
- **🔥 고급 시나리오별 테스트**: `test/web/index.html` (권장)

### 고급 시나리오별 테스트 클라이언트 (`test/web/index.html`)

**🎯 핵심 기능:**
- **3가지 시나리오 지원**: 💕 소개팅, 💼 면접, 📊 발표
- **실시간 음성 분석**: 세그먼트별 WPM, 말하기 패턴, pause 분석
- **고급 오디오 시각화**: 실시간 주파수 분석 및 파형 표시
- **60초 버퍼링 시스템**: 안정적인 실시간 처리

**단계별 제어:**
1. 🎤 **마이크 권한 요청**: 브라우저 마이크 접근 권한 획득
2. 🔗 **서버 연결**: WebSocket 서버 연결 (연결 상태 실시간 표시)
3. 🎙️ **음성 녹음**: 실시간 음성 데이터 스트리밍 (16kHz PCM)

**편의 기능:**
- ⚡ **원클릭 시작**: 모든 단계를 자동으로 처리
- 📊 **상세한 음성 메트릭**: WPM, SPM, 발화 밀도, pause 패턴 분석
- 📁 **파일 업로드 분석**: 로컬 오디오 파일 분석
- 📈 **실시간 로그**: 오디오 송수신 상태 모니터링
- 🎨 **직관적인 UI**: 시나리오별 색상 구분 및 애니메이션

**테스트 방법:**
```bash
# STT 서버 실행
uvicorn app.main:app --reload

# 별도 터미널에서 테스트 서버 실행 (선택사항)
cd test/web
python -m http.server 8080

# 브라우저에서 접속
open http://localhost:8080/index.html  # 고급 시나리오별 테스트 (권장)
```

### 🎯 새로운 고급 기능들

**세그먼트 기반 분석:**
- **평균/중앙값 WPM**: 더 정확한 말하기 속도 측정
- **말하기 패턴 분류**: 끊어 말하기, 연속적, 일정한 속도 등
- **속도 변동성**: 변동계수(CV) 및 표준편차 계산
- **Pause 상세 분석**: 횟수, 평균/최대 길이, 패턴 분류

**언어별 최적화:**
- **한국어**: 음절 기반 SPM (Syllables Per Minute) 계산
- **일본어/중국어**: 문자 기반 음절 분석 지원
- **영어**: 모음 기반 음절 추정

**실시간 처리:**
- **ScriptProcessor 기반**: 실시간 PCM 데이터 처리
- **60초 자동 버퍼링**: 안정적인 스트리밍 처리
- **즉시 응답**: 음성과 동시에 STT 결과 수신

## 사용 예시

### 1. 파일 업로드 API

```bash
# 기본 STT
curl -X POST "http://localhost:8000/api/v1/stt/transcribe" \
  -H "Content-Type: multipart/form-data" \
  -F "audio_file=@/경로/파일명.wav" \
  -F "language=ko" \
  -F "return_timestamps=true"

# 시나리오별 STT
curl -X POST "http://localhost:8000/api/v1/stt/transcribe?scenario=interview" \
  -H "Content-Type: multipart/form-data" \
  -F "audio_file=@/경로/파일명.wav" \
  -F "language=ko" \
  -F "return_timestamps=true"
```

**응답 예시:**
```json
{
  "text": "안녕하세요. 저는 김철수라고 합니다.",
  "language": "ko",
  "duration": 3.5,
  "processing_time": 0.45,
  "words": [
    {
      "word": "안녕하세요",
      "start": 0.0,
      "end": 0.8,
      "probability": 0.98
    }
  ]
}
```

### 2. WebSocket을 통한 실시간 음성 인식

WebSocket 프로토콜을 사용하여 실시간 음성 스트리밍 및 인식이 가능합니다:

```javascript
// 시나리오별 WebSocket 연결
const socket = new WebSocket("ws://localhost:8000/api/v1/stt/stream?language=ko&scenario=interview");

// 연결 성공 이벤트
socket.onopen = () => {
  console.log("WebSocket 연결 성공");
};

// 메시지 수신 이벤트
socket.onmessage = (event) => {
  const data = JSON.parse(event.data);
  if (data.type === "transcription") {
    console.log("인식 결과:", data.text);
    console.log("말하기 속도:", data.speech_metrics);
    console.log("시나리오:", data.scenario);
  }
};

// 오디오 데이터 전송 (16kHz, 16-bit PCM, 모노)
socket.send(audioData);

// 최종 처리 요청
socket.send(JSON.stringify({command: "process_final"}));
```

**WebSocket 응답 예시:**
```json
{
  "type": "transcription",
  "text": "제가 지원한 이유는 귀하의 회사에서 제 능력을 발휘하고 싶기 때문입니다.",
  "scenario": "interview",
  "language": "ko",
  "is_final": true,
  "speech_metrics": {
    "evaluation_wpm": 175.8,
    "speed_category": "normal",
    "speech_pattern": "steady",
    "average_segment_wpm": 180.5,
    "median_segment_wmp": 178.2,
    "wpm_cv": 0.15,
    "wpm_active": 180.5,
    "wmp_total": 165.2,
    "speech_density": 0.85,
    "pause_metrics": {
      "count": 2,
      "average_duration": 0.8,
      "max_duration": 1.2,
      "pause_ratio": 0.15
    },
    "pause_pattern": "short"
  },
  "syllable_metrics": {
    "syllable_count": 23,
    "spm_active": 120.3,
    "spm_total": 110.1
  },
  "variability_metrics": {
    "cv": 0.15,
    "std": 25.3,
    "mean": 175.8
  },
  "segments": [
    {
      "index": 0,
      "text": "제가 지원한 이유는",
      "start": 0.0,
      "end": 2.1,
      "duration": 2.1,
      "word_count": 4,
      "wpm": 114.3,
      "spm": 171.4
    }
  ]
}
```

## 시나리오별 설정

각 시나리오는 다음과 같은 특성을 가집니다:

### 💕 소개팅 (dating)
- **목적**: 자연스러운 대화, 빠른 반응 감지
- **VAD 설정**: 민감하게 (threshold: 0.6, speech_pad_ms: 500)
- **침묵 허용**: 짧음 (500ms)
- **beam_size**: 5 (표준 속도)
- **분석 특징**: 빠른 응답, 자연스러운 대화 흐름 중시
- **적합한 상황**: 일상 대화, 채팅, 즉석 반응

### 💼 면접 (interview)  
- **목적**: 정확한 발화, 신중한 답변 인식
- **VAD 설정**: 표준 (threshold: 0.7, speech_pad_ms: 1000)
- **침묵 허용**: 김 (1000ms)
- **beam_size**: 10 (높은 정확도)
- **분석 특징**: 정확성 우선, 신중한 발언 패턴 인식
- **적합한 상황**: 공식적인 대화, 인터뷰, 중요한 미팅

### 📊 발표 (presentation)
- **목적**: 표준적인 발표 형태 분석
- **VAD 설정**: 약간 높음 (threshold: 0.75, speech_pad_ms: 800)
- **침묵 허용**: 적당함 (800ms)
- **beam_size**: 5 (표준 속도)
- **분석 특징**: 일정한 말하기 패턴, 표준 속도 기준
- **적합한 상황**: 발표, 강의, 공개 연설, 프레젠테이션

## 말하기 속도 기준

### 한국어 (WPM)
| 시나리오 | 매우 느림 | 느림 | 적당 | 빠름 | 매우 빠름 |
|---------|---------|------|------|------|----------|
| 소개팅   | < 60    | 60-70| 70-120| 120-150| > 150    |
| 면접     | < 50    | 50-65| 65-110| 110-140| > 140    |
| 발표     | < 65    | 65-75| 75-120| 120-160| > 160    |

### 영어 (WPM)
| 시나리오 | 매우 느림 | 느림 | 적당 | 빠름 | 매우 빠름 |
|---------|---------|------|------|------|----------|
| 소개팅   | < 80    | 80-100| 100-150| 150-180| > 180   |
| 면접     | < 70    | 70-90| 90-140| 140-170| > 170    |
| 발표     | < 90    | 90-110| 110-160| 160-190| > 190   |

## 🏆 주요 기술적 성과

### 말하기 분석 알고리즘
- **세그먼트 기반 WPM**: 기존 전체 시간 기반 WPM의 한계를 극복하고 더 정확한 말하기 속도 측정
- **말하기 패턴 분류**: 발화 밀도, pause 패턴, 속도 변동성을 종합하여 7가지 패턴 자동 분류
- **시나리오별 최적화**: 각 상황에 맞는 VAD 파라미터와 평가 기준 적용

### 실시간 처리 최적화
- **60초 자동 버퍼링**: 안정적인 스트리밍을 위한 적응적 버퍼 관리
- **비동기 처리**: FastAPI + asyncio를 활용한 고성능 concurrent 처리
- **메모리 효율성**: 대용량 오디오 데이터의 효율적인 스트리밍 처리

### 다국어 지원
- **언어별 음절 계산**: 한국어(한글), 일본어(히라가나/가타카나/한자), 중국어(한자), 영어(모음 기반)
- **언어별 속도 기준**: 각 언어의 특성을 고려한 말하기 속도 임계값 설정
- **Unicode 범위 기반**: 정확한 문자 분류를 통한 신뢰성 있는 음절 분석

## 📊 프로젝트 구조

```
stt-service/
├── app/
│   ├── main.py                 # FastAPI 애플리케이션 엔트리포인트
│   ├── api/endpoints/          # API 라우터 (stt.py, health.py)
│   ├── core/                   # 핵심 설정 (config.py, logging.py, models.py)
│   └── services/               # 비즈니스 로직 (stt_service.py, websocket_service.py)
├── test/web/
│   └── index.html             # 고급 시나리오별 테스트 클라이언트
├── requirements.txt           # Python 의존성
└── README.md                 # 프로젝트 문서
```

## 라이선스

이 프로젝트는 MIT 라이선스를 따릅니다. 