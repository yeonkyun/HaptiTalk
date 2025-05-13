# HaptiTalk 애플 워치 앱

## 프로젝트 구조
```frontend/watch/
  ├── Models/                 # 데이터 모델
  │   └── ConnectionModel.swift  # iPhone과의 연결 관리 모델
  ├── Services/               # 비즈니스 로직, 서비스 
  │   └── WatchSessionService.swift  # 세션 관리 서비스
  ├── Resources/              # 리소스, 유틸리티
  │   └── SessionAssets.swift  # 색상, 스타일, 애셋 정의
  └── README.md               # 프로젝트 설명
```

## 개요
HaptiTalk 애플 워치 앱은 iOS 앱과 연동하여 실시간 대화 모니터링 및 햅틱 피드백을 제공합니다. Swift/SwiftUI로 개발되었으며, 워치OS와 iOS 간의 통신을 위해 WatchConnectivity 프레임워크를 사용합니다.

## 주요 기능
- 세션 시작 및 관리
- iPhone과의 실시간 연동
- 최근 세션 정보 표시
- 햅틱 피드백 알림

## 구현된 컴포넌트
- **ConnectionModel**: iPhone과의 연결 상태 관리
- **WatchSessionService**: 세션 시작, 데이터 전송 등의 서비스 로직
- **SessionAssets**: 워치 앱에서 사용하는 색상, 치수, 스타일 정의

## 개발 및 테스트 환경
- Xcode 15.0+
- watchOS 10.0+
- iOS 17.0+
- 실제 Apple Watch 또는 시뮬레이터

## 피그마 디자인 구현
앱 UI는 피그마에 있는 "애플 워치 시작 화면" 디자인을 기반으로 구현되었습니다. 블랙 배경, 로고, 준비됨 상태, 세션 시작 버튼, 최근 세션 버튼 등의 요소가 포함되어 있습니다.
