import Foundation
import WatchConnectivity

// iPhone과의 연결을 관리하는 모델 클래스
class ConnectionModel: NSObject, ObservableObject, WCSessionDelegate {
    @Published var isConnected = true
    @Published var connectedDeviceName = "iPhone 15 Pro"
    
    private var session: WCSession?
    
    override init() {
        super.init()
        
        // WatchConnectivity 설정
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }
    
    // MARK: - WCSessionDelegate
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isConnected = activationState == .activated
        }
    }
    
    #if os(watchOS)
    // 워치OS에서만 필요한 메서드
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        // 메시지 처리 로직
        if let deviceName = message["deviceName"] as? String {
            DispatchQueue.main.async {
                self.connectedDeviceName = deviceName
            }
        }
    }
    #endif
    
    // WatchOS에서만 필요한 메서드들
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif
} 