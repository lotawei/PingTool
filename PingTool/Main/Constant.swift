import SwiftUI
#if os(iOS)
import UIKit
#else
import AppKit
#endif
// MARK: - 主题颜色
struct ThemeColors {
    static let primary = Color("AccentColor")
    static let secondary = Color.blue.opacity(0.7)
    
    // 渐变色
    static let gradientStart = Color.blue.opacity(0.05)
    static let gradientEnd = Color.purple.opacity(0.05)
    static let borderGradientStart = Color.blue.opacity(0.2)
    static let borderGradientEnd = Color.purple.opacity(0.2)
    
    // 功能色
    static let success = Color(hex: "#76F6ABFF")
    static let warning = Color(hex: "#FFA500")
    static let error = Color(hex: "#FF4B4B")
    static let info = Color(hex: "#131314FF")
    
    // 背景色
    static let background = Color.white
    static let secondaryBackground = Color.white
    static let cardBackground = Color.white
    
    // 文字颜色
    static let textPrimary = Color.init(hex: "#000000")
    static let textSecondary = Color.init(hex: "#EEEEEE")
    static let textTertiary = Color.init(hex: "#FFEEEE")
}

// MARK: - 布局常量
struct LayoutMetrics {
    // 圆角
    static let cornerRadiusSmall: CGFloat = 8
    static let cornerRadiusMedium: CGFloat = 12
    static let cornerRadiusLarge: CGFloat = 16
    
    // 间距
    static let spacingSmall: CGFloat = 8
    static let spacingMedium: CGFloat = 12
    static let spacingLarge: CGFloat = 16
    static let spacingExtraLarge: CGFloat = 24
    
    // 内边距
    static let paddingSmall: CGFloat = 8
    static let paddingMedium: CGFloat = 12
    static let paddingLarge: CGFloat = 16
    static let paddingExtraLarge: CGFloat = 24
    
    // 卡片阴影
    static let shadowRadius: CGFloat = 10
    static let shadowY: CGFloat = 4
    static let shadowOpacity: CGFloat = 0.1
}

// MARK: - 动画常量
struct AnimationMetrics {
    static let defaultDuration: Double = 0.3
    static let defaultSpringDamping: Double = 0.7
    static let defaultSpringResponse: Double = 0.3
}

// MARK: - 字体样式
struct ThemeFonts {
    static let titleLarge = Font.system(.title, design: .rounded)
    static let titleMedium = Font.system(.title2, design: .rounded)
    static let titleSmall = Font.system(.title3, design: .rounded)
    
    static let headlineBold = Font.system(.headline, design: .rounded).weight(.bold)
    static let headline = Font.system(.headline, design: .rounded)
    
    static let bodyMedium = Font.system(.body, design: .rounded)
    static let bodyMonospaced = Font.system(.body, design: .monospaced)
    
    static let caption = Font.system(.caption, design: .rounded)
}

// MARK: - 预设渐变
struct ThemeGradients {
    static let cardBackground = LinearGradient(
        colors: [ThemeColors.gradientStart, ThemeColors.gradientEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let cardBorder = LinearGradient(
        colors: [ThemeColors.borderGradientStart, ThemeColors.borderGradientEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - 仪表盘布局常量
struct GaugeMetrics {
    // 主圆环
    static let circleScale: CGFloat = 0.8        // 圆环相对父视图的比例
    static let lineWidthScale: CGFloat = 0.05    // 线宽相对父视图的比例
    
    // 指针
    static let pointerScale: CGFloat = 0.35      // 指针长度相对父视图的比例
    static let pointerWidth: CGFloat = 4         // 指针宽度
    static let arrowHeight: CGFloat = 15         // 箭头高度
    static let arrowWidth: CGFloat = 10          // 箭头宽度
    
    // 文字
    static let titleFontScale: CGFloat = 0.08    // 标题字体大小比例
    static let subtitleFontScale: CGFloat = 0.05 // 副标题字体大小比例
    static let textTopPaddingScale: CGFloat = 0.25 // 文字顶部间距比例
    
    // 刻度线
    static let scaleLineWidth: CGFloat = 6       // 刻度线宽度
    static let scaleStartScale: CGFloat = 0.8    // 刻度起始位置比例
    static let scaleMinLengthScale: CGFloat = 0.3 // 最小刻度长度比例
    static let scaleMaxLengthScale: CGFloat = 0.8 // 最大刻度长度比例
}
