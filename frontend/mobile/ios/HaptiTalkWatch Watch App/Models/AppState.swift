//
//  AppState.swift
//  HaptiTalkWatch Watch App
//
//  Created on 5/13/25.
//

import Foundation
import SwiftUI
import Combine
#if os(watchOS)
import WatchKit
#endif
import WatchConnectivity

@available(watchOS 6.0, *)
class AppState: NSObject, ObservableObject, WCSessionDelegate {
    @Published var isConnected: Bool = false
    @Published var connectedDevice: String = "연결 중..."
    @Published var recentSessions: [Session] = []
    
    // 햅틱 피드백 관련 상태
    @Published var showHapticFeedback: Bool = false
    @Published var hapticFeedbackMessage: String = ""
    @Published var sessionType: String = "소개팅"
    @Published var elapsedTime: String = "00:00:00"
    
    // 실시간 분석 데이터
    @Published var currentLikability: Int = 78
    @Published var currentInterest: Int = 92
    @Published var currentSpeakingSpeed: Int = 85
    @Published var currentEmotion: String = "긍정적"
    @Published var currentFeedback: String = ""
    
    // 세션 요약 관련 상태
    @Published var sessionSummaries: [SessionSummary] = []
    
    // 설정 관련 상태
    @Published var hapticIntensity: String = "기본"  // "기본", "강하게" 옵션
    @Published var hapticCount: Int = 2           // 햅틱 피드백 횟수 (1~4회)
    @Published var notificationStyle: String = "전체"  // "아이콘", "전체"
    @Published var isWatchfaceComplicationEnabled: Bool = true
    @Published var isBatterySavingEnabled: Bool = false
    
    // 세션 상태
    @Published var isSessionActive: Bool = false
    
    // 더미 데이터 초기화
    override init() {
        super.init()
        setupWatchConnectivity()
        
        recentSessions = [
            Session(id: UUID(), name: "소개팅 모드", date: Date().addingTimeInterval(-86400), duration: 1800)
        ]
        
        sessionSummaries = [
            SessionSummary(
                id: UUID(),
                sessionMode: "소개팅 모드",
                totalTime: "1:32:05",
                mainEmotion: "긍정적",
                likeabilityPercent: "88%",
                coreFeedback: "여행 주제에서 높은 호감도를 보였으며, 경청하는 자세가 매우 효과적이었습니다.",
                date: Date().addingTimeInterval(-86400)
            )
        ]
    }
    
    // MARK: - WatchConnectivity Setup
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
            print("Watch: WCSession setup completed")
            
