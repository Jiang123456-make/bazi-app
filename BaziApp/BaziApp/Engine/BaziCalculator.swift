import Foundation

/// 八字排盘引擎（Swift 原生离线实现，移植自知识库 bazi-paipan 的核心算法）
/// 参考锚点：1990-05-15 12:00 男 = 庚午 / 辛巳 / 庚辰 / 壬午，顺排，起运 7 岁
enum BaziCalculator {

    // MARK: - 六十甲子

    static let liushiJiazi: [String] = {
        var result: [String] = []
        for i in 0..<60 {
            result.append(Gan.all[i % 10] + Zhi.all[i % 12])
        }
        return result
    }()

    // MARK: - 儒略日（日柱核心）

    /// 公历日期 → 儒略日数 JDN（以中午为界）
    static func julianDay(year: Int, month: Int, day: Int) -> Int {
        var y = year, m = month
        if m <= 2 { y -= 1; m += 12 }
        let a = y / 100
        let b = 2 - a + a / 4
        let jd = Int(365.25 * Double(y + 4716)) + Int(30.6001 * Double(m + 1)) + day + b - 1524
        return jd
    }

    /// 日柱干支下标（锚点：1990-05-15 = 庚辰，序号 16）
    static func dayPillarIndex(jdn: Int) -> Int {
        return (jdn + 49) % 60
    }

    // MARK: - 年柱（立春分界）

    /// 立春的近似日期（返回该年立春的月/日，日级精度）
    /// 立春通常在 2 月 3-5 日，简化为 2 月 4 日；精确到分钟需 VSOP87（MVP 用日级）
    static func lichunDate(year: Int) -> (month: Int, day: Int) {
        // 简化：立春约在 2 月 4 日（1900-2100 误差 ±1 天）
        // 更精确可用寿星公式，但日级对时辰排盘够用
        return (2, 4)
    }

    /// 年柱干支
    static func yearPillar(year: Int, month: Int, day: Int) -> String {
        let lc = lichunDate(year: year)
        var y = year
        // 立春前出生，年柱属上一年
        if month < lc.month || (month == lc.month && day < lc.day) {
            y -= 1
        }
        let idx = (y - 4) % 60
        return liushiJiazi[(idx + 60) % 60]
    }

    // MARK: - 月柱（十二"节"分界）

    /// 十二节的近似日期（月，日）—— 立春/惊蛰/清明/立夏/芒种/小暑/立秋/白露/寒露/立冬/大雪/小寒
    static let jieQiDates: [(month: Int, day: Int)] = [
        (2, 4),   // 立春
        (3, 6),   // 惊蛰
        (4, 5),   // 清明
        (5, 6),   // 立夏
        (6, 6),   // 芒种
        (7, 7),   // 小暑
        (8, 8),   // 立秋
        (9, 8),   // 白露
        (10, 8),  // 寒露
        (11, 7),  // 立冬
        (12, 7),  // 大雪
        (1, 6)    // 小寒
    ]

