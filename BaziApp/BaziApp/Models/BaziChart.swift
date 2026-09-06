import Foundation

/// 四柱中的一柱
struct Pillar: Codable, Hashable {
    /// 天干（如 庚）
    let gan: String
    /// 地支（如 午）
    let zhi: String
    /// 干支（如 庚午）
    var ganzhi: String { gan + zhi }
    /// 天干十神（如 比肩；日柱为「日主」）
    let shiShen: String
    /// 藏干（如 [丁, 己]）
    let cangGan: [String]
    /// 藏干十神（如 [正官, 正印]）
    let cangGanShiShen: [String]
    /// 纳音（如 路旁土）
    let naYin: String
    /// 星运：日主天干对此柱地支的十二长生
    let xingYun: String
    /// 自坐：本柱天干对本柱地支的十二长生
    let ziZuo: String
    /// 本柱旬空（空亡地支，如 戌亥）
    let kongWang: String
    /// 本柱神煞（如 ["月德贵人", "将星"]；吉凶由全局表判断颜色）
    let shenSha: [String]
}

/// 大运
struct DaYun: Codable, Hashable {
    /// 干支（如 甲申）
    let ganzhi: String
    /// 十神（如 食神）
    let shiShen: String
    /// 起运年龄（如 27）
    let startAge: Int
    /// 结束年龄（如 36）
    let endAge: Int
    /// 起运公历年份
    let startYear: Int
    /// 结束公历年份
    let endYear: Int
    /// 大运纳音（如 泉中水）
    let naYin: String
    /// 大运星运（日主对大运地支的十二长生）
    let xingYun: String
    /// 该大运对应的流年列表（起运后 10 年）
    let liunian: [LiuNian]
}

/// 流年
struct LiuNian: Codable, Hashable {
    /// 年份（如 2026）
    let year: Int
    /// 干支（如 丙午）
    let ganzhi: String
    /// 十神（如 七杀）
    let shiShen: String
}

/// 完整八字命盘
struct BaziChart: Codable, Hashable {
    /// 姓名
    var name: String
    /// 性别
    var gender: String
    /// 阳历生日（字符串，如 1990-05-15）
    var solarDate: String
    /// 出生钟表时间（如 12:00）
    var hour: String
    /// 出生地（如 北京）
    var place: String
    /// 真太阳时修正后的时间（如 11:49）
    var trueSolarTime: String
    /// 经度时差（分钟，如 -14）
    var longitudeOffset: Int

    // MARK: - 基本信息（问真式）

    /// 生肖（如 马）
    var shengxiao: String
    /// 星座（如 金牛座）
    var xingzuo: String
    /// 农历日期（如 庚午年 四月十一）
    var lunarDate: String
    /// 节气详情（如 立夏后第 9 天）
    var jieQiDetail: String
    /// 胎元（如 壬子·桑柘木）
    var taiYuan: String
    /// 胎息（日柱干支六合位，如 乙酉）
    var taiXi: String
    /// 命宫（如 辛酉）
    var mingGong: String
    /// 身宫（如 乙未）
    var shenGong: String
    /// 命卦（如 乾卦 · 西四命）
    var mingGua: String
    /// 星宿（如 胃宿）
    var xingXiu: String
    /// 人元司令（月令分野司令之干，如 庚金）
    var renYuanSiLing: String
    /// 袁天罡称骨（如 三两八钱）
    var chengGu: String
    /// 起运详述（如 7 年 8 个月起运）
    var qiYunDetail: String

    /// 四柱（年/月/日/时）
    var pillars: [Pillar]
    /// 日主（日柱天干 + 五行，如 庚金）
    var dayMaster: String
    /// 身强弱
    var strength: String
    /// 旺衰三判：得令
    var deLing: Bool
    /// 旺衰三判：得地
    var deDi: Bool
    /// 旺衰三判：得势
    var deShi: Bool
    /// 旺衰解读（综合判定 + 调候建议）
    var strengthNote: String
    /// 格局
    var pattern: String
    /// 调候参考（如 壬水）
    var tiaoHou: String

