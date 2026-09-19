import Foundation

/// AI 回复文本清理 —— 去除模型自带的 Markdown 修饰与不可见字符
/// AI 卡片（报告页解读 / 顾问页气泡）全部用纯文本自绘样式，模型输出先过这里再上屏。
enum AIClean {

    /// 单段/整段文本清理：去 **、#、`、行首列表符、分隔线、零宽字符、多余空行
    static func text(_ raw: String) -> String {
        var s = raw
            .replacingOccurrences(of: "\u{200B}", with: "")   // 零宽空格
            .replacingOccurrences(of: "\u{FEFF}", with: "")   // BOM
            .replacingOccurrences(of: "\u{00A0}", with: " ")  // 不换行空格
        let lines = s.components(separatedBy: "\n").map { line -> String in
            var l = line.trimmingCharacters(in: .whitespaces)
            // 剥掉行首的 Markdown 修饰符（#、*、>、` 等）
            while let f = l.first, "*#>`•· ".contains(f) {
                l = String(l.dropFirst()).trimmingCharacters(in: .whitespaces)
            }
            // 列表符仅当「- 」带空格时剥（避免误伤「-39 分」这类负号内容）
            for p in ["- ", "— ", "– ", "· "] where l.hasPrefix(p) {
                l = String(l.dropFirst(p.count)).trimmingCharacters(in: .whitespaces)
            }
            // 行内粗体/斜体标记
            l = l.replacingOccurrences(of: "**", with: "")
            l = l.replacingOccurrences(of: "`", with: "")
            if l == "---" || l == "***" { return "" }
            return l
        }
        // 合并连续空行
        var out: [String] = []
        for l in lines {
            if l.isEmpty, out.last?.isEmpty != false { continue }
            out.append(l)
        }
        return out.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 降级纯文本展示：剥离五段式标记（【话题】【结论】…），只留内容
    static func stripSectionTags(_ raw: String) -> String {
        let tags = ["【话题】", "【结论】", "【分析】", "【建议】", "【追问】"]
        return text(raw)
            .components(separatedBy: "\n")
            .map { line -> String in
                var l = line
                for tag in tags where l.hasPrefix(tag) {
                    l = String(l.dropFirst(tag.count)).trimmingCharacters(in: .whitespaces)
                }
                return l
            }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }
}
