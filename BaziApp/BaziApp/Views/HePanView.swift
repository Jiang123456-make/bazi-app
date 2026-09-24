import SwiftUI

/// 屏 6：合盘·结果（双方四柱对照 + 生肖/日柱关系 + 五行互补 + 综合参考分）
struct HePanView: View {
    let result: HePanResult

    @State private var saved = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                pillarsCard
                relationCard("生肖关系", result.zodiacRelation, result.zodiacNote)
                relationCard("日柱关系", result.dayRelation, result.dayNote)
                complementCard
                scoreCard
                Spacer().frame(height: 12)
            }
        }
        .background(BaziTheme.canvas)
        .navigationTitle("合盘")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(BaziTheme.canvas, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { saveResult() } label: {
                    Text(saved ? "已保存" : "保存")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(saved ? BaziTheme.tertiary : BaziTheme.actionBlue)
                }
                .disabled(saved)
            }
        }
    }

    /// 存入合盘记录（我的页可复看）
    private func saveResult() {
        guard !saved else { return }
        HePanHistory.save(HePanEntry(
            aName: result.a.name,
            bName: result.b.name,
            aGanzhi: result.a.pillars.map(\.ganzhi).joined(separator: " "),
            bGanzhi: result.b.pillars.map(\.ganzhi).joined(separator: " "),
            zodiacRelation: result.zodiacRelation,
            dayRelation: result.dayRelation,
            score: result.score,
            detail: result))
        saved = true
    }

    // MARK: - 头部

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("合盘")
                .font(BaziTheme.largeTitle())
                .foregroundStyle(BaziTheme.ink)
            Text("\(result.a.gender == "男" ? "乾造" : "坤造") \(result.a.name) × \(result.b.gender == "男" ? "乾造" : "坤造") \(result.b.name)")
                .font(BaziTheme.footnote(14))
                .foregroundStyle(BaziTheme.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }

    // MARK: - 双方四柱对照

    private var pillarsCard: some View {
        VStack(spacing: 0) {
            personRow("甲方", result.a)
            Rectangle().fill(BaziTheme.divider).frame(height: 1).padding(.horizontal, 4)
            personRow("乙方", result.b)
        }
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .baziCard()
        .padding(.horizontal, 20)
    }

    private func personRow(_ side: String, _ c: BaziChart) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(side).font(.system(size: 13, weight: .semibold)).foregroundStyle(BaziTheme.ink)
                Text("\(c.name) · \(c.dayMaster)").font(.system(size: 10)).foregroundStyle(BaziTheme.tertiary)
            }
            .frame(width: 64, alignment: .leading)

            HStack(spacing: 0) {
                ForEach(0..<4, id: \.self) { i in
                    let p = c.pillars[i]
                    VStack(spacing: 2) {
                        Text(p.gan)
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundStyle(i == 2 ? BaziTheme.actionBlue : BaziTheme.wuxingColor(ganWuxing(p.gan)))
                        Text(p.zhi)
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundStyle(i == 2 ? BaziTheme.actionBlue : BaziTheme.wuxingColor(zhiWuxing(p.zhi)))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - 关系卡（生肖 / 日柱）

    private func relationCard(_ title: String, _ relation: String, _ note: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title).font(BaziTheme.title(15)).foregroundStyle(BaziTheme.ink)
                Spacer()
                Text(relation)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(relationColor(relation))
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(relationColor(relation).opacity(0.12))
                    .clipShape(Capsule())
            }
            Text(note)
                .font(.system(size: 13)).foregroundStyle(BaziTheme.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineSpacing(3)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .baziCard()
        .padding(.horizontal, 20)
    }

    // MARK: - 五行互补

    private var complementCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("五行互补").font(BaziTheme.title(15)).foregroundStyle(BaziTheme.ink)
                Spacer()
            }
            // 双方五行条对照
            ForEach([("甲方", result.a), ("乙方", result.b)], id: \.0) { side, c in
                let total = max(c.wuxingCount.values.reduce(0, +), 1)
                HStack(spacing: 8) {
                    Text(side).font(.system(size: 11)).foregroundStyle(BaziTheme.tertiary)
                        .frame(width: 30, alignment: .leading)
                    ForEach(["木", "火", "土", "金", "水"], id: \.self) { e in
                        let n = c.wuxingCount[e] ?? 0
                        Text("\(e)\(n)")
                            .font(.system(size: 11))
                            .foregroundStyle(n == 0 ? BaziTheme.placeholder : BaziTheme.wuxingColor(e))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 5)
                            .background(n == 0 ? BaziTheme.fill : BaziTheme.wuxingColor(e).opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                }
            }
            Text(result.complementNote)
                .font(.system(size: 13)).foregroundStyle(BaziTheme.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineSpacing(3)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .baziCard()
        .padding(.horizontal, 20)
    }

    // MARK: - 综合参考分

    private var scoreCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(result.score)").font(.system(size: 44, weight: .semibold)).foregroundStyle(BaziTheme.ink)
                Text("分 · 合婚参考").font(.system(size: 15)).foregroundStyle(BaziTheme.secondary)
                Spacer()
            }
            ForEach(result.summary, id: \.self) { line in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Circle().fill(BaziTheme.actionBlue).frame(width: 5, height: 5).padding(.top, 5)
                    Text(line).font(.system(size: 13)).foregroundStyle(BaziTheme.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineSpacing(3)
                }
            }
            Rectangle().fill(BaziTheme.divider).frame(height: 1)
            Text("合盘按生肖、日柱、五行互补综合评定，仅供文化娱乐参考，不构成感情决策依据")
                .font(.system(size: 11)).foregroundStyle(BaziTheme.placeholder)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .baziCard()
        .padding(.horizontal, 20)
    }

    // MARK: - 辅助

    private func relationColor(_ relation: String) -> Color {
        switch relation {
        case "六合", "三合", "天合地合", "天干五合", "地支六合":
            return BaziTheme.shenshaGood
        case "六冲":
            return BaziTheme.shenshaBad
        default:
            return BaziTheme.secondary
        }
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
