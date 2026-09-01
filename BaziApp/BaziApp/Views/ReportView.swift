import SwiftUI

/// 屏 3：命理·报告
struct ReportView: View {
    let chart: BaziChart?

    @State private var aiLoading = false
    @State private var aiText: String? = nil

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
                        dimensionCard(c)
                        fortuneCard(c)
                        yijiCard()
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
            case .success(let text): aiText = text
            case .failure: aiText = nil   // 保持 nil，卡片显示本地兜底文案
            }
        }
    }

    // MARK: - 综合评分卡（深色）

    private func scoreCard(_ c: BaziChart) -> some View {
        VStack(spacing: 8) {
            Text("\(score)").font(.system(size: 56, weight: .semibold)).foregroundStyle(.white)
            Text("综合运势 · \(level)").font(.system(size: 15)).foregroundStyle(BaziTheme.placeholder)
            Text("\(c.dayMaster)日主 · \(c.pattern)").font(.system(size: 13)).foregroundStyle(BaziTheme.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(BaziTheme.darkTile)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 20)
    }

    // MARK: - AI 解读卡（深色）

    private func aiCard(_ c: BaziChart) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("AI 解读").font(.system(size: 13, weight: .semibold)).foregroundStyle(.white).kerning(1.2)
                Spacer()
                if aiLoading {
                    ProgressView().tint(.white)
                }
            }
            if let text = aiText {
                Text(text)
                    .font(.system(size: 13)).foregroundStyle(.white)
                    .lineSpacing(6)
            } else if aiLoading {
                Text("灵犀正在结合您的命盘进行解读…")
                    .font(.system(size: 13)).foregroundStyle(BaziTheme.placeholder)
                    .lineSpacing(6)
            } else {
                Text(fallbackAI(c))
                    .font(.system(size: 13)).foregroundStyle(BaziTheme.placeholder)
                    .lineSpacing(6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(BaziTheme.darkTile)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 20)
    }

    /// 本地兜底文案（AI 不可用时展示）
    private func fallbackAI(_ c: BaziChart) -> String {
        "\(c.dayMaster)日主，\(c.strength)。\(c.pattern)，聪明且善于理财，适合文化创意、口才相关事业。当前大运\(c.dayun.indices.contains(c.currentDayunIndex) ? c.dayun[c.currentDayunIndex].ganzhi : "")，事业稳步上升。性格刚毅重情，但需注意脾气控制。"
    }

    // MARK: - 4 维度卡

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

    // MARK: - 10 年运势卡

    private func fortuneCard(_ c: BaziChart) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("10 年运势").font(BaziTheme.title(15)).foregroundStyle(BaziTheme.ink)
            HStack(spacing: 8) {
                ForEach(c.liunian.prefix(5), id: \.year) { ln in
                    let s = fortuneScore(ln)
                    VStack(spacing: 4) {
                        Text("\(ln.year)").font(.system(size: 11)).foregroundStyle(BaziTheme.secondary)
                        Text(ln.ganzhi).font(.system(size: 14, weight: .semibold)).foregroundStyle(BaziTheme.ink)
                        Text("\(s) 分").font(.system(size: 14, weight: .semibold)).foregroundStyle(s >= 8 ? BaziTheme.wood : (s >= 7 ? BaziTheme.earth : BaziTheme.fire))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
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

    // MARK: - 今日宜忌卡

    private func yijiCard() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今日宜忌").font(BaziTheme.title(15)).foregroundStyle(BaziTheme.ink)
            HStack(spacing: 10) {
                Text("宜").font(.system(size: 14, weight: .semibold)).foregroundStyle(BaziTheme.ink).frame(width: 28)
                chip("进取决策", bg: BaziTheme.shenshaGoodBG, fg: BaziTheme.shenshaGood)
                chip("主动出击", bg: BaziTheme.shenshaGoodBG, fg: BaziTheme.shenshaGood)
            }
            HStack(spacing: 10) {
                Text("忌").font(.system(size: 14, weight: .semibold)).foregroundStyle(BaziTheme.ink).frame(width: 28)
                chip("犹豫保守", bg: BaziTheme.shenshaBadBG, fg: BaziTheme.shenshaBad)
                chip("与人争执", bg: BaziTheme.shenshaBadBG, fg: BaziTheme.shenshaBad)
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

    private func dimensions(_ c: BaziChart) -> [(title: String, desc: String, score: Int)] {
        let strong = c.strength == "身旺"
        return [
            ("性格", strong ? "刚毅果决，重情重义，责任心强" : "温和细腻，善解人意，思虑周详", 9),
            ("事业", "食神生财，宜文化创意与口才表达", 8),
            ("财运", "正财平稳，中年后渐入佳境", 7),
            ("感情", "配偶宫坐食神，晚婚为宜", 8)
        ]
    }

    private var score: Int { 82 }
    private var level: String { "中上" }

    private func fortuneScore(_ ln: LiuNian) -> Int {
        // 简化：根据十神吉凶给分（食神/正官/正印/正财/偏财 吉，七杀/劫财/伤官 平或凶）
        switch ln.shiShen {
        case "正印", "正官", "正财", "偏财", "食神": return 8
        case "偏印", "比肩": return 7
        case "七杀", "劫财", "伤官": return 6
        default: return 7
        }
    }
}
