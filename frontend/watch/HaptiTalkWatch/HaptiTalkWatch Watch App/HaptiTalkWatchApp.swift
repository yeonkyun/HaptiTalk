//
//  HaptiTalkWatchApp.swift
//  HaptiTalkWatch Watch App
//
//  Created by 이은범 on 5/13/25.
//

import SwiftUI

@main
struct HaptiTalkWatch_Watch_AppApp: App {
    // 애플리케이션 시작 시 ConnectionModel 초기화
    @StateObject private var connectionModel = ConnectionModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(connectionModel)
        }
    }
}
