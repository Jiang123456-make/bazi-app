import Foundation

/// 一次排盘输入的存档（用于「最近排盘」一键重排）
struct PaipanEntry: Codable, Identifiable, Hashable {
    var id = UUID()
    /// 称谓
    var name: String
    /// 性别（男 / 女）
    var gender: String
    /// 公历日期（yyyy-MM-dd，农历输入已换算为公历存储）
    var dateStr: String
    /// 钟表时间（HH:mm）
    var hour: String
    /// 出生地
    var place: String
    /// 是否启用真太阳时校正
    var useTrueSolar: Bool
    /// 排盘结果四柱（展示用，如 庚午 辛巳 庚辰 壬午）
    var ganzhi: String
    /// 排盘时间
    var time = Date()
}

/// 最近排盘持久化（UserDefaults，最多 8 条，按时间倒序）
enum PaipanHistory {
    private static let key = "paipan.history.v1"

    static func load() -> [PaipanEntry] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let list = try? JSONDecoder().decode([PaipanEntry].self, from: data) else { return [] }
        return list
    }

    static func save(_ entry: PaipanEntry) {
        var list = load()
        // 同一人同一盘去重，置顶
        list.removeAll {
            $0.name == entry.name && $0.dateStr == entry.dateStr &&
            $0.hour == entry.hour && $0.gender == entry.gender
        }
        list.insert(entry, at: 0)
        if list.count > 8 { list = Array(list.prefix(8)) }
        if let data = try? JSONEncoder().encode(list) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
