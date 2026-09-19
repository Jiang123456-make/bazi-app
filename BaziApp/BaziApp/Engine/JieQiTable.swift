import Foundation

/// 节气精确时刻表（寿星天文历口径，由 lunar-python 6tail 导出，Resources/jieqi.json 随包分发）
/// 用途：年柱立春分界、月柱十二节分界 —— 分钟级精度，替代旧的「固定 2 月 4 日」日级近似。
/// 顺序：0 立春 / 1 惊蛰 / 2 清明 / 3 立夏 / 4 芒种 / 5 小暑 / 6 立秋 / 7 白露 / 8 寒露 / 9 立冬 / 10 大雪 / 11 小寒
enum JieQiTable {

    struct Moment: Comparable {
        let month: Int
        let day: Int
        let hour: Int
        let minute: Int

        static func < (l: Moment, r: Moment) -> Bool {
            (l.month, l.day, l.hour, l.minute) < (r.month, r.day, r.hour, r.minute)
        }
    }

    private static let table: [String: [[Int]]] = {
        guard let url = Bundle.main.url(forResource: "jieqi", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let y = obj["y"] as? [String: [[Int]]] else { return [:] }
        return y
    }()

    /// JSON 是否加载成功（失败时引擎回落到旧的日级近似）
    static var isLoaded: Bool { !table.isEmpty }

    /// year 年第 index 个节的精确时刻（0=立春…10=大雪 在当年；11=小寒 在当年 1 月）
    static func moment(year: Int, index: Int) -> Moment? {
        guard let arr = table[String(year)], index >= 0, index < arr.count,
              arr[index].count == 4 else { return nil }
        return Moment(month: arr[index][0], day: arr[index][1], hour: arr[index][2], minute: arr[index][3])
    }

    /// 年柱的有效年份：立春精确时刻前出生属上一年
    /// （1 月必在立春前；2 月与立春时刻逐分比较；3-12 月必在当年立春后）
    static func effectiveYear(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Int {
        if month == 1 { return year - 1 }
        if month > 2 { return year }
        if let lc = moment(year: year, index: 0) {
            let birth = Moment(month: month, day: day, hour: hour, minute: minute)
            return birth < lc ? year - 1 : year
        }
        return day < 4 ? year - 1 : year   // JSON 缺失时回落：2 月 4 日前
    }

    /// 月柱分界：返回 (节下标 0…11, 年柱有效年份, 月支下标)
    /// 规则：找出生时刻之前最近的节；小寒（1 月）及其后的丑月段（2 月初立春前）年柱属上一年
    static func jieBoundary(year: Int, month: Int, day: Int, hour: Int, minute: Int)
        -> (jieIndex: Int, effectiveYear: Int, zhiIndex: Int)? {
        let birth = Moment(month: month, day: day, hour: hour, minute: minute)

        // 从大雪（12 月）倒查到立春（2 月）
        if month >= 2 {
            for i in stride(from: 10, through: 0, by: -1) {
                if let m = moment(year: year, index: i), birth >= m {
                    return (i, year, zhiIndex(of: i))
                }
            }
            // 2 月初、立春前 → 属上一年周期的小寒（丑月），年柱属上一年
            if month == 2, let _ = moment(year: year, index: 11) {
                return (11, year - 1, zhiIndex(of: 11))
            }
            return nil
        }

        // 1 月：小寒（当年 1 月）之后 → 丑月，年柱属上一年；之前 → 上年大雪之后的子月？——
        // 子月是上年 12 月大雪起；1 月出生且在小寒前，仍属子月（大雪→小寒之间），年柱属上上一年周期？
        // 注意：子月+丑月都在立春前，年柱都属 y-1；月柱五虎遁以年柱为准。
        if let xh = moment(year: year, index: 11), birth >= xh {
            return (11, year - 1, zhiIndex(of: 11))
        }
        if let ds = moment(year: year - 1, index: 10) {
            return (10, year - 1, zhiIndex(of: 10))
        }
        return nil
    }

    /// 节下标 → 月支下标（立春寅 2 … 大雪子 0，小寒丑 1）
    static func zhiIndex(of jieIndex: Int) -> Int {
        (jieIndex + 2) % 12
    }
}
