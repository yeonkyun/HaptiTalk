//
//  MainScreenView.swift
//  HaptiTalkWatch Watch App
//
//  Created on 5/13/25.
//

import SwiftUI

struct MainScreenView: View {
    @EnvironmentObject var appState: AppState
    @State private var showSessionModeSelection = false
    @State private var showConnectionStatus = false
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // 앱 아이콘 및 상태
                VStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(UIColor(red: 0.25, green: 0.32, blue: 0.71, alpha: 1.0))) // #3F51B5
                            .frame(width: 40, height: 40)
                        
                        Text("H")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Text("준비됨")
                        .font(.system(size: 10))
                        .foregroundColor(Color(UIColor(red: 0.47, green: 0.53, blue: 0.8, alpha: 1.0))) // #7986CB
                }
                
                // 연결 상태
                if appState.isConnected {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(UIColor(red: 0.3, green: 0.69, blue: 0.31, alpha: 1.0))) // #4CAF50
                            .frame(width: 6, height: 6)
                        
                        Text(appState.connectedDevice)
                            .font(.system(size: 11))
                            .foregroundColor(Color(UIColor(red: 0.3, green: 0.69, blue: 0.31, alpha: 1.0))) // #4CAF50
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 10)
                } else {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 6, height: 6)
                        
                        Text("연결 안됨")
                            .font(.system(size: 11))
                            .foregroundColor(.red)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 10)
                }
                
                Spacer()
                
                // 버튼 섹션
                VStack(spacing: 15) {
                    Button(action: {
                        // 세션 시작 액션 - 임시로 연결 상태 화면으로 이동
                        showConnectionStatus = true
                    }) {
                        Text("세션 시작")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color(UIColor(red: 0.25, green: 0.32, blue: 0.71, alpha: 1.0))) // #3F51B5
                            )
                    }
                    
                    if !appState.recentSessions.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("세션 모드")
                                .font(.system(size: 11))
                                .foregroundColor(Color(UIColor(red: 0.62, green: 0.62, blue: 0.62, alpha: 1.0))) // #9E9E9E
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Button(action: {
                                // 세션 모드 선택 화면 열기
                                showSessionModeSelection = true
                            }) {
                                Text(appState.recentSessions.first?.name ?? "소개팅 모드")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 9)
                                    .background(
                                        RoundedRectangle(cornerRadius: 15)
                                            .fill(Color(UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1.0))) // #212121
                                    )
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .sheet(isPresented: $showSessionModeSelection) {
            SessionModeSelectionView()
        }
        .sheet(isPresented: $showConnectionStatus) {
            ConnectionStatusView()
        }
    }
}

struct MainScreenView_Previews: PreviewProvider {
    static var previews: some View {
        MainScreenView()
            .environmentObject(AppState())
    }
} 