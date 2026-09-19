import SwiftUI

/// 术语词典 · 全量浏览页（我的页「术语词典」入口）
/// 按分类分组（十神 / 星运 / 神煞 / 概念），点按任一条弹出底部解释卡。
struct GlossaryBrowser: View {
    @State private var term: GlossaryTerm? = nil
    @Environment(\.dismiss) private var dismiss

    private let categories = ["十神", "星运 · 十二长生", "神煞", "概念"]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    Text("排盘与解读中出现的术语都能在这里查到白话解释；命盘页里点带标记的词也可直接查。")
                        .font(.system(size: 12)).foregroundStyle(BaziTheme.tertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    ForEach(categories, id: \.self) { cat in
                        let items = Glossary.allTerms.filter { $0.category == cat }
                        if !items.isEmpty {
                            VStack(alignment: .leading, spacing: 0) {
                                Text("\(cat) · \(items.count) 条")
                                    .font(BaziTheme.title(14)).foregroundStyle(BaziTheme.ink)
                                    .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 4)
                                ForEach(items) { t in
                                    Button { term = t } label: {
                                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                                            Text(t.name)
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundStyle(BaziTheme.ink)
                                                .frame(width: 88, alignment: .leading)
                                            Text(t.brief)
                                                .font(.system(size: 12)).foregroundStyle(BaziTheme.secondary)
                                                .lineLimit(2)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 11)).foregroundStyle(BaziTheme.placeholder)
                                        }
                                        .padding(.horizontal, 16).padding(.vertical, 11)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .background(BaziTheme.cardBG)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(BaziTheme.hairline, lineWidth: 1)
                            )
                            .padding(.horizontal, 20)
                        }
                    }

                    Text("命理解释仅供文化参考")
                        .font(.system(size: 11)).foregroundStyle(BaziTheme.placeholder)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
            }
            .background(BaziTheme.canvas)
            .navigationTitle("术语词典")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22)).foregroundStyle(BaziTheme.placeholder)
                    }
                }
            }
        }
        .sheet(item: $term) { t in
            GlossarySheet(term: t)
        }
    }
}
