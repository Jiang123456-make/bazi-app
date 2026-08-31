import SwiftUI

/// 屏 5：我的
struct ProfileView: View {
    let chart: BaziChart?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 标题
                    Text("我的")
                        .font(BaziTheme.largeTitle())
                        .foregroundStyle(BaziTheme.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 24)

                    // 灵犀状态卡
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(BaziTheme.actionBlue).frame(width: 40, height: 40)
                            Text("灵").font(.system(size: 18, weight: .semibold)).foregroundStyle(.white)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("灵犀 · AI 命理顾问").font(.system(size: 14, weight: .semibold)).foregroundStyle(.white)
                            Text("在线 · 已为你服务 1000+ 次").font(.system(size: 11)).foregroundStyle(BaziTheme.placeholder)
                        }
                        Spacer()
                        Text("问问灵犀 →").font(.system(size: 13, weight: .medium)).foregroundStyle(BaziTheme.blueOnDark)
                    }
                    .padding(14)
                    .background(BaziTheme.darkTile)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal, 20)

                    // 功能入口
                    FlowLayout(spacing: 8) {
                        entry("我的命盘", icon: "scope")
                        entry("案例库", icon: "books.vertical")
                        entry("AI 设置", icon: "gearshape")
                        entry("帮助反馈", icon: "questionmark.circle")
                    }
                    .padding(.horizontal, 20)

                    // 我的命盘摘要卡
                    if let c = chart {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("我的命盘").font(BaziTheme.title(15)).foregroundStyle(BaziTheme.ink)
                                Spacer()
                                Text("\(score) 分 · \(level)").font(.system(size: 13, weight: .semibold)).foregroundStyle(BaziTheme.actionBlue)
                            }
                            summaryRow("当前大运", value: currentDayun(c))
                            summaryRow("喜用神", value: c.xiYong.joined(separator: "、"), valueColor: BaziTheme.fire)
                            summaryRow("下一大运", value: nextDayun(c))
                        }
                        .padding(16)
                        .baziCard()
                        .padding(.horizontal, 20)
                    }

                    // 个人信息卡
                    HStack(spacing: 16) {
                        ZStack {
                            Circle().fill(BaziTheme.parchment).frame(width: 60, height: 60)
                            Image(systemName: "person.fill").font(.system(size: 28)).foregroundStyle(BaziTheme.placeholder)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(chart?.name ?? "陈先生").font(.system(size: 17, weight: .semibold)).foregroundStyle(BaziTheme.ink)
                            Text(chart != nil ? "\(chart!.solarDate) · \(chart!.hour)" : "1990年5月15日 · 午时").font(.system(size: 13)).foregroundStyle(BaziTheme.secondary)
                        }
                        Spacer()
                    }
                    .padding(16)
                    .baziCard()
                    .padding(.horizontal, 20)

                    // 排盘历史
                    VStack(alignment: .leading, spacing: 0) {
                        Text("排盘历史").font(BaziTheme.title(15)).foregroundStyle(BaziTheme.ink).padding(.bottom, 12)
                        historyRow("庚午 辛巳 庚辰 壬午", "今天 14:30")
                        Rectangle().fill(BaziTheme.divider).frame(height: 1)
                        historyRow("甲子 丙寅 戊申 壬戌", "昨天 09:12")
                    }
                    .padding(16)
                    .baziCard()
                    .padding(.horizontal, 20)

                    // 设置
                    VStack(alignment: .leading, spacing: 0) {
                        Text("设置").font(BaziTheme.title(15)).foregroundStyle(BaziTheme.ink).padding(.bottom, 12)
                        settingRow("通知", icon: "bell")
                        Rectangle().fill(BaziTheme.divider).frame(height: 1)
                        settingRow("隐私政策", icon: "hand.raised")
                        Rectangle().fill(BaziTheme.divider).frame(height: 1)
                        settingRow("关于", icon: "info.circle")
                    }
                    .padding(16)
                    .baziCard()
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .background(BaziTheme.canvas)
        }
    }

    // MARK: - 子视图

    private func entry(_ text: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 14)).foregroundStyle(BaziTheme.ink)
            Text(text).font(.system(size: 13)).foregroundStyle(BaziTheme.ink)
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(BaziTheme.fill)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func summaryRow(_ label: String, value: String, valueColor: Color = BaziTheme.ink) -> some View {
        HStack {
            Text(label).font(.system(size: 13)).foregroundStyle(BaziTheme.secondary)
            Spacer()
            Text(value).font(.system(size: 13, weight: .medium)).foregroundStyle(valueColor)
        }
    }

    private func historyRow(_ gz: String, _ time: String) -> some View {
        HStack {
            Text(gz).font(.system(size: 15)).foregroundStyle(BaziTheme.ink)
            Spacer()
            Text(time).font(.system(size: 13)).foregroundStyle(BaziTheme.secondary)
        }
        .frame(height: 48)
    }

    private func settingRow(_ text: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon).font(.system(size: 16)).foregroundStyle(BaziTheme.secondary).frame(width: 24)
            Text(text).font(BaziTheme.body()).foregroundStyle(BaziTheme.ink)
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 13)).foregroundStyle(BaziTheme.placeholder)
        }
        .frame(height: 48)
    }

    // MARK: - 辅助

    private var score: Int { 82 }
    private var level: String { "中上" }

    private func currentDayun(_ c: BaziChart) -> String {
        guard c.dayun.indices.contains(c.currentDayunIndex) else { return "—" }
        let dy = c.dayun[c.currentDayunIndex]
        return "\(dy.ganzhi) \(dy.startAge)-\(dy.endAge)岁（\(dy.shiShen)）"
    }

    private func nextDayun(_ c: BaziChart) -> String {
        let next = c.currentDayunIndex + 1
        guard c.dayun.indices.contains(next) else { return "—" }
        let dy = c.dayun[next]
        return "\(dy.ganzhi) \(dy.startAge)-\(dy.endAge)岁（\(dy.shiShen)）"
    }
}
