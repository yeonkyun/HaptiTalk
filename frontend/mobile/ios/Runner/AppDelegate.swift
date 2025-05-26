import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  // private var watchChannel: FlutterMethodChannel? // Watch 기능 비활성화
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Watch 관련 기능 완전 비활성화 (키보드 문제 해결용)
    // Method Channel 설정
    // let controller = window?.rootViewController as! FlutterViewController
    // watchChannel = FlutterMethodChannel(name: "com.haptitalk/watch", 
    //                                    binaryMessenger: controller.binaryMessenger)
    
    // watchChannel?.setMethodCallHandler { [weak self] (call, result) in
    //   self?.handleMethodCall(call: call, result: result)
    // }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  /*
  private func setupWatchConnectivity() {
    if WCSession.isSupported() {
      let session = WCSession.default
      print("=== iOS WCSession 초기 상태 ===")
      print("활성화 상태: \(session.activationState.rawValue)")
      print("워치 앱 설치됨: \(session.isWatchAppInstalled)")
      print("페어링 상태: \(session.isPaired)")
      print("통신 가능 상태: \(session.isReachable)")
      print("===========================")
      
      session.delegate = self
      session.activate()
      print("iOS: WCSession setup completed")
      
      // 초기 연결 상태를 Flutter에 알림
      DispatchQueue.main.async { [weak self] in
        self?.notifyWatchConnectionStatus()
      }
    } else {
      print("iOS: WatchConnectivity not supported")
    }
  }
  */
  
  /*
  // 모든 Watch 관련 메서드들 비활성화
  private func notifyWatchConnectionStatus() {
    let session = WCSession.default
    let status = [
      "isSupported": WCSession.isSupported(),
      "isPaired": session.isPaired,
      "isWatchAppInstalled": session.isWatchAppInstalled,
      "isReachable": session.isReachable,
      "activationState": session.activationState.rawValue
    ] as [String : Any]
    
    watchChannel?.invokeMethod("watchConnectionStatus", arguments: status)
    print("iOS: Notified connection status - \(status)")
  }
  
  private func handleMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "startSession":
      if let args = call.arguments as? [String: Any],
         let sessionType = args["sessionType"] as? String {
        sendToWatch(message: ["action": "startSession", "sessionType": sessionType])
        result("Session started")
      } else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "sessionType is required", details: nil))
      }
    case "stopSession":
      sendToWatch(message: ["action": "stopSession"])
      result("Session stopped")
    case "sendHapticFeedback":
      if let args = call.arguments as? [String: Any],
         let message = args["message"] as? String {
        sendToWatch(message: ["action": "hapticFeedback", "message": message])
        result("Haptic sent")
      } else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "message is required", details: nil))
      }
    case "sendRealtimeAnalysis":
      if let args = call.arguments as? [String: Any] {
        var message: [String: Any] = ["action": "realtimeAnalysis"]
        message["likability"] = args["likability"]
        message["interest"] = args["interest"]
        message["speakingSpeed"] = args["speakingSpeed"]
        message["emotion"] = args["emotion"]
        message["feedback"] = args["feedback"]
        message["elapsedTime"] = args["elapsedTime"]
        sendToWatch(message: message)
        result("Realtime analysis sent")
      } else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "analysis data is required", details: nil))
      }
    case "isWatchConnected":
      let session = WCSession.default
      let isConnected = session.isPaired && session.isWatchAppInstalled
      result(isConnected)
    case "testConnection":
      let session = WCSession.default
      let status = [
        "isSupported": WCSession.isSupported(),
        "isPaired": session.isPaired,
        "isWatchAppInstalled": session.isWatchAppInstalled,
        "isReachable": session.isReachable,
        "activationState": session.activationState.rawValue
      ] as [String : Any]
      result(status)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func sendToWatch(message: [String: Any]) {
    let session = WCSession.default
    print("iOS: Attempting to send message - \(message)")
    
    // 연결 상태 전체 체크
    guard session.activationState == .activated,
          session.isPaired,
          session.isWatchAppInstalled else {
      print("iOS: Watch is not properly connected - activationState: \(session.activationState.rawValue), isPaired: \(session.isPaired), isWatchAppInstalled: \(session.isWatchAppInstalled)")
      return
    }
    
    if session.isReachable {
      session.sendMessage(message, replyHandler: { response in
        print("iOS: Watch responded - \(response)")
      }) { error in
        print("iOS: Failed to send message - \(error.localizedDescription)")
        
        // 메시지 전송 실패 시 applicationContext로 재시도
        self.sendViaApplicationContext(message)
      }
    } else {
      print("iOS: Watch is not reachable, trying applicationContext")
      sendViaApplicationContext(message)
    }
  }
  
  private func sendViaApplicationContext(_ message: [String: Any]) {
    do {
      try WCSession.default.updateApplicationContext(message)
      print("iOS: Sent via applicationContext")
    } catch {
      print("iOS: Failed to update applicationContext - \(error.localizedDescription)")
    }
  }
  
  // MARK: - WCSessionDelegate
  func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    DispatchQueue.main.async { [weak self] in
      print("iOS: Session activation completed - state: \(activationState.rawValue)")
      if let error = error {
        print("iOS: Session activation error - \(error.localizedDescription)")
      }
      self?.notifyWatchConnectionStatus()
    }
  }
  
  func sessionDidBecomeInactive(_ session: WCSession) {
    print("Watch session became inactive")
  }
  
  func sessionDidDeactivate(_ session: WCSession) {
    print("Watch session deactivated")
    // 재활성화
    session.activate()
  }
  
  func sessionReachabilityDidChange(_ session: WCSession) {
    DispatchQueue.main.async { [weak self] in
      print("iOS: Reachability changed - isReachable: \(session.isReachable)")
      self?.notifyWatchConnectionStatus()
    }
  }
  
  func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
    print("Received message from watch: \(message)")
    DispatchQueue.main.async { [weak self] in
      self?.watchChannel?.invokeMethod("watchMessage", arguments: message)
    }
  }
  
  func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
    print("Received application context from watch: \(applicationContext)")
    DispatchQueue.main.async { [weak self] in
      self?.watchChannel?.invokeMethod("watchMessage", arguments: applicationContext)
    }
  }
  */
}
