import SwiftUI

/// 屏 2：排盘·结果（问真八字风格完整命盘：基本信息 + 基本命盘 + 专业细盘）
struct ChartView: View {
    let chart: BaziChart

    private let pillarNames = ["年柱", "月柱", "日柱", "时柱"]
    private let gongWei = ["祖上", "父母", "自己", "子女"]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header

                // ① 基本信息
                basicInfoCard

                // ② 基本命盘（四柱大表格）
                mingPanTable

                // ③ 五行结构
                wuxingCard

                // ④ 喜用神 / 忌神
                xiYongCard

                // ⑤ 神煞
                shenShaCard

                // ⑥ 专业细盘：大运 + 流年对照
                daYunCard

                // ⑦ 近期流年
                liuNianCard

                Spacer().frame(height: 12)
            }
        }
        .background(BaziTheme.canvas)
    }

    // MARK: - 头部

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("命盘")
                .font(BaziTheme.largeTitle())
                .foregroundStyle(BaziTheme.ink)
            Text("\(chart.gender == "男" ? "乾造" : "坤造") · \(chart.name) · \(chart.pillars.map(\.ganzhi).joined(separator: " "))")
                .font(BaziTheme.footnote(15))
                .foregroundStyle(BaziTheme.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 24)
    }

    // MARK: - ① 基本信息

    private var basicInfoCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("基本信息").font(BaziTheme.title(15)).foregroundStyle(BaziTheme.ink)
                Spacer()
                Text("真太阳时 \(chart.trueSolarTime)").font(.system(size: 12)).foregroundStyle(BaziTheme.tertiary)
            }

            infoGrid([
                ("公历", "\(chart.solarDate) \(chart.hour)"),
                ("农历", chart.lunarDate),
                ("生肖", chart.shengxiao),
                ("星座", chart.xingzuo),
                ("节气", chart.jieQiDetail),
                ("星宿", chart.xingXiu),
                ("胎元", chart.taiYuan),
                ("命宫", chart.mingGong),
                ("身宫", chart.shenGong),
                ("命卦", chart.mingGua),
                ("起运", chart.qiYunDetail),
                ("空亡", chart.pillars[2].kongWang)
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
                        .frame(width: 36, alignment: .leading)
                    Text(item.1).font(.system(size: 13, weight: .medium)).foregroundStyle(BaziTheme.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    // MARK: - ② 基本命盘（四柱大表格）

    private var mingPanTable: some View {
        VStack(spacing: 0) {
            HStack {
                Text("基本命盘").font(BaziTheme.title(15)).foregroundStyle(BaziTheme.ink)
                Spacer()
                Text("\(chart.dayMaster)日主 · \(chart.strength)").font(.system(size: 13)).foregroundStyle(BaziTheme.actionBlue)
            }
            .padding(16)
            .padding(.bottom, 8)

            // 四列并列
            HStack(alignment: .top, spacing: 0) {
                ForEach(0..<4, id: \.self) { i in
                    pillarColumn(chart.pillars[i], index: i, isDay: i == 2)
                    if i < 3 {
                        Rectangle().fill(BaziTheme.divider).frame(width: 1)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .baziCard()
        .padding(.horizontal, 20)
    }

    private func pillarColumn(_ p: Pillar, index: Int, isDay: Bool) -> some View {
        VStack(spacing: 7) {
            // 柱名 + 宫位
            Text(pillarNames[index]).font(.system(size: 12, weight: .semibold)).foregroundStyle(BaziTheme.ink)
            Text(gongWei[index]).font(.system(size: 10)).foregroundStyle(BaziTheme.tertiary)

            Divider().frame(width: 24)

            // 主星（十神）
            Text(p.shiShen)
                .font(.system(size: 12, weight: isDay ? .semibold : .regular))
                .foregroundStyle(isDay ? BaziTheme.actionBlue : BaziTheme.secondary)

            // 天干
            Text(p.gan)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(isDay ? BaziTheme.actionBlue : BaziTheme.wuxingColor(ganWuxing(p.gan)))
            Text(ganWuxing(p.gan))
                .font(.system(size: 10))
                .foregroundStyle(BaziTheme.wuxingColor(ganWuxing(p.gan)))

            // 地支
            Text(p.zhi)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(isDay ? BaziTheme.actionBlue : BaziTheme.wuxingColor(zhiWuxing(p.zhi)))
            Text(zhiWuxing(p.zhi))
                .font(.system(size: 10))
                .foregroundStyle(BaziTheme.wuxingColor(zhiWuxing(p.zhi)))

            // 藏干（每个带十神）
            VStack(spacing: 3) {
                ForEach(0..<p.cangGan.count, id: \.self) { j in
                    HStack(spacing: 3) {
                        Text(p.cangGan[j]).font(.system(size: 11)).foregroundStyle(BaziTheme.wuxingColor(ganWuxing(p.cangGan[j])))
                        Text(p.cangGanShiShen[j]).font(.system(size: 10)).foregroundStyle(BaziTheme.secondary)
                    }
                }
            }
            .frame(minHeight: 42, alignment: .center)

            Divider().frame(width: 24)

            // 星运
            Text(p.xingYun).font(.system(size: 11)).foregroundStyle(BaziTheme.ink)
            // 空亡
            Text(p.kongWang.isEmpty ? "—" : p.kongWang).font(.system(size: 11)).foregroundStyle(BaziTheme.tertiary)
            // 纳音
            Text(p.naYin).font(.system(size: 10)).foregroundStyle(BaziTheme.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(isDay ? BaziTheme.dayPillarBG : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - ③ 五行结构

    private var wuxingCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("五行结构").font(BaziTheme.title(15)).foregroundStyle(BaziTheme.ink)
            let total = max(chart.wuxingCount.values.reduce(0, +), 1)
            ForEach(["木", "火", "土", "金", "水"], id: \.self) { elem in
                let count = chart.wuxingCount[elem] ?? 0
                let percent = Int(round(Double(count) * 100 / Double(total)))
                HStack(spacing: 10) {
                    Text(elem).font(.system(size: 14, weight: .medium)).foregroundStyle(BaziTheme.ink).frame(width: 20)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(BaziTheme.fill).frame(height: 10)
                            Capsule()
                                .fill(BaziTheme.wuxingColor(elem))
                                .frame(width: geo.size.width * CGFloat(count) / CGFloat(max(chart.wuxingCount.values.max() ?? 1, 1)), height: 10)
                        }
                    }
                    .frame(height: 10)
                    Text("\(count) · \(percent)%").font(.system(size: 12)).foregroundStyle(BaziTheme.secondary).frame(width: 64, alignment: .trailing)
                }
            }
            Text("按天干、地支、藏干统计；百分比为该五行占总数的比例")
                .font(.system(size: 10)).foregroundStyle(BaziTheme.placeholder)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .baziCard()
        .padding(.horizontal, 20)
    }

    // MARK: - ④ 喜用神 / 忌神

    private var xiYongCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("喜用神").font(BaziTheme.title(15)).foregroundStyle(BaziTheme.ink)
            HStack(spacing: 8) {
                Text("喜用").font(.system(size: 14)).foregroundStyle(BaziTheme.ink).frame(width: 40, alignment: .leading)
                ForEach(chart.xiYong, id: \.self) { e in
                    chip(e, bg: BaziTheme.wuxingColor(e).opacity(0.14), fg: BaziTheme.wuxingColor(e))
                }
                Text("· \(chart.pattern)").font(.system(size: 12)).foregroundStyle(BaziTheme.secondary)
            }
            HStack(spacing: 8) {
                Text("忌神").font(.system(size: 14)).foregroundStyle(BaziTheme.ink).frame(width: 40, alignment: .leading)
                ForEach(chart.jiShen, id: \.self) { e in
                    chip(e, bg: BaziTheme.parchment, fg: BaziTheme.secondary)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .baziCard()
        .padding(.horizontal, 20)
    }

    // MARK: - ⑤ 神煞

    private var shenShaCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("神煞").font(BaziTheme.title(15)).foregroundStyle(BaziTheme.ink)
            if !chart.goodShenSha.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Text("吉").font(.system(size: 12, weight: .semibold)).foregroundStyle(BaziTheme.shenshaGood).frame(width: 20, alignment: .leading)
                    FlowLayout(spacing: 8) {
                        ForEach(chart.goodShenSha, id: \.self) { s in
                            chip(s, bg: BaziTheme.shenshaGoodBG, fg: BaziTheme.shenshaGood)
                        }
                    }
                }
            }
            if !chart.badShenSha.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Text("凶").font(.system(size: 12, weight: .semibold)).foregroundStyle(BaziTheme.shenshaBad).frame(width: 20, alignment: .leading)
                    FlowLayout(spacing: 8) {
                        ForEach(chart.badShenSha, id: \.self) { s in
                            chip(s, bg: BaziTheme.shenshaBadBG, fg: BaziTheme.shenshaBad)
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .baziCard()
        .padding(.horizontal, 20)
    }

    // MARK: - ⑥ 大运 + 流年对照

    private var daYunCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("大运").font(BaziTheme.title(15)).foregroundStyle(BaziTheme.ink)
                Spacer()
                Text("\(chart.dayunDirection) · \(chart.dayunStart)").font(.system(size: 13)).foregroundStyle(BaziTheme.secondary)
            }

            // 大运横向排列
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(chart.dayun.enumerated()), id: \.offset) { idx, dy in
                        let isCurrent = idx == chart.currentDayunIndex
                        VStack(spacing: 4) {
                            Text(dy.ganzhi).font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(isCurrent ? BaziTheme.actionBlue : BaziTheme.ink)
                            Text(dy.shiShen).font(.system(size: 11)).foregroundStyle(BaziTheme.secondary)
                            Text("\(dy.startAge)-\(dy.endAge)岁").font(.system(size: 10)).foregroundStyle(BaziTheme.tertiary)
                            Text(dy.naYin).font(.system(size: 9)).foregroundStyle(BaziTheme.tertiary)
                        }
                        .frame(width: 72)
                        .padding(.vertical, 12)
                        .background(isCurrent ? BaziTheme.dayPillarBG : BaziTheme.fill)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(isCurrent ? BaziTheme.actionBlue : Color.clear, lineWidth: 1.5)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
            }

            // 当前大运的流年
            if chart.currentDayunIndex < chart.dayun.count {
                let cur = chart.dayun[chart.currentDayunIndex]
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(cur.ganzhi) 大运流年（\(cur.startYear)-\(cur.endYear)）")
                        .font(.system(size: 12, weight: .semibold)).foregroundStyle(BaziTheme.ink)
                    FlowLayout(spacing: 8) {
                        ForEach(cur.liunian, id: \.year) { ln in
                            VStack(spacing: 3) {
                                Text("\(ln.year)").font(.system(size: 10)).foregroundStyle(BaziTheme.secondary)
                                Text(ln.ganzhi).font(.system(size: 15, weight: .semibold)).foregroundStyle(BaziTheme.ink)
                                Text(ln.shiShen).font(.system(size: 10)).foregroundStyle(BaziTheme.secondary)
                            }
                            .frame(width: 60)
                            .padding(.vertical, 8)
                            .background(BaziTheme.fill)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                    }
                }
                .padding(12)
                .background(BaziTheme.parchment)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .baziCard()
        .padding(.horizontal, 20)
    }

    // MARK: - ⑦ 近期流年

    private var liuNianCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("近期流年").font(BaziTheme.title(15)).foregroundStyle(BaziTheme.ink)
            FlowLayout(spacing: 8) {
                ForEach(chart.liunian, id: \.year) { ln in
                    VStack(spacing: 4) {
                        Text("\(ln.year)").font(.system(size: 11)).foregroundStyle(BaziTheme.secondary)
                        Text(ln.ganzhi).font(.system(size: 17, weight: .semibold)).foregroundStyle(BaziTheme.ink)
                        Text(ln.shiShen).font(.system(size: 11)).foregroundStyle(BaziTheme.secondary)
                    }
                    .frame(width: 64)
                    .padding(.vertical, 10)
                    .background(BaziTheme.fill)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .baziCard()
        .padding(.horizontal, 20)
    }

    // MARK: - 辅助

    private func chip(_ text: String, bg: Color, fg: Color) -> some View {
        Text(text).font(.system(size: 12)).foregroundStyle(fg)
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(bg)
            .clipShape(Capsule())
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
