//
//  ContentView.swift
//  HaptiTalkWatch Watch App
//
//  Created by 이은범 on 5/13/25.
//

import SwiftUI
import WatchConnectivity

struct ContentView: View {
    @EnvironmentObject var connectionModel: ConnectionModel
    @State private var recentSession: RecentSession?
    
    var body: some View {
        ZStack {
            SessionAssets.Colors.background.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 15) {
                // 앱 아이콘 및 연결 상태
                VStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(SessionAssets.Colors.primary)
                            .frame(width: 40, height: 40)
                        
                        Text("H")
                            .font(SessionAssets.TextStyles.title)
                            .foregroundColor(SessionAssets.Colors.text)
                    }
                    
                    Text("준비됨")
                        .font(SessionAssets.TextStyles.xsmall)
                        .foregroundColor(SessionAssets.Colors.secondary)
                }
                
                // 연결된 기기 표시
                HStack {
                    Circle()
                        .fill(connectionModel.isConnected ? SessionAssets.Colors.success : Color.red)
                        .frame(width: 6, height: 6)
                    
                    Text(connectionModel.connectedDeviceName)
                        .font(SessionAssets.TextStyles.xsmall)
                        .foregroundColor(connectionModel.isConnected ? SessionAssets.Colors.success : Color.red)
                }
                .padding(.top, 5)
                
                Spacer()
                    .frame(height: 10)
                
                // 버튼 영역
                VStack(spacing: 15) {
                    // 세션 시작 버튼
                    Button(action: {
                        WatchSessionService.shared.startSession(mode: .dating)
                    }) {
                        Text("세션 시작")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(SessionAssets.Colors.text)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: SessionAssets.Dimensions.cornerRadius)
                                    .fill(SessionAssets.Colors.primary)
                            )
                    }
                    
                    // 최근 세션 영역
                    VStack(alignment: .leading, spacing: 8) {
                        Text("최근 세션")
                            .font(SessionAssets.TextStyles.xsmall)
                            .foregroundColor(SessionAssets.Colors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        if let session = recentSession {
                            Button(action: {
                                WatchSessionService.shared.startSession(mode: .dating)
                            }) {
                                Text(session.title)
                                    .font(SessionAssets.TextStyles.xsmall)
                                    .foregroundColor(SessionAssets.Colors.text)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 9)
                                    .background(
                                        RoundedRectangle(cornerRadius: 15)
                                            .fill(SessionAssets.Colors.dark)
                                    )
                            }
                        } else {
                            Text("최근 세션이 없습니다")
                                .font(SessionAssets.TextStyles.xsmall)
                                .foregroundColor(SessionAssets.Colors.textSecondary)
                        }
                    }
                }
            }
            .padding(SessionAssets.Dimensions.standardPadding)
            .onAppear {
                // 최근 세션 정보 로드
                recentSession = WatchSessionService.shared.getRecentSession()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ConnectionModel())
}
