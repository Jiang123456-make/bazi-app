import SwiftUI

/// 十神 → 宜/忌/一句话提示（报告页「今年宜忌」与首页「今日指南」共用）
enum TenGodGuide {

    static func guide(_ shiShen: String) -> (yi: [String], ji: [String], tip: String) {
        switch shiShen {
        case "七杀":
            return (["谨慎决策", "直面挑战"], ["硬碰硬", "冲动行事"], "压力与机遇并存，宜谋定而后动")
        case "正官":
            return (["守规履约", "争取认可"], ["越线行事", "与人争执"], "规则内行事最顺，口碑是资产")
        case "正财":
            return (["稳健理财", "深耕主业"], ["投机冒进", "盲目扩张"], "细水长流，积少成多")
        case "偏财":
            return (["把握机会", "广结善缘"], ["贪多求快", "独占资源"], "机会较多，落袋为安")
        case "食神":
            return (["创作表达", "休养生息"], ["急功近利", "透支精力"], "输出与享受并存，宜慢节奏")
        case "伤官":
            return (["创意表达", "突破常规"], ["口舌是非", "顶撞权威"], "才华外露，谨言可免是非")
        case "正印":
            return (["学习充电", "请教长辈"], ["固执己见", "轻信承诺"], "贵人多助，宜提升自己")
        case "偏印":
            return (["深度研究", "独立思考"], ["多疑犹豫", "闭门造车"], "直觉敏锐，宜专精一事")
        case "比肩":
            return (["团队协作", "强身健体"], ["意气用事", "替人担保"], "同辈助力多，也防竞争")
        case "劫财":
            return (["守财谨慎", "合作分工"], ["借贷担保", "冲动消费"], "破耗较多，钱财宜守")
        default:
            return (["顺势而为"], ["逆势强求"], "运势平稳，宜稳中求进")
        }
    }

    /// 流年/流日十神 → 吉 / 平 / 滞 档位
    static func grade(_ shiShen: String) -> (String, Color) {
        switch shiShen {
        case "正印", "正官", "正财", "偏财", "食神": return ("吉", BaziTheme.shenshaGood)
        case "偏印", "比肩": return ("平", BaziTheme.earth)
        default: return ("滞", BaziTheme.shenshaBad)
        }
    }
}
