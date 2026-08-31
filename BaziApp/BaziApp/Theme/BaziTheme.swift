import SwiftUI

/// 八字 App 视觉系统 —— 基于 Apple 设计语言（Action Blue + iOS 语义色 + 五行色）
enum BaziTheme {

    // MARK: - 主色 & 墨色

    /// Action Blue（单一强调色，Apple 风格）
    static let actionBlue = Color(hex: 0x0066CC)
    /// 焦点蓝
    static let actionBlueFocus = Color(hex: 0x0071E3)
    /// 深色面上的链接蓝
    static let blueOnDark = Color(hex: 0x2997FF)

    /// 墨色（所有标题/正文的主文字色）
    static let ink = Color(hex: 0x1D1D1F)
    /// 次级文字
    static let secondary = Color(hex: 0x7A7A7A)
    /// 更浅的占位/辅助文字
    static let tertiary = Color(hex: 0x8E8E93)
    /// 占位符灰
    static let placeholder = Color(hex: 0xC7C7CC)

    // MARK: - 表面

    /// 画布（纯白）
    static let canvas = Color(hex: 0xFFFFFF)
    /// 羊皮纸（次级背景）
    static let parchment = Color(hex: 0xF5F5F7)
    /// 浅灰填充（气泡/输入框）
    static let fill = Color(hex: 0xF2F2F7)
    /// 分隔线
    static let hairline = Color(hex: 0xE0E0E0)
    /// 柔和分隔线
    static let divider = Color(hex: 0xF0F0F0)
    /// 深色 tile（苹果官网风格暗面）
    static let darkTile = Color(hex: 0x1D1D1F)

    // MARK: - 五行色（贯穿全 App）

    /// 木
    static let wood = Color(hex: 0x34C759)
    /// 火
    static let fire = Color(hex: 0xFF3B30)
    /// 土
    static let earth = Color(hex: 0xFF9500)
    /// 金（暗金，白背景清晰）
    static let metal = Color(hex: 0xB8860B)
    /// 水
    static let water = Color(hex: 0x007AFF)

    /// 五行 → 颜色
    static func wuxingColor(_ element: String) -> Color {
        switch element {
        case "木": return wood
        case "火": return fire
        case "土": return earth
        case "金": return metal
        case "水": return water
        default: return ink
        }
    }

    // MARK: - 神煞配色

    /// 吉神淡底
    static let shenshaGoodBG = Color(hex: 0xE8F8EC)
    /// 吉神字
    static let shenshaGood = Color(hex: 0x2E9E4F)
    /// 凶煞淡底
    static let shenshaBadBG = Color(hex: 0xFDECEA)
    /// 凶煞字
    static let shenshaBad = Color(hex: 0xE03A2F)

    /// 日柱高亮底
    static let dayPillarBG = Color(hex: 0xEAF2FC)

    // MARK: - 字体

    /// 大标题（34 Bold）
    static func largeTitle(_ size: CGFloat = 34) -> Font {
        .system(size: size, weight: .bold, design: .default)
    }
    /// 标题（17 SemiBold）
    static func title(_ size: CGFloat = 17) -> Font {
        .system(size: size, weight: .semibold)
    }
    /// 正文（17 Regular）
    static func body(_ size: CGFloat = 17) -> Font {
        .system(size: size, weight: .regular)
    }
    /// 次要（13 Regular）
    static func footnote(_ size: CGFloat = 13) -> Font {
        .system(size: size, weight: .regular)
    }
    /// 微（11 Regular）
    static func caption(_ size: CGFloat = 11) -> Font {
        .system(size: size, weight: .regular)
    }
}

// MARK: - Color Hex 扩展

extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}

// MARK: - 通用卡片修饰符

struct BaziCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(BaziTheme.canvas)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(BaziTheme.hairline, lineWidth: 1)
            )
    }
}

extension View {
    func baziCard() -> some View { modifier(BaziCard()) }
}