    /// 月支下标（寅=2 ... 丑=1，对应地支）
    static let jieZhiIndex = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 0, 1]

    /// 月柱
    static func monthPillar(year: Int, month: Int, day: Int) -> String {
        // 归一化：1 月视作 13 月（小寒在立春之后，避免 1 月干扰遍历顺序）
        let mm = month >= 2 ? month : month + 12
        var jieIndex = -1
        for (i, jq) in jieQiDates.enumerated() {
            let jmm = jq.month >= 2 ? jq.month : jq.month + 12
            if mm > jmm || (mm == jmm && day >= jq.day) {
                jieIndex = i
            }
        }
        // 立春前（2月4日前）出生 → 属于上一年丑月
        let zhiIdx = jieIndex == -1 ? 1 : jieZhiIndex[jieIndex]
        let zhi = Zhi.all[zhiIdx]

        // 年上起月（五虎遁）：年干 → 寅月天干
        let yearGan = String(yearPillar(year: year, month: month, day: day).first!)
        let yinGan = wuhudun(yearGan: yearGan)
        // 寅月起，推算到当前月支
        let yinIndex = 2 // 寅
        let offset = (zhiIdx - yinIndex + 12) % 12
        let ganIndex = (Gan.all.firstIndex(of: yinGan)! + offset) % 10
        return Gan.all[ganIndex] + zhi
    }

    /// 五虎遁：年干 → 寅月天干
    static func wuhudun(yearGan: String) -> String {
        switch yearGan {
        case "甲", "己": return "丙"
        case "乙", "庚": return "戊"
        case "丙", "辛": return "庚"
        case "丁", "壬": return "壬"
        case "戊", "癸": return "甲"
        default: return "甲"
        }
    }

    // MARK: - 时柱（五鼠遁）

    /// 五鼠遁：日干 → 子时天干
    static func wushudun(dayGan: String) -> String {
        switch dayGan {
        case "甲", "己": return "甲"
        case "乙", "庚": return "丙"
        case "丙", "辛": return "戊"
        case "丁", "壬": return "庚"
        case "戊", "癸": return "壬"
        default: return "甲"
        }
    }

    /// 钟表时间 → 时支下标（子 23-01，丑 01-03 ... 亥 21-23）
    static func hourZhiIndex(hour: Int, minute: Int) -> Int {
        // 晚子时 23:00-24:00 算子时（时支子）
        let h = hour % 24
        if h == 23 || h == 0 { return 0 } // 子
        return (h + 1) / 2 // 01→丑(1), 02→丑, 03→寅(2)...
    }

    /// 时柱
    static func hourPillar(dayGan: String, hour: Int, minute: Int) -> String {
        let zhiIdx = hourZhiIndex(hour: hour, minute: minute)
        let zhi = Zhi.all[zhiIdx]
        let ziGan = wushudun(dayGan: dayGan)
        let ganIndex = (Gan.all.firstIndex(of: ziGan)! + zhiIdx) % 10
        return Gan.all[ganIndex] + zhi
    }

    // MARK: - 真太阳时

    /// 经度时差（分钟）：(经度 - 120°) × 4
    /// 出生地经度来自 PlaceData（130+ 城市）；未知地区默认经度 120°，时差 0（即北京时间）
    static func longitudeOffset(place: String) -> Int {
        let lon = PlaceData.longitude(of: place)
        return Int(round((lon - 120.0) * 4))
    }

    // MARK: - 空亡（旬空）

    /// 某柱干支 → 该柱所在旬的空亡地支（逐柱空亡，非全局）
    /// 六十甲子每旬 10 组，旬内未出现的两个地支即为空亡
    static func kongWang(ganzhi: String) -> String {
        guard let idx = liushiJiazi.firstIndex(of: ganzhi) else { return "" }
        let xunStart = (idx / 10) * 10          // 旬首下标（甲子=0，甲戌=10…）
        let kongStart = (xunStart + 10) % 12    // 旬内 10 个地支之后的两个地支
        let z1 = Zhi.all[kongStart]
        let z2 = Zhi.all[(kongStart + 1) % 12]
        return z1 + z2
    }

    // MARK: - 大运

    /// 大运（顺逆 + 起运 + 列表）
    static func daYun(year: Int, month: Int, day: Int, hour: Int, gender: String, monthPillar: String) -> (direction: String, start: String, list: [DaYun]) {
        let yearPillarStr = yearPillar(year: year, month: month, day: day)
        let yearGan = String(yearPillarStr.first!)
        let isYangYear = Gan.isYang[Gan.all.firstIndex(of: yearGan)!]
        // 阳年男/阴年女 顺排，否则逆排
        let shun = (isYangYear && gender == "男") || (!isYangYear && gender == "女")
        let direction = shun ? "顺排" : "逆排"

        let mpIndex = liushiJiazi.firstIndex(of: monthPillar)!
        let dayGan = dayMasterGan(year: year, month: month, day: day)

        // 起运年龄 = 出生到最近节的天数 ÷ 3（简化：按日估算）
        let startAge = estimateStartAge(year: year, month: month, day: day, shun: shun)

        var list: [DaYun] = []
        for step in 0..<8 {
            let offset = shun ? (step + 1) : -(step + 1)
            let gz = liushiJiazi[(mpIndex + offset + 60) % 60]
            let ss = ShiShen.of(dayGan: dayGan, targetGan: String(gz.first!))
            let age = startAge + step * 10
            let startYear = year + age
            let endYear = startYear + 9
            let ny = NaYin.map[gz] ?? ""
            let xy = XingYun.state(gan: dayGan, zhi: String(gz.last!)) // 日主对大运地支的十二长生
            // 该大运对应的 10 年流年（问真式专业细盘）
            var lns: [LiuNian] = []
            for i in 0..<10 {
                let ly = startYear + i
                let gzIdx = (ly - 4) % 60
                let lgz = liushiJiazi[(gzIdx + 60) % 60]
                let lss = ShiShen.of(dayGan: dayGan, targetGan: String(lgz.first!))
                lns.append(LiuNian(year: ly, ganzhi: lgz, shiShen: lss))
            }
            list.append(DaYun(ganzhi: gz, shiShen: ss, startAge: age, endAge: age + 9,
                              startYear: startYear, endYear: endYear, naYin: ny,
                              xingYun: xy, liunian: lns))
        }

        return (direction, "起运 \(startAge) 岁", list)
    }

    /// 估算起运年龄（简化：出生月到最近节的日差 ÷ 3）
    static func estimateStartAge(year: Int, month: Int, day: Int, shun: Bool) -> Int {
        // MVP：简化估算 3-8 岁（精确需节气分钟级 VSOP87）
        // 用出生日到当月节的距离做粗略估计
        var days = 0
        if shun {
            // 顺数到下一个节
            for jq in jieQiDates {
                if jq.month > month || (jq.month == month && jq.day >= day) {
                    days = (jq.month - month) * 30 + (jq.day - day)
                    if days < 0 { days += 360 }
                    break
                }
            }
        } else {
            // 逆数到上一个节
            for jq in jieQiDates.reversed() {
                if jq.month < month || (jq.month == month && jq.day <= day) {
                    days = (month - jq.month) * 30 + (day - jq.day)
                    if days < 0 { days += 360 }
                    break
                }
            }
        }
        let age = max(1, days / 3)
        return min(age, 10)
    }

    /// 日主天干
    static func dayMasterGan(year: Int, month: Int, day: Int) -> String {
        let jdn = julianDay(year: year, month: month, day: day)
        let idx = dayPillarIndex(jdn: jdn)
        return String(liushiJiazi[idx].first!)
    }

    // MARK: - 流年

    /// 流年（从某年开始 N 年）
    static func liuNian(dayGan: String, fromYear: Int, count: Int) -> [LiuNian] {
        var result: [LiuNian] = []
        for i in 0..<count {
            let y = fromYear + i
            let idx = (y - 4) % 60
            let gz = liushiJiazi[(idx + 60) % 60]
            let ss = ShiShen.of(dayGan: dayGan, targetGan: String(gz.first!))
            result.append(LiuNian(year: y, ganzhi: gz, shiShen: ss))
        }
        return result
    }

    // MARK: - 神煞（逐柱，问真式）

    /// 天德贵人（月支 → 天干；值支者不入表，按干匹配柱）
    static let tianDe: [String: String] = [
        "寅": "丁", "卯": "申", "辰": "壬", "巳": "辛", "午": "亥", "未": "甲",
        "申": "癸", "酉": "寅", "戌": "丙", "亥": "乙", "子": "巳", "丑": "庚"
    ]
    /// 月德贵人（月支三合局 → 天干：寅午戌丙、申子辰壬、巳酉丑庚、亥卯未甲）
    static let yueDe: [String: String] = [
        "寅": "丙", "午": "丙", "戌": "丙",
        "申": "壬", "子": "壬", "辰": "壬",
        "巳": "庚", "酉": "庚", "丑": "庚",
        "亥": "甲", "卯": "甲", "未": "甲"
    ]

    /// 神煞（逐柱归属）+ 吉凶色调表（true 吉 / false 凶；未收录者中性）
    /// perPillar 顺序 = [年柱, 月柱, 日柱, 时柱]
    static func shenShaDetail(dayPillar: String, yearPillar: String, monthPillar: String, hourPillar: String)
        -> (perPillar: [[String]], tone: [String: Bool], good: [String], bad: [String]) {
        let gzs = [yearPillar, monthPillar, dayPillar, hourPillar]
        var per = [[String]](repeating: [], count: 4)
        var tone: [String: Bool] = [:]

        /// 按「支匹配」或「干匹配」把神煞挂到命中的柱上；good 传 nil 表示中性（不着色）
        func add(_ name: String, _ good: Bool?, _ hit: (String, String) -> Bool) {
            var matched = false
            for (i, gz) in gzs.enumerated() {
                let g = String(gz.first!), z = String(gz.last!)
                if hit(g, z), !per[i].contains(name) {
                    per[i].append(name)
                    matched = true
                }
            }
            if matched, let good = good { tone[name] = good }
        }

        let dayGan = String(dayPillar.first!)
        let dayZhi = String(dayPillar.last!)
        let yearZhi = String(yearPillar.last!)
        let monthZhi = String(monthPillar.last!)

        // 天乙贵人（日干查支）
        let tianyi: [String: [String]] = [
            "甲": ["丑", "未"], "戊": ["丑", "未"],
            "乙": ["子", "申"], "己": ["子", "申"],
            "丙": ["亥", "酉"], "丁": ["亥", "酉"],
            "庚": ["丑", "未"], "辛": ["寅", "午"],
            "壬": ["卯", "巳"], "癸": ["卯", "巳"]
        ]
        for z in tianyi[dayGan] ?? [] { add("天乙贵人", true, { _, zz in zz == z }) }

        // 文昌（日干查支）
        let wenchang: [String: String] = [
            "甲": "巳", "乙": "午", "丙": "申", "丁": "酉", "戊": "申",
            "己": "酉", "庚": "亥", "辛": "子", "壬": "寅", "癸": "卯"
        ]
        if let z = wenchang[dayGan] { add("文昌", true, { _, zz in zz == z }) }

        // 桃花（年支 / 日支查）
        let taohua: [String: String] = [
            "申": "酉", "子": "酉", "辰": "酉", "寅": "卯", "午": "卯", "戌": "卯",
            "巳": "午", "酉": "午", "丑": "午", "亥": "子", "卯": "子", "未": "子"
        ]
        if let z = taohua[yearZhi] { add("桃花", nil, { _, zz in zz == z }) }
        if let z = taohua[dayZhi] { add("桃花", nil, { _, zz in zz == z }) }

        // 驿马（年支 / 日支查）
        let yima: [String: String] = [
            "申": "寅", "子": "寅", "辰": "寅", "寅": "申", "午": "申", "戌": "申",
            "巳": "亥", "酉": "亥", "丑": "亥", "亥": "巳", "卯": "巳", "未": "巳"
        ]
        if let z = yima[yearZhi] { add("驿马", nil, { _, zz in zz == z }) }
        if let z = yima[dayZhi] { add("驿马", nil, { _, zz in zz == z }) }

        // 将星（三合旺位，年支 / 日支查）
        let jiangxing: [String: String] = [
            "申": "子", "子": "子", "辰": "子", "寅": "午", "午": "午", "戌": "午",
            "巳": "酉", "酉": "酉", "丑": "酉", "亥": "卯", "卯": "卯", "未": "卯"
        ]
        if let z = jiangxing[yearZhi] { add("将星", true, { _, zz in zz == z }) }
        if let z = jiangxing[dayZhi] { add("将星", true, { _, zz in zz == z }) }

        // 华盖（年支 / 日支查）
        let huagai: [String: String] = [
            "申": "辰", "子": "辰", "辰": "辰", "寅": "戌", "午": "戌", "戌": "戌",
            "巳": "丑", "酉": "丑", "丑": "丑", "亥": "未", "卯": "未", "未": "未"
        ]
        if let z = huagai[yearZhi] { add("华盖", true, { _, zz in zz == z }) }
        if let z = huagai[dayZhi] { add("华盖", true, { _, zz in zz == z }) }

        // 羊刃（日干查支）
        let yangren: [String: String] = [
            "甲": "卯", "乙": "辰", "丙": "午", "丁": "未", "戊": "午",
            "己": "未", "庚": "酉", "辛": "戌", "壬": "子", "癸": "丑"
        ]
        if let z = yangren[dayGan] { add("羊刃", false, { _, zz in zz == z }) }

        // 劫煞（年支 / 日支查）
        let jiesha: [String: String] = [
            "申": "巳", "子": "巳", "辰": "巳", "寅": "亥", "午": "亥", "戌": "亥",
            "巳": "申", "酉": "申", "丑": "申", "亥": "寅", "卯": "寅", "未": "寅"
        ]
        if let z = jiesha[yearZhi] { add("劫煞", false, { _, zz in zz == z }) }
        if let z = jiesha[dayZhi] { add("劫煞", false, { _, zz in zz == z }) }

        // 亡神（年支 / 日支查）
        let wangshen: [String: String] = [
            "申": "亥", "子": "亥", "辰": "亥", "寅": "巳", "午": "巳", "戌": "巳",
            "巳": "寅", "酉": "寅", "丑": "寅", "亥": "申", "卯": "申", "未": "申"
        ]
        if let z = wangshen[yearZhi] { add("亡神", false, { _, zz in zz == z }) }
        if let z = wangshen[dayZhi] { add("亡神", false, { _, zz in zz == z }) }

        // 魁罡（日柱）
        if ["庚辰", "壬辰", "戊戌", "庚戌"].contains(dayPillar) {
            add("魁罡", false, { g, z in g + z == dayPillar })
        }

        // 天德贵人 / 月德贵人（月支 → 天干，落在天干所在之柱）
        if let g = tianDe[monthZhi], Gan.all.contains(g) { add("天德贵人", true, { gg, _ in gg == g }) }
        if let g = yueDe[monthZhi], Gan.all.contains(g) { add("月德贵人", true, { gg, _ in gg == g }) }

        var good: [String] = [], bad: [String] = []
        for (name, isGood) in tone {
            if isGood { good.append(name) } else { bad.append(name) }
        }
        return (per, tone, good.sorted(), bad.sorted())
    }

    // MARK: - 五行统计 & 喜用神

    /// 五行统计（含藏干）
    static func wuxingCount(pillars: [Pillar]) -> [String: Int] {
        var count: [String: Int] = ["木": 0, "火": 0, "土": 0, "金": 0, "水": 0]
        for p in pillars {
            if let gi = Gan.all.firstIndex(of: p.gan) { count[Gan.wuxing[gi]]! += 1 }
            if let zi = Zhi.all.firstIndex(of: p.zhi) { count[Zhi.wuxing[zi]]! += 1 }
            for cg in p.cangGan {
                if let ci = Gan.all.firstIndex(of: cg) { count[Gan.wuxing[ci]]! += 1 }
            }
        }
        return count
    }

    /// 喜用神 / 忌神（结合身强弱与命局实缺：喜用取最缺者，忌神取最旺者）
    static func xiYongJiShen(dayGan: String, wuxing: [String: Int], isStrong: Bool) -> (xiYong: [String], jiShen: [String]) {
        let dayElem = Gan.wuxing[Gan.all.firstIndex(of: dayGan)!]
        let shengWo = ["木": "水", "火": "木", "土": "火", "金": "土", "水": "金"][dayElem]! // 印
        let woSheng = ["木": "火", "火": "土", "土": "金", "金": "水", "水": "木"][dayElem]! // 食伤
        let woKe = ["木": "土", "火": "金", "土": "水", "金": "木", "水": "火"][dayElem]!    // 财
        let keWo = ["木": "金", "火": "水", "土": "木", "金": "火", "水": "土"][dayElem]!    // 官杀

        if isStrong {
            // 身旺：喜克泄耗，取命局中最缺的两项；忌生扶，取最旺的两项
            let xi = [woSheng, woKe, keWo].sorted { (wuxing[$0] ?? 0) < (wuxing[$1] ?? 0) }
            let ji = [dayElem, shengWo].sorted { (wuxing[$0] ?? 0) > (wuxing[$1] ?? 0) }
            return (Array(xi.prefix(2)), Array(ji.prefix(2)))
        } else {
            // 身弱：喜生扶（印、比劫），忌克泄耗中最旺的两项
            let xi = [shengWo, dayElem].sorted { (wuxing[$0] ?? 0) > (wuxing[$1] ?? 0) }
            let ji = [keWo, woSheng, woKe].sorted { (wuxing[$0] ?? 0) > (wuxing[$1] ?? 0) }
            return (Array(xi.prefix(2)), Array(ji.prefix(2)))
        }
    }

    // MARK: - 胎元 / 命宫 / 身宫 / 命卦 / 星宿（问真式基本信息）

    /// 胎元：月柱天干进一位 + 月柱地支进三位（怀胎十月之月）
    static func taiYuan(monthPillar: String) -> String {
        let gan = String(monthPillar.first!)
        let zhi = String(monthPillar.last!)
        let ganIdx = Gan.all.firstIndex(of: gan) ?? 0
        let zhiIdx = Zhi.all.firstIndex(of: zhi) ?? 0
        let tGan = Gan.all[(ganIdx + 1) % 10]
        let tZhi = Zhi.all[(zhiIdx + 3) % 12]
        return tGan + tZhi
    }

    /// 命宫：正月=子逆数至生月，再从生时顺数至卯（已验证：1998 五月初... 命宫酉；2026-08-15 命宫亥）
    static func mingGong(lunarMonth: Int, shichenIndex: Int, yearGan: String) -> String {
        // 逆数生月：正月子 → Zhi[(13 - n) % 12]
        let monthZhiIdx = (13 - lunarMonth) % 12
        // 顺数生时至卯（卯下标 3）
        let offset = (3 - shichenIndex + 12) % 12
        let gongZhiIdx = (monthZhiIdx + offset) % 12
        let gongZhi = Zhi.all[gongZhiIdx]
        // 命宫天干：年上起月（五虎遁）顺数到命宫地支
        let yinGan = wuhudun(yearGan: yearGan)
        let ganOffset = (gongZhiIdx - 2 + 12) % 12
        let ganIdx = (Gan.all.firstIndex(of: yinGan)! + ganOffset) % 10
        return Gan.all[ganIdx] + gongZhi
    }

    /// 身宫：正月=子顺数至生月，再从生时顺数至酉（简化参考实现，流派差异较大）
    static func shenGong(lunarMonth: Int, shichenIndex: Int, yearGan: String) -> String {
        // 顺数生月：正月子 → Zhi[(n - 1) % 12]
        let monthZhiIdx = (lunarMonth - 1) % 12
        // 顺数生时至酉（酉下标 9）
        let offset = (9 - shichenIndex + 12) % 12
        let gongZhiIdx = (monthZhiIdx + offset) % 12
        let gongZhi = Zhi.all[gongZhiIdx]
        let yinGan = wuhudun(yearGan: yearGan)
        let ganOffset = (gongZhiIdx - 2 + 12) % 12
        let ganIdx = (Gan.all.firstIndex(of: yinGan)! + ganOffset) % 10
        return Gan.all[ganIdx] + gongZhi
    }

    /// 命卦（东四命/西四命）：以立春为界的年命推算
    static func mingGua(year: Int, month: Int, day: Int, gender: String) -> String {
        // 立春前出生，年命属上一年
        let lc = lichunDate(year: year)
        let effectiveYear = (month < lc.month || (month == lc.month && day < lc.day)) ? year - 1 : year
        let yy = effectiveYear % 100
        var digit = (yy / 10 + yy % 10) % 9
        if digit == 0 { digit = 9 }
        var num: Int
        if gender == "男" {
            num = 11 - digit
        } else {
            num = digit + 4
        }
        if num > 9 { num -= 9 }
        if num == 5 { num = (gender == "男") ? 2 : 8 } // 中宫：男寄坤，女寄艮
        let guaNames: [Int: String] = [1: "坎", 2: "坤", 3: "震", 4: "巽", 6: "乾", 7: "兑", 8: "艮", 9: "离"]
        let gua = guaNames[num] ?? ""
        let eastWest = [1, 3, 4, 9].contains(num) ? "东四命" : "西四命"
        return "\(gua)卦 · \(eastWest)"
    }

    /// 星宿：命宫地支对应的二十八宿主宿（传统十二宫配宿）
    static func xingXiu(mingGongZhi: String) -> String {
        let map: [String: String] = [
            "子": "虚宿", "丑": "斗宿", "寅": "箕宿", "卯": "房宿", "辰": "角宿", "巳": "翼宿",
            "午": "星宿", "未": "井宿", "申": "参宿", "酉": "胃宿", "戌": "娄宿", "亥": "壁宿"
        ]
        return map[mingGongZhi] ?? ""
    }

    // MARK: - 节气详情 / 格局

    /// 节气详情（如「立夏后第 9 天」）
    static func jieQiDetail(year: Int, month: Int, day: Int) -> String {
        let jieNames = ["立春", "惊蛰", "清明", "立夏", "芒种", "小暑", "立秋", "白露", "寒露", "立冬", "大雪", "小寒"]
        let mm = month >= 2 ? month : month + 12
        var prevIdx = -1
        for (i, jq) in jieQiDates.enumerated() {
            let jmm = jq.month >= 2 ? jq.month : jq.month + 12
            if mm > jmm || (mm == jmm && day >= jq.day) { prevIdx = i }
        }
        // 1 月 6 日（小寒）之前 → 属上一年大雪后
        if prevIdx == -1 {
            let jd1 = julianDay(year: year - 1, month: 12, day: 7)
            let jd2 = julianDay(year: year, month: month, day: day)
            return "大雪后第 \(jd2 - jd1) 天"
        }
        let name = jieNames[prevIdx]
        let jq = jieQiDates[prevIdx]
        let jqYear = (jq.month == 1) ? year : year
        let jd1 = julianDay(year: jqYear, month: jq.month, day: jq.day)
        let jd2 = julianDay(year: year, month: month, day: day)
        let diff = jd2 - jd1
        return diff == 0 ? "\(name)当天" : "\(name)后第 \(diff) 天"
    }

    /// 格局：按月令（月支）藏干取格（月令本气/中气/余气，取非比劫者）
    static func pattern(monthPillar: String, dayGan: String) -> String {
        let zhi = String(monthPillar.last!)
        guard let zhiIdx = Zhi.all.firstIndex(of: zhi) else { return "普通格局" }
        for g in Zhi.cangGan[zhiIdx] {
            let ss = ShiShen.of(dayGan: dayGan, targetGan: g)
            if ss != "比肩" && ss != "劫财" {
                return ss + "格"
            }
        }
        return "建禄格" // 月令为比劫
    }

    // MARK: - 胎息 / 人元司令 / 称骨 / 调候 / 旺衰三判（问真式）

    /// 胎息：日柱天干五合 + 地支六合（如 庚辰 → 乙酉）
    static func taiXi(dayPillar: String) -> String {
        let g = String(dayPillar.first!)
        let z = String(dayPillar.last!)
        let tg = GanHe.map[g] ?? g
        let tz = Zhi.liuHe[z] ?? z
        return tg + tz
    }

    /// 人元司令分野：月支各藏干司权天数（按节后天数推算当令之干）
    static let renYuanTable: [String: [(gan: String, days: Int)]] = [
        "寅": [("戊", 7), ("丙", 7), ("甲", 16)],
        "卯": [("甲", 10), ("乙", 20)],
        "辰": [("乙", 9), ("癸", 3), ("戊", 18)],
        "巳": [("戊", 5), ("庚", 9), ("丙", 16)],
        "午": [("丙", 10), ("己", 9), ("丁", 11)],
        "未": [("丁", 9), ("乙", 3), ("己", 18)],
        "申": [("己", 7), ("戊", 3), ("壬", 3), ("庚", 17)],
        "酉": [("庚", 10), ("辛", 20)],
        "戌": [("辛", 9), ("丁", 3), ("戊", 18)],
        "亥": [("戊", 7), ("甲", 5), ("壬", 18)],
        "子": [("壬", 10), ("癸", 20)],
        "丑": [("癸", 9), ("辛", 3), ("己", 18)]
    ]

    /// 人元司令：月支 + 节后天数 → 当令之干（如 庚金）
    static func renYuanSiLing(monthZhi: String, daysAfterJie: Int) -> String {
        guard let segs = renYuanTable[monthZhi], !segs.isEmpty else { return "" }
        var acc = 0
        for seg in segs {
            acc += seg.days
            if daysAfterJie < acc {
                return seg.gan + Gan.wuxing[Gan.all.firstIndex(of: seg.gan) ?? 0]
            }
        }
        let last = segs[segs.count - 1]
        return last.gan + Gan.wuxing[Gan.all.firstIndex(of: last.gan) ?? 0]
    }

    /// 出生日所属月支 + 距上一个「节」的天数
    static func jieQiOffset(year: Int, month: Int, day: Int) -> (zhi: String, days: Int) {
        let mm = month >= 2 ? month : month + 12
        var prevIdx = -1
        for (i, jq) in jieQiDates.enumerated() {
            let jmm = jq.month >= 2 ? jq.month : jq.month + 12
            if mm > jmm || (mm == jmm && day >= jq.day) { prevIdx = i }
        }
        // 小寒（1/6）之前 → 属上一年大雪（子月）
        if prevIdx == -1 {
            let jd1 = julianDay(year: year - 1, month: 12, day: 7)
            let jd2 = julianDay(year: year, month: month, day: day)
            return (Zhi.all[jieZhiIndex[10]], jd2 - jd1)
        }
        let jq = jieQiDates[prevIdx]
        let jd1 = julianDay(year: year, month: jq.month, day: jq.day)
        let jd2 = julianDay(year: year, month: month, day: day)
        return (Zhi.all[jieZhiIndex[prevIdx]], jd2 - jd1)
    }

    /// 袁天罡称骨：年柱 + 农历月 + 农历日 + 时支
    static func chengGu(yearPillar: String, lunarMonth: Int, lunarDay: Int, hourZhiIndex: Int) -> String {
        let y = ChengGu.yearTable[yearPillar] ?? 0
        let m = ChengGu.monthTable[max(0, min(11, lunarMonth - 1))]
        let d = ChengGu.dayTable[max(0, min(29, lunarDay - 1))]
        let h = ChengGu.hourTable[max(0, min(11, hourZhiIndex))]
        return ChengGu.string(totalQian: y + m + d + h)
    }

    /// 调候用神（《穷通宝鉴》概要）：日干 + 月支 → 调候天干（按优先级）
    static let tiaoHouTable: [String: String] = [
        "甲寅": "丙癸", "甲卯": "庚丙", "甲辰": "庚丁壬", "甲巳": "癸丁庚", "甲午": "癸庚丁", "甲未": "癸丁庚",
        "甲申": "庚丁壬", "甲酉": "庚丁丙", "甲戌": "庚甲丁壬", "甲亥": "庚丁丙戊", "甲子": "丁庚丙", "甲丑": "丁庚丙",
        "乙寅": "丙癸", "乙卯": "丙癸", "乙辰": "癸戊丙", "乙巳": "癸", "乙午": "癸丙", "乙未": "癸丙",
        "乙申": "癸丙", "乙酉": "癸丙丁", "乙戌": "癸辛", "乙亥": "丙戊", "乙子": "丙", "乙丑": "丙",
        "丙寅": "壬庚", "丙卯": "壬己", "丙辰": "壬甲", "丙巳": "壬癸庚", "丙午": "壬庚", "丙未": "壬庚",
        "丙申": "壬戊", "丙酉": "壬癸", "丙戌": "甲壬", "丙亥": "甲戊庚壬", "丙子": "壬戊己", "丙丑": "壬甲",
        "丁寅": "甲庚", "丁卯": "庚甲", "丁辰": "甲庚", "丁巳": "甲癸壬", "丁午": "壬癸庚", "丁未": "甲壬庚",
        "丁申": "甲庚丙戊", "丁酉": "甲庚丙戊", "丁戌": "甲庚戊", "丁亥": "甲庚", "丁子": "甲庚", "丁丑": "甲庚",
        "戊寅": "丙甲癸", "戊卯": "甲丙癸", "戊辰": "甲丙癸", "戊巳": "甲丙癸", "戊午": "壬甲丙", "戊未": "癸甲丙",
        "戊申": "丙癸甲", "戊酉": "丙癸", "戊戌": "甲丙癸", "戊亥": "甲丙", "戊子": "丙甲", "戊丑": "丙甲",
        "己寅": "丙庚甲", "己卯": "甲癸丙", "己辰": "丙甲癸", "己巳": "癸丙", "己午": "癸丙", "己未": "癸丙",
        "己申": "丙癸", "己酉": "丙癸", "己戌": "丙甲癸", "己亥": "丙甲", "己子": "丙甲", "己丑": "丙甲",
        "庚寅": "戊甲壬丙", "庚卯": "丁甲丙庚", "庚辰": "甲丁壬癸", "庚巳": "壬戊丙丁", "庚午": "壬癸戊", "庚未": "丁甲",
        "庚申": "丁甲", "庚酉": "丁甲丙", "庚戌": "甲壬", "庚亥": "丁丙", "庚子": "丁丙甲", "庚丑": "丙丁甲",
        "辛寅": "己壬庚", "辛卯": "壬甲", "辛辰": "壬甲", "辛巳": "壬癸甲", "辛午": "壬己癸", "辛未": "壬庚甲",
        "辛申": "壬甲戊", "辛酉": "壬甲", "辛戌": "壬甲", "辛亥": "壬丙", "辛子": "壬丙", "辛丑": "壬丙己",
        "壬寅": "庚丙戊", "壬卯": "戊辛庚", "壬辰": "甲庚", "壬巳": "壬癸庚辛", "壬午": "癸庚辛", "壬未": "辛甲庚",
        "壬申": "戊丁", "壬酉": "甲庚", "壬戌": "甲丙", "壬亥": "戊丙庚", "壬子": "戊丙", "壬丑": "丙戊丁",
        "癸寅": "辛庚丙", "癸卯": "庚辛", "癸辰": "丙辛甲", "癸巳": "辛庚", "癸午": "庚辛壬癸", "癸未": "庚辛壬癸",
        "癸申": "庚辛丁", "癸酉": "辛丙", "癸戌": "辛甲壬癸", "癸亥": "庚辛戊丁", "癸子": "丙辛", "癸丑": "丙丁"
    ]

    /// 调候用神（取前两位，显示为「干 + 五行」）
    static func tiaoHou(dayGan: String, monthZhi: String) -> String {
        guard let s = tiaoHouTable[dayGan + monthZhi], !s.isEmpty else { return "" }
        let stems = Array(s).prefix(2).map { String($0) }
        return stems.map { $0 + Gan.wuxing[Gan.all.firstIndex(of: $0) ?? 0] }.joined(separator: "、")
    }

    /// 旺衰三判：得令（日主在月令十二长生得地）/ 得地（地支藏干见同气或印星）/ 得势（天干比劫印星帮扶）
    static func wangShuai(dayGan: String, monthZhi: String, pillars: [Pillar], wuxing: [String: Int])
        -> (deLing: Bool, deDi: Bool, deShi: Bool, strength: String, topTwo: String) {
        let dayElem = Gan.wuxing[Gan.all.firstIndex(of: dayGan)!]
        let shengWo = ["木": "水", "火": "木", "土": "火", "金": "土", "水": "金"][dayElem]!

        // 得令：日主在月令处于生旺之地
        let yueState = XingYun.state(gan: dayGan, zhi: monthZhi)
        let deLing = ["长生", "冠带", "临官", "帝旺", "养"].contains(yueState)

        // 得地：地支本气或藏干见日主同气 / 印星
        var deDi = false
        for p in pillars {
            if Zhi.wuxing[Zhi.all.firstIndex(of: p.zhi) ?? 0] == dayElem { deDi = true }
            for cg in p.cangGan {
                let e = Gan.wuxing[Gan.all.firstIndex(of: cg) ?? 0]
                if e == dayElem || e == shengWo { deDi = true }
            }
        }

        // 得势：天干见比劫或印星 ≥ 2
        let help = pillars.filter { ["比肩", "劫财", "正印", "偏印"].contains($0.shiShen) }.count
        let deShi = help >= 2

        let score = (deLing ? 1 : 0) + (deDi ? 1 : 0) + (deShi ? 1 : 0)
        let strength = score >= 2 ? "身旺" : "身弱"
        let topTwo = wuxing.sorted { $0.value > $1.value }.prefix(2).map { $0.key }.joined(separator: "")
        return (deLing, deDi, deShi, strength, topTwo)
    }

    // MARK: - 主入口：完整排盘

    static func calculate(name: String, gender: String, solarDate: String, hour: String, place: String) -> BaziChart {
        // 解析日期
        let dateParts = solarDate.split(separator: "-").compactMap { Int($0) }
        let year = dateParts.count > 0 ? dateParts[0] : 1990
        let month = dateParts.count > 1 ? dateParts[1] : 5
        let day = dateParts.count > 2 ? dateParts[2] : 15
        let hourParts = hour.split(separator: ":").compactMap { Int($0) }
        let hh = hourParts.count > 0 ? hourParts[0] : 12
        let mm = hourParts.count > 1 ? hourParts[1] : 0

        // 真太阳时
        let lonOffset = longitudeOffset(place: place)
        let trueTotalMinutes = hh * 60 + mm + lonOffset
        let trueHour = (trueTotalMinutes / 60 + 24) % 24
        let trueMinute = (trueTotalMinutes % 60 + 60) % 60
        let trueSolarTime = String(format: "%02d:%02d", trueHour, trueMinute)

        // 四柱
        let yp = yearPillar(year: year, month: month, day: day)
        let mp = monthPillar(year: year, month: month, day: day)
        let jdn = julianDay(year: year, month: month, day: day)
        let dp = liushiJiazi[dayPillarIndex(jdn: jdn)]
        let dayGan = String(dp.first!)
        let hp = hourPillar(dayGan: dayGan, hour: trueHour, minute: trueMinute)

        // 神煞（逐柱归属 + 吉凶表）
        let ssDetail = shenShaDetail(dayPillar: dp, yearPillar: yp, monthPillar: mp, hourPillar: hp)

        // 构建四柱
        // 星运 = 日主对本柱地支的十二长生；自坐 = 本柱天干对本柱地支；空亡 = 本柱所在旬
        func buildPillar(_ gz: String, isDay: Bool, index: Int) -> Pillar {
            let g = String(gz.first!)
            let z = String(gz.last!)
            let ss = isDay ? "日主" : ShiShen.of(dayGan: dayGan, targetGan: g)
            let cg = Zhi.cangGan[Zhi.all.firstIndex(of: z)!]
            let cgSS = cg.map { ShiShen.of(dayGan: dayGan, targetGan: $0) }
            let ny = NaYin.map[gz] ?? ""
            let xy = XingYun.state(gan: dayGan, zhi: z)
            let zz = XingYun.state(gan: g, zhi: z)
            return Pillar(gan: g, zhi: z, shiShen: ss, cangGan: cg, cangGanShiShen: cgSS,
                          naYin: ny, xingYun: xy, ziZuo: zz,
                          kongWang: kongWang(ganzhi: gz), shenSha: ssDetail.perPillar[index])
        }
        let pillars = [buildPillar(yp, isDay: false, index: 0),
                       buildPillar(mp, isDay: false, index: 1),
                       buildPillar(dp, isDay: true, index: 2),
                       buildPillar(hp, isDay: false, index: 3)]

        // 五行统计
        let wuxing = wuxingCount(pillars: pillars)
        // 日主 + 旺衰三判 + 格局
        let dayElem = Gan.wuxing[Gan.all.firstIndex(of: dayGan)!]
        let dayMaster = dayGan + dayElem
        let monthZhi = String(mp.last!)
        let ws = wangShuai(dayGan: dayGan, monthZhi: monthZhi, pillars: pillars, wuxing: wuxing)
        let strength = ws.strength
        let pattern = self.pattern(monthPillar: mp, dayGan: dayGan)

        // 喜用神 / 忌神（结合旺衰与命局实缺）+ 综合解读
        let isStrong = strength == "身旺"
        let (xiyong, jishen) = xiYongJiShen(dayGan: dayGan, wuxing: wuxing, isStrong: isStrong)
        let strengthNote = isStrong
            ? "\(ws.topTwo)偏旺，宜\(xiyong.joined(separator: "、"))泄秀调候"
            : "日主偏弱，宜\(xiyong.joined(separator: "、"))生扶为要"

        // 大运
        let dy = daYun(year: year, month: month, day: day, hour: hh, gender: gender, monthPillar: mp)

        // 流年（当前年 + 9 年）
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let ln = liuNian(dayGan: dayGan, fromYear: currentYear, count: 10)

        // 当前大运下标
        let age = currentYear - year
        var curDyIndex = 0
        for (i, d) in dy.list.enumerated() {
            if age >= d.startAge && age <= d.endAge { curDyIndex = i }
        }

        // MARK: 问真式基本信息（生肖/星座/农历/节气/胎元/命宫/身宫/命卦/星宿）
        let shengxiao = LunarCalendar.shengXiao(yearPillar: yp)
        let xingzuo = LunarCalendar.xingZuo(month: month, day: day)
        let lunar = LunarCalendar.solarToLunar(year: year, month: month, day: day)
        let lunarDate = LunarCalendar.lunarString(solarYear: year, month: month, day: day, ganzhiYear: yp)
        let jieQiDetailStr = jieQiDetail(year: year, month: month, day: day)
        let taiYuanStr = taiYuan(monthPillar: mp)
        let taiYuanFull = "\(taiYuanStr)·\(NaYin.map[taiYuanStr] ?? "")"
        let yearGan = String(yp.first!)
        let shichenIdx = hourZhiIndex(hour: trueHour, minute: trueMinute)
        let mingGongStr = mingGong(lunarMonth: lunar.month, shichenIndex: shichenIdx, yearGan: yearGan)
        let shenGongStr = shenGong(lunarMonth: lunar.month, shichenIndex: shichenIdx, yearGan: yearGan)
        let mingGuaStr = mingGua(year: year, month: month, day: day, gender: gender)
        let xingXiuStr = xingXiu(mingGongZhi: String(mingGongStr.last!))
        // 胎息 / 人元司令 / 称骨 / 调候
        let taiXiStr = taiXi(dayPillar: dp)
        let jqOffset = jieQiOffset(year: year, month: month, day: day)
        let renYuanStr = renYuanSiLing(monthZhi: jqOffset.zhi, daysAfterJie: jqOffset.days)
        let chengGuStr = chengGu(yearPillar: yp, lunarMonth: lunar.month, lunarDay: lunar.day, hourZhiIndex: shichenIdx)
        let tiaoHouStr = tiaoHou(dayGan: dayGan, monthZhi: monthZhi)

        return BaziChart(
            name: name, gender: gender, solarDate: solarDate, hour: hour, place: place,
            trueSolarTime: trueSolarTime, longitudeOffset: lonOffset,
            shengxiao: shengxiao, xingzuo: xingzuo, lunarDate: lunarDate,
            jieQiDetail: jieQiDetailStr, taiYuan: taiYuanFull, taiXi: taiXiStr,
            mingGong: mingGongStr, shenGong: shenGongStr,
            mingGua: mingGuaStr, xingXiu: xingXiuStr,
            renYuanSiLing: renYuanStr, chengGu: chengGuStr, qiYunDetail: dy.start,
            pillars: pillars, dayMaster: dayMaster, strength: strength,
            deLing: ws.deLing, deDi: ws.deDi, deShi: ws.deShi,
            strengthNote: strengthNote, pattern: pattern, tiaoHou: tiaoHouStr,
            wuxingCount: wuxing,
            goodShenSha: ssDetail.good, badShenSha: ssDetail.bad, shenShaTone: ssDetail.tone,
            xiYong: xiyong, jiShen: jishen,
            dayunDirection: dy.direction, dayunStart: dy.start, dayun: dy.list,
            liunian: ln, currentDayunIndex: curDyIndex
        )
    }
}
