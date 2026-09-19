import SwiftUI

/// 屏 3：命理·报告（评分 + AI 解读 + 当前大运 + 四维度 + 10 年运势 + 今年宜忌，全部按命局动态生成）
struct ReportView: View {
    let chart: BaziChart?

    @State private var aiLoading = false
    @State private var aiText: String? = nil
    @State private var aiFailed = false

    private var currentYear: Int { Calendar.current.component(.year, from: Date()) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 标题
                    VStack(alignment: .leading, spacing: 8) {
                        Text("报告")
                            .font(BaziTheme.largeTitle())
                            .foregroundStyle(BaziTheme.ink)
                        Text("灵犀基于四柱八字的综合命理分析")
                            .font(BaziTheme.footnote(15))
                            .foregroundStyle(BaziTheme.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 24)

                    if let c = chart {
                        scoreCard(c)
                        aiCard(c)
                        dayunCard(c)
                        dimensionCard(c)
                        fortuneCard(c)
                        yijiCard(c)
                    } else {
                        emptyState
                    }
                }
            }
            .background(BaziTheme.canvas)
            .task(id: chart?.solarDate ?? "") {
                aiText = nil
                if let c = chart { loadAI(c) }
            }
        }
    }

    // MARK: - AI 解读（真实 AI 异步加载）

    private func loadAI(_ c: BaziChart) {
        aiLoading = true
        let messages: [AiService.ChatMessage] = [
            AiService.ChatMessage(role: "system", content: AiService.buildSystemPrompt(chart: c)),
            AiService.ChatMessage(role: "user", content: "请为我的八字命盘做一段综合命理解读（性格、事业、财运、感情、健康），200 字以内，分点清晰。")
        ]
        AiService.chat(messages: messages) { result in
            aiLoading = false
            switch result {
            case .success(let text):
                aiText = text
                aiFailed = false
            case .failure:
                aiText = nil       // 保持 nil，卡片显示本地兜底文案
                aiFailed = true    // 失败可见，可手动重试
            }
        }
    }

    // MARK: - 综合评分卡（浅色）

    private func scoreCard(_ c: BaziChart) -> some View {
        let result = ChartScore.evaluate(c)
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(result.total)").font(.system(size: 44, weight: .semibold)).foregroundStyle(BaziTheme.ink)
                Text("分 · 综合\(result.level)").font(.system(size: 15)).foregroundStyle(BaziTheme.secondary)
                Spacer()
                Text(c.strength)
                    .font(.system(size: 13, weight: .semibold)).foregroundStyle(BaziTheme.goldDeep)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(BaziTheme.dayColumn).clipShape(Capsule())
            }
            Text("\(c.dayMaster)日主 · \(c.pattern)")
                .font(.system(size: 13)).foregroundStyle(BaziTheme.secondary)
            if !c.strengthNote.isEmpty {
                Text(c.strengthNote).font(.system(size: 12)).foregroundStyle(BaziTheme.tertiary)
            }
            // 四维评分进度条
            VStack(spacing: 9) {
                ForEach(result.parts, id: \.name) { p in
                    VStack(spacing: 4) {
                        HStack {
                            Text(p.name).font(.system(size: 12.5)).foregroundStyle(BaziTheme.ink)
                            Spacer()
                            Text("\(p.score)/\(p.full)").font(.system(size: 11.5)).foregroundStyle(BaziTheme.tertiary)
                        }
                        ProgressView(value: Double(p.score), total: Double(p.full))
                            .progressViewStyle(.linear)
                            .tint(BaziTheme.actionBlue)
                    }
                }
            }
            .padding(.top, 2)
            Text("评分口径：五行流通 · 用神有力 · 格局层次 · 调候得宜，仅供文化参考")
                .font(.system(size: 10.5)).foregroundStyle(BaziTheme.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .baziCard()
        .padding(.horizontal, 20)
    }

    // MARK: - AI 解读卡

    private func aiCard(_ c: BaziChart) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("AI 解读").font(BaziTheme.title(15)).foregroundStyle(BaziTheme.ink)
                Spacer()
                if aiLoading {
                    ProgressView().tint(BaziTheme.actionBlue)
                } else if let _ = aiText {
                    Button { loadAI(c) } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise").font(.system(size: 11))
                            Text("重新生成").font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(BaziTheme.actionBlue)
                    }
                }
            }
            if let text = aiText {
                Text(text)
                    .font(.system(size: 14)).foregroundStyle(BaziTheme.ink)
                    .lineSpacing(6)
            } else if aiLoading {
                Text("灵犀正在结合您的命盘进行解读…")
                    .font(.system(size: 13)).foregroundStyle(BaziTheme.tertiary)
                    .lineSpacing(6)
            } else {
                // 本地兜底 + 失败可见可重试
                Text(fallbackAI(c))
                    .font(.system(size: 14)).foregroundStyle(BaziTheme.ink)
                    .lineSpacing(6)
                Button {
                    aiFailed = false
                    loadAI(c)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: aiFailed ? "wifi.exclamationmark" : "sparkles")
                            .font(.system(size: 12))
                        Text(aiFailed ? "联网失败 · 点击重试 AI 详版" : "联网生成 AI 详版解读")
                            .font(.system(size: 13, weight: .medium))
                        Spacer()
                    }
                    .foregroundStyle(aiFailed ? BaziTheme.earth : BaziTheme.actionBlue)
                    .padding(.horizontal, 12).padding(.vertical, 9)
                    .background(aiFailed ? BaziTheme.earth.opacity(0.08) : BaziTheme.dayColumn)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
            Text(aiText == nil ? "以上为本地命理解读 · 生成后由灵犀 AI 提供 · 仅供文化参考" : "由灵犀 AI 生成 · 仅供文化参考")
                .font(.system(size: 10)).foregroundStyle(BaziTheme.placeholder)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .baziCard()
        .padding(.horizontal, 20)
    }

    /// 本地兜底解读（AI 不可用时展示）：按真实格局与十神组合生成
    private func fallbackAI(_ c: BaziChart) -> String {
        let hourShi = c.pillars[3].shiShen   // 时干十神
        let monthShi = c.pillars[1].shiShen  // 月干十神
        var text = "\(c.dayMaster)日主，生于\(c.pillars[1].zhi)月，\(c.strength)。月令取\(c.pattern)"

        if c.pattern == "七杀格", hourShi == "食神" {
            text += "，时干食神透出，成食神制杀之象：压力可化为动力，宜以专业与表达立身，不宜硬碰"
        } else if hourShi == "食神" || hourShi == "伤官" {
            text += "，时干\(hourShi)泄秀，宜以才艺、表达、创意安身立命"
        } else {
            text += "，月干\(monthShi)、时干\(hourShi)并见，宜稳中求进，借喜用\(c.xiYong.joined(separator: "、"))调候"
        }

        let dy = c.dayun.indices.contains(c.currentDayunIndex) ? c.dayun[c.currentDayunIndex].ganzhi : ""
        return text + "。当前大运\(dy)，流年宜守拙藏锋、厚积薄发。"
    }

    // MARK: - 当前大运 + 今年流年

    private func dayunCard(_ c: BaziChart) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("当前大运").font(BaziTheme.title(15)).foregroundStyle(BaziTheme.ink)
                Spacer()
                Text("\(c.dayunDirection)排 · \(c.dayunStart)")
                    .font(.system(size: 12)).foregroundStyle(BaziTheme.secondary)
            }

            if c.dayun.indices.contains(c.currentDayunIndex) {
                let dy = c.dayun[c.currentDayunIndex]
                HStack(spacing: 10) {
                    Text(dy.ganzhi)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(BaziTheme.actionBlue)
                    Text(dy.shiShen).font(.system(size: 13)).foregroundStyle(BaziTheme.ink)
                    Text("星运\(dy.xingYun)").font(.system(size: 12)).foregroundStyle(BaziTheme.secondary)
                    Spacer()
                    Text(verbatim: "\(dy.startAge)-\(dy.endAge)岁 · \(dy.startYear)-\(dy.endYear)")
                        .font(.system(size: 12)).foregroundStyle(BaziTheme.tertiary)
                        .lineLimit(1).minimumScaleFactor(0.8)
                }
            }

            if let now = c.liunian.first(where: { $0.year == currentYear }) {
                HStack(spacing: 10) {
                    Text("今年")
                        .font(.system(size: 11)).foregroundStyle(BaziTheme.actionBlue)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(BaziTheme.dayColumn).clipShape(Capsule())
                    Text(now.ganzhi).font(.system(size: 15, weight: .semibold)).foregroundStyle(BaziTheme.ink)
                    Text(now.shiShen).font(.system(size: 12)).foregroundStyle(BaziTheme.secondary)
                    Text("星运\(XingYun.state(gan: String(c.dayMaster.first ?? "甲"), zhi: String(now.ganzhi.last ?? "子")))")
                        .font(.system(size: 12)).foregroundStyle(BaziTheme.secondary)
                    Spacer(minLength: 0)
                }
                .padding(10)
                .background(BaziTheme.parchment.opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            Text(shiShenGuide(c).tip)
                .font(.system(size: 12)).foregroundStyle(BaziTheme.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .baziCard()
        .padding(.horizontal, 20)
    }

    // MARK: - 4 维度卡（分数按命局官杀/财星推导）

    private func dimensionCard(_ c: BaziChart) -> some View {
        VStack(spacing: 0) {
            ForEach(dimensions(c), id: \.title) { dim in
                VStack(alignment: .leading, spacing: 4) {
                    Text(dim.title).font(BaziTheme.title(15)).foregroundStyle(BaziTheme.ink)
                    Text("\(dim.desc) · \(dim.score) 分").font(.system(size: 13)).foregroundStyle(BaziTheme.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 12)
                if dim.title != "感情" {
                    Rectangle().fill(BaziTheme.divider).frame(height: 1)
                }
            }
        }
        .padding(.horizontal, 16)
        .baziCard()
        .padding(.horizontal, 20)
    }

    private func dimensions(_ c: BaziChart) -> [(title: String, desc: String, score: Int)] {
        let strong = c.strength == "身旺"
        let yueShi = c.pillars[1].shiShen     // 月干十神 → 事业心性
        let hourShi = c.pillars[3].shiShen    // 时干十神 → 收束与晚年
        let peiouZhi = c.pillars[2].zhi       // 日支（配偶宫）
        let peiouShi = c.pillars[2].cangGanShiShen.first ?? "—"

        // 事业分看官杀数量、财运分看财星数量（含藏干统计）
        let dayGan = String(c.dayMaster.first ?? "甲")
        let dayElem = Gan.wuxing[Gan.all.firstIndex(of: dayGan) ?? 0]
        let keMap = ["木": "土", "土": "水", "水": "火", "火": "金", "金": "木"]
        let caiElem = keMap[dayElem] ?? "木"
        let guanElem = keMap.first(where: { $0.value == dayElem })?.key ?? "木"
        let caiN = c.wuxingCount[caiElem] ?? 0
        let guanN = c.wuxingCount[guanElem] ?? 0
        let careerScore = guanN >= 4 ? 9 : (guanN >= 2 ? 8 : 7)
        let wealthScore = caiN >= 4 ? 9 : (caiN >= 2 ? 8 : 7)

        return [
            ("性格", strong ? "身旺气足，主见强、行动力佳，宜主动出击" : "身弱思细，感知力强，宜借势而为",
             strong ? 9 : 7),
            ("事业", "月干\(yueShi)透出，官杀\(guanElem)星\(guanN)个，事业路径与\(yueShi)心性相合", careerScore),
            ("财运", "财星\(caiElem)星\(caiN)个，喜用\(c.xiYong.joined(separator: "、"))，顺用神而行财自至", wealthScore),
            ("感情", "配偶宫坐\(peiouZhi)（\(peiouShi)），时柱\(hourShi)收束，晚成更稳", 8)
        ]
    }

    // MARK: - 10 年运势卡（吉 / 平 / 滞 三档，今年高亮）

    private func fortuneCard(_ c: BaziChart) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("10 年运势").font(BaziTheme.title(15)).foregroundStyle(BaziTheme.ink)
                Spacer()
                Text("按流年十神分三档")
                    .font(.system(size: 11)).foregroundStyle(BaziTheme.tertiary)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                ForEach(c.liunian, id: \.year) { ln in
                    let grade = fortuneGrade(ln.shiShen)
                    let isNow = ln.year == currentYear
                    VStack(spacing: 2) {
                        Text(verbatim: "\(ln.year)").font(.system(size: 10)).foregroundStyle(BaziTheme.tertiary)
                        Text(ln.ganzhi)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(isNow ? BaziTheme.actionBlue : BaziTheme.ink)
                        Text(ln.shiShen).font(.system(size: 10)).foregroundStyle(BaziTheme.secondary)
                        Text(grade.0).font(.system(size: 11, weight: .semibold)).foregroundStyle(grade.1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(isNow ? BaziTheme.dayColumn : BaziTheme.fill)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
            Text("档位按流年十神与命局喜忌粗判，年份以立春为界")
                .font(.system(size: 10)).foregroundStyle(BaziTheme.placeholder)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .baziCard()
        .padding(.horizontal, 20)
    }

    // MARK: - 今年宜忌卡（按今年十神动态生成）

    private func yijiCard(_ c: BaziChart) -> some View {
        let guide = shiShenGuide(c)
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("今年宜忌").font(BaziTheme.title(15)).foregroundStyle(BaziTheme.ink)
                Spacer()
                if let now = c.liunian.first(where: { $0.year == currentYear }) {
                    Text(verbatim: "\(now.year) · \(now.ganzhi) \(now.shiShen)主事")
                        .font(.system(size: 11)).foregroundStyle(BaziTheme.tertiary)
                }
            }
            HStack(spacing: 10) {
                Text("宜").font(.system(size: 14, weight: .semibold)).foregroundStyle(BaziTheme.shenshaGood).frame(width: 22)
                ForEach(guide.yi, id: \.self) { chip($0, bg: BaziTheme.shenshaGoodBG, fg: BaziTheme.shenshaGood) }
                Spacer(minLength: 0)
            }
            HStack(spacing: 10) {
                Text("忌").font(.system(size: 14, weight: .semibold)).foregroundStyle(BaziTheme.shenshaBad).frame(width: 22)
                ForEach(guide.ji, id: \.self) { chip($0, bg: BaziTheme.shenshaBadBG, fg: BaziTheme.shenshaBad) }
                Spacer(minLength: 0)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .baziCard()
        .padding(.horizontal, 20)
    }

    // MARK: - 空状态

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 40)).foregroundStyle(BaziTheme.placeholder)
            Text("请先在「排盘」页生成命盘")
                .font(BaziTheme.body()).foregroundStyle(BaziTheme.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
    }

    // MARK: - 辅助

    private func chip(_ text: String, bg: Color, fg: Color) -> some View {
        Text(text).font(.system(size: 12)).foregroundStyle(fg)
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(bg).clipShape(Capsule())
    }

    /// 按今年（流年干支）十神生成宜忌与一句话提示（与首页「今日指南」共用 TenGodGuide）
    private func shiShenGuide(_ c: BaziChart) -> (yi: [String], ji: [String], tip: String) {
        let ss = c.liunian.first(where: { $0.year == currentYear })?.shiShen ?? ""
        return TenGodGuide.guide(ss)
    }

    /// 流年十神 → 吉 / 平 / 滞 档位
    private func fortuneGrade(_ ss: String) -> (String, Color) {
        TenGodGuide.grade(ss)
    }
}
