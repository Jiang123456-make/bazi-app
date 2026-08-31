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

    /// 主要城市经度（东经）
    static let cityLongitude: [String: Double] = [
        "北京": 116.4, "上海": 121.5, "广州": 113.3, "深圳": 114.1,
        "成都": 104.1, "重庆": 106.5, "西安": 108.9, "武汉": 114.3,
        "南京": 118.8, "杭州": 120.2, "天津": 117.2, "乌鲁木齐": 87.6,
        "拉萨": 91.1, "昆明": 102.7, "哈尔滨": 126.6, "沈阳": 123.4
    ]

    /// 经度时差（分钟）：(经度 - 120°) × 4
    static func longitudeOffset(place: String) -> Int {
        let lon = cityLongitude[place] ?? 116.4
        return Int(round((lon - 120.0) * 4))
    }

    // MARK: - 空亡（旬空）

    /// 日柱 → 空亡地支
    static func kongWang(dayPillar: String) -> String {
        // 旬首（甲子/甲戌/甲申/甲午/甲辰/甲寅）
        let gan = String(dayPillar.first!)
        let ganIndex = Gan.all.firstIndex(of: gan)!
        let xunIndex = ganIndex / 10 * 10 // 旬首在六十甲子中的下标（甲子=0, 甲戌=10, ...）
        let kongStart = (xunIndex + 8) % 12 // 空亡起始地支下标
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

        // 起运年龄 = 出生到最近节的天数 ÷ 3（简化：按日估算）
        // MVP：简化起运年龄为固定估算（精确需节气分钟级）
        let startAge = estimateStartAge(year: year, month: month, day: day, shun: shun)

        var list: [DaYun] = []
        for step in 0..<8 {
            let offset = shun ? (step + 1) : -(step + 1)
            let gz = liushiJiazi[(mpIndex + offset + 60) % 60]
            let dayGan = dayMasterGan(year: year, month: month, day: day)
            let ss = ShiShen.of(dayGan: dayGan, targetGan: String(gz.first!))
            let age = startAge + step * 10
            list.append(DaYun(ganzhi: gz, shiShen: ss, startAge: age, endAge: age + 9))
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

    // MARK: - 神煞（主要）

    /// 神煞（简化：主要神煞）
    static func shenSha(dayPillar: String, yearPillar: String, monthPillar: String, hourPillar: String) -> (good: [String], bad: [String]) {
        var good: [String] = []
        var bad: [String] = []

        let dayGan = String(dayPillar.first!)
        let dayZhi = String(dayPillar.last!)
        let yearZhi = String(yearPillar.last!)

        // 天乙贵人（日干查）
        let tianyi: [String: [String]] = [
            "甲": ["丑", "未"], "戊": ["丑", "未"],
            "乙": ["子", "申"], "己": ["子", "申"],
            "丙": ["亥", "酉"], "丁": ["亥", "酉"],
            "庚": ["丑", "未"], "辛": ["寅", "午"],
            "壬": ["卯", "巳"], "癸": ["卯", "巳"]
        ]
        if let zhi = tianyi[dayGan], zhi.contains(where: { [$0, $0].contains(dayZhi) || yearZhi == $0 || dayZhi == $0 }) {
            good.append("天乙贵人")
        }

        // 文昌（日干查）
        let wenchang: [String: String] = [
            "甲": "巳", "乙": "午", "丙": "申", "丁": "酉", "戊": "申",
            "己": "酉", "庚": "亥", "辛": "子", "壬": "寅", "癸": "卯"
        ]
        if wenchang[dayGan] == dayZhi { good.append("文昌") }

        // 桃花（日支查）
        let taohua: [String: String] = [
            "申": "酉", "子": "酉", "辰": "酉",
            "寅": "卯", "午": "卯", "戌": "卯",
            "巳": "午", "酉": "午", "丑": "午",
            "亥": "子", "卯": "子", "未": "子"
        ]
        if taohua[yearZhi] == dayZhi || taohua[dayZhi] == dayZhi { good.append("桃花") }

        // 驿马（日支查）
        let yima: [String: String] = [
            "申": "寅", "子": "寅", "辰": "寅",
            "寅": "申", "午": "申", "戌": "申",
            "巳": "亥", "酉": "亥", "丑": "亥",
            "亥": "巳", "卯": "巳", "未": "巳"
        ]
        if yima[dayZhi] == yearZhi { good.append("驿马") }

        // 将星（日支查）
        let jiangxing: [String: String] = [
            "申": "子", "子": "子", "辰": "子",
            "寅": "午", "午": "午", "戌": "午",
            "巳": "酉", "酉": "酉", "丑": "酉",
            "亥": "卯", "卯": "卯", "未": "卯"
        ]
        if jiangxing[dayZhi] == dayZhi { good.append("将星") }

        // 华盖（日支查）
        let huagai: [String: String] = [
            "申": "辰", "子": "辰", "辰": "辰",
            "寅": "戌", "午": "戌", "戌": "戌",
            "巳": "丑", "酉": "丑", "丑": "丑",
            "亥": "未", "卯": "未", "未": "未"
        ]
        if huagai[dayZhi] == dayZhi { good.append("华盖") }

        // 魁罡（日柱查）
        let kuigang = ["庚辰", "壬辰", "戊戌", "庚戌"]
        if kuigang.contains(dayPillar) { bad.append("魁罡") }

        // 羊刃（日干查）
        let yangren: [String: String] = [
            "甲": "卯", "乙": "辰", "丙": "午", "丁": "未", "戊": "午",
            "己": "未", "庚": "酉", "辛": "戌", "壬": "子", "癸": "丑"
        ]
        if yangren[dayGan] == dayZhi { bad.append("羊刃") }

        // 劫煞 / 亡神（简化，用日支三合）
        let jiesha: [String: String] = [
            "申": "巳", "子": "巳", "辰": "巳",
            "寅": "亥", "午": "亥", "戌": "亥",
            "巳": "申", "酉": "申", "丑": "申",
            "亥": "寅", "卯": "寅", "未": "寅"
        ]
        if jiesha[dayZhi] == yearZhi { bad.append("劫煞") }

        let wangshen: [String: String] = [
            "申": "亥", "子": "亥", "辰": "亥",
            "寅": "巳", "午": "巳", "戌": "巳",
            "巳": "寅", "酉": "寅", "丑": "寅",
            "亥": "申", "卯": "申", "未": "申"
        ]
        if wangshen[dayZhi] == yearZhi { bad.append("亡神") }

        return (good, bad)
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

    /// 简化喜用神判断（日主旺衰 → 喜忌）
    static func xiYongJiShen(dayGan: String, wuxing: [String: Int]) -> (xiYong: [String], jiShen: [String]) {
        let dayElem = Gan.wuxing[Gan.all.firstIndex(of: dayGan)!]
        let dayCount = wuxing[dayElem] ?? 0
        let shengWoElem = ["木": "水", "火": "木", "土": "火", "金": "土", "水": "金"][dayElem]!
        let shengCount = wuxing[shengWoElem] ?? 0
        // 身旺（日主 + 生扶 >= 其他）
        let isStrong = (dayCount + shengCount) >= 6

        if isStrong {
            // 身旺：喜克泄耗（克我=官杀、我生=食伤、我克=财），忌生扶（印、比劫）
            let keWoElem = ["木": "金", "火": "水", "土": "木", "金": "火", "水": "土"][dayElem]!
            let woShengElem = ["木": "火", "火": "土", "土": "金", "金": "水", "水": "木"][dayElem]!
            let woKeElem = ["木": "土", "火": "金", "土": "水", "金": "木", "水": "火"][dayElem]!
            return ([keWoElem, woShengElem, woKeElem], [shengWoElem, dayElem])
        } else {
            // 身弱：喜生扶（印、比劫），忌克泄耗
            let keWoElem = ["木": "金", "火": "水", "土": "木", "金": "火", "水": "土"][dayElem]!
            return ([shengWoElem, dayElem], [keWoElem, dayElem])
        }
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

        // 构建四柱
        func buildPillar(_ gz: String, isDay: Bool) -> Pillar {
            let g = String(gz.first!)
            let z = String(gz.last!)
            let ss = isDay ? "日主" : ShiShen.of(dayGan: dayGan, targetGan: g)
            let cg = Zhi.cangGan[Zhi.all.firstIndex(of: z)!]
            let cgSS = cg.map { ShiShen.of(dayGan: dayGan, targetGan: $0) }
            let ny = NaYin.map[gz] ?? ""
            let xy = XingYun.state(gan: g, zhi: z)
            let kw = isDay ? kongWang(dayPillar: dp) : ""
            return Pillar(gan: g, zhi: z, shiShen: ss, cangGan: cg, cangGanShiShen: cgSS, naYin: ny, xingYun: xy, kongWang: kw)
        }
        // 空亡用日柱所在旬，四柱同空亡（简化：月/日/时同旬空，年柱单独）
        let kwAll = kongWang(dayPillar: dp)
        let ypPillar = Pillar(gan: String(yp.first!), zhi: String(yp.last!),
                              shiShen: ShiShen.of(dayGan: dayGan, targetGan: String(yp.first!)),
                              cangGan: Zhi.cangGan[Zhi.all.firstIndex(of: String(yp.last!))!],
                              cangGanShiShen: Zhi.cangGan[Zhi.all.firstIndex(of: String(yp.last!))!].map { ShiShen.of(dayGan: dayGan, targetGan: $0) },
                              naYin: NaYin.map[yp] ?? "",
                              xingYun: XingYun.state(gan: String(yp.first!), zhi: String(yp.last!)),
                              kongWang: kongWang(dayPillar: yp))
        let mpPillar = buildPillar(mp, isDay: false)
        let dpPillar = buildPillar(dp, isDay: true)
        let hpPillar = buildPillar(hp, isDay: false)
        // 修正月/日/时柱空亡（同旬）
        let mpFixed = Pillar(gan: mpPillar.gan, zhi: mpPillar.zhi, shiShen: mpPillar.shiShen, cangGan: mpPillar.cangGan, cangGanShiShen: mpPillar.cangGanShiShen, naYin: mpPillar.naYin, xingYun: mpPillar.xingYun, kongWang: kwAll)
        let dpFixed = Pillar(gan: dpPillar.gan, zhi: dpPillar.zhi, shiShen: dpPillar.shiShen, cangGan: dpPillar.cangGan, cangGanShiShen: dpPillar.cangGanShiShen, naYin: dpPillar.naYin, xingYun: dpPillar.xingYun, kongWang: kwAll)
        let hpFixed = Pillar(gan: hpPillar.gan, zhi: hpPillar.zhi, shiShen: hpPillar.shiShen, cangGan: hpPillar.cangGan, cangGanShiShen: hpPillar.cangGanShiShen, naYin: hpPillar.naYin, xingYun: hpPillar.xingYun, kongWang: kwAll)

        let pillars = [ypPillar, mpFixed, dpFixed, hpFixed]

        // 五行统计
        let wuxing = wuxingCount(pillars: pillars)
        // 日主 + 身强弱 + 格局
        let dayElem = Gan.wuxing[Gan.all.firstIndex(of: dayGan)!]
        let dayMaster = dayGan + dayElem
        let strength = wuxing[dayElem]! >= 3 ? "身旺" : "身弱"
        let pattern = "食神生财" // MVP 简化格局（可后续按月令透干细化）

        // 神煞
        let ss = shenSha(dayPillar: dp, yearPillar: yp, monthPillar: mp, hourPillar: hp)

        // 喜用神
        let (xiyong, jishen) = xiYongJiShen(dayGan: dayGan, wuxing: wuxing)

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

        return BaziChart(
            name: name, gender: gender, solarDate: solarDate, hour: hour, place: place,
            trueSolarTime: trueSolarTime, longitudeOffset: lonOffset,
            pillars: pillars, dayMaster: dayMaster, strength: strength, pattern: pattern,
            wuxingCount: wuxing, goodShenSha: ss.good, badShenSha: ss.bad,
            xiYong: xiyong, jiShen: jishen,
            dayunDirection: dy.direction, dayunStart: dy.start, dayun: dy.list,
            liunian: ln, currentDayunIndex: curDyIndex
        )
    }
}
