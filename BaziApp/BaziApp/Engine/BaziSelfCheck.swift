import Foundation

/// 排盘引擎自检 —— 用公开可查的历法锚点命例校验算法正确性
/// 锚点均为权威历法事实（非本 App 自算），通过即证明四柱/农历算法与公认历法一致。
/// 结果在「我的」页展示，让用户对排盘准确率有可验证的依据。
enum BaziSelfCheck {

    // MARK: - 校验项定义

    private struct GanzhiCase {
        let name: String
        let solar: String
        let expected: [String]   // 年/月/日/时 四柱干支（时柱按 12:00 北京时间排，午时）
    }

    /// 四柱锚点（起午时 12:00，北京真太阳时约 11:47，仍属午时，不跨时辰）
    private static let ganzhiCases: [GanzhiCase] = [
        .init(name: "1949-10-01 开国大典（史载甲子日）", solar: "1949-10-01",
              expected: ["己丑", "癸酉", "甲子", "庚午"]),
        .init(name: "2000-01-01 跨年（戊午日）", solar: "2000-01-01",
              expected: ["己卯", "丙子", "戊午", "戊午"]),
        .init(name: "2024-02-10 春节（甲辰年甲辰日）", solar: "2024-02-10",
              expected: ["甲辰", "丙寅", "甲辰", "庚午"]),
        .init(name: "1990-05-15 示例盘（庚辰日）", solar: "1990-05-15",
              expected: ["庚午", "辛巳", "庚辰", "壬午"]),
    ]

    /// 农历正反算往返锚点（公历 → 农历 → 公历 必须还原）
    private static let lunarRoundTrip: [(String, Int, Int, Int)] = [
        ("1990-05-15", 1990, 5, 15),
        ("2000-01-01", 2000, 1, 1),
        ("2024-02-10", 2024, 2, 10),
        ("2024-09-17 中秋", 2024, 9, 17),
        ("1984-02-02", 1984, 2, 2),
    ]

    // MARK: - 对拍基线（parity.json）

    struct ParityCase {
        let dt: String
        let city: String
        let gender: String
        let tst: Bool
        let pillars: [String]
    }

