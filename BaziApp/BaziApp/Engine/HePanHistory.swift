import Foundation

/// 一次合盘结果的存档（我的页「合盘记录」展示）
struct HePanEntry: Codable, Identifiable {
    var id = UUID()
    var aName: String
    var bName: String
    /// 双方四柱（展示用，如 庚午 辛巳 庚辰 壬午）
    var aGanzhi: String
    var bGanzhi: String
    var zodiacRelation: String
    var dayRelation: String
    var score: Int
    var time = Date()
}

/// 合盘记录持久化（UserDefaults，最多 8 条，按时间倒序）
enum HePanHistory {
    private static let key = "hepan.history.v1"

    static func load() -> [HePanEntry] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let list = try? JSONDecoder().decode([HePanEntry].self, from: data) else { return [] }
        return list
    }

    static func save(_ entry: HePanEntry) {
        var list = load()
        // 同一对双方去重，置顶
        list.removeAll {
            $0.aGanzhi == entry.aGanzhi && $0.bGanzhi == entry.bGanzhi
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
