import Foundation

/// 八字解读知识库（L2 层）—— 从专业解读方法论沉淀，随包分发。
/// 按命盘特征（格局/旺衰/喜用/神煞/当前大运十神）+ 用户问题关键词检索相关条目，
/// 注入 AI 提示词，让解读「详细且有依据」。后续知识包可整包替换本 JSON 下发更新。
enum KnowledgeStore {

    struct Entry {
        let id: String
        let topic: String
        let tags: [String]
        let always: Bool
        let brief: String
        let detail: String
    }

    // MARK: - 加载

    private static let entries: [Entry] = {
        guard let url = Bundle.main.url(forResource: "knowledge", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let list = obj["entries"] as? [[String: Any]] else { return [] }
        return list.compactMap { e in
            guard let id = e["id"] as? String,
                  let topic = e["topic"] as? String,
                  let tags = e["tags"] as? [String],
                  let always = e["always"] as? Bool,
                  let brief = e["brief"] as? String,
                  let detail = e["detail"] as? String else { return nil }
            return Entry(id: id, topic: topic, tags: tags, always: always, brief: brief, detail: detail)
        }
    }()

    static var isLoaded: Bool { !entries.isEmpty }

    // MARK: - 检索

    /// 从命盘派生检索标签：格局、旺衰、喜用五行、透干十神（年/月/时干）、神煞、当前大运十神
    static func chartTags(_ c: BaziChart) -> Set<String> {
        var tags = Set<String>()
        // 格局（含复合格局：食神制杀 → 七杀格口径）
        let ganShi = ["正官", "七杀", "正印", "偏印", "正财", "偏财", "食神", "伤官"]
        for kw in ganShi where c.pattern.contains(kw) {
            tags.insert(kw)
            tags.insert(kw + "格")
        }
        if c.pattern.contains("制杀") || c.pattern.contains("化杀") { tags.insert("七杀格") }
        // 旺衰
        if c.strength.contains("弱") { tags.insert("身弱") }
        if c.strength.contains("旺") { tags.insert("身旺") }
        // 喜用神五行
        c.xiYong.forEach { tags.insert($0) }
        // 透干十神（年/月/时干——透干者有力，是解读重点；不取全部藏干避免稀释）
        for (i, p) in c.pillars.enumerated() where i != 2 {
            tags.insert(p.shiShen)
        }
        // 神煞
        for s in c.goodShenSha { tags.insert(s) }
        for s in c.badShenSha { tags.insert(s) }
        // 当前大运十神
        if c.dayun.indices.contains(c.currentDayunIndex) {
            tags.insert(c.dayun[c.currentDayunIndex].shiShen)
        }
        return tags
    }

    /// 检索相关条目：命盘特征命中 + 问题关键词命中 + 恒选条目，按相关度排序，限量
    static func relevant(chart: BaziChart?, query: String = "", limit: Int = 12) -> [Entry] {
        guard !entries.isEmpty else { return [] }
        var t = Set<String>()
        if let c = chart {
            t = chartTags(c)
            // 大运流年话题恒选大运条目
            if query.contains("大运") || query.contains("流年") || query.contains("运势") { t.insert("大运") }
        }
        let matched = entries
            .map { e -> (Entry, Int) in
                var score = 0
                if e.always {
                    score = 1
                } else {
                    for tag in e.tags {
                        if t.contains(tag) { score += 2 }
                        if !query.isEmpty && query.contains(tag) { score += 2 }
                    }
                }
                return (e, score)
            }
            .filter { $0.1 > 0 }
            .sorted { $0.1 > $1.1 }
        return matched.prefix(limit).map { $0.0 }
    }

    /// 渲染成提示词块
    static func promptBlock(for chart: BaziChart?, query: String = "", limit: Int = 12) -> String {
        let items = relevant(chart: chart, query: query, limit: limit)
        guard !items.isEmpty else { return "" }
        var lines = ["可运用的解读知识（务必结合命盘具体化表达，禁止照抄原文）："]
        for e in items {
            lines.append("【\(e.topic)】\(e.detail)")
        }
        return lines.joined(separator: "\n")
    }

    /// 取一条最相关知识的首句，作为本地兜底解读的「专业洞察」行
    static func insightLine(chart: BaziChart?, query: String) -> String? {
        let items = relevant(chart: chart, query: query, limit: 4)
        guard let e = items.first(where: { !$0.always }) ?? items.first else { return nil }
        let d = e.detail
        guard let idx = d.firstIndex(of: "。") else { return d }
        return String(d[..<idx]) + "。"
    }
}