    /// 五行统计（含藏干）
    var wuxingCount: [String: Int]

    /// 神煞（吉 + 减，全局汇总，展示用）
    var goodShenSha: [String]
    var badShenSha: [String]
    /// 神煞吉凶表（名称 → true 吉 / false 凶），供逐柱着色
    var shenShaTone: [String: Bool]

    /// 喜用神 / 忌神
    var xiYong: [String]
    var jiShen: [String]

    /// 大运（顺排/逆排 + 起运 + 列表）
    var dayunDirection: String
    var dayunStart: String
    var dayun: [DaYun]

    /// 流年（当前 + 未来）
    var liunian: [LiuNian]

    /// 当前大运下标
    var currentDayunIndex: Int

    /// 神煞是否为吉（查表；未知默认中性 nil）
    func isGoodShenSha(_ name: String) -> Bool? { shenShaTone[name] }
}

/// 天干
enum Gan {
    static let all = ["甲", "乙", "丙", "丁", "戊", "己", "庚", "辛", "壬", "癸"]
    /// 天干五行
    static let wuxing = ["木", "木", "火", "火", "土", "土", "金", "金", "水", "水"]
    /// 天干阴阳（true = 阳）
    static let isYang = [true, false, true, false, true, false, true, false, true, false]
}

/// 地支
enum Zhi {
    static let all = ["子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥"]
    /// 地支五行
    static let wuxing = ["水", "土", "木", "木", "土", "火", "火", "土", "金", "金", "土", "水"]
    /// 地支藏干（主气、中气、余气）
    static let cangGan: [[String]] = [
        ["癸"],           // 子
        ["己", "癸", "辛"], // 丑
        ["甲", "丙", "戊"], // 寅
        ["乙"],           // 卯
        ["戊", "乙", "癸"], // 辰
        ["丙", "庚", "戊"], // 巳
        ["丁", "己"],      // 午
        ["己", "丁", "乙"], // 未
        ["庚", "壬", "戊"], // 申
        ["辛"],           // 酉
        ["戊", "辛", "丁"], // 戌
        ["壬", "甲"]       // 亥
    ]
    /// 地支六合（子丑、寅亥、卯戌、辰酉、巳申、午未）
    static let liuHe: [String: String] = [
        "子": "丑", "丑": "子", "寅": "亥", "亥": "寅", "卯": "戌", "戌": "卯",
        "辰": "酉", "酉": "辰", "巳": "申", "申": "巳", "午": "未", "未": "午"
    ]
    /// 地支三合局（旺位）
    static let sanHeWang: [String: String] = [
        "申": "子", "子": "子", "辰": "子",
        "寅": "午", "午": "午", "戌": "午",
        "巳": "酉", "酉": "酉", "丑": "酉",
        "亥": "卯", "卯": "卯", "未": "卯"
    ]
}

/// 天干五合（甲己、乙庚、丙辛、丁壬、戊癸）
enum GanHe {
    static let map: [String: String] = [
        "甲": "己", "己": "甲", "乙": "庚", "庚": "乙", "丙": "辛",
        "辛": "丙", "丁": "壬", "壬": "丁", "戊": "癸", "癸": "戊"
    ]
}

/// 十神（日主对目标天干的关系）
enum ShiShen {
    /// 天干 tenGan 相对日主 dayGan 的十神
    static func of(dayGan: String, targetGan: String) -> String {
        guard let day = Gan.all.firstIndex(of: dayGan),
              let target = Gan.all.firstIndex(of: targetGan) else { return "" }
        let dayElem = Gan.wuxing[day]   // 日主五行
        let targetElem = Gan.wuxing[target] // 目标五行
        let sameYang = Gan.isYang[day] == Gan.isYang[target] // 同阴阳

        if dayElem == targetElem {
            // 同五行 → 比肩/劫财
            return sameYang ? "比肩" : "劫财"
        }
        // 生克关系
        let sheng = wuxingSheng(dayElem, targetElem) // 日主生目标 → 食伤
        let ke = wuxingKe(dayElem, targetElem)       // 日主克目标 → 财
        let shengWo = wuxingSheng(targetElem, dayElem) // 目标生日主 → 印
        let keWo = wuxingKe(targetElem, dayElem)       // 目标克日主 → 官杀

        if sheng { return sameYang ? "食神" : "伤官" }
        if ke { return sameYang ? "偏财" : "正财" }
        if shengWo { return sameYang ? "偏印" : "正印" }
        if keWo { return sameYang ? "七杀" : "正官" }
        return ""
    }

