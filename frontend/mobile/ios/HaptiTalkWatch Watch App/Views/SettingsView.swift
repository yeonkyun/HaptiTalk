import SwiftUI
import WatchKit

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var appState: AppState
    
    // 설정 상태들
    @State private var hapticIntensity: String = "기본"  // "약하게", "기본", "강하게" 옵션으로 변경
    @State private var hapticCount: Int = 2          // 햅틱 피드백 횟수 (1~4회)
    @State private var notificationStyle: NotificationStyle = .full
    @State private var isWatchfaceComplicationEnabled: Bool = true
    @State private var isBatterySavingEnabled: Bool = false
    
    // 햅틱 테스트 관련 상태
    @State private var isTestingHaptic: Bool = false
    @State private var hapticFeedbackMessage: String = ""
    @State private var showHapticFeedbackMessage: Bool = false
    
    // 화면 너비 계산
    private let screenWidth = WKInterfaceDevice.current().screenBounds.width
    
    enum NotificationStyle: String, CaseIterable {
        case icon = "아이콘"
        case full = "전체"
    }
    
    // 햅틱 강도 옵션
    let hapticIntensityOptions = ["기본", "강하게"]
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 16) {
                    // 제목
                    Text("설정")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 8)
                    
                    VStack(spacing: 14) {
                        // 햅틱 강도 설정
                        HapticIntensityCard(
                            hapticIntensity: $hapticIntensity,
                            options: hapticIntensityOptions
                        )
                        
                        // 햅틱 횟수 설정
                        HapticCountCard(hapticCount: $hapticCount)
                        
                        // 알림 표시 방식
                        NotificationStyleCard(
                            notificationStyle: $notificationStyle
                        )
                        
                        // 워치페이스 컴플리케이션
                        ToggleSettingCard(
                            title: "워치페이스 컴플리케이션",
                            isOn: $isWatchfaceComplicationEnabled
                        )
                        
                        // 배터리 절약 모드
                        ToggleSettingCard(
                            title: "배터리 절약 모드",
                            isOn: $isBatterySavingEnabled
                        )
                        
                        // 햅틱 피드백 테스트 버튼
                        Button(action: {
                            // 햅틱 강도 및 횟수를 AppState에 업데이트
                            appState.hapticIntensity = hapticIntensity
                            appState.hapticCount = hapticCount
                            
                            // 햅틱 피드백 테스트 실행
                            appState.testHaptic()
                            
                            // 햅틱 피드백 메시지 표시
                            displayHapticFeedbackMessage()
                        }) {
                            Text("햅틱 피드백 테스트")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.indigo)
                                )
                        }
                        
                        // 햅틱 피드백 메시지 (테스트 후 표시)
                        if showHapticFeedbackMessage {
                            Text(hapticFeedbackMessage)
                                .font(.system(size: 12))
                                .foregroundColor(Color.green)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                    }
                    
                    Spacer(minLength: 20)
                    
                    // 저장 버튼
                    Button(action: {
                        saveSettings()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("저장")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(Color.blue)
                            )
                    }
                    .padding(.bottom, 10)
                }
                .padding(.horizontal, 16)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .edgesIgnoringSafeArea(.bottom)
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .onAppear {
            // 앱 스테이트에서 현재 설정값 로드
            loadCurrentSettings()
        }
    }
    
    @ViewBuilder
    private func settingCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
            
            content()
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
        }
    }
    
    private func loadCurrentSettings() {
        // AppState에서 설정 값을 로드
        hapticIntensity = appState.hapticIntensity
        
        hapticCount = min(appState.hapticCount, 4) // 최대 4회로 제한
        
        switch appState.notificationStyle {
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
        appState.hapticCount = hapticCount
        appState.notificationStyle = notificationStyle.rawValue
        appState.isWatchfaceComplicationEnabled = isWatchfaceComplicationEnabled
        appState.isBatterySavingEnabled = isBatterySavingEnabled
    }
    
    private func displayHapticFeedbackMessage() {
        // 햅틱 강도 및 횟수에 따른 메시지 설정
        var intensityText = ""
        if hapticIntensity == "기본" {
            intensityText = "방향 햅틱 (중강도)"
        } else if hapticIntensity == "강하게" {
            intensityText = "진한 햅틱 (알림 + 방향 진동)"
        }
        
        hapticFeedbackMessage = "\(intensityText), \(hapticCount)회 햅틱 피드백이 전달되었습니다."
        
        // 메시지 표시
        showHapticFeedbackMessage = true
        
        // 3초 후 메시지 숨기기
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                showHapticFeedbackMessage = false
            }
        }
    }
}

// 햅틱 강도 설정 카드
struct HapticIntensityCard: View {
    @Binding var hapticIntensity: String
    let options: [String]
    
    var body: some View {
        SettingCardView {
            VStack(spacing: 10) {
                HStack {
                    Text("햅틱 강도")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                }
                
                HStack(spacing: 6) {
                    ForEach(options, id: \.self) { option in
                        Button(action: {
                            hapticIntensity = option
                        }) {
                            Text(option)
                                .font(.system(size: 12))
                                .foregroundColor(hapticIntensity == option ? .white : .gray)
                                .frame(maxWidth: .infinity)
                                .frame(height: 32)
                                .background(
                                    hapticIntensity == option ?
                                    Color.blue :
                                    Color.clear
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(hapticIntensity == option ?
                                                Color.blue :
                                                Color.gray,
                                                lineWidth: 1)
                                )
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
    }
}

// 햅틱 횟수 설정 카드
struct HapticCountCard: View {
    @Binding var hapticCount: Int
    
    var body: some View {
        SettingCardView {
            VStack(spacing: 10) {
                HStack {
                    Text("햅틱 횟수")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                }
                
                HStack {
                    ForEach(1...4, id: \.self) { count in
                        Button(action: {
                            hapticCount = count
                        }) {
                            Text("\(count)")
                                .font(.system(size: 14, weight: hapticCount == count ? .semibold : .regular))
                                .foregroundColor(hapticCount == count ? .white : .gray)
                                .frame(width: 32, height: 32)
                                .background(
                                    Circle()
                                        .fill(hapticCount == count ? Color.blue : Color.clear)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(hapticCount == count ? Color.blue : Color.gray, lineWidth: 1)
                                )
                        }
                        
                        if count < 4 {
                            Spacer()
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

// 알림 표시 방식 카드
struct NotificationStyleCard: View {
    @Binding var notificationStyle: SettingsView.NotificationStyle
    
    var body: some View {
        SettingCardView {
            VStack(spacing: 10) {
                HStack {
                    Text("알림 표시 방식")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                }
                
                HStack(spacing: 6) {
                    ForEach(SettingsView.NotificationStyle.allCases, id: \.self) { style in
                        Button(action: {
                            notificationStyle = style
                        }) {
                            Text(style.rawValue)
                                .font(.system(size: 12))
                                .foregroundColor(notificationStyle == style ? .white : .gray)
                                .frame(maxWidth: .infinity)
                                .frame(height: 32)
                                .background(
                                    notificationStyle == style ?
                                    Color.blue :
                                    Color.clear
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(notificationStyle == style ?
                                                Color.blue :
                                                Color.gray,
                                                lineWidth: 1)
                                )
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
    }
}

// 토글 설정 카드
struct ToggleSettingCard: View {
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        SettingCardView {
            HStack {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Toggle("", isOn: $isOn)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: Color.blue))
                    .scaleEffect(0.8)
            }
        }
    }
}

// 설정 카드 기본 뷰
struct SettingCardView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
            
            content
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
} 
