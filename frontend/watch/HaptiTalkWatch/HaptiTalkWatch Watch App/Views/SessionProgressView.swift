//
//  SessionProgressView.swift
//  HaptiTalkWatch Watch App
//
//  Created on 5/15/25.
//

import SwiftUI
import WatchKit

struct SessionProgressView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var appState: AppState
    @State private var sessionTimer: TimeInterval = 0
    @State private var sessionMode: String = "소개팅"
    @State private var formattedTime: String = "00:00:00"
    @State private var emotionState: String = "긍정적"
    @State private var emotionColor: Color = Color.green
    @State private var speakingSpeed: Double = 0.75 // 0.0 ~ 1.0
    @State private var feedbackMessage: String = "말하기 속도가 빨라지고 있어요. 좀 더 천천히 말해보세요."
    @State private var showFeedback: Bool = true
    @State private var showHapticNotification: Bool = false
    @State private var hapticNotificationMessage: String = ""
    @State private var currentTime: String = ""
    @State private var showSessionSummary: Bool = false
    @State private var likeabilityPercent: String = "88%"
    @State private var coreFeedback: String = "여행 주제에서 높은 호감도를 보였으며, 경청하는 자세가 매우 효과적이었습니다."
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var recommendedTopics = ["여행 경험", "취미 활동", "좋아하는 음식"]
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // 상단 시간 및 모드 표시
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(UIColor(red: 0.91, green: 0.12, blue: 0.39, alpha: 1.0))) // #E91E63
                            .frame(width: 55, height: 21.5)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .resizable()
                                .frame(width: 10, height: 10)
                                .foregroundColor(.white)
                            
                            Text(sessionMode)
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    
                    Spacer()
                    
                    Text(formattedTime)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color(UIColor(red: 0.88, green: 0.88, blue: 0.88, alpha: 1.0))) // #E0E0E0
                }
                .padding(.top, 5)
                
                // 감정 상태 및 말하기 속도 표시
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 67)
                    
                    VStack(spacing: 8) {
                        // 감정 상태
                        HStack {
                            Text("감정 상태")
                                .font(.system(size: 10))
                                .foregroundColor(Color(UIColor(red: 0.88, green: 0.88, blue: 0.88, alpha: 1.0))) // #E0E0E0
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Image(systemName: "face.smiling.fill")
                                    .resizable()
                                    .frame(width: 12, height: 12)
                                    .foregroundColor(emotionColor)
                                
                                Text(emotionState)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(emotionColor)
                            }
                        }
                        
                        // 말하기 속도
                        VStack(spacing: 4) {
                            Text("말하기 속도")
                                .font(.system(size: 10))
                                .foregroundColor(Color(UIColor(red: 0.88, green: 0.88, blue: 0.88, alpha: 1.0))) // #E0E0E0
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(height: 4)
                                    .cornerRadius(2)
                                
                                Rectangle()
                                    .fill(Color(UIColor(red: 0.25, green: 0.32, blue: 0.71, alpha: 1.0))) // #3F51B5
                                    .frame(width: WKInterfaceDevice.current().screenBounds.width * 0.75 * speakingSpeed, height: 4)
                                    .cornerRadius(2)
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                }
                .padding(.top, 10)
                
                // 피드백 메시지
                if showFeedback {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor(red: 0.25, green: 0.32, blue: 0.71, alpha: 0.15))) // #3F51B5 with opacity
                            .frame(height: 44)
                        
                        Text(feedbackMessage)
                            .font(.system(size: 10))
                            .foregroundColor(Color(UIColor(red: 0.56, green: 0.79, blue: 0.98, alpha: 1.0))) // #90CAF9
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                    }
                    .padding(.top, 10)
                }
                
                // 추천 대화 주제
                VStack(alignment: .leading, spacing: 4) {
                    Text("추천 대화 주제")
                        .font(.system(size: 10))
                        .foregroundColor(Color(UIColor(red: 0.62, green: 0.62, blue: 0.62, alpha: 1.0))) // #9E9E9E
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(recommendedTopics, id: \.self) { topic in
                                Text(topic)
                                    .font(.system(size: 9))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(UIColor(red: 0.3, green: 0.69, blue: 0.31, alpha: 0.3))) // #4CAF50 with opacity
                                            .stroke(Color(UIColor(red: 0.3, green: 0.69, blue: 0.31, alpha: 1.0)), lineWidth: 1)
                                    )
                            }
                        }
                    }
                }
                .padding(.top, 10)
                
                Spacer()
                
                // 테스트 햅틱 피드백 버튼 (데모용)
                Button(action: {
                    showHapticNotification(message: "상대방의 호감도가 상\n승했습니다.\n현재 대화 주제를 이어\n가세요.")
                }) {
                    Text("햅틱 피드백 테스트")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.indigo)
                        )
                }
                .padding(.bottom, 10)
                
                // 종료 버튼
                Button(action: {
                    // 세션 요약 저장
                    saveSessionSummary()
                    
                    // 세션 종료 및 세션 요약 화면으로 이동
                    showSessionSummary = true
                }) {
                    Text("세션 종료")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(UIColor(red: 0.96, green: 0.26, blue: 0.21, alpha: 1.0))) // #F44336
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            
            // 햅틱 피드백 알림 오버레이
            if showHapticNotification {
                HapticFeedbackNotificationView(
                    sessionType: sessionMode,
                    elapsedTime: formattedTime,
                    message: hapticNotificationMessage,
                    currentTime: getCurrentTimeString()
                )
                .onDisappear {
                    showHapticNotification = false
                }
            }
        }
        .fullScreenCover(isPresented: $showSessionSummary) {
            SessionSummaryView(
                sessionMode: sessionMode + " 모드",
                totalTime: formattedTime,
                mainEmotion: emotionState,
                likeabilityPercent: likeabilityPercent,
                coreFeedback: coreFeedback
            )
        }
        .onReceive(timer) { _ in
            updateTimer()
            updateCurrentTime()
        }
        .onChange(of: appState.showHapticFeedback) { newValue in
            if newValue {
                showHapticNotification(message: appState.hapticFeedbackMessage)
                appState.showHapticFeedback = false
            }
        }
    }
    
    private func updateTimer() {
        sessionTimer += 1
        
        let hours = Int(sessionTimer) / 3600
        let minutes = (Int(sessionTimer) % 3600) / 60
        let seconds = Int(sessionTimer) % 60
        
        formattedTime = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    private func updateCurrentTime() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        currentTime = formatter.string(from: Date())
    }
    
    private func getCurrentTimeString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
    }
    
    private func showHapticNotification(message: String) {
        hapticNotificationMessage = message
        showHapticNotification = true
        
        // 5초 후 자동으로 닫기
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.showHapticNotification = false
        }
    }
    
    private func saveSessionSummary() {
        // 세션 요약 정보 생성
        let summary = SessionSummary(
            id: UUID(),
            sessionMode: sessionMode + " 모드",
            totalTime: formattedTime,
            mainEmotion: emotionState,
            likeabilityPercent: likeabilityPercent,
            coreFeedback: coreFeedback,
            date: Date()
        )
        
        // AppState에 세션 요약 저장
        appState.saveSessionSummary(summary: summary)
    }
}

struct SessionProgressView_Previews: PreviewProvider {
    static var previews: some View {
        SessionProgressView()
            .environmentObject(AppState())
    }
} 