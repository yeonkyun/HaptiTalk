//
//  HaptiTalkWatchApp.swift
//  HaptiTalkWatch Watch App
//
//  Created by 이은범 on 5/13/25.
//

import SwiftUI

@available(watchOS 7.0, *)
@main
struct HaptiTalkWatch_Watch_AppApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}
