//
//  MainScreenView.swift
//  HaptiTalkWatch Watch App
//
//  Created on 5/13/25.
//

#if os(watchOS)
import SwiftUI

@available(watchOS 6.0, *)
struct MainScreenView: View {
    @EnvironmentObject var appState: AppState
    @State private var showSessionModeSelection = false
    @State private var showConnectionStatus = false
    @State private var showSessionProgress = false
    @State private var showSettings = false
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                
                // 앱 아이콘 및 상태 - 화면 중앙에 배치
                VStack(spacing: 12) {
                    // 아이콘 - 사용자가 제공한 PNG 이미지 사용
                    // Assets.xcassets에 'AppIconUI' 이름으로 추가해야 함
                    Image("AppIconUI")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
                    
                    // 연결 상태
                    if appState.isConnected {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color(.sRGB, red: 0.3, green: 0.69, blue: 0.31, opacity: 1.0)) // #4CAF50
                                .frame(width: 6, height: 6)
                            
                            Text(appState.connectedDevice)
                                .font(.system(size: 11))
                                .foregroundColor(Color(.sRGB, red: 0.3, green: 0.69, blue: 0.31, opacity: 1.0)) // #4CAF50
                                .lineLimit(1)
                        }
                    } else {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 6, height: 6)
                            
                            Text("연결 안됨")
                                .font(.system(size: 11))
                                .foregroundColor(.red)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                
                Spacer()
                
                // 세션 시작 버튼 제거됨
                Spacer().frame(height: 20)
                
                // 설정 버튼 - 세션 모드 자리에 배치
                Button(action: {
                    showSettings = true
                }) {
                    HStack {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                        Text("설정")
                            .font(.system(size: 11))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color(.sRGB, red: 0.13, green: 0.13, blue: 0.13, opacity: 1.0)) // #212121
                    )
                }
                .padding(.bottom, 5)
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .sheet(isPresented: $showSessionModeSelection) {
            SessionModeSelectionView(onModeSelected: { mode in
                showSessionProgress = true
            })
        }
        .sheet(isPresented: $showConnectionStatus) {
            ConnectionStatusView()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .fullScreenCover(isPresented: $showSessionProgress) {
            SessionProgressView()
        }
        // 🚀 iPhone에서 세션 시작 메시지를 받으면 자동으로 세션 화면으로 전환
        .onChange(of: appState.shouldNavigateToSession) { shouldNavigate in
            if shouldNavigate {
                print("🚀 Watch: 자동 세션 화면 전환 시작")
                showSessionProgress = true
                // 플래그 리셋 (한 번만 실행되도록)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    appState.shouldNavigateToSession = false
                    print("🔄 Watch: 자동 전환 플래그 리셋 완료")
                }
            }
        }
    }
}

struct MainScreenView_Previews: PreviewProvider {
    static var previews: some View {
        MainScreenView()
            .environmentObject(AppState())
    }
}
#endif 