            // 초기 연결 상태 확인
            DispatchQueue.main.async {
                self.updateConnectionStatus()
            }
        } else {
            print("Watch: WCSession is not supported")
        }
    }
    
    private func updateConnectionStatus() {
        let session = WCSession.default
        self.isConnected = session.activationState == .activated && session.isReachable
        
        #if os(watchOS)
        let deviceName = WKInterfaceDevice.current().name
        self.connectedDevice = self.isConnected ? "연결됨: \(deviceName)" : "연결 안됨"
        #endif
        
        print("Watch: Connection status updated - isConnected: \(self.isConnected), device: \(self.connectedDevice)")
    }
    
    // MARK: - WCSessionDelegate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            print("Watch: Session activation completed - state: \(activationState.rawValue)")
            if let error = error {
                print("Watch: Session activation error - \(error.localizedDescription)")
            }
            self.updateConnectionStatus()
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("Watch received message from iPhone: \(message)")
        DispatchQueue.main.async {
            self.handleMessageFromiPhone(message)
        }
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print("Watch received application context from iPhone: \(applicationContext)")
        DispatchQueue.main.async {
            self.handleMessageFromiPhone(applicationContext)
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            print("Watch: Reachability changed - isReachable: \(session.isReachable)")
            self.updateConnectionStatus()
        }
    }
    
    // MARK: - Message Handling
    private func handleMessageFromiPhone(_ message: [String: Any]) {
        guard let action = message["action"] as? String else { return }
        
        switch action {
        case "startSession":
            if let sessionType = message["sessionType"] as? String {
                self.sessionType = sessionType
                self.isSessionActive = true
                self.showHapticNotification(message: "\(sessionType) 세션이 시작되었습니다")
            }
        case "stopSession":
            self.isSessionActive = false
            self.showHapticNotification(message: "세션이 종료되었습니다")
        case "hapticFeedback":
            if let feedbackMessage = message["message"] as? String {
                self.showHapticNotification(message: feedbackMessage)
                
                // 실시간 분석 데이터 파싱
                self.parseAnalysisData(from: feedbackMessage)
            }
        case "realtimeAnalysis":
            // 실시간 분석 데이터 업데이트
            if let likability = message["likability"] as? Int {
                self.currentLikability = likability
            }
            if let interest = message["interest"] as? Int {
                self.currentInterest = interest
            }
            if let speakingSpeed = message["speakingSpeed"] as? Int {
                self.currentSpeakingSpeed = speakingSpeed
            }
            if let emotion = message["emotion"] as? String {
                self.currentEmotion = emotion
            }
            if let feedback = message["feedback"] as? String {
                self.currentFeedback = feedback
                if !feedback.isEmpty {
                    self.showHapticNotification(message: feedback)
                }
            }
        default:
            break
        }
    }
    
    // 햅틱 피드백 메시지에서 분석 데이터 파싱
    private func parseAnalysisData(from message: String) {
        // "호감도: 78%, 관심도: 92%" 형태의 메시지 파싱
        if message.contains("호감도:") && message.contains("관심도:") {
            let components = message.components(separatedBy: ", ")
            
            for component in components {
                if component.contains("호감도:") {
                    let likabilityStr = component.replacingOccurrences(of: "호감도: ", with: "").replacingOccurrences(of: "%", with: "")
                    if let likability = Int(likabilityStr) {
                        self.currentLikability = likability
                    }
                } else if component.contains("관심도:") {
                    let interestStr = component.replacingOccurrences(of: "관심도: ", with: "").replacingOccurrences(of: "%", with: "")
                    if let interest = Int(interestStr) {
                        self.currentInterest = interest
                    }
                }
            }
        } else {
            // 일반 피드백 메시지
            self.currentFeedback = message
        }
    }
    
    // iPhone으로 메시지 전송
    func sendToiPhone(message: [String: Any]) {
        let session = WCSession.default
        print("Watch attempting to send message to iPhone: \(message)")
        print("Session state - isReachable: \(session.isReachable)")
        
        if session.isReachable {
            session.sendMessage(message, replyHandler: { (response: [String: Any]?) in
                if let response = response {
                    print("iPhone responded: \(response)")
                }
            }) { (error: Error?) in
                if let error = error {
                    print("iPhone message error: \(error.localizedDescription)")
                }
            }
        } else {
            print("iPhone is not reachable, using applicationContext")
            do {
                try session.updateApplicationContext(message)
                print("Sent message via applicationContext")
            } catch {
                print("Failed to update applicationContext: \(error.localizedDescription)")
            }
        }
    }
    
    // 연결 상태 관리 함수
    func disconnectDevice() {
        isConnected = false
        // 실제 구현에서는 여기에 Bluetooth 연결 해제 로직이 들어갈 수 있습니다
    }
    
    func reconnectDevice() {
        isConnected = true
        // 실제 구현에서는 여기에 Bluetooth 재연결 로직이 들어갈 수 있습니다
    }
    
    // 햅틱 테스트 함수
    func testHaptic() {
        // UI 업데이트를 위해 메인 스레드에서 시작
        DispatchQueue.main.async {
            // 설정된 햅틱 횟수만큼 반복
            self.playHapticSequence(count: self.hapticCount)
        }
    }
    
    private func playHapticSequence(count: Int, currentIndex: Int = 0) {
        guard currentIndex < count else { return }
        
        #if os(watchOS)
        let device = WKInterfaceDevice.current()
        
        // 강도에 따른 햅틱 피드백 결정
        if self.hapticIntensity == "기본" {
            // 기본 강도 - directionUp 햅틱 사용
            device.play(.directionUp)
            
            // 매우 짧은 간격으로 추가 햅틱 제공
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                device.play(.notification)
            }
        } else {
            // 강한 강도 - 3중 연타 햅틱
            device.play(.notification)
            
            // 더 강한 느낌을 위해 추가 햅틱 제공
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                device.play(.directionUp)
            }
        }
        #endif
        
        // 다음 햅틱을 0.7초 후에 실행 (명확하게 구분될 수 있도록 충분한 간격 필요)
        if currentIndex < count - 1 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                self.playHapticSequence(count: count, currentIndex: currentIndex + 1)
            }
        }
    }
    
    // 햅틱 피드백 알림 표시 함수
    func showHapticNotification(message: String) {
        hapticFeedbackMessage = message
        showHapticFeedback = true
        
        // 실제 워치에서는 햅틱 피드백 발생시키기
        triggerHapticFeedback()
        
        // 5초 후 자동으로 알림 닫기 (필요시)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.showHapticFeedback = false
        }
    }
    
    // 햅틱 피드백 발생 함수
    private func triggerHapticFeedback() {
        // 사용자가 설정한 햅틱 강도에 따라 피드백 제공
        testHaptic()
    }
    
    // 세션 요약 저장 함수
    func saveSessionSummary(summary: SessionSummary) {
        sessionSummaries.insert(summary, at: 0)
        // 실제 구현에서는 여기에 데이터 저장 로직이 들어갈 수 있습니다
    }
    
    // 설정 저장 함수
    func saveSettings() {
        // 실제 구현에서는 여기에 설정 저장 로직이 들어갈 수 있습니다
        // UserDefaults 또는 다른 영구 저장소에 저장
    }
}

struct Session: Identifiable {
    var id: UUID
    var name: String
    var date: Date
    var duration: TimeInterval // 초 단위
}

struct SessionSummary: Identifiable {
    var id: UUID
    var sessionMode: String
    var totalTime: String
    var mainEmotion: String
    var likeabilityPercent: String
    var coreFeedback: String
    var date: Date
} 