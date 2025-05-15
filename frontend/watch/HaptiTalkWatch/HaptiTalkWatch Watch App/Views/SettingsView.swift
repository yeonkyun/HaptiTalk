import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var appState: AppState
    @State private var currentTime: String = ""
    
    // 설정 상태들
    @State private var hapticIntensity: Double = 0.7  // 0.0 ~ 1.0 사이의 값 (3~5 사이를 표현)
    @State private var notificationStyle: NotificationStyle = .full
    @State private var isWatchfaceComplicationEnabled: Bool = true
    @State private var isBatterySavingEnabled: Bool = false
    
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    enum NotificationStyle: String, CaseIterable {
        case none = "없음"
        case icon = "아이콘"
        case full = "전체"
    }
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // 상단 시간 표시
                HStack {
                    Spacer()
                    Text(currentTime)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 8)
                        .padding(.trailing, 15)
                }
                
                // 헤더
                Text("설정")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.top, 15)
                
                ScrollView {
                    VStack(spacing: 10) {
                        // 햅틱 강도 설정
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 53)
                            
                            VStack(spacing: 8) {
                                HStack {
                                    Text("햅틱 강도")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.white)
                                    Spacer()
                                }
                                
                                HStack {
                                    Text("3")
                                        .font(.system(size: 10))
                                        .foregroundColor(Color(UIColor.lightGray))
                                    
                                    ZStack(alignment: .leading) {
                                        Rectangle()
                                            .fill(Color(UIColor(red: 0.26, green: 0.26, blue: 0.26, alpha: 1.0))) // #424242
                                            .frame(height: 3)
                                            .cornerRadius(1.5)
                                        
                                        Rectangle()
                                            .fill(Color(UIColor(red: 0.25, green: 0.32, blue: 0.71, alpha: 1.0))) // #3F51B5
                                            .frame(width: 104 * hapticIntensity, height: 3)
                                            .cornerRadius(1.5)
                                        
                                        Circle()
                                            .fill(Color(UIColor(red: 0.25, green: 0.32, blue: 0.71, alpha: 1.0))) // #3F51B5
                                            .frame(width: 10, height: 10)
                                            .offset(x: 104 * hapticIntensity - 5)
                                    }
                                    .frame(width: 104, height: 10)
                                    .gesture(
                                        DragGesture(minimumDistance: 0)
                                            .onChanged { value in
                                                let width: CGFloat = 104
                                                let xPos = min(max(0, value.location.x), width)
                                                hapticIntensity = xPos / width
                                            }
                                    )
                                    
                                    Text("5")
                                        .font(.system(size: 10))
                                        .foregroundColor(Color(UIColor.lightGray))
                                }
                            }
                            .padding(.horizontal, 10)
                        }
                        
                        // 알림 표시 방식
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 67)
                            
                            VStack(spacing: 8) {
                                HStack {
                                    Text("알림 표시 방식")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.white)
                                    Spacer()
                                }
                                
                                HStack(spacing: 0) {
                                    ForEach(NotificationStyle.allCases, id: \.self) { style in
                                        Button(action: {
                                            notificationStyle = style
                                        }) {
                                            Text(style.rawValue)
                                                .font(.system(size: 10))
                                                .foregroundColor(notificationStyle == style ? .white : Color(UIColor.lightGray))
                                                .frame(width: 49.33, height: 25)
                                                .background(
                                                    notificationStyle == style ?
                                                    Color(UIColor(red: 0.25, green: 0.32, blue: 0.71, alpha: 1.0)) : // #3F51B5
                                                    Color.clear
                                                )
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 0)
                                                        .stroke(notificationStyle == style ? 
                                                                Color(UIColor(red: 0.25, green: 0.32, blue: 0.71, alpha: 1.0)) : // #3F51B5
                                                                Color(UIColor(red: 0.26, green: 0.26, blue: 0.26, alpha: 1.0)), // #424242
                                                                lineWidth: 1)
                                                )
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 10)
                        }
                        
                        // 워치페이스 컴플리케이션
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 58)
                            
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("워치페이스 컴플리케이")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    Text("션")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: $isWatchfaceComplicationEnabled)
                                    .labelsHidden()
                                    .toggleStyle(SwitchToggleStyle(tint: Color(UIColor(red: 0.25, green: 0.32, blue: 0.71, alpha: 1.0)))) // #3F51B5
                            }
                            .padding(.horizontal, 10)
                        }
                        
                        // 배터리 절약 모드
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 42)
                            
                            HStack {
                                Text("배터리 절약 모드")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Toggle("", isOn: $isBatterySavingEnabled)
                                    .labelsHidden()
                                    .toggleStyle(SwitchToggleStyle(tint: Color(UIColor(red: 0.25, green: 0.32, blue: 0.71, alpha: 1.0)))) // #3F51B5
                            }
                            .padding(.horizontal, 10)
                        }
                    }
                    .padding(.top, 10)
                    .padding(.horizontal, 10)
                }
                
                Spacer()
                
                // 저장 버튼
                Button(action: {
                    // 설정 저장
                    saveSettings()
                    
                    // 화면 닫기
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("저장")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.15))
                        )
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 10)
        }
        .onAppear {
            // 앱 스테이트에서 현재 설정값 로드
            loadCurrentSettings()
            updateCurrentTime()
        }
        .onReceive(timer) { _ in
            updateCurrentTime()
        }
    }
    
    private func updateCurrentTime() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        currentTime = formatter.string(from: Date())
    }
    
    private func loadCurrentSettings() {
        // AppState에서 설정 값을 로드
        hapticIntensity = appState.hapticIntensity
        
        switch appState.notificationStyle {
        case "없음":
            notificationStyle = .none
        case "아이콘":
            notificationStyle = .icon
        case "전체":
            notificationStyle = .full
        default:
            notificationStyle = .full
        }
        
        isWatchfaceComplicationEnabled = appState.isWatchfaceComplicationEnabled
        isBatterySavingEnabled = appState.isBatterySavingEnabled
    }
    
    private func saveSettings() {
        // AppState에 설정 값을 저장
        appState.hapticIntensity = hapticIntensity
        appState.notificationStyle = notificationStyle.rawValue
        appState.isWatchfaceComplicationEnabled = isWatchfaceComplicationEnabled
        appState.isBatterySavingEnabled = isBatterySavingEnabled
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
} 