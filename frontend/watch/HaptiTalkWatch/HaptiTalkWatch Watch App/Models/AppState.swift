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
}

struct Session: Identifiable {
    var id: UUID
    var name: String
    var date: Date
    var duration: TimeInterval // 초 단위
} 