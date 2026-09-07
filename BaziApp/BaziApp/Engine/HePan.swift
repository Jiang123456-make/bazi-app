import Foundation

/// 合盘结果（双方八字关系分析，参考问真合盘口径）
struct HePanResult: Codable, Hashable {
    /// 甲方命盘
    let a: BaziChart
    /// 乙方命盘
    let b: BaziChart
    /// 生肖关系（六合 / 三合 / 六冲 / 中性）
    let zodiacRelation: String
    /// 生肖关系说明
    let zodiacNote: String
    /// 日柱关系（天合地合 / 天干五合 / 地支六合 / 无相合）
    let dayRelation: String
    /// 日柱关系说明
    let dayNote: String
    /// 双方日主十神关系（如 正财）
    let masterRelation: String
    /// 五行互补说明
    let complementNote: String
    /// 合婚参考分（60-95，仅供文化娱乐）
    let score: Int
    /// 结论条目
    let summary: [String]
}

/// 合盘引擎：生肖（年支）关系 + 日柱天合地合 + 双方日主生克 + 五行互补
enum HePan {

    /// 地支六冲（子午、丑未、寅申、卯酉、辰戌、巳亥）
    private static let chongPairs: Set<String> = [
        "子午", "丑未", "寅申", "卯酉", "辰戌", "巳亥",
        "午子", "未丑", "申寅", "酉卯", "戌辰", "亥巳"
    ]

    static func calculate(a: BaziChart, b: BaziChart) -> HePanResult {
        let aYearZhi = String(a.pillars[0].zhi)
        let bYearZhi = String(b.pillars[0].zhi)
        let aDay = a.pillars[2]
        let bDay = b.pillars[2]
        var score = 72

        // MARK: 生肖（年支）关系
        var zodiacRelation = "中性"
        var zodiacNote = "两个属相无特殊组合，看双方整体五行搭配"
        if Zhi.liuHe[aYearZhi] == bYearZhi {
            zodiacRelation = "六合"
            score += 8
            zodiacNote = "属\(a.shengxiao)与属\(b.shengxiao)六合，气场相投，天生容易亲近"
        } else if chongPairs.contains(aYearZhi + bYearZhi) {
            zodiacRelation = "六冲"
            score -= 12
            zodiacNote = "属\(a.shengxiao)与属\(b.shengxiao)六冲，个性差异较大，需多包容磨合"
        } else if let wang = Zhi.sanHeWang[aYearZhi], wang == Zhi.sanHeWang[bYearZhi] {
            zodiacRelation = "三合"
            score += 6
            zodiacNote = "属\(a.shengxiao)与属\(b.shengxiao)三合，志趣相投，合作无间"
        }

        // MARK: 日柱（夫妻宫）关系：天干五合 + 地支六合
        let ganHe = GanHe.map[aDay.gan] == bDay.gan
        let zhiHe = Zhi.liuHe[aDay.zhi] == bDay.zhi
        let dayRelation: String
        var dayNote = "日柱无相合，相处方式偏平淡务实"
        if ganHe && zhiHe {
            dayRelation = "天合地合"
            score += 10
            dayNote = "\(aDay.ganzhi)与\(bDay.ganzhi)天干五合、地支六合，夫妻宫互为组合，极为难得"
        } else if ganHe {
            dayRelation = "天干五合"
            score += 5
            dayNote = "双方日主天干五合（\(aDay.gan)\(bDay.gan)合），性情互补"
        } else if zhiHe {
            dayRelation = "地支六合"
            score += 5
            dayNote = "双方日支六合（\(aDay.zhi)\(bDay.zhi)合），夫妻宫相合，居家和睦"
        } else {
            dayRelation = "无相合"
        }

        // MARK: 双方日主生克（乙方日主相对甲方日主的十神）
        let aMaster = String(a.dayMaster.first ?? "甲")
        let bMaster = String(b.dayMaster.first ?? "乙")
        let ss = ShiShen.of(dayGan: aMaster, targetGan: bMaster)
        let masterRelation = ss.isEmpty ? "五行比和" : ss

        // MARK: 五行互补：甲方最弱的两项，乙方是否旺
        let elements = ["木", "火", "土", "金", "水"]
        let weakestA = elements.sorted { (a.wuxingCount[$0] ?? 0) < (a.wuxingCount[$1] ?? 0) }
        var complements: [String] = []
        for e in weakestA.prefix(2) where (b.wuxingCount[e] ?? 0) >= 2 {
            complements.append("乙方\(e)旺，可补甲方\(e)弱之缺")
        }
        let complementNote = complements.isEmpty
            ? "双方五行无明显互补，靠大运流年调济"
            : complements.joined(separator: "；")
        if !complements.isEmpty { score += 5 }

        // MARK: 结论条目
        var summary: [String] = []
        summary.append("生肖\(zodiacRelation)：\(zodiacNote)")
        summary.append("日柱\(dayRelation)：\(dayNote)")
        summary.append("日主关系：乙方日主为甲方\(masterRelation)\(ganHe ? "，且与甲方日主五合" : "")")
        if !complements.isEmpty { summary.append("五行互补：\(complementNote)") }

        return HePanResult(
            a: a, b: b,
            zodiacRelation: zodiacRelation, zodiacNote: zodiacNote,
            dayRelation: dayRelation, dayNote: dayNote,
            masterRelation: masterRelation,
            complementNote: complementNote,
            score: min(95, max(60, score)),
            summary: summary
        )
    }
}