    /// lunar-python 权威引擎导出的对拍锚点盘（立春/节气交界、晚子时、极端经度、闰月等）
    private static let parityCases: [ParityCase] = {
        guard let url = Bundle.main.url(forResource: "parity", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let cases = obj["cases"] as? [[String: Any]] else { return [] }
        return cases.compactMap { c in
            guard let dt = c["dt"] as? String,
                  let city = c["city"] as? String,
                  let gender = c["gender"] as? String,
                  let tst = c["tst"] as? Bool,
                  let pillars = c["pillars"] as? [String] else { return nil }
            return ParityCase(dt: dt, city: city, gender: gender, tst: tst, pillars: pillars)
        }
    }()

    /// 大运对拍锚点（lunar-python 权威导出：起运年月天 / 交运日 / 前 4 步大运）
    private struct DayunCase {
        let dt: String
        let gender: String
        let start: [Int]
        let qiyun: String
        let dayun: [[String: Any]]
    }

    private static let dayunCases: [DayunCase] = {
        guard let url = Bundle.main.url(forResource: "dayun-parity", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let cases = obj["cases"] as? [[String: Any]] else { return [] }
        return cases.compactMap { c in
            guard let dt = c["dt"] as? String,
                  let gender = c["gender"] as? String,
                  let start = c["start"] as? [Int],
                  let qiyun = c["qiyun"] as? String,
                  let dayun = c["dayun"] as? [[String: Any]] else { return nil }
            return DayunCase(dt: dt, gender: gender, start: start, qiyun: qiyun, dayun: dayun)
        }
    }()

    // MARK: - 执行

    struct Item {
        let name: String
        let ok: Bool
        let detail: String   // 通过时显示实际排盘；失败时显示期望 vs 实际
    }

    struct Result {
        let passed: Int
        let total: Int
        let items: [Item]

        var summary: String { "\(passed)/\(total) 通过" }
    }

    private static var cached: Result?

    static func run() -> Result {
        if let c = cached { return c }
        var items: [Item] = []

        // 四柱锚点
        for tc in ganzhiCases {
            let chart = BaziCalculator.calculate(name: "自检", gender: "男",
                                                 solarDate: tc.solar, hour: "12:00",
                                                 place: "北京", useTrueSolar: true)
            let actual = chart.pillars.map { $0.ganzhi }
            let ok = actual == tc.expected
            let detail = ok
                ? actual.joined(separator: " ")
                : "期望 \(tc.expected.joined(separator: " "))，实际 \(actual.joined(separator: " "))"
            items.append(Item(name: tc.name, ok: ok, detail: detail))
        }

        // 农历往返
        for (name, y, m, d) in lunarRoundTrip {
            let lunar = LunarCalendar.solarToLunar(year: y, month: m, day: d)
            let back = LunarCalendar.lunarToSolar(lunar.year, lunar.month, isLeap: lunar.isLeap, lunar.day)
            let ok = back != nil && back!.year == y && back!.month == m && back!.day == d
            let detail = ok
                ? "农历 \(lunar.year)年\(lunar.isLeap ? "闰" : "")\(lunar.month)月\(lunar.day)日 ⇄ 还原一致"
                : "往返失败：\(lunar.year)年\(lunar.isLeap ? "闰" : "")\(lunar.month)月\(lunar.day)日 → \(back.map { "\($0.year)-\($0.month)-\($0.day)" } ?? "nil")"
            items.append(Item(name: "农历往返 \(name)", ok: ok, detail: detail))
        }

        // 引擎对拍（parity.json：lunar-python 6tail 权威基线，447 例含边界）
        for (i, pc) in Self.parityCases.enumerated() {
            let chart = BaziCalculator.calculate(name: "对拍", gender: pc.gender,
                                                 solarDate: String(pc.dt.prefix(10)),
                                                 hour: String(pc.dt.suffix(5)),
                                                 place: pc.city, useTrueSolar: pc.tst)
            let actual = chart.pillars.map { $0.ganzhi }
            let ok = actual == pc.pillars
            let detail = ok
                ? "\(pc.dt) \(pc.city)\(pc.tst ? " 真太阳时" : "") ✓"
                : "\(pc.dt) \(pc.city)：期望 \(pc.pillars.joined(separator: " "))，实际 \(actual.joined(separator: " "))"
            items.append(Item(name: "对拍 \(i + 1)", ok: ok, detail: detail))
        }

        // 大运对拍（dayun-parity.json：起运 + 前 4 步大运，lunar-python 权威口径）
        for (i, dc) in Self.dayunCases.enumerated() {
            let chart = BaziCalculator.calculate(name: "对拍", gender: dc.gender,
                                                 solarDate: String(dc.dt.prefix(10)),
                                                 hour: String(dc.dt.suffix(5)),
                                                 place: "北京", useTrueSolar: false)
            var fails: [String] = []
            if dc.start[0] > 0, !chart.qiYunDetail.contains("起运 \(dc.start[0])年") { fails.append("起运年") }
            if !chart.qiYunDetail.contains("\(dc.start[1])个月") { fails.append("起运月") }
            if !chart.qiYunDetail.contains("个月\(dc.start[2])天") { fails.append("起运天") }
            if !chart.qiYunDetail.contains(dc.qiyun) { fails.append("交运日") }
            for (k, exp) in dc.dayun.enumerated() {
                guard chart.dayun.indices.contains(k) else {
                    fails.append("第\(k + 1)步缺失")
                    break
                }
                let act = chart.dayun[k]
                let egz = exp["gz"] as? String ?? ""
                let esy = exp["sy"] as? Int ?? 0
                let eey = exp["ey"] as? Int ?? 0
                let esa = exp["sa"] as? Int ?? 0
                let eea = exp["ea"] as? Int ?? 0
                if act.ganzhi != egz || act.startYear != esy || act.endYear != eey
                    || act.startAge != esa || act.endAge != eea {
                    fails.append("第\(k + 1)步 期望\(egz)/\(esy)/\(esa)岁 实际\(act.ganzhi)/\(act.startYear)/\(act.startAge)岁")
                    break
                }
            }
            let ok = fails.isEmpty
            let detail = ok
                ? "\(dc.dt) \(dc.gender) \(chart.qiYunDetail) ✓"
                : "\(dc.dt) \(dc.gender)：\(fails.joined(separator: "；"))"
            items.append(Item(name: "大运对拍 \(i + 1)", ok: ok, detail: detail))
        }

        let result = Result(passed: items.filter { $0.ok }.count,
                            total: items.count,
                            items: items)
        cached = result
        return result
    }
}
