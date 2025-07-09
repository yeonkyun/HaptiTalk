//
//  WatchVisualFeedbackView.swift
//  HaptiTalkWatch Watch App
//
//  Created on 5/15/25.
//

#if os(watchOS)
import SwiftUI
import WatchKit

// 🎨 자신감 상승 애니메이션 스타일 옵션 (전문적 스타일만)
enum ConfidenceAnimationStyle: String, CaseIterable {
    case levelUpBar = "성취 바"           // 기본값 - 전문적 성취감
    case chartRise = "차트 상승"          // 데이터 상승 표현
    case sparkleStars = "별 반짝임"       // 화려한 축하 효과
    case firework = "파이어워크"          // 폭발적 성취감
}

@available(watchOS 6.0, *)
struct WatchVisualFeedbackView: View {
    @EnvironmentObject var appState: AppState
    
    // 🎨 애니메이션 스타일 설정 (기본값: 성취 바 - 발표/면접 전용)
    @State private var confidenceAnimationStyle: ConfidenceAnimationStyle = .levelUpBar
    
    // 🎨 애니메이션 스타일 변경 방법:
    // ================================================================================
    // 
    // 💡 **쉬운 변경 방법:**
    // 위의 .heartGlow 부분을 다른 스타일로 바꾸면 됩니다!
    //
         // 📋 **발표/면접 전용 전문적 스타일들:**
     // 
     // 1️⃣ .levelUpBar   - 🎯 성취 바 (기본, 전문적 성취감)  
     //    → "EXCELLENT!" 텍스트와 함께 바가 채워지는 성취감 효과
     //
     // 2️⃣ .chartRise    - 📈 차트 상승 (비즈니스 스타일)
     //    → 차트 바가 올라가면서 화살표가 위로 향하는 전문적 효과
     //
     // 3️⃣ .sparkleStars - ✨ 별 반짝임 (특별한 순간 강조)
     //    → 별이 빛나면서 주변에 반짝임이 퍼지는 중요한 순간 효과
     //
     // 4️⃣ .firework     - 🎆 파이어워크 (큰 성취 달성)
     //    → 중앙에서 폭발하면서 파티클이 사방으로 퍼지는 큰 성취 효과
     //
     // 💻 **변경 예시:**
     // @State private var confidenceAnimationStyle: ConfidenceAnimationStyle = .chartRise
    //
    // ================================================================================
    
    // 🎨 애니메이션 상태 변수들
    @State private var animationOffset: CGFloat = 0
    @State private var animationScale: CGFloat = 1.0
    @State private var animationOpacity: Double = 1.0
    @State private var animationRotation: Double = 0
    @State private var animationPulse: CGFloat = 1.0
    @State private var animationWave: CGFloat = 0
    
    let screenSize = WKInterfaceDevice.current().screenBounds.size
    
