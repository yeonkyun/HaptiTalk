import Foundation
import WatchConnectivity

// 워치 세션 관련 서비스 클래스
class WatchSessionService {
    static let shared = WatchSessionService()
    
    private init() {}
    
    // 세션 시작 함수
    func startSession(mode: SessionMode) {
        // 세션 시작 로직
        print("세션 시작: \(mode.rawValue) 모드")
        
        // 연결된 iPhone에 세션 시작 메시지 전송
        sendMessageToPhone(message: [
            "action": "startSession",
            "mode": mode.rawValue
        ])
    }
    
    // 가장 최근 세션 정보 가져오기
    func getRecentSession() -> RecentSession? {
        // 실제 앱에서는 UserDefaults 또는 다른 저장소에서 가져옴
        return RecentSession(id: "recent-001", title: "소개팅 모드", date: Date())
    }
    
    // iPhone에 메시지 전송
    private func sendMessageToPhone(message: [String: Any]) {
        guard WCSession.isSupported(),
              WCSession.default.activationState == .activated,
              WCSession.default.isReachable else {
            print("워치 연결 안됨: 메시지 전송 불가")
            return
        }
        
        WCSession.default.sendMessage(message, replyHandler: { reply in
            print("메시지 전송 성공, 응답: \(reply)")
        }, errorHandler: { error in
            print("메시지 전송 실패: \(error.localizedDescription)")
        })
    }
}

// 세션 모드 열거형
enum SessionMode: String {
    case dating = "소개팅"
    case interview = "면접"
    case meeting = "회의"
    case custom = "커스텀"
}

// 최근 세션 모델
struct RecentSession {
    let id: String
    let title: String
    let date: Date
} 