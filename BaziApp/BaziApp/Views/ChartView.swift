import SwiftUI

/// 屏 2：排盘·结果（问真八字风格完整命盘：基本信息 + 基本命盘 + 专业细盘）
struct ChartView: View {
    let chart: BaziChart

    private let pillarNames = ["年柱", "月柱", "日柱", "时柱"]
    private let gongWei = ["祖上", "父母", "自己", "子女"]
    private let wuxingOrder = ["木", "火", "土", "金", "水"]

    private var dayGan: String { String(chart.dayMaster.first ?? "甲") }
    private var currentYear: Int { Calendar.current.component(.year, from: Date()) }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header

                // ① 基本信息
                basicInfoCard

                // ② 基本命盘（问真式行式大表）
                mingPanCard

                // ③ 五行分布 + 旺衰三判
                wangShuaiCard

                // ④ 喜用 / 忌神 / 调候 / 格局
                xiYongCard

                // ⑤ 大运 + 流年
                daYunCard

                // ⑥ 经典论述
                quoteCard

                Spacer().frame(height: 12)
            }
        }
        .background(BaziTheme.canvas)
    }

    // MARK: - 头部

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("命盘")
                .font(BaziTheme.largeTitle())
                .foregroundStyle(BaziTheme.ink)
            Text("\(chart.gender == "男" ? "乾造" : "坤造") · \(chart.name) · \(chart.pillars.map(\.ganzhi).joined(separator: " "))")
                .font(BaziTheme.footnote(14))
                .foregroundStyle(BaziTheme.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }

    // MARK: - ① 基本信息

    private var basicInfoCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("基本信息").font(BaziTheme.title(15)).foregroundStyle(BaziTheme.ink)
                Spacer()
                Text("真太阳时 \(chart.trueSolarTime)")
                    .font(.system(size: 12)).foregroundStyle(BaziTheme.tertiary)
            }

            infoGrid([
                ("公历", "\(chart.solarDate) \(chart.hour)"),
                ("农历", chart.lunarDate),
                ("生肖", chart.shengxiao),
                ("星座", chart.xingzuo),
                ("节气", chart.jieQiDetail),
                ("人元司令", chart.renYuanSiLing),
                ("真太阳时", "\(chart.trueSolarTime)（\(signed(chart.longitudeOffset))分）"),
                ("出生地", chart.place),
                ("胎元", chart.taiYuan),
                ("胎息", chart.taiXi),
                ("命宫", chart.mingGong),
                ("身宫", chart.shenGong),
                ("命卦", chart.mingGua),
                ("星宿", chart.xingXiu),
                ("称骨", chart.chengGu),
                ("日柱旬空", chart.pillars[2].kongWang),
                ("起运", chart.qiYunDetail),
                ("大运", "\(chart.dayunDirection)排")
            ])
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .baziCard()
        .padding(.horizontal, 20)
    }

    private func infoGrid(_ items: [(String, String)]) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 12) {
            ForEach(items, id: \.0) { item in
                HStack(alignment: .top, spacing: 6) {
                    Text(item.0).font(.system(size: 12)).foregroundStyle(BaziTheme.tertiary)
                        .frame(width: 52, alignment: .leading)
                    Text(item.1).font(.system(size: 13, weight: .medium)).foregroundStyle(BaziTheme.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private func signed(_ v: Int) -> String { v >= 0 ? "+\(v)" : "\(v)" }

    // MARK: - ② 基本命盘（行式大表）

    private var mingPanCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("基本命盘").font(BaziTheme.title(15)).foregroundStyle(BaziTheme.ink)
                Spacer()
                Text("\(chart.dayMaster)日主 · \(chart.strength)")
                    .font(.system(size: 13)).foregroundStyle(BaziTheme.actionBlue)
            }
            .padding(16)
            .padding(.bottom, 10)

            VStack(spacing: 0) {
                // 1 宫位
                pzRow("宫位", isFirst: true) { i in
                    VStack(spacing: 2) {
                        Text(pillarNames[i]).font(.system(size: 11, weight: .semibold)).foregroundStyle(BaziTheme.ink)
                        Text(gongWei[i]).font(.system(size: 9)).foregroundStyle(BaziTheme.tertiary)
                    }
                }
                // 2 主星（十神）
                pzRow("主星") { i in
                    Text(chart.pillars[i].shiShen)
                        .font(.system(size: 13, weight: i == 2 ? .semibold : .regular))
                        .foregroundStyle(i == 2 ? BaziTheme.actionBlue : BaziTheme.secondary)
                }
                // 3 天干
                pzRow("天干") { i in
                    let p = chart.pillars[i]
                    VStack(spacing: 1) {
                        Text(p.gan)
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(i == 2 ? BaziTheme.actionBlue : BaziTheme.wuxingColor(ganWuxing(p.gan)))
                        Text(ganWuxing(p.gan))
                            .font(.system(size: 9))
                            .foregroundStyle(BaziTheme.tertiary)
                    }
                }
                // 4 地支
                pzRow("地支") { i in
                    let p = chart.pillars[i]
                    VStack(spacing: 1) {
                        Text(p.zhi)
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(i == 2 ? BaziTheme.actionBlue : BaziTheme.wuxingColor(zhiWuxing(p.zhi)))
                        Text(zhiWuxing(p.zhi))
                            .font(.system(size: 9))
                            .foregroundStyle(BaziTheme.tertiary)
                    }
                }
                // 5 藏干（含副星）
                pzRow("藏干") { i in
                    let p = chart.pillars[i]
                    VStack(spacing: 3) {
                        ForEach(0..<3, id: \.self) { j in
                            if j < p.cangGan.count {
                                HStack(spacing: 3) {
                                    Text(p.cangGan[j])
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(BaziTheme.wuxingColor(ganWuxing(p.cangGan[j])))
                                    Text(p.cangGanShiShen[j])
                                        .font(.system(size: 9))
                                        .foregroundStyle(BaziTheme.tertiary)
                                }
                            } else {
                                Color.clear.frame(height: 14)
                            }
                        }
                    }
                }
                // 6 星运
                pzRow("星运") { i in
                    Text(chart.pillars[i].xingYun)
                        .font(.system(size: 12)).foregroundStyle(BaziTheme.ink)
                }
                // 7 自坐
                pzRow("自坐") { i in
                    Text(chart.pillars[i].ziZuo)
                        .font(.system(size: 12)).foregroundStyle(BaziTheme.secondary)
                }
                // 8 空亡
                pzRow("空亡") { i in
                    Text(chart.pillars[i].kongWang.isEmpty ? "—" : chart.pillars[i].kongWang)
                        .font(.system(size: 12)).foregroundStyle(BaziTheme.tertiary)
                }
                // 9 纳音
                pzRow("纳音") { i in
                    Text(chart.pillars[i].naYin)
                        .font(.system(size: 10)).foregroundStyle(BaziTheme.tertiary)
                        .lineLimit(1).minimumScaleFactor(0.8)
                }
                // 10 神煞
                pzRow("神煞", isLast: true) { i in
                    let list = chart.pillars[i].shenSha
                    if list.isEmpty {
                        Text("—").font(.system(size: 10)).foregroundStyle(BaziTheme.placeholder)
                    } else {
                        VStack(spacing: 3) {
                            ForEach(list, id: \.self) { s in
                                Text(s)
                                    .font(.system(size: 9))
                                    .foregroundStyle(toneColor(s))
                                    .padding(.horizontal, 4).padding(.vertical, 2)
                                    .background(toneColor(s).opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                                    .lineLimit(1).minimumScaleFactor(0.8)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .baziCard()
        .padding(.horizontal, 20)
    }

    /// 行式大表的一行：左侧行标题 + 四柱单元（日柱整列浅蓝底）
    private func pzRow<Cell: View>(
        _ title: String,
        isFirst: Bool = false,
        isLast: Bool = false,
        @ViewBuilder cell: @escaping (Int) -> Cell
    ) -> some View {
        HStack(alignment: .center, spacing: 0) {
            Text(title)
                .font(.system(size: 11))
                .foregroundStyle(BaziTheme.tertiary)
                .frame(width: 38, alignment: .leading)

            ForEach(0..<4, id: \.self) { i in
                cell(i)
                    .padding(.vertical, 5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(dayColumnBG(index: i, isFirst: isFirst, isLast: isLast))
            }
        }
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle().fill(BaziTheme.divider).frame(height: 1)
            }
        }
    }

    /// 日柱列底色（首行上圆角、末行下圆角，中间无圆角以拼接成整列）
    @ViewBuilder
    private func dayColumnBG(index: Int, isFirst: Bool, isLast: Bool) -> some View {
        if index == 2 {
            UnevenRoundedRectangle(
                cornerRadii: .init(
                    topLeading: isFirst ? 10 : 0,
                    bottomLeading: isLast ? 10 : 0,
                    bottomTrailing: isLast ? 10 : 0,
                    topTrailing: isFirst ? 10 : 0
                ),
                style: .continuous
            )
            .fill(BaziTheme.dayColumn)
        }
    }

    // MARK: - ③ 五行分布 + 旺衰三判

    private var wangShuaiCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("五行与旺衰").font(BaziTheme.title(15)).foregroundStyle(BaziTheme.ink)

            let total = max(chart.wuxingCount.values.reduce(0, +), 1)
            let peak = max(chart.wuxingCount.values.max() ?? 1, 1)
            VStack(spacing: 8) {
                ForEach(wuxingOrder, id: \.self) { elem in
                    let count = chart.wuxingCount[elem] ?? 0
                    let percent = Int(round(Double(count) * 100 / Double(total)))
                    HStack(spacing: 10) {
                        Text(elem).font(.system(size: 13, weight: .medium))
                            .foregroundStyle(BaziTheme.wuxingColor(elem))
                            .frame(width: 18, alignment: .leading)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(BaziTheme.fill).frame(height: 8)
                                Capsule()
                                    .fill(BaziTheme.wuxingColor(elem))
                                    .frame(width: geo.size.width * CGFloat(count) / CGFloat(peak), height: 8)
                            }
                        }
                        .frame(height: 8)
                        Text("\(count) · \(percent)%")
                            .font(.system(size: 12)).foregroundStyle(BaziTheme.secondary)
                            .frame(width: 58, alignment: .trailing)
                    }
                }
            }

            Rectangle().fill(BaziTheme.divider).frame(height: 1)

            // 旺衰三判
            VStack(spacing: 8) {
                judgeRow(chart.deLing, "得令",
                         "日主\(chart.dayMaster)在月令\(chart.pillars[1].zhi)为\(chart.pillars[1].xingYun)")
                judgeRow(chart.deDi, "得地", "地支藏干见同气或印星")
                judgeRow(chart.deShi, "得势", "天干得比劫印星帮扶")
            }

            Rectangle().fill(BaziTheme.divider).frame(height: 1)

            HStack(spacing: 8) {
                Text(chart.strength)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(BaziTheme.actionBlue)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(BaziTheme.dayColumn)
                    .clipShape(Capsule())
                Text(chart.strengthNote)
                    .font(.system(size: 12)).foregroundStyle(BaziTheme.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Text("五行按天干、地支、藏干统计；旺衰看得令·得地·得势，中两项即判身旺")
                .font(.system(size: 10)).foregroundStyle(BaziTheme.placeholder)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .baziCard()
        .padding(.horizontal, 20)
    }

    private func judgeRow(_ ok: Bool, _ title: String, _ desc: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(ok ? "✓" : "✗")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(ok ? BaziTheme.shenshaGood : BaziTheme.tertiary)
                .frame(width: 12)
            Text(title).font(.system(size: 13, weight: .medium)).foregroundStyle(BaziTheme.ink)
                .frame(width: 30, alignment: .leading)
            Text(desc).font(.system(size: 12)).foregroundStyle(BaziTheme.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - ④ 喜用 / 忌神 / 调候 / 格局

    private var xiYongCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("用神参考").font(BaziTheme.title(15)).foregroundStyle(BaziTheme.ink)

            wuxingRow("喜用神", chart.xiYong, tinted: true)
            wuxingRow("忌神", chart.jiShen, tinted: false)

            Rectangle().fill(BaziTheme.divider).frame(height: 1)

            kvRow("调候", chart.tiaoHou.isEmpty ? "命局中和，无需专调" : chart.tiaoHou)
            kvRow("格局", chart.pattern)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .baziCard()
        .padding(.horizontal, 20)
    }

    private func wuxingRow(_ title: String, _ items: [String], tinted: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(title).font(.system(size: 13)).foregroundStyle(BaziTheme.secondary)
                .frame(width: 52, alignment: .leading)
            if items.isEmpty {
                Text("—").font(.system(size: 13)).foregroundStyle(BaziTheme.tertiary)
            } else {
                FlowLayout(spacing: 6) {
                    ForEach(items, id: \.self) { e in
                        Text(e).font(.system(size: 12))
                            .foregroundStyle(tinted ? BaziTheme.wuxingColor(e) : BaziTheme.secondary)
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(tinted ? BaziTheme.wuxingColor(e).opacity(0.14) : BaziTheme.fill)
                            .clipShape(Capsule())
                    }
                }
            }
            Spacer(minLength: 0)
        }
    }

    private func kvRow(_ key: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(key).font(.system(size: 13)).foregroundStyle(BaziTheme.secondary)
                .frame(width: 52, alignment: .leading)
            Text(value).font(.system(size: 13, weight: .medium)).foregroundStyle(BaziTheme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - ⑤ 大运 + 流年

    private var daYunCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("大运流年").font(BaziTheme.title(15)).foregroundStyle(BaziTheme.ink)
                Spacer()
                Text("\(chart.dayunDirection)排 · \(chart.dayunStart)")
                    .font(.system(size: 12)).foregroundStyle(BaziTheme.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(chart.dayun.enumerated()), id: \.offset) { idx, dy in
                        let isCurrent = idx == chart.currentDayunIndex
                        VStack(spacing: 3) {
                            Text(dy.ganzhi)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(isCurrent ? BaziTheme.actionBlue : BaziTheme.ink)
                            Text(dy.shiShen).font(.system(size: 11)).foregroundStyle(BaziTheme.secondary)
                            Text(dy.xingYun).font(.system(size: 10)).foregroundStyle(BaziTheme.tertiary)
                            Text(dy.naYin).font(.system(size: 9)).foregroundStyle(BaziTheme.tertiary)
                                .lineLimit(1).minimumScaleFactor(0.8)
                            Text("\(dy.startAge)-\(dy.endAge)岁").font(.system(size: 10)).foregroundStyle(BaziTheme.tertiary)
                        }
                        .frame(width: 70)
                        .padding(.vertical, 10)
                        .background(isCurrent ? BaziTheme.dayColumn : BaziTheme.fill)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(isCurrent ? BaziTheme.actionBlue : Color.clear, lineWidth: 1.5)
                        )
                    }
                }
            }

            if chart.currentDayunIndex < chart.dayun.count {
                let cur = chart.dayun[chart.currentDayunIndex]
                VStack(alignment: .leading, spacing: 10) {
                    Text("\(cur.ganzhi) 大运 · \(cur.startYear)-\(cur.endYear)")
                        .font(.system(size: 12, weight: .semibold)).foregroundStyle(BaziTheme.ink)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                        ForEach(cur.liunian, id: \.year) { ln in
                            let isNow = ln.year == currentYear
                            VStack(spacing: 2) {
                                Text("\(ln.year)").font(.system(size: 10)).foregroundStyle(BaziTheme.tertiary)
                                Text(ln.ganzhi)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(isNow ? BaziTheme.actionBlue : BaziTheme.ink)
                                Text(ln.shiShen).font(.system(size: 10)).foregroundStyle(BaziTheme.secondary)
                                Text(XingYun.state(gan: dayGan, zhi: String(ln.ganzhi.last ?? "子")))
                                    .font(.system(size: 9)).foregroundStyle(BaziTheme.tertiary)
                                Text(NaYin.map[ln.ganzhi] ?? "").font(.system(size: 8))
                                    .foregroundStyle(BaziTheme.placeholder)
                                    .lineLimit(1).minimumScaleFactor(0.7)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                            .background(isNow ? BaziTheme.dayColumn : BaziTheme.fill)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                    }

                    if let now = cur.liunian.first(where: { $0.year == currentYear }) {
                        HStack(spacing: 10) {
                            Text("今年").font(.system(size: 11)).foregroundStyle(BaziTheme.tertiary)
                                .frame(width: 28, alignment: .leading)
                            Text("\(now.ganzhi)")
                                .font(.system(size: 14, weight: .semibold)).foregroundStyle(BaziTheme.actionBlue)
                            Text(now.shiShen).font(.system(size: 12)).foregroundStyle(BaziTheme.ink)
                            Text(XingYun.state(gan: dayGan, zhi: String(now.ganzhi.last ?? "子")))
                                .font(.system(size: 12)).foregroundStyle(BaziTheme.secondary)
                            Text(NaYin.map[now.ganzhi] ?? "").font(.system(size: 12))
                                .foregroundStyle(BaziTheme.tertiary)
                            Spacer(minLength: 0)
                        }
                        .padding(10)
                        .background(BaziTheme.parchment)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
                .padding(12)
                .background(BaziTheme.parchment.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .baziCard()
        .padding(.horizontal, 20)
    }

    // MARK: - ⑥ 经典论述

    private var quoteCard: some View {
        let quote = DiTianSui.quote(dayGan: dayGan)
        return Group {
            if !quote.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("《滴天髓》论\(dayGan)").font(BaziTheme.title(15)).foregroundStyle(BaziTheme.ink)
                        Spacer()
                        Text("经典").font(.system(size: 11)).foregroundStyle(BaziTheme.tertiary)
                    }
                    Text(quote)
                        .font(.system(size: 14))
                        .foregroundStyle(BaziTheme.ink)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("古籍原文仅供文化参考，不作为决策依据")
                        .font(.system(size: 10)).foregroundStyle(BaziTheme.placeholder)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .baziCard()
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - 辅助

    private func toneColor(_ name: String) -> Color {
        if let good = chart.shenShaTone[name] {
            return good ? BaziTheme.shenshaGood : BaziTheme.shenshaBad
        }
        return BaziTheme.secondary
    }

    private func ganWuxing(_ gan: String) -> String {
        if let i = Gan.all.firstIndex(of: gan) { return Gan.wuxing[i] }
        return "土"
    }

    private func zhiWuxing(_ zhi: String) -> String {
        if let i = Zhi.all.firstIndex(of: zhi) { return Zhi.wuxing[i] }
        return "土"
    }
}

// MARK: - FlowLayout（简易 wrap 布局）

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0; y += rowHeight + spacing; rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX; y += rowHeight + spacing; rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
