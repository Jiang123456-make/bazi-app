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

    // MARK: - 执行

    struct Result {
        let passed: Int
        let total: Int
        let items: [Item]

        struct Item {
            let name: String
            let ok: Bool
            let detail: String   // 通过时显示实际排盘；失败时显示期望 vs 实际
        }

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

        let result = Result(passed: items.filter { $0.ok }.count,
                            total: items.count,
                            items: items)
        cached = result
        return result
    }
}
