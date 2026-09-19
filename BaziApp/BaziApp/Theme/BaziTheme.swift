import SwiftUI

/// 八字 App 视觉系统 —— 问真式排版语言（暖灰纸底 × 墨字 × 古铜金唯一强调色 × 黑底金字）
/// v5.1：token 值整体切换为问真风，属性名保持不变以兼容全部调用点。
enum BaziTheme {

    // MARK: - 主色 & 墨色

    /// 强调色（古铜金；属性名沿用 actionBlue 以兼容历史调用点）
    static let actionBlue = Color(hex: 0xB9986A)
    /// 强调色加深（链接/按钮按下）
    static let actionBlueFocus = Color(hex: 0xA07F4E)
    /// 深色面上的强调色（黑底金字）
    static let blueOnDark = Color(hex: 0xD8BD8F)

    /// 墨色（所有标题/正文的主文字色）
    static let ink = Color(hex: 0x33302B)
    /// 次级文字
    static let secondary = Color(hex: 0x8A857C)
    /// 更浅的占位/辅助文字
    static let tertiary = Color(hex: 0x9A958B)
    /// 占位符灰
    static let placeholder = Color(hex: 0xC9C4BA)

    // MARK: - 表面

    /// 画布（暖灰纸底，屏幕背景）
    static let canvas = Color(hex: 0xEFEDE8)
    /// 卡片底（纯白）
    static let cardBG = Color(hex: 0xFFFFFF)
    /// 浅色面板（chip/次级底）
    static let parchment = Color(hex: 0xFAF9F5)
    /// 浅灰填充（输入框/胶囊）
    static let fill = Color(hex: 0xF3F1EC)
    /// 分隔线
    static let hairline = Color(hex: 0xE5E1D8)
    /// 柔和分隔线
    static let divider = Color(hex: 0xEDEAE2)
    /// 墨黑（黑底金字按钮 / 命盘页头部）
    static let darkTile = Color(hex: 0x211E1A)
    /// 墨黑（别名，语义同 darkTile）
    static let blackPill = Color(hex: 0x211E1A)
    /// 黑底上的金字
    static let goldOnBlack = Color(hex: 0xD8BD8F)
    /// 强调金加深
    static let goldDeep = Color(hex: 0xA07F4E)
    /// 金色淡底
    static let goldSoft = Color(hex: 0xF3EDE2)

    // MARK: - 五行色（传统沉色，贯穿全 App）

    /// 木
    static let wood = Color(hex: 0x3F8F5F)
    /// 火
    static let fire = Color(hex: 0xC2472E)
    /// 土
    static let earth = Color(hex: 0xC87F2F)
    /// 金（暗金，白背景清晰）
    static let metal = Color(hex: 0xA8862B)
    /// 水
    static let water = Color(hex: 0x4A6FA5)

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
    static let shenshaGoodBG = Color(hex: 0xEEF4EE)
    /// 吉神字
    static let shenshaGood = Color(hex: 0x3F8F5F)
    /// 凶煞淡底
    static let shenshaBadBG = Color(hex: 0xF8ECE8)
    /// 凶煞字
    static let shenshaBad = Color(hex: 0xC2472E)

    /// 日柱高亮底（金色淡底）
    static let dayPillarBG = Color(hex: 0xF3EDE2)
    /// 行式命盘表：日柱整列底色（更淡，避免抢戏）
    static let dayColumn = Color(hex: 0xB9986A).opacity(0.10)

    // MARK: - 字体

    /// 楷/宋体感（干支、大标题、仪式感文字）——Serif 设计在中文回落宋体
    static func kai(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

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
            .background(BaziTheme.cardBG)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(BaziTheme.hairline, lineWidth: 1)
            )
    }
}

extension View {
    func baziCard() -> some View { modifier(BaziCard()) }
}