    var body: some View {
        ZStack {
            // 🌟 전체화면 배경
            appState.visualPatternColor.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
                .animation(.easeInOut(duration: 0.5), value: appState.visualPatternColor)
            
            // 🎨 패턴별 시각적 효과 (화면 가득)
            buildPatternVisualEffect()
            
            // 🎨 애니메이션과 조화로운 패턴 정보 오버레이
            VStack(spacing: 8) {
                // 패턴 아이콘 (애니메이션과 조화)
                getPatternIcon()
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.6), radius: 2, x: 1, y: 1)
                    .scaleEffect(animationScale * 0.1 + 0.95) // 애니메이션과 연동
                    .animation(.easeInOut(duration: 0.8), value: animationScale)
                
                // 간결한 패턴 메시지
                if !appState.hapticFeedbackMessage.isEmpty {
                    Text(appState.hapticFeedbackMessage)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.7), radius: 1, x: 0, y: 1)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.black.opacity(0.4))
                                .blur(radius: 0.5)
                        )
                        .opacity(animationOpacity * 0.9 + 0.1) // 애니메이션과 연동
                        .animation(.easeInOut(duration: 1.0), value: animationOpacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .allowsHitTesting(false) // 터치 차단하여 애니메이션 방해 방지
        }
        .onAppear {
            print("🎨 Watch: WatchVisualFeedbackView appeared - 패턴: \(appState.currentVisualPattern)")
            startPatternAnimation()
        }
        .onDisappear {
            print("🎨 Watch: WatchVisualFeedbackView disappeared")
            resetAnimations()
            // �� AppState의 시각적 피드백 상태도 완전히 초기화
            DispatchQueue.main.async {
                appState.showVisualFeedback = false
                appState.currentVisualPattern = ""
                appState.visualAnimationIntensity = 0.0
                appState.hapticFeedbackMessage = ""
                print("🔥 Watch: onDisappear에서 모든 시각적 피드백 상태 완전 초기화")
            }
        }
        .onChange(of: appState.currentVisualPattern) { _, newPattern in
            // 패턴 변경 시 애니메이션 리셋 후 재시작으로 안정성 확보
            resetAnimations()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                startPatternAnimation()
            }
        }
    }
    
    // 🎨 패턴별 아이콘 반환 (4개 핵심 패턴만)
    @ViewBuilder
    private func getPatternIcon() -> some View {
        switch appState.currentVisualPattern {
        // ✅ 활성화된 4개 핵심 패턴 - 더 직관적인 아이콘
        case "S1": // 속도 조절
            Image(systemName: "speedometer")
        case "R1": // 자신감 상승 (하트 → 상승 화살표)
            Image(systemName: "arrow.up.circle.fill")
        case "R2": // 자신감 하락
            Image(systemName: "arrow.down.circle.fill")
        case "S2": // 음량 조절
            Image(systemName: "speaker.wave.3.fill")
            
        // 🔒 비활성화된 패턴들 (주석 처리)
        /*
        case "L1": // 경청 강화
            Image(systemName: "ear.fill")
        case "F1": // 주제 전환
            Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
        case "F2": // 침묵 관리
            Image(systemName: "speaker.slash.fill")
        case "L3": // 질문 제안
            Image(systemName: "questionmark.circle.fill")
        */
        default:
            Image(systemName: "circle.fill")
        }
    }
    
    // 🎨 패턴별 제목 반환 (세션별 동적)
    private func getPatternTitle() -> String {
        let sessionType = appState.sessionType
        
        // 📊 세션 타입별 + 패턴별 제목 매핑 테이블
        let titleMapping: [String: [String: String]] = [
            // 🎤 발표 모드 제목
            "발표": [
                "S1": "속도 조절",
                "L1": "청중 소통 강화", 
                "F1": "관심도 하락",
                "R1": "자신감 상승",
                "F2": "휴지 관리",
                "S2": "음량 조절",
                "R2": "자신감 하락",
                "L3": "설득력 강화"
            ],
            
            // 👔 면접 모드 제목  
            "면접": [
                "S1": "답변 속도 조절",
                "L1": "면접관 경청",
                "F1": "면접 관심도 하락", 
                "R1": "면접 자신감 우수",
                "F2": "면접 침묵 관리",
                "S2": "답변 음량 조절",
                "R2": "면접 자신감 하락", // 🔥 자신감 하락
                "L3": "면접 질문 제안"
            ],
            
            // 💕 소개팅 모드 제목 (사용 안함 - 발표/면접 위주로 변경)
            /*
            "소개팅": [
                "S1": "대화 속도 조절",
                "L1": "상대방 경청",
                "F1": "대화 관심도 하락",
                "R1": "호감도 상승",
                "F2": "대화 침묵 관리", 
                "S2": "대화 음량 조절",
                "R2": "호감도 부족", // 🔥 호감도 부족
                "L3": "대화 흥미도 강화"
            ]
            */
        ]
        
        // 세션 타입에 맞는 제목 찾기
        if let sessionTitles = titleMapping[sessionType],
           let specificTitle = sessionTitles[appState.currentVisualPattern] {
            return specificTitle
        }
        
        // 폴백: 4개 핵심 패턴만
        switch appState.currentVisualPattern {
        // ✅ 활성화된 4개 핵심 패턴
        case "S1": return "속도 조절"
        case "R1": return "자신감 상승"
        case "R2": return "자신감 하락"
        case "S2": return "음량 조절"
            
        // 🔒 비활성화된 패턴들 (주석 처리)
        /*
        case "L1": return "경청 강화"
        case "F1": return "주제 전환"
        case "F2": return "침묵 관리"
        case "L3": return "질문 제안"
        */
        default: return "피드백"
        }
    }
    
    // 🎨 패턴별 시각적 효과 빌더 (4개 핵심 패턴만)
    @ViewBuilder
    private func buildPatternVisualEffect() -> some View {
        switch appState.currentVisualPattern {
        // ✅ 활성화된 4개 핵심 패턴 - 개선된 애니메이션
        case "S1": // 속도 조절 - 리듬감 있는 펄스
            buildSpeedControlEffect()
            
        case "R1": // 자신감 상승 - 우아한 상승 효과
            buildConfidenceUpEffect()
            
        case "R2": // 자신감 하락 - 부드러운 하락 효과
            buildConfidenceDownEffect()
            
        case "S2": // 음량 조절 - 음파 파동 효과
            buildVolumeControlEffect()
            
        // 🔒 비활성화된 패턴들 (주석 처리)
        /*
        case "L1": // 경청 강화 - 점진적 증가 (화면 가득)
            buildListeningEffect()
            
        case "F1": // 주제 전환 - 긴 페이드 (화면 가득)
            buildTopicChangeEffect()
            
        case "F2": // 침묵 관리 - 부드러운 펄스 (화면 가득)
            buildSilenceEffect()
            
        case "L3": // 질문 제안 - 물음표 형태 (화면 가득)
            buildQuestionEffect()
        */
            
        default:
            EmptyView()
        }
    }
    
    // S1: 속도 조절 효과 - 리듬감 있는 펄스
    @ViewBuilder
    private func buildSpeedControlEffect() -> some View {
        ZStack {
            // 외부 링
            Circle()
                .stroke(Color.orange.opacity(0.4), lineWidth: 3)
                .frame(width: 140, height: 140)
                .scaleEffect(animationPulse)
                .animation(
                    Animation.easeInOut(duration: 0.8)
                        .repeatForever(autoreverses: true),
                    value: animationPulse
                )
            
            // 중간 펄스 링들
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.orange.opacity(0.3 - Double(index) * 0.08))
                    .frame(
                        width: 80 + CGFloat(index) * 25, 
                        height: 80 + CGFloat(index) * 25
                    )
                    .scaleEffect(0.8 + (animationScale + CGFloat(index) * 0.1) * 0.4)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.1),
                        value: animationScale
                    )
            }
            
            // 중심 속도계 시각 요소 (애니메이션과 조화)
            ZStack {
                // 속도계 배경
                Circle()
                    .stroke(Color.orange.opacity(0.6), lineWidth: 3)
                    .frame(width: 20, height: 20)
                    .scaleEffect(animationPulse * 0.3 + 0.9)
                
                // 내부 펄스
                Circle()
                    .fill(Color.orange)
                    .frame(width: 8, height: 8)
                    .scaleEffect(animationScale * 0.4 + 0.8)
                    .opacity(0.9)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // L1: 경청 강화 효과 (점진적 증가) - 🔧 position 제거
    @ViewBuilder
    private func buildListeningEffect() -> some View {
        ZStack {
            Circle()
                .stroke(appState.visualPatternColor, lineWidth: 6 + animationScale * 10)
                .frame(
                    width: 80 + animationScale * 120, 
                    height: 80 + animationScale * 120
                )
                .opacity(1.0 - animationScale * 0.3)
                .animation(
                    Animation.easeInOut(duration: 2.0)
                        .repeatForever(autoreverses: false),
                    value: animationScale
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // F1: 주제 전환 효과 (긴 페이드) - 🔧 position 제거
    @ViewBuilder
    private func buildTopicChangeEffect() -> some View {
        ZStack {
            VStack(spacing: 10) {
                ForEach(0..<3) { index in
                    RoundedRectangle(cornerRadius: 20)
                        .fill(appState.visualPatternColor.opacity(animationOpacity * 0.7))
                        .frame(width: screenSize.width * 0.9, height: 30)
                        .animation(
                            Animation.easeInOut(duration: 0.8)
                                .repeatCount(2, autoreverses: true)
                                .delay(Double(index) * 0.2),
                            value: animationOpacity
                        )
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // R1: 자신감 상승 효과 - 우아한 상승 애니메이션
    @ViewBuilder
    private func buildConfidenceUpEffect() -> some View {
        ZStack {
            // 배경 원형 파동
            ForEach(0..<3) { index in
                Circle()
                    .stroke(Color.green.opacity(0.3), lineWidth: 2)
                    .frame(width: 80 + CGFloat(index) * 40, height: 80 + CGFloat(index) * 40)
                    .scaleEffect(animationPulse + CGFloat(index) * 0.2)
                    .opacity(1.0 - CGFloat(index) * 0.3)
                    .animation(
                        Animation.easeOut(duration: 1.5)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 0.3),
                        value: animationPulse
                    )
            }
            
            // 상승하는 화살표 파티클들
            ForEach(0..<6) { index in
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.green)
                    .offset(
                        x: cos(Double(index) * .pi / 3) * 35,
                        y: sin(Double(index) * .pi / 3) * 35 + animationOffset
                    )
                    .opacity(animationOpacity * (1.0 - Double(index) * 0.1))
                    .animation(
                        Animation.easeOut(duration: 2.0)
                            .repeatCount(2, autoreverses: false)
                            .delay(Double(index) * 0.1),
                        value: animationOffset
                    )
            }
            
            // 중앙 상승 시각 요소 (애니메이션과 조화)
            ZStack {
                // 상승 링
                Circle()
                    .stroke(Color.green.opacity(0.7), lineWidth: 2)
                    .frame(width: 25, height: 25)
                    .scaleEffect(animationScale)
                    .animation(
                        Animation.easeInOut(duration: 0.8)
                            .repeatCount(3, autoreverses: true),
                        value: animationScale
                    )
                
                // 상승 화살표 시각화
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.green)
                    .frame(width: 3, height: 12)
                    .offset(y: -2)
                    .scaleEffect(animationPulse * 0.2 + 0.9)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // R2: 자신감 하락 효과 - 부드러운 하락 애니메이션
    @ViewBuilder
    private func buildConfidenceDownEffect() -> some View {
        ZStack {
            // 경고 배경 펄스
            Circle()
                .fill(Color.red.opacity(0.2))
                .frame(width: 120, height: 120)
                .scaleEffect(animationPulse)
                .animation(
                    Animation.easeInOut(duration: 1.0)
                        .repeatForever(autoreverses: true),
                    value: animationPulse
                )
            
            // 하락하는 화살표 파티클들
            ForEach(0..<4) { index in
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.red)
                    .offset(
                        x: cos(Double(index) * .pi / 2) * 30,
                        y: sin(Double(index) * .pi / 2) * 30 + animationOffset
                    )
                    .opacity(animationOpacity * 0.7)
                    .animation(
                        Animation.easeIn(duration: 1.5)
                            .repeatCount(2, autoreverses: false)
                            .delay(Double(index) * 0.2),
                        value: animationOffset
                    )
            }
            
            // 중앙 경고 시각 요소 (애니메이션과 조화)
            ZStack {
                // 경고 삼각형 배경
                Triangle()
                    .stroke(Color.red.opacity(0.8), lineWidth: 2)
                    .frame(width: 20, height: 20)
                    .scaleEffect(animationScale)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatCount(3, autoreverses: true),
                        value: animationScale
                    )
                
                // 하락 표시
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.red)
                    .frame(width: 3, height: 10)
                    .offset(y: 2)
                    .scaleEffect(animationPulse * 0.3 + 0.8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // 🎨 옵션 1: 성취 바 효과 (기본)
    @ViewBuilder
    private func buildLevelUpBarEffect() -> some View {
        ZStack {
            VStack(spacing: 8) {
                // "EXCELLENT!" 텍스트 (발표/면접에 더 적합)
                Text("EXCELLENT!")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.yellow)
                    .opacity(animationOpacity)
                    .scaleEffect(animationScale)
                    .animation(
                        Animation.easeOut(duration: 0.6)
                            .repeatCount(3, autoreverses: true),
                        value: animationScale
                    )
                
                // 레벨업 바
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: screenSize.width * 0.8, height: 20)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [.yellow, .orange, .red]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: screenSize.width * 0.8 * animationWave, height: 20)
                        .animation(
                            Animation.easeOut(duration: 2.5)
                                .repeatCount(1, autoreverses: false),
                            value: animationWave
                        )
                }
                
                // 자신감 상승 표시
                Text("자신감 ↗")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.green)
                    .offset(y: animationOffset)
                    .opacity(animationOpacity)
                    .animation(
                        Animation.easeOut(duration: 1.5),
                        value: animationOffset
                    )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // 🎨 옵션 2: 별 반짝임 효과 (컴파일 최적화를 위해 서브뷰로 분리)
    @ViewBuilder
    private func buildSparkleStarsEffect() -> some View {
        ZStack {
            // 중앙 별
            centralStarView
            
            // 주변 작은 별들
            surroundingStarsView
            
            // 반짝임 효과
            sparkleParticlesView
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // 🎨 중앙 별 뷰 (분리)
    @ViewBuilder
    private var centralStarView: some View {
        Image(systemName: "star.fill")
            .font(.system(size: 40, weight: .bold))
            .foregroundColor(.yellow)
            .scaleEffect(animationScale)
            .rotationEffect(.degrees(animationRotation))
            .animation(
                Animation.easeInOut(duration: 1.0)
                    .repeatCount(3, autoreverses: true),
                value: animationScale
            )
    }
    
    // 🎨 주변 별들 뷰 (분리 - 단순화)
    @ViewBuilder
    private var surroundingStarsView: some View {
        ForEach(0..<8) { index in
            singleStarView(for: index)
        }
    }
    
    // 🎨 개별 별 뷰 (더 단순화)
    @ViewBuilder
    private func singleStarView(for index: Int) -> some View {
        let starSize = 8 + index % 3 * 4
        let starColor = index % 2 == 0 ? Color.yellow : Color.white
        let angle = Double(index) * .pi / 4
        let radius = 50 + animationPulse * 30
        
        Image(systemName: "star.fill")
            .font(.system(size: CGFloat(starSize), weight: .medium))
            .foregroundColor(starColor)
            .offset(
                x: cos(angle) * radius,
                y: sin(angle) * radius
            )
            .opacity(animationOpacity)
            .animation(
                Animation.easeInOut(duration: 0.8)
                    .repeatForever(autoreverses: true)
                    .delay(Double(index) * 0.1),
                value: animationPulse
            )
    }
    
    // 🎨 반짝임 파티클 뷰 (분리 - 단순화)
    @ViewBuilder
    private var sparkleParticlesView: some View {
        ForEach(0..<12) { index in
            sparkleParticle(for: index)
        }
    }
    
    // 🎨 개별 반짝임 파티클 (더 단순화)
    @ViewBuilder
    private func sparkleParticle(for index: Int) -> some View {
        let positions: [(CGFloat, CGFloat)] = [
            (-60, -40), (30, -70), (-40, 50), (70, -20),
            (-80, 10), (40, 60), (-30, -60), (80, 30),
            (-50, -10), (20, -50), (-70, 40), (60, -30)
        ]
        
        let position = positions[index % positions.count]
        
        Circle()
            .fill(Color.white)
            .frame(width: 4, height: 4)
            .offset(x: position.0, y: position.1)
            .opacity(animationWave)
            .animation(
                Animation.linear(duration: 0.5)
                    .repeatCount(6, autoreverses: true)
                    .delay(Double(index) * 0.05),
                value: animationWave
            )
    }
    
    // 🎨 옵션 3: 차트 상승 효과
    @ViewBuilder
    private func buildChartRiseEffect() -> some View {
        ZStack {
            VStack(spacing: 4) {
                // 상승 화살표
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 25, weight: .bold))
                    .foregroundColor(.green)
                    .offset(y: animationOffset)
                    .animation(
                        Animation.easeOut(duration: 1.5)
                            .repeatCount(2, autoreverses: false),
                        value: animationOffset
                    )
                
                // 차트 바들
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(0..<5) { index in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [.blue, .green]),
                                startPoint: .bottom,
                                endPoint: .top
                            ))
                            .frame(
                                width: 16,
                                height: 20 + CGFloat(index) * 10 + animationScale * 30
                            )
                            .animation(
                                Animation.easeOut(duration: 0.8)
                                    .repeatCount(2, autoreverses: false)
                                    .delay(Double(index) * 0.15),
                                value: animationScale
                            )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // 🎨 옵션 4: 파이어워크 효과
    @ViewBuilder
    private func buildFireworkEffect() -> some View {
        ZStack {
            // 중앙 폭발
            Circle()
                .fill(RadialGradient(
                    gradient: Gradient(colors: [.yellow, .orange, .red, .clear]),
                    center: .center,
                    startRadius: 5,
                    endRadius: 80
                ))
                .frame(width: 120, height: 120)
                .scaleEffect(animationPulse)
                .opacity(animationOpacity)
                .animation(
                    Animation.easeOut(duration: 1.2)
                        .repeatCount(2, autoreverses: false),
                    value: animationPulse
                )
            
            // 파이어워크 파티클들
            ForEach(0..<16) { index in
                Circle()
                    .fill(index % 4 == 0 ? .yellow : 
                          index % 4 == 1 ? .orange :
                          index % 4 == 2 ? .red : .pink)
                    .frame(width: 6, height: 6)
                    .offset(
                        x: cos(Double(index) * .pi / 8) * animationOffset,
                        y: sin(Double(index) * .pi / 8) * animationOffset
                    )
                    .opacity(animationWave)
                    .animation(
                        Animation.easeOut(duration: 2.0)
                            .repeatCount(1, autoreverses: false)
                            .delay(Double(index) * 0.02),
                        value: animationOffset
                    )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // F2: 침묵 관리 효과 (부드러운 펄스) - 🔧 position 제거
    @ViewBuilder
    private func buildSilenceEffect() -> some View {
        ZStack {
            Circle()
                .fill(appState.visualPatternColor.opacity(0.4))
                .frame(width: 140, height: 140)
                .scaleEffect(animationPulse)
                .animation(
                    Animation.easeInOut(duration: 1.2).repeatCount(2, autoreverses: true),
                    value: animationPulse
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // S2: 음량 조절 효과 - 음파 파동 애니메이션
    @ViewBuilder
    private func buildVolumeControlEffect() -> some View {
        ZStack {
            // 외부로 퍼져나가는 음파 링들
            ForEach(0..<4) { index in
                Circle()
                    .stroke(Color.blue.opacity(0.4), lineWidth: 2)
                    .frame(width: 60 + CGFloat(index) * 30, height: 60 + CGFloat(index) * 30)
                    .scaleEffect(animationPulse + CGFloat(index) * 0.3)
                    .opacity(1.0 - animationPulse * 0.5 - CGFloat(index) * 0.2)
                    .animation(
                        Animation.easeOut(duration: 1.5)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 0.2),
                        value: animationPulse
                    )
            }
            
            // 중앙 음량 바 이퀄라이저
            HStack(spacing: 4) {
                ForEach(0..<5) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.blue)
                        .frame(
                            width: 6, 
                            height: 15 + CGFloat(index) * 5 + animationScale * 15
                        )
                        .animation(
                            Animation.easeInOut(duration: 0.4)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.08),
                            value: animationScale
                        )
                }
            }
            .scaleEffect(1.2)
            
            // 중심 음량 시각 요소 (애니메이션과 조화)
            ZStack {
                // 스피커 베이스
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.blue.opacity(0.7))
                    .frame(width: 8, height: 6)
                
                // 음파 표시 링
                ForEach(0..<2) { index in
                    RoundedRectangle(cornerRadius: 1)
                        .stroke(Color.blue.opacity(0.6), lineWidth: 1)
                        .frame(width: 4 + CGFloat(index) * 3, height: 2)
                        .offset(x: 8 + CGFloat(index) * 2)
                        .scaleEffect(animationPulse * 0.3 + 0.8)
                        .animation(
                            Animation.easeInOut(duration: 0.5)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.1),
                            value: animationPulse
                        )
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // R2: 관심도 하락 효과 (강한 경고) - 🔧 position 제거
    @ViewBuilder
    private func buildInterestDownEffect() -> some View {
        ZStack {
            Triangle()
                .fill(Color.red.opacity(0.8))
                .frame(width: 60, height: 60)
                .rotationEffect(.degrees(animationRotation))
                .scaleEffect(animationScale)
                .animation(
                    Animation.easeInOut(duration: 0.3)
                        .repeatForever(autoreverses: true),
                    value: animationRotation
                )
                .animation(
                    Animation.easeInOut(duration: 0.5)
                        .repeatForever(autoreverses: true),
                    value: animationScale
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // L3: 질문 제안 효과 (물음표 형태) - 🔧 position 제거
    @ViewBuilder
    private func buildQuestionEffect() -> some View {
        ZStack {
            Text("?")
                .font(.system(size: 80, weight: .bold))
                .foregroundColor(appState.visualPatternColor)
                .opacity(animationOpacity)
                .scaleEffect(animationScale)
                .animation(
                    Animation.easeInOut(duration: 1.0)
                        .repeatForever(autoreverses: true),
                    value: animationOpacity
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // 🎨 애니메이션 시작 (4개 핵심 패턴만)
    private func startPatternAnimation() {
        switch appState.currentVisualPattern {
        // ✅ 활성화된 4개 핵심 패턴
        case "S1": // 속도 조절
            animationPulse = 1.2
            animationScale = 1.0
            animationOpacity = 1.0
            
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                animationPulse = 1.4
            }
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                animationScale = 1.3
            }
            
        case "R1": // 자신감 상승
            animationPulse = 0.8
            animationScale = 1.0
            animationOpacity = 1.0
            animationOffset = 30
            
            withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                animationPulse = 1.5
            }
            withAnimation(.easeInOut(duration: 0.8).repeatCount(3, autoreverses: true)) {
                animationScale = 1.3
            }
            withAnimation(.easeOut(duration: 2.0).repeatCount(2, autoreverses: false)) {
                animationOffset = -40
                animationOpacity = 0.8
            }
            
        case "R2": // 자신감 하락
            animationPulse = 0.9
            animationScale = 1.0
            animationOpacity = 1.0
            animationOffset = -20
            
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                animationPulse = 1.3
            }
            withAnimation(.easeInOut(duration: 0.6).repeatCount(3, autoreverses: true)) {
                animationScale = 1.2
            }
            withAnimation(.easeIn(duration: 1.5).repeatCount(2, autoreverses: false)) {
                animationOffset = 25
                animationOpacity = 0.7
            }
            
        case "S2": // 음량 조절
            animationPulse = 0.5
            animationScale = 0.5
            animationOpacity = 1.0
            
            withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                animationPulse = 2.0
            }
            withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
                animationScale = 1.5
            }
            
        // 🔒 비활성화된 패턴들 (주석 처리)
        /*
        case "L1":
            animationScale = 1.0
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: false)) {
                animationScale = 0.3
            }
        case "F1":
            animationOpacity = 1.0
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                animationOpacity = 0.3
            }
        case "F2":
            animationPulse = 1.3
        case "L3":
            animationOpacity = 1.0
            animationScale = 1.0
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                animationOpacity = 0.4
                animationScale = 1.2
            }
        */
        default:
            break
        }
    }
    
    // 🎨 애니메이션 리셋
    private func resetAnimations() {
        animationOffset = 0
        animationScale = 1.0
        animationOpacity = 1.0
        animationRotation = 0
        animationPulse = 1.0
        animationWave = 0
    }
    
    // 🎨 자신감 상승 애니메이션 스타일별 시작
    private func startConfidenceAnimation() {
        switch confidenceAnimationStyle {
        case .levelUpBar:
            // 레벨업 바 효과
            animationScale = 1.0
            animationOpacity = 1.0
            animationWave = 0.0
            animationOffset = 20
            
            withAnimation(.easeOut(duration: 0.6).repeatCount(3, autoreverses: true)) {
                animationScale = 1.2
            }
            withAnimation(.easeOut(duration: 2.5).repeatCount(1, autoreverses: false)) {
                animationWave = 1.0
            }
            withAnimation(.easeOut(duration: 1.5)) {
                animationOffset = -30
                animationOpacity = 0.8
            }
            
        case .sparkleStars:
            // 별 반짝임 효과
            animationScale = 1.0
            animationRotation = 0
            animationPulse = 1.0
            animationOpacity = 1.0
            animationWave = 0.0
            
            withAnimation(.easeInOut(duration: 1.0).repeatCount(3, autoreverses: true)) {
                animationScale = 1.3
                animationRotation = 45
            }
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                animationPulse = 1.5
            }
            withAnimation(.linear(duration: 0.5).repeatCount(6, autoreverses: true)) {
                animationWave = 1.0
            }
            
        case .chartRise:
            // 차트 상승 효과
            animationOffset = 50
            animationScale = 0.5
            
            withAnimation(.easeOut(duration: 1.5).repeatCount(2, autoreverses: false)) {
                animationOffset = -20
            }
            withAnimation(.easeOut(duration: 0.8).repeatCount(2, autoreverses: false).delay(0.2)) {
                animationScale = 1.5
            }
            
        case .firework:
            // 파이어워크 효과
            animationPulse = 0.5
            animationOpacity = 1.0
            animationOffset = 0
            animationWave = 0.0
            
            withAnimation(.easeOut(duration: 1.2).repeatCount(2, autoreverses: false)) {
                animationPulse = 2.0
                animationOpacity = 0.3
            }
            withAnimation(.easeOut(duration: 2.0).repeatCount(1, autoreverses: false).delay(0.3)) {
                animationOffset = 120
                animationWave = 1.0
            }
        }
    }
}

// 🎨 커스텀 Heart 모양
struct Heart: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: width * 0.5, y: height * 0.9))
        path.addCurve(
            to: CGPoint(x: width * 0.1, y: height * 0.3),
            control1: CGPoint(x: width * 0.5, y: height * 0.7),
            control2: CGPoint(x: width * 0.1, y: height * 0.5)
        )
        path.addArc(
            center: CGPoint(x: width * 0.25, y: height * 0.25),
            radius: width * 0.15,
            startAngle: .degrees(135),
            endAngle: .degrees(0),
            clockwise: false
        )
        path.addArc(
            center: CGPoint(x: width * 0.75, y: height * 0.25),
            radius: width * 0.15,
            startAngle: .degrees(180),
            endAngle: .degrees(45),
            clockwise: false
        )
        path.addCurve(
            to: CGPoint(x: width * 0.5, y: height * 0.9),
            control1: CGPoint(x: width * 0.9, y: height * 0.5),
            control2: CGPoint(x: width * 0.5, y: height * 0.7)
        )
        return path
    }
}

// 🎨 커스텀 Triangle 모양
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        return path
    }
}

// 🎨 개발자 테스트용 유틸리티
extension WatchVisualFeedbackView {
    
    // 🛠️ 애니메이션 미리보기용 함수 (개발/테스트용)
    static func previewWithStyle(_ style: ConfidenceAnimationStyle) -> some View {
        WatchVisualFeedbackView()
            .environmentObject({
                let appState = AppState()
                appState.showVisualFeedback = true
                appState.currentVisualPattern = "R1"
                appState.visualPatternColor = .pink
                return appState
            }())
            .onAppear {
                // 스타일 설정은 내부적으로 처리됨
            }
    }
    
    // 🔧 애니메이션 스타일 변경 도우미 함수
    mutating func changeConfidenceStyle(to style: ConfidenceAnimationStyle) {
        self.confidenceAnimationStyle = style
        print("🎨 자신감 애니메이션 스타일 변경: \(style.rawValue)")
    }
}

struct WatchVisualFeedbackView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // 성취 바 효과 (기본)
            WatchVisualFeedbackView.previewWithStyle(.levelUpBar)
                .previewDisplayName("🎯 성취 바")
                
            // 차트 상승 효과
            WatchVisualFeedbackView.previewWithStyle(.chartRise)
                .previewDisplayName("📈 차트 상승")
                
            // 별 반짝임 효과
            WatchVisualFeedbackView.previewWithStyle(.sparkleStars)
                .previewDisplayName("✨ 별 반짝임")
                
            // 파이어워크 효과
            WatchVisualFeedbackView.previewWithStyle(.firework)
                .previewDisplayName("🎆 파이어워크")
        }
    }
}
#endif 