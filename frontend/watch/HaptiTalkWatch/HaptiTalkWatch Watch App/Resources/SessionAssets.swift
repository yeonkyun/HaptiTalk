import SwiftUI

// 워치 앱에서 사용할 색상, 이미지, 애셋 등을 관리하는 구조체
struct SessionAssets {
    // MARK: - 색상
    struct Colors {
        static let primary = Color(hex: "3f51b5")    // 주요 액션 버튼 색상
        static let success = Color(hex: "4caf50")    // 연결 성공, 긍정적 피드백 색상
        static let secondary = Color(hex: "7986cb")  // 보조 텍스트, 아이콘 색상
        static let dark = Color(hex: "212121")       // 최근 세션 배경 색상
        static let background = Color.black          // 기본 배경 색상
        static let text = Color.white                // 기본 텍스트 색상
        static let textSecondary = Color.gray        // 보조 텍스트 색상
    }
    
    // MARK: - 치수
    struct Dimensions {
        static let buttonHeight: CGFloat = 42.0
        static let logoSize: CGFloat = 40.0
        static let cornerRadius: CGFloat = 20.0
        static let standardPadding: CGFloat = 16.0
        static let smallPadding: CGFloat = 8.0
    }
    
    // MARK: - 텍스트 스타일
    struct TextStyles {
        static let title = Font.system(size: 18, weight: .bold)
        static let body = Font.system(size: 14)
        static let small = Font.system(size: 12)
        static let xsmall = Font.system(size: 10)
    }
    
    // MARK: - 애니메이션
    struct Animations {
        static let standard = Animation.easeInOut(duration: 0.3)
        static let button = Animation.spring(response: 0.3, dampingFraction: 0.7)
    }
}

// 헥스 색상 확장
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
} 