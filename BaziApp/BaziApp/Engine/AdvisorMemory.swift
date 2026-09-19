import Foundation

/// 顾问记忆系统 —— 让 AI 顾问「越用越顺手」
/// 三层记忆：① 会话持久化（按命盘保存对话，跨启动延续上下文）
///           ② 用户记忆摘要（关注话题/最近问过/赞踩统计，注入 system prompt）
///           ③ 风格偏好（简答/详解 + 差评原因规避）
/// 全部数据仅存本地 UserDefaults，不上传任何服务器。
enum AdvisorMemory {

    // MARK: - 数据模型

    struct ChatRecord: Codable {
        var question: String
        var answer: String        // AI 回复原文（含格式标记，便于原样恢复）
        var topic: String
        var liked: Int            // 1=有帮助 -1=没帮助 0=未评价
        var time: Date
    }

    enum Style: String, Codable, CaseIterable {
        case brief = "简答"
        case detailed = "详解"
    }

    struct Store: Codable {
        var histories: [String: [ChatRecord]] = [:]
        var dislikedReasons: [String] = []
        var style: Style = .detailed
        var totalAsked = 0
    }

    // MARK: - 存储

    private static let key = "advisor.memory.v1"
    private static let maxPerChart = 60

    private static var store: Store = {
        guard let data = UserDefaults.standard.data(forKey: key),
              let s = try? JSONDecoder().decode(Store.self, from: data) else { return Store() }
        return s
    }()

    private static func save() {
        if let data = try? JSONEncoder().encode(store) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    /// 命盘标识（同一张盘共享会话与记忆）
    static func chartKey(_ chart: BaziChart?) -> String {
        guard let c = chart else { return "default" }
        return "\(c.name)|\(c.gender)|\(c.solarDate)|\(c.hour)"
    }

    // MARK: - ① 会话持久化

    static func history(forKey key: String) -> [ChatRecord] {
        store.histories[key] ?? []
    }

    static func append(question: String, answer: String, topic: String, forKey key: String) {
        var list = store.histories[key] ?? []
        list.append(ChatRecord(question: question, answer: answer, topic: topic, liked: 0, time: Date()))
        if list.count > maxPerChart { list = Array(list.suffix(maxPerChart)) }
        store.histories[key] = list
        store.totalAsked += 1
        save()
    }

    static func setFeedback(_ liked: Int, at index: Int, forKey key: String) {
        var list = store.histories[key] ?? []
        guard list.indices.contains(index) else { return }
        list[index].liked = liked
        store.histories[key] = list
        save()
    }

    static func clearHistory(forKey key: String) {
        store.histories[key] = nil
        save()
    }

    // MARK: - ② 记忆摘要（注入 system prompt）

    /// 生成给 AI 看的用户记忆摘要；无历史时返回空串
    static func memorySummary(forKey key: String) -> String {
        let h = history(forKey: key)
        guard !h.isEmpty else { return "" }

        var lines: [String] = []
        lines.append("与该用户的历史交互（共\(h.count)次问答，本地记忆，供延续上下文与个性化）：")

        let topics = Dictionary(grouping: h, by: { $0.topic })
        let top = topics.sorted { $0.value.count > $1.value.count }.prefix(3)
        lines.append("最关注的话题：" + top.map { "\($0.key)（\($0.value.count)次）" }.joined(separator: "、"))

        let recent = h.suffix(5)
        lines.append("最近问过：" + recent.map { "\($0.topic)——\($0.question)" }.joined(separator: "；"))

        let likes = h.filter { $0.liked == 1 }.count
        let dislikes = h.filter { $0.liked == -1 }.count
        if likes + dislikes > 0 {
            lines.append("用户已反馈：\(likes) 条有帮助、\(dislikes) 条没帮助。")
        }
        if !store.dislikedReasons.isEmpty {
            lines.append("用户曾反馈的不满（回答时注意规避）：" + store.dislikedReasons.suffix(5).joined(separator: "、"))
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - ③ 风格偏好

    static var style: Style {
        get { store.style }
        set { store.style = newValue; save() }
    }

    /// 风格 → 提示词片段
    static var stylePrompt: String {
        switch style {
        case .brief:
            return "回答长度：用户偏好简答，【分析】2-3 点、每点 40 字内，总长 150 字左右。"
        case .detailed:
            return "回答长度：用户偏好详解，【分析】4-6 点、每点 60-80 字，逐点引用干支、十神与生克关系作为依据，总长 400-600 字。宁可详细，不要笼统。"
        }
    }

    static let dislikeReasonOptions = ["太笼统、不给具体年份", "不符合我的命盘", "太宿命论", "回答太长"]

    static func addDislikeReason(_ reason: String) {
        if !store.dislikedReasons.contains(reason) {
            store.dislikedReasons.append(reason)
            if store.dislikedReasons.count > 10 { store.dislikedReasons.removeFirst() }
            save()
        }
    }

    // MARK: - 统计

    static var totalAsked: Int { store.totalAsked }

    static func resetAll() {
        store = Store()
        save()
    }
}
