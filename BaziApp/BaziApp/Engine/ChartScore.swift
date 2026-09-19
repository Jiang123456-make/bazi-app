import Foundation

/// 命盘综合评分引擎 —— 替代旧版硬编码 82 分
/// 口径：四维各 25 分（五行流通 / 用神有力 / 格局层次 / 调候得宜），
/// 全部由 BaziChart 的引擎输出实时推导，同一命盘结果恒定，不同命盘分数不同。
/// 仅供文化研究参考，不构成任何决策依据。
enum ChartScore {

    struct Part {
        let name: String
        let score: Int
        let full: Int
    }

    struct Result {
        let total: Int
        let level: String
        let parts: [Part]
        let note: String
    }

    static func evaluate(_ c: BaziChart) -> Result {
        let wuxing = partWuxing(c)
        let yong = partYong(c)
        let ge = partGe(c)
        let tiao = partTiaoHou(c)
        let total = min(100, wuxing + yong + ge + tiao)
        let level: String
        switch total {
        case 85...: level = "上等"
        case 70..<85: level = "中上"
        case 55..<70: level = "中等"
        default: level = "中下"
        }
        return Result(
            total: total,
            level: level,
            parts: [
                Part(name: "五行流通", score: wuxing, full: 25),
                Part(name: "用神有力", score: yong, full: 25),
                Part(name: "格局层次", score: ge, full: 25),
                Part(name: "调候得宜", score: tiao, full: 25)
            ],
            note: "以日主旺衰为基，参五行流通、用神透干得地、格局成败与调候需求综合折算，仅供文化研究参考。"
        )
    }

    // MARK: - 五行流通（25）
    /// 五行越齐全、分布越均匀，流通性越好
    private static func partWuxing(_ c: BaziChart) -> Int {
        let counts = c.wuxingCount
        let total = counts.values.reduce(0, +)
        guard total > 0 else { return 10 }
        let present = counts.values.filter { $0 > 0 }.count
        var s = 10 + present * 2                      // 齐全度：最多 20
        let spread = (counts.values.max() ?? 0) - (counts.values.min() ?? 0)
        if spread <= 2 { s += 5 }                     // 均衡度
        else if spread <= 4 { s += 3 }
        else { s += 1 }
        return max(6, min(25, s))
    }

    // MARK: - 用神有力（25）
    /// 喜用神在全局的出现次数 + 是否透出天干
    private static func partYong(_ c: BaziChart) -> Int {
        let n = c.xiYong.reduce(0) { $0 + (c.wuxingCount[$1] ?? 0) }
        var s = 9 + min(n, 4) * 4                     // 数量：9..25
        let stems = c.pillars.filter { $0.shiShen != "日主" }.map(\.gan)
        let stemHit = stems.filter { g in
            let e = Gan.wuxing[Gan.all.firstIndex(of: g) ?? 0]
            return c.xiYong.contains(e)
        }.count
        s += min(stemHit, 2) * 2                      // 透干加成：最多 +4
        return max(6, min(25, s))
    }

    // MARK: - 格局层次（25）
    /// 格局成败基准分 + 组合加成（如食神制杀）+ 吉凶神平衡
    private static func partGe(_ c: BaziChart) -> Int {
        var s: Int
        switch c.pattern {
        case "正官格": s = 20
        case "正财格", "食神格": s = 19
        case "偏财格", "正印格": s = 18
        case "七杀格": s = 17
        case "偏印格", "伤官格": s = 15
        default: s = 16
        }
        // 食神制杀：才华驾驭压力的上等组合
        let hasShiShen = c.pillars.contains { $0.shiShen == "食神" }
        if c.pattern == "七杀格" && hasShiShen { s += 4 }
        // 吉神与凶煞的平衡微调
        s += min(max(c.goodShenSha.count - c.badShenSha.count, -2), 3)
        return max(8, min(25, s))
    }

    // MARK: - 调候得宜（25）
    /// 命局所需调候用神在全局的满足程度；无调候需求视为平（14）
    private static func partTiaoHou(_ c: BaziChart) -> Int {
        let th = c.tiaoHou
        guard !th.isEmpty else { return 14 }
        let chars = th.map { String($0) }
        var hit = 0
        for ch in chars {
            let elem: String?
            if let i = Gan.all.firstIndex(of: ch) { elem = Gan.wuxing[i] }
            else if let i = Zhi.all.firstIndex(of: ch) { elem = Zhi.wuxing[i] }
            else { elem = nil }
            if let e = elem, (c.wuxingCount[e] ?? 0) > 0 { hit += 1 }
        }
        let frac = chars.isEmpty ? 0.0 : Double(hit) / Double(chars.count)
        return max(6, min(25, 10 + Int((15 * frac).rounded())))
    }
}
