import SwiftUI

/// 屏 5：我的（v5.1：功能入口全部接通 + 设置真实化 + 命盘摘要/历史/合盘/自检保留）
struct ProfileView: View {
    let chart: BaziChart?

    // MARK: - 状态（此前缺失声明导致编译失败的三个补齐）

    @State private var ppList: [PaipanEntry] = []
    @State private var hpList: [HePanEntry] = []
    @State private var showClearDialog = false
    /// 自检结果异步加载（486 例全量排盘较重，严禁在 body 内同步执行——会卡死主线程）
    @State private var check: BaziSelfCheck.Result?

    // 功能入口 / 设置 Sheet
    @State private var showGlossary = false
    @State private var showDisclaimer = false
    @State private var showPrivacy = false
    @State private var showAbout = false

    /// 每日指南提醒开关（本机偏好；提醒能力随版本迭代接入）
    @AppStorage("settings.notifyDaily") private var notifyDaily = true

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
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
                                Circle().stroke(BaziTheme.actionBlue, lineWidth: 1.5)
                                    .frame(width: 44, height: 44)
                                Text("灵")
                                    .font(BaziTheme.kai(19))
                                    .foregroundStyle(BaziTheme.goldDeep)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("灵犀命理").font(.system(size: 16, weight: .semibold)).foregroundStyle(BaziTheme.ink)
                                Text("本机排盘 · 数据不出设备").font(.system(size: 11)).foregroundStyle(BaziTheme.secondary)
                            }
                            Spacer()
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(BaziTheme.parchment)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .padding(.horizontal, 20)

                        // 统计条
                        HStack(spacing: 0) {
                            statCell("\(ppList.count)", "已排命盘")
                            statCell("\(hpList.count)", "合盘记录")
                            statCell("\(Glossary.allTerms.count)", "词典条目")
                        }
                        .background(BaziTheme.cardBG)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(BaziTheme.hairline, lineWidth: 1)
                        )
                        .padding(.horizontal, 20)

                        // 功能入口（全部接通）
                        VStack(alignment: .leading, spacing: 0) {
                            Text("功能").font(BaziTheme.title(15)).foregroundStyle(BaziTheme.ink)
                                .padding(.bottom, 10)
                            funcEntry(icon: "book.closed", title: "术语词典",
                                      sub: "主星 / 藏干 / 神煞 即点即查",
                                      badge: "\(Glossary.allTerms.count) 条") { showGlossary = true }
                            groupDivider()
                            funcEntry(icon: "clock.arrow.circlepath", title: "排盘历史",
                                      sub: "最近记录 · 点按查看") { scrollTo(proxy, "history") }
                            groupDivider()
                            funcEntry(icon: "heart.text.square", title: "合盘记录",
                                      sub: "保存过的合盘结果随时回看",
                                      badge: hpList.isEmpty ? nil : "\(hpList.count) 次") { scrollTo(proxy, "hepan") }
                            groupDivider()
                            funcEntry(icon: "checkmark.seal", title: "引擎自检",
                                      sub: "排盘引擎正确性锚点校验",
                                      badge: check.map { "\($0.passed)/\($0.total)" } ?? "校验中",
                                      badgeGood: check.map { $0.passed == $0.total } ?? true) { scrollTo(proxy, "selfcheck") }
                        }
                        .padding(16)
                        .baziCard()
                        .padding(.horizontal, 20)

                        // 我的命盘摘要卡
                        if let c = chart {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("我的命盘").font(BaziTheme.title(15)).foregroundStyle(BaziTheme.ink)
                                    Spacer()
                                    Text("\(score) 分 · \(level)").font(.system(size: 13, weight: .semibold)).foregroundStyle(BaziTheme.goldDeep)
                                }
                                summaryRow("日主", value: "\(c.dayMaster) · \(c.strength)")
                                summaryRow("格局", value: c.pattern)
                                summaryRow("当前大运", value: currentDayun(c))
                                summaryRow("喜用神", value: c.xiYong.joined(separator: "、"), valueColor: BaziTheme.goldDeep)
                                summaryRow("下一大运", value: nextDayun(c))
                            }
                            .padding(16)
                            .baziCard()
                            .padding(.horizontal, 20)
                        }

                        // 排盘引擎自检（异步结果，未就绪时显示占位）
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("引擎自检").font(BaziTheme.title(15)).foregroundStyle(BaziTheme.ink)
                                Spacer()
                                Text(check.map { $0.summary } ?? "校验中…")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(check.map { $0.passed == $0.total } ?? true ? BaziTheme.shenshaGood : BaziTheme.shenshaBad)
                            }
                            if let check {
                                let rows = Self.selfCheckRows(check)
                                ForEach(rows.indices, id: \.self) { i in
                                    let item = rows[i]
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: item.ok ? "checkmark.circle.fill" : "xmark.circle.fill")
                                            .font(.system(size: 13))
                                            .foregroundStyle(item.ok ? BaziTheme.shenshaGood : BaziTheme.shenshaBad)
                                            .padding(.top, 1)
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(item.name).font(.system(size: 13)).foregroundStyle(BaziTheme.ink)
                                            Text(item.detail).font(.system(size: 11)).foregroundStyle(BaziTheme.secondary)
                                        }
                                    }
                                }
                            } else {
                                Text("正在后台逐例校验 490 例锚点，完成后自动刷新…")
                                    .font(.system(size: 12)).foregroundStyle(BaziTheme.tertiary)
                                    .padding(.vertical, 10)
                            }
                            if let check {
                                Text("锚点+对拍基线（lunar-python 权威口径 \(check.total) 例：历法事实锚点 / 立春节气交界 / 晚子时 / 极端经度），全部通过即与权威引擎四柱一致。")
                                    .font(.system(size: 11)).foregroundStyle(BaziTheme.tertiary)
                            }
                        }
                        .padding(16)
                        .baziCard()
                        .padding(.horizontal, 20)
                        .id("selfcheck")

                        // 排盘历史（真实记录）
                        VStack(alignment: .leading, spacing: 0) {
                            Text("排盘历史").font(BaziTheme.title(15)).foregroundStyle(BaziTheme.ink).padding(.bottom, 12)
                            if ppList.isEmpty {
                                Text("还没有排盘记录，去「排盘」页生成第一张命盘")
                                    .font(.system(size: 12)).foregroundStyle(BaziTheme.tertiary)
                                    .padding(.vertical, 10)
                            } else {
                                ForEach(Array(ppList.prefix(5).enumerated()), id: \.element.id) { i, e in
                                    if i > 0 { Rectangle().fill(BaziTheme.divider).frame(height: 1) }
                                    historyRow(e.ganzhi, "\(e.name) · \(timeText(e.time))")
                                }
                            }
                        }
                        .padding(16)
                        .baziCard()
                        .padding(.horizontal, 20)
                        .id("history")

                        // 合盘记录
                        VStack(alignment: .leading, spacing: 0) {
                            Text("合盘记录").font(BaziTheme.title(15)).foregroundStyle(BaziTheme.ink).padding(.bottom, 12)
                            if hpList.isEmpty {
                                Text("还没有合盘记录，排盘页切换「合盘」模式即可开始")
                                    .font(.system(size: 12)).foregroundStyle(BaziTheme.tertiary)
                                    .padding(.vertical, 10)
                            } else {
                                ForEach(Array(hpList.prefix(5).enumerated()), id: \.element.id) { i, e in
                                    if i > 0 { Rectangle().fill(BaziTheme.divider).frame(height: 1) }
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("\(e.aName) × \(e.bName)")
                                                .font(.system(size: 15)).foregroundStyle(BaziTheme.ink)
                                            Text("\(e.zodiacRelation) · \(e.dayRelation) · \(e.score) 分")
                                                .font(.system(size: 12)).foregroundStyle(BaziTheme.secondary)
                                        }
                                        Spacer()
                                        Text(timeText(e.time))
                                            .font(.system(size: 13)).foregroundStyle(BaziTheme.secondary)
                                    }
                                    .frame(height: 52)
                                }
                            }
                        }
                        .padding(16)
                        .baziCard()
                        .padding(.horizontal, 20)
                        .id("hepan")

                        // 设置（全部真实功能）
                        VStack(alignment: .leading, spacing: 0) {
                            Text("设置").font(BaziTheme.title(15)).foregroundStyle(BaziTheme.ink).padding(.bottom, 12)
                            HStack {
                                Image(systemName: "bell").font(.system(size: 16)).foregroundStyle(BaziTheme.secondary).frame(width: 24)
                                Text("每日指南提醒").font(BaziTheme.body()).foregroundStyle(BaziTheme.ink)
                                Spacer()
                                Toggle("", isOn: $notifyDaily).labelsHidden().tint(BaziTheme.actionBlue)
                            }
                            .frame(height: 48)
                            Rectangle().fill(BaziTheme.divider).frame(height: 1)
                            settingRow("免责声明", icon: "exclamationmark.shield") { showDisclaimer = true }
                            Rectangle().fill(BaziTheme.divider).frame(height: 1)
                            settingRow("隐私政策", icon: "hand.raised") { showPrivacy = true }
                            Rectangle().fill(BaziTheme.divider).frame(height: 1)
                            settingRow("关于", icon: "info.circle") { showAbout = true }
                            Rectangle().fill(BaziTheme.divider).frame(height: 1)
                            Button { showClearDialog = true } label: {
                                HStack {
                                    Image(systemName: "trash").font(.system(size: 16)).foregroundStyle(BaziTheme.secondary).frame(width: 24)
                                    Text("清除我的数据").font(BaziTheme.body()).foregroundStyle(BaziTheme.ink)
                                    Spacer()
                                    Image(systemName: "chevron.right").font(.system(size: 13)).foregroundStyle(BaziTheme.placeholder)
                                }
                                .frame(height: 48)
                            }
                        }
                        .padding(16)
                        .baziCard()
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
                .background(BaziTheme.canvas)
            }
            .onAppear {
                ppList = PaipanHistory.load()
                hpList = HePanHistory.load()
                // 自检后台执行，完成后回主线程刷新（避免 body 内同步跑 486 例排盘卡死）
                if check == nil {
                    Task.detached(priority: .userInitiated) {
                        let result = BaziSelfCheck.run()
                        await MainActor.run { self.check = result }
                    }
                }
            }
            .sheet(isPresented: $showGlossary) { GlossaryBrowser() }
            .sheet(isPresented: $showDisclaimer) { DisclaimerSheet() }
            .sheet(isPresented: $showPrivacy) { PrivacySheet() }
            .sheet(isPresented: $showAbout) { AboutSheet() }
            .confirmationDialog("清除哪些数据？（仅存本机，清除后不可恢复）",
                                isPresented: $showClearDialog, titleVisibility: .visible) {
                Button("清除排盘历史", role: .destructive) { PaipanHistory.clear(); ppList = [] }
                Button("清除合盘记录", role: .destructive) { HePanHistory.clear(); hpList = [] }
                Button("清除顾问记忆与对话", role: .destructive) { AdvisorMemory.resetAll() }
                Button("全部清除", role: .destructive) {
                    PaipanHistory.clear(); HePanHistory.clear(); AdvisorMemory.resetAll()
                    ppList = []; hpList = []
                }
                Button("取消", role: .cancel) { }
            }
        }
    }

    // MARK: - 子视图

    private func statCell(_ num: String, _ label: String) -> some View {
        VStack(spacing: 3) {
            Text(num).font(BaziTheme.kai(21)).foregroundStyle(BaziTheme.ink)
            Text(label).font(.system(size: 10)).foregroundStyle(BaziTheme.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 13)
        .overlay(alignment: .leading) {
            Rectangle().fill(BaziTheme.divider).frame(width: 1).opacity(num == "\(ppList.count)" ? 0 : 1)
        }
    }

    private func funcEntry(icon: String, title: String, sub: String,
                           badge: String? = nil, badgeGood: Bool = true,
                           action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 15)).foregroundStyle(BaziTheme.actionBlue)
                    .frame(width: 26)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 15, weight: .medium)).foregroundStyle(BaziTheme.ink)
                    Text(sub).font(.system(size: 11)).foregroundStyle(BaziTheme.secondary)
                }
                Spacer()
                if let badge {
                    Text(badge)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(badgeGood ? BaziTheme.goldDeep : BaziTheme.shenshaBad)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(badgeGood ? BaziTheme.goldSoft : BaziTheme.shenshaBadBG)
                        .clipShape(Capsule())
                }
                Image(systemName: "chevron.right").font(.system(size: 12)).foregroundStyle(BaziTheme.placeholder)
            }
            .padding(.vertical, 11)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func groupDivider() -> some View {
        Rectangle().fill(BaziTheme.divider).frame(height: 1)
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

    private func timeText(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = Calendar.current.isDateInToday(date) ? "今天 HH:mm" : "MM-dd HH:mm"
        return f.string(from: date)
    }

    private func settingRow(_ text: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon).font(.system(size: 16)).foregroundStyle(BaziTheme.secondary).frame(width: 24)
                Text(text).font(BaziTheme.body()).foregroundStyle(BaziTheme.ink)
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 13)).foregroundStyle(BaziTheme.placeholder)
            }
            .frame(height: 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func scrollTo(_ proxy: ScrollViewProxy, _ id: String) {
        withAnimation { proxy.scrollTo(id, anchor: .top) }
    }

    // MARK: - 辅助

    /// 命盘综合评分（ChartScore 实时计算，替代硬编码 82）
    private var score: Int {
        guard let c = chart else { return 0 }
        return ChartScore.evaluate(c).total
    }
    private var level: String {
        guard let c = chart else { return "—" }
        return ChartScore.evaluate(c).level
    }

    /// 自检卡展示策略：有失败只列失败；全过则展示 9 条锚点样例（447 条对拍不全列）
    static func selfCheckRows(_ check: BaziSelfCheck.Result) -> [BaziSelfCheck.Item] {
        let failures = check.items.filter { !$0.ok }
        return failures.isEmpty ? Array(check.items.prefix(9)) : failures
    }

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
