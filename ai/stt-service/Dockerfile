# CUDA 지원 PyTorch 기반 이미지 사용
FROM nvidia/cuda:13.0.1-cudnn-devel-ubuntu22.04

# 환경 변수 설정
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    DEBIAN_FRONTEND=noninteractive

# 시스템 패키지 업데이트 및 필수 패키지 설치
RUN apt-get update && apt-get install -y \
    python3.10 \
    python3.10-dev \
    python3-pip \
    python3.10-venv \
    ffmpeg \
    libsndfile1 \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Python 심볼릭 링크 생성
RUN ln -sf /usr/bin/python3.10 /usr/bin/python && \
    ln -sf /usr/bin/python3.10 /usr/bin/python3

# pip 업그레이드
RUN python -m pip install --upgrade pip

# 작업 디렉토리 설정
WORKDIR /stt-service

# requirements.txt 복사 및 의존성 설치
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/ ./app/
COPY test/ ./test/

# 로그 디렉토리 생성
RUN mkdir -p /stt-service/logs

# 임시 오디오 디렉토리 생성 (config.py에서 /tmp/stt_audio 사용)
RUN mkdir -p /tmp/stt_audio

# 포트 노출
EXPOSE 80

# # 헬스체크 설정
# HEALTHCHECK --interval=30s --timeout=30s --start-period=60s --retries=3 \
#     CMD curl -f http://localhost:8002/api/v1/health || exit 1

# 애플리케이션 시작
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "80"]
