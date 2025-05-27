//
//  ContentView.swift
//  HaptiTalkWatch Watch App
//
//  Created by 이은범 on 5/13/25.
//

import SwiftUI

@available(watchOS 6.0, *)
struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            MainScreenView()
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 5, coordinateSpace: .global)
                .onChanged { value in
                    let horizontalAmount = abs(value.translation.width)
                    let verticalAmount = abs(value.translation.height)
                    
                    if horizontalAmount > verticalAmount {
                        // 수평 제스처 무시
                    }
                    // 수직 제스처는 기본 동작 허용
                }
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppState())
    }
}
