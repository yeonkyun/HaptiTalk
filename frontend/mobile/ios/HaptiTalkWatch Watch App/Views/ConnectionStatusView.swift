//
//  ConnectionStatusView.swift
//  HaptiTalkWatch Watch App
//
//  Created on 5/13/25.
//

#if os(watchOS)
import SwiftUI
import WatchKit

@available(watchOS 6.0, *)
struct ConnectionStatusView: View {
    @EnvironmentObject var appState: AppState
    @State private var showDisconnectAlert = false
    @State private var showSessionModeSelection = false
    @State private var showSessionProgress = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 25) {
                // 연결 상태 아이콘 및 텍스트
                VStack(spacing: 20) {
                    // 연결 아이콘
                    ZStack {
                        Circle()
                            .fill(Color(.sRGB, red: 0.3, green: 0.69, blue: 0.31, opacity: 0.2)) // #4CAF50 with opacity
                            .frame(width: 50, height: 50)
                        
                        Circle()
                            .fill(Color(.sRGB, red: 0.3, green: 0.69, blue: 0.31, opacity: 1.0)) // #4CAF50
                            .frame(width: 30, height: 30)
                        
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundColor(.white)
                            .font(.system(size: 16))
                    }
                    
                    // 연결 상태 텍스트
                    VStack(spacing: 4) {
                        Text("스마트폰과 연결됨")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text(appState.connectedDevice)
                            .font(.system(size: 11))
                            .foregroundColor(Color(.sRGB, red: 0.3, green: 0.69, blue: 0.31, opacity: 1.0)) // #4CAF50
                    }
                }
                
                Spacer()
                
                // 버튼 섹션
                VStack(spacing: 10) {
                    Button(action: {
                        // 세션 진행 화면으로 이동
                        showSessionProgress = true
                    }) {
                        Text("세션 시작")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color(.sRGB, red: 0.25, green: 0.32, blue: 0.71, opacity: 1.0)) // #3F51B5
                            )
                    }
                    
                    Button(action: {
                        // 햅틱 테스트 액션
                        WKInterfaceDevice.current().play(.success)
                    }) {
                        Text("햅틱 테스트")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color(.sRGB, red: 0.13, green: 0.13, blue: 0.13, opacity: 1.0)) // #212121
                            )
                    }
                    
                    Button(action: {
                        // 연결 해제 확인 알림
                        showDisconnectAlert = true
                    }) {
                        Text("연결 해제")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color(.sRGB, red: 0.13, green: 0.13, blue: 0.13, opacity: 1.0)) // #212121
                            )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .alert(isPresented: $showDisconnectAlert) {
            Alert(
                title: Text("연결 해제"),
                message: Text("정말 연결을 해제하시겠습니까?"),
                primaryButton: .destructive(Text("해제")) {
                    // 연결 해제 로직
                    appState.disconnectDevice()
                },
                secondaryButton: .cancel(Text("취소"))
            )
        }
        .fullScreenCover(isPresented: $showSessionProgress) {
            SessionProgressView()
        }
    }
}

struct ConnectionStatusView_Previews: PreviewProvider {
    static var previews: some View {
        ConnectionStatusView()
            .environmentObject(AppState())
    }
}
#endif 