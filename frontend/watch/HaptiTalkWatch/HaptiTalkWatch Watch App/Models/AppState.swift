//
//  AppState.swift
//  HaptiTalkWatch Watch App
//
//  Created on 5/13/25.
//

import Foundation
import SwiftUI
import Combine

class AppState: ObservableObject {
    @Published var isConnected: Bool = true
    @Published var connectedDevice: String = "iPhone 15 Pro"
    @Published var recentSessions: [Session] = []
    
    // 더미 데이터 초기화
    init() {
        recentSessions = [
            Session(id: UUID(), name: "소개팅 모드", date: Date().addingTimeInterval(-86400), duration: 1800)
        ]
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
        // 실제 애플 워치 햅틱 구현 코드로 대체될 수 있습니다
    }
}

struct Session: Identifiable {
    var id: UUID
    var name: String
    var date: Date
    var duration: TimeInterval // 초 단위
} 