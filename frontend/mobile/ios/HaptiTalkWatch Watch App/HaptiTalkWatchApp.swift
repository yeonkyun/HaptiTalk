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
    #if os(watchOS)
    @StateObject private var appState = AppState()
    #endif
    
    var body: some Scene {
        #if os(watchOS)
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
        #else
        WindowGroup {
            EmptyView()
        }
        #endif
    }
}