    /// a 生 b（五行相生）
    static func wuxingSheng(_ a: String, _ b: String) -> Bool {
        let shengMap: [String: String] = ["木": "火", "火": "土", "土": "金", "金": "水", "水": "木"]
        return shengMap[a] == b
    }
    /// a 克 b（五行相克）
    static func wuxingKe(_ a: String, _ b: String) -> Bool {
        let keMap: [String: String] = ["木": "土", "土": "水", "水": "火", "火": "金", "金": "木"]
        return keMap[a] == b
    }
}

/// 纳音（六十甲子纳音）
enum NaYin {
    static let map: [String: String] = [
        "甲子": "海中金", "乙丑": "海中金", "丙寅": "炉中火", "丁卯": "炉中火",
        "戊辰": "大林木", "己巳": "大林木", "庚午": "路旁土", "辛未": "路旁土",
        "壬申": "剑锋金", "癸酉": "剑锋金", "甲戌": "山头火", "乙亥": "山头火",
        "丙子": "涧下水", "丁丑": "涧下水", "戊寅": "城头土", "己卯": "城头土",
        "庚辰": "白蜡金", "辛巳": "白蜡金", "壬午": "杨柳木", "癸未": "杨柳木",
        "甲申": "泉中水", "乙酉": "泉中水", "丙戌": "屋上土", "丁亥": "屋上土",
        "戊子": "霹雳火", "己丑": "霹雳火", "庚寅": "松柏木", "辛卯": "松柏木",
        "壬辰": "长流水", "癸巳": "长流水", "甲午": "砂石金", "乙未": "砂石金",
        "丙申": "山下火", "丁酉": "山下火", "戊戌": "平地木", "己亥": "平地木",
        "庚子": "壁上土", "辛丑": "壁上土", "壬寅": "金箔金", "癸卯": "金箔金",
        "甲辰": "覆灯火", "乙巳": "覆灯火", "丙午": "天河水", "丁未": "天河水",
        "戊申": "大驿土", "己酉": "大驿土", "庚戌": "钗钏金", "辛亥": "钗钏金",
        "壬子": "桑柘木", "癸丑": "桑柘木", "甲寅": "大溪水", "乙卯": "大溪水",
        "丙辰": "沙中土", "丁巳": "沙中土", "戊午": "天上火", "己未": "天上火",
        "庚申": "石榴木", "辛酉": "石榴木", "壬戌": "大海水", "癸亥": "大海水"
    ]
}

/// 十二长生（阳干顺行、阴干逆行）
enum XingYun {
    /// 十二长生序
    static let sequence = ["长生", "沐浴", "冠带", "临官", "帝旺", "衰", "病", "死", "墓", "绝", "胎", "养"]
    /// 阳干 → 长生起始地支下标（甲=亥11，丙=寅2，戊=寅2，庚=巳5，壬=申8）
    private static let yangStart: [Int: Int] = [0: 11, 2: 2, 4: 2, 6: 5, 8: 8]
    /// 阴干 → 长生起始地支下标（乙=午6，丁=酉9，己=酉9，辛=子0，癸=卯3）
    private static let yinStart: [Int: Int] = [1: 6, 3: 9, 5: 9, 7: 0, 9: 3]

    /// 天干 gan 在地支 zhi 的十二长生（阳顺阴逆）
    static func state(gan: String, zhi: String) -> String {
        guard let g = Gan.all.firstIndex(of: gan),
              let z = Zhi.all.firstIndex(of: zhi) else { return "" }
        let idx: Int
        if Gan.isYang[g], let s = yangStart[g] {
            idx = (z - s + 12) % 12
        } else if let s = yinStart[g] {
            idx = (s - z + 12) % 12
        } else {
            return ""
        }
        return sequence[idx]
    }
}

