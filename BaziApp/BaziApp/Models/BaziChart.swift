import Foundation

/// 四柱中的一柱
struct Pillar: Codable, Hashable {
    /// 天干（如 庚）
    let gan: String
    /// 地支（如 午）
    let zhi: String
    /// 干支（如 庚午）
    var ganzhi: String { gan + zhi }
    /// 天干十神（如 比肩）
    let shiShen: String
    /// 藏干（如 [丁, 己]）
    let cangGan: [String]
    /// 藏干十神（如 [正官, 正印]）
    let cangGanShiShen: [String]
    /// 纳音（如 路旁土）
    let naYin: String
    /// 十二长生（星运，如 沐浴）
    let xingYun: String
    /// 空亡（如 戌亥）
    let kongWang: String
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

    /// 四柱（年/月/日/时）
    var pillars: [Pillar]
    /// 日主（日柱天干 + 五行，如 庚金）
    var dayMaster: String
    /// 身强弱
    var strength: String
    /// 格局
    var pattern: String

    /// 五行统计（含藏干）
    var wuxingCount: [String: Int]

    /// 神煞（吉 + 凶）
    var goodShenSha: [String]
    var badShenSha: [String]

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
}

// MARK: - 五行与干支常量

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

/// 十二长生
enum XingYun {
    /// 天干五行在地支的十二长生
    static let sequence = ["长生", "沐浴", "冠带", "临官", "帝旺", "衰", "病", "死", "墓", "绝", "胎", "养"]
    /// 五行 → 长生起始地支下标
    static func state(gan: String, zhi: String) -> String {
        guard let g = Gan.all.firstIndex(of: gan),
              let z = Zhi.all.firstIndex(of: zhi) else { return "" }
        let elem = Gan.wuxing[g]
        // 五行长生起始地支（阳干顺行；阴干逆行，此处用简化阳干）
        let start: [String: Int] = ["木": 2, "火": 2, "金": 5, "水": 8, "土": 8] // 寅亥巳申
        guard let s = start[elem] else { return "" }
        let idx = ((z - s) + 12) % 12
        return sequence[idx]
    }
}
