import Foundation
import UserNotifications

/// 每日指南提醒 —— 本地通知（每日 08:30，无需网络）
/// 开关在「我的-设置」，授权被拒时静默降级（开关仍记录偏好但不调度）。
enum DailyReminder {

    static let notificationId = "daily.guide.reminder"

    /// 请求授权并按开关调度 / 取消每日提醒
    static func setEnabled(_ enabled: Bool) {
        let center = UNUserNotificationCenter.current()
        if !enabled {
            center.removePendingNotificationRequests(withIdentifiers: [notificationId])
            return
        }
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }   // 授权被拒：不调度，偏好仍保留
            schedule()
        }
    }

    private static func schedule() {
        let content = UNMutableNotificationContent()
        content.title = "灵犀 · 今日指南"
        content.body = "今天的干支与宜忌已就绪，点开看看今日运势要点。"
        content.sound = .default

        var comps = DateComponents()
        comps.hour = 8
        comps.minute = 30
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)

        let req = UNNotificationRequest(identifier: notificationId, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
    }
}