/// 《滴天髓》日主论述（按日干取，用于命盘页「经典论述」卡）
enum DiTianSui {
    static let quotes: [String: String] = [
        "甲": "甲木参天，脱胎要火。春不容金，秋不容土。",
        "乙": "乙木虽柔，刲羊解牛。怀丁抱丙，跨凤乘猴。",
        "丙": "丙火猛烈，欺霜侮雪。能煅庚金，逢辛反怯。",
        "丁": "丁火柔中，内性昭融。抱乙而孝，合壬而忠。",
        "戊": "戊土固重，既中且正。静翕动辟，万物司命。",
        "己": "己土卑湿，中正蓄藏。不愁木盛，不畏水狂。",
        "庚": "庚金带煞，刚健为最。得水而清，得火而锐。",
        "辛": "辛金软弱，温润而清。畏土之叠，乐水之盈。",
        "壬": "壬水通河，能泄金气。刚中之德，周流不滞。",
        "癸": "癸水至弱，达于天津。得龙而运，功化斯神。"
    ]

    /// 日干 → 论日主原文
    static func quote(dayGan: String) -> String { quotes[dayGan] ?? "" }
}

/// 袁天罡称骨重量表（单位：钱；1 两 = 10 钱）
enum ChengGu {
    /// 年柱重量（干支 → 钱）
    static let yearTable: [String: Double] = [
        "甲子": 12, "乙丑": 8, "丙寅": 6, "丁卯": 7, "戊辰": 12, "己巳": 8,
        "庚午": 8, "辛未": 7, "壬申": 7, "癸酉": 8,
        "甲戌": 15, "乙亥": 9, "丙子": 16, "丁丑": 8, "戊寅": 8, "己卯": 19,
        "庚辰": 12, "辛巳": 8, "壬午": 8, "癸未": 7,
        "甲申": 5, "乙酉": 10, "丙戌": 6, "丁亥": 8, "戊子": 15, "己丑": 8,
        "庚寅": 9, "辛卯": 12, "壬辰": 10, "癸巳": 8,
        "甲午": 15, "乙未": 8, "丙申": 8, "丁酉": 9, "戊戌": 14, "己亥": 9,
        "庚子": 7, "辛丑": 7, "壬寅": 9, "癸卯": 12,
        "甲辰": 8, "乙巳": 7, "丙午": 13, "丁未": 8, "戊申": 14, "己酉": 5,
        "庚戌": 9, "辛亥": 10, "壬子": 7, "癸丑": 7,
        "甲寅": 8, "乙卯": 8, "丙辰": 8, "丁巳": 6, "戊午": 14, "己未": 6,
        "庚申": 8, "辛酉": 8, "壬戌": 9, "癸亥": 6
    ]
    /// 农历月重量（正月起）
    static let monthTable: [Double] = [6, 7, 18, 9, 5, 16, 9, 15, 18, 8, 9, 5]
    /// 农历日重量（初一起）
    static let dayTable: [Double] = [
        5, 10, 8, 15, 16, 15, 8, 16, 8, 16,
        9, 17, 8, 17, 10, 8, 9, 18, 5, 15,
        10, 9, 8, 9, 15, 18, 7, 8, 16, 16
    ]
    /// 时支重量（子起）
    static let hourTable: [Double] = [16, 6, 7, 10, 9, 16, 10, 8, 8, 9, 6, 6]

    /// 钱数 → 中文（如 37 → 三两七钱）
    static func string(totalQian: Double) -> String {
        let liang = Int(totalQian / 10)
        let qian = Int(totalQian.truncatingRemainder(dividingBy: 10))
        let digits = ["零", "一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]
        let liangStr: String
        if liang <= 10 { liangStr = digits[min(liang, 10)] } else { return "—" }
        if qian == 0 { return "\(liangStr)两" }
        return "\(liangStr)两\(digits[qian])钱"
    }
}
