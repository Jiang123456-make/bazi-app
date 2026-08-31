import SwiftUI

/// 屏 2：排盘·结果（问真八字风格完整排盘）
struct ChartView: View {
    let chart: BaziChart

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 标题
                VStack(alignment: .leading, spacing: 8) {
                    Text("命盘")
                        .font(BaziTheme.largeTitle())
                        .foregroundStyle(BaziTheme.ink)
                    Text("\(chart.name) · \(chart.gender) · \(chart.pillars.map(\.ganzhi).joined(separator: " "))")
                        .font(BaziTheme.footnote(15))
                        .foregroundStyle(BaziTheme.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 24)

                // 命盘图（方形）
                mingPanCard

                // 四柱卡
                pillarsCard

                // 神煞卡
                shenShaCard

                // 五行卡
                wuxingCard

                // 喜用神卡
                xiYongCard

                // 十神统计卡
                shiShenCard

                // 节气卡
                jieQiCard

                // 近期流年卡
                liuNianCard

                // 大运卡
                daYunCard

                Spacer().frame(height: 20)
            }
        }
        .background(BaziTheme.canvas)
    }

    // MARK: - 命盘图（方形：上/左右下中）

    private var mingPanCard: some View {
        VStack(spacing: 16) {
            Text("命盘").font(.system(size: 13, weight: .semibold)).foregroundStyle(BaziTheme.ink).kerning(1.2)
            // 年柱（上）
            pillarBlock(label: "年柱", pillar: chart.pillars[0])
            // 中行：月柱 + 日主 + 日柱
            HStack(spacing: 24) {
                pillarBlock(label: "月柱", pillar: chart.pillars[1])
                // 日主高亮
                VStack(spacing: 2) {
                    Text("日主").font(.system(size: 10)).foregroundStyle(BaziTheme.actionBlue).kerning(1)
                    Text(String(chart.pillars[2].gan))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(BaziTheme.actionBlue)
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
                .background(BaziTheme.dayPillarBG)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                pillarBlock(label: "日柱", pillar: chart.pillars[2])
            }
            // 时柱（下）
            pillarBlock(label: "时柱", pillar: chart.pillars[3])
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .baziCard()
        .padding(.horizontal, 20)
    }

    private func pillarBlock(label: String, pillar: Pillar) -> some View {
        VStack(spacing: 4) {
            Text(label).font(.system(size: 11)).foregroundStyle(BaziTheme.secondary)
            Text(pillar.ganzhi).font(.system(size: 22, weight: .semibold)).foregroundStyle(BaziTheme.ink)
            HStack(spacing: 4) {
                Text(pillar.gan).font(.system(size: 12)).foregroundStyle(BaziTheme.wuxingColor(ganWuxing(pillar.gan)))
                Text(pillar.zhi).font(.system(size: 12)).foregroundStyle(BaziTheme.wuxingColor(zhiWuxing(pillar.zhi)))
            }
        }
    }

    // MARK: - 四柱卡

    private var pillarsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("四柱").font(BaziTheme.title(15)).foregroundStyle(BaziTheme.ink)
                Spacer()
                Text("日主 · \(chart.dayMaster)").font(.system(size: 13)).foregroundStyle(BaziTheme.actionBlue)
            }
            HStack(alignment: .top, spacing: 8) {
                ForEach(0..<4, id: \.self) { i in
                    let isDay = i == 2
                    pillarDetail(pillar: chart.pillars[i], isDay: isDay)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .baziCard()
        .padding(.horizontal, 20)
    }

    private func pillarDetail(pillar: Pillar, isDay: Bool) -> some View {
        VStack(spacing: 4) {
            Text(pillar.gan)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(isDay ? BaziTheme.actionBlue : BaziTheme.wuxingColor(ganWuxing(pillar.gan)))
            Text(pillar.zhi)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(isDay ? BaziTheme.actionBlue : BaziTheme.wuxingColor(zhiWuxing(pillar.zhi)))
            Text(pillar.shiShen).font(.system(size: 12, weight: isDay ? .semibold : .regular)).foregroundStyle(isDay ? BaziTheme.actionBlue : BaziTheme.secondary)
            Text(pillar.cangGan.joined()).font(.system(size: 11)).foregroundStyle(BaziTheme.secondary)
            Text(pillar.naYin).font(.system(size: 10)).foregroundStyle(BaziTheme.placeholder)
            Text(pillar.xingYun).font(.system(size: 11)).foregroundStyle(BaziTheme.tertiary)
            Text("空亡 \(pillar.kongWang)").font(.system(size: 11)).foregroundStyle(BaziTheme.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(isDay ? BaziTheme.dayPillarBG : BaziTheme.parchment)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - 神煞卡

    private var shenShaCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("神煞").font(BaziTheme.title(15)).foregroundStyle(BaziTheme.ink)
            FlowLayout(spacing: 8) {
                ForEach(chart.goodShenSha, id: \.self) { s in
                    chip(s, bg: BaziTheme.shenshaGoodBG, fg: BaziTheme.shenshaGood)
                }
                ForEach(chart.badShenSha, id: \.self) { s in
                    chip(s, bg: BaziTheme.shenshaBadBG, fg: BaziTheme.shenshaBad)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .baziCard()
        .padding(.horizontal, 20)
    }

    // MARK: - 五行卡

    private var wuxingCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("五行强弱").font(BaziTheme.title(15)).foregroundStyle(BaziTheme.ink)
            let maxCount = max(chart.wuxingCount.values.max() ?? 1, 1)
            ForEach(["木", "火", "土", "金", "水"], id: \.self) { elem in
                let count = chart.wuxingCount[elem] ?? 0
                HStack(spacing: 10) {
                    Text(elem).font(.system(size: 14)).foregroundStyle(BaziTheme.ink).frame(width: 20)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(BaziTheme.fill).frame(height: 8)
                            Capsule()
                                .fill(BaziTheme.wuxingColor(elem))
                                .frame(width: geo.size.width * CGFloat(count) / CGFloat(maxCount), height: 8)
                        }
                    }
                    .frame(height: 8)
                    Text("\(count)").font(.system(size: 14)).foregroundStyle(BaziTheme.secondary).frame(width: 16)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .baziCard()
        .padding(.horizontal, 20)
    }

    // MARK: - 喜用神卡

    private var xiYongCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("喜用神").font(BaziTheme.title(15)).foregroundStyle(BaziTheme.ink)
            HStack(spacing: 8) {
                Text("喜用").font(.system(size: 14)).foregroundStyle(BaziTheme.ink).frame(width: 40, alignment: .leading)
                ForEach(chart.xiYong, id: \.self) { e in
                    chip(e, bg: BaziTheme.wuxingColor(e).opacity(0.12), fg: BaziTheme.wuxingColor(e))
                }
            }
            HStack(spacing: 8) {
                Text("忌神").font(.system(size: 14)).foregroundStyle(BaziTheme.ink).frame(width: 40, alignment: .leading)
                ForEach(chart.jiShen, id: \.self) { e in
                    chip(e, bg: BaziTheme.wuxingColor(e).opacity(0.12), fg: BaziTheme.wuxingColor(e))
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .baziCard()
        .padding(.horizontal, 20)
    }

    // MARK: - 十神统计卡

    private var shiShenCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("十神统计").font(BaziTheme.title(15)).foregroundStyle(BaziTheme.ink)
            let stats = shiShenStats()
            FlowLayout(spacing: 8) {
                ForEach(stats.sorted(by: { $0.key < $1.key }), id: \.key) { item in
                    chip("\(item.key) \(item.value)", bg: BaziTheme.parchment, fg: BaziTheme.secondary)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .baziCard()
        .padding(.horizontal, 20)
    }

    private func shiShenStats() -> [String: Int] {
        var stats: [String: Int] = [:]
        for p in chart.pillars {
            if p.shiShen != "日主" { stats[p.shiShen, default: 0] += 1 }
            for ss in p.cangGanShiShen { stats[ss, default: 0] += 1 }
        }
        return stats
    }

    // MARK: - 节气卡

    private var jieQiCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("节气").font(BaziTheme.title(15)).foregroundStyle(BaziTheme.ink)
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("出生").font(.system(size: 12)).foregroundStyle(BaziTheme.secondary)
                    Text("立夏后").font(.system(size: 16, weight: .semibold)).foregroundStyle(BaziTheme.ink)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("真太阳时").font(.system(size: 12)).foregroundStyle(BaziTheme.secondary)
                    Text("\(chart.trueSolarTime)（\(chart.longitudeOffset >= 0 ? "+" : "")\(chart.longitudeOffset)分）").font(.system(size: 16, weight: .semibold)).foregroundStyle(BaziTheme.ink)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .baziCard()
        .padding(.horizontal, 20)
    }

    // MARK: - 近期流年卡

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

    // MARK: - 大运卡

    private var daYunCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("大运").font(BaziTheme.title(15)).foregroundStyle(BaziTheme.ink)
                Spacer()
                Text("\(chart.dayunDirection) · \(chart.dayunStart)").font(.system(size: 13)).foregroundStyle(BaziTheme.secondary)
            }
            // 当前大运
            if chart.currentDayunIndex < chart.dayun.count {
                let cur = chart.dayun[chart.currentDayunIndex]
                HStack {
                    Text(cur.ganzhi).font(.system(size: 24, weight: .semibold)).foregroundStyle(BaziTheme.actionBlue)
                    Spacer()
                    Text("\(cur.startAge)-\(cur.endAge)岁 · \(cur.shiShen)").font(.system(size: 15, weight: .semibold)).foregroundStyle(BaziTheme.ink)
                }
                .padding(14)
                .background(BaziTheme.dayPillarBG)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            // 后续大运
            HStack(spacing: 8) {
                ForEach(chart.dayun, id: \.self) { dy in
                    VStack(spacing: 4) {
                        Text(dy.ganzhi).font(.system(size: 15, weight: .semibold)).foregroundStyle(BaziTheme.ink)
                        Text("\(dy.startAge)-\(dy.endAge)").font(.system(size: 11)).foregroundStyle(BaziTheme.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(BaziTheme.fill)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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
