import SwiftUI
import WatchKit

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var appState: AppState
    
    // 설정 상태들
    @State private var hapticIntensity: Double = 0.7  // 0.0 ~ 1.0 사이의 값 (3~5 사이를 표현)
    @State private var hapticCount: Int = 2          // 햅틱 피드백 횟수 (1~5회)
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
        case none = "없음"
        case icon = "아이콘"
        case full = "전체"
    }
    
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
                        settingCard {
                            VStack(spacing: 10) {
                                HStack {
                                    Text("햅틱 강도")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.white)
                                    Spacer()
                                }
                                
                                HStack {
                                    Text("3")
                                        .font(.system(size: 13))
                                        .foregroundColor(.gray)
                                    
                                    // 슬라이더 컴포넌트
                                    let sliderWidth = screenWidth * 0.6
                                    
                                    ZStack(alignment: .leading) {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.5))
                                            .frame(height: 5)
                                            .cornerRadius(2.5)
                                        
                                        Rectangle()
                                            .fill(Color.blue)
                                            .frame(width: sliderWidth * hapticIntensity, height: 5)
                                            .cornerRadius(2.5)
                                        
                                        Circle()
                                            .fill(Color.blue)
                                            .frame(width: 18, height: 18)
                                            .offset(x: sliderWidth * hapticIntensity - 9)
                                    }
                                    .frame(width: sliderWidth, height: 18)
                                    .gesture(
                                        DragGesture(minimumDistance: 0)
                                            .onChanged { value in
                                                let xPos = min(max(0, value.location.x), sliderWidth)
                                                hapticIntensity = xPos / sliderWidth
                                            }
                                    )
                                    
                                    Text("5")
                                        .font(.system(size: 13))
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        
                        // 햅틱 횟수 설정
                        settingCard {
                            VStack(spacing: 10) {
                                HStack {
                                    Text("햅틱 횟수")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.white)
                                    Spacer()
                                }
                                
                                HStack {
                                    ForEach(1...5, id: \.self) { count in
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
                                        
                                        if count < 5 {
                                            Spacer()
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        
                        // 알림 표시 방식
                        settingCard {
                            VStack(spacing: 10) {
                                HStack {
                                    Text("알림 표시 방식")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.white)
                                    Spacer()
                                }
                                
                                HStack(spacing: 6) {
                                    ForEach(NotificationStyle.allCases, id: \.self) { style in
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
                        
                        // 워치페이스 컴플리케이션
                        settingCard {
                            HStack {
                                Text("워치페이스 컴플리케이션")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                                Toggle("", isOn: $isWatchfaceComplicationEnabled)
                                    .labelsHidden()
                                    .toggleStyle(SwitchToggleStyle(tint: Color.blue))
                                    .scaleEffect(0.8)
                            }
                        }
                        
                        // 배터리 절약 모드
                        settingCard {
                            HStack {
                                Text("배터리 절약 모드")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                                Toggle("", isOn: $isBatterySavingEnabled)
                                    .labelsHidden()
                                    .toggleStyle(SwitchToggleStyle(tint: Color.blue))
                                    .scaleEffect(0.8)
                            }
                        }
                        
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
            // 가로 스크롤 제스처 비활성화
            .contentShape(Rectangle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 5, coordinateSpace: .global)
                    .onChanged { value in
                        // 수직 방향 제스처만 허용, 수평 제스처는 무시
                        let horizontalAmount = abs(value.translation.width)
                        let verticalAmount = abs(value.translation.height)
                        
                        if horizontalAmount > verticalAmount {
                            // 수평 제스처 무시
                        }
                        // 수직 제스처는 기본 스크롤 동작에 위임
                    }
            )
        }
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
        hapticCount = appState.hapticCount
        
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
        appState.hapticCount = hapticCount
        appState.notificationStyle = notificationStyle.rawValue
        appState.isWatchfaceComplicationEnabled = isWatchfaceComplicationEnabled
        appState.isBatterySavingEnabled = isBatterySavingEnabled
    }
    
    private func displayHapticFeedbackMessage() {
        // 햅틱 강도 및 횟수에 따른 메시지 설정
        var intensityText = ""
        if hapticIntensity < 0.3 {
            intensityText = "약한 강도 (3)"
        } else if hapticIntensity < 0.6 {
            intensityText = "중간 강도 (4)"
        } else if hapticIntensity < 0.9 {
            intensityText = "강한 강도 (4.5)"
        } else {
            intensityText = "최대 강도 (5)"
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

#Preview {
    SettingsView()
        .environmentObject(AppState())
} 