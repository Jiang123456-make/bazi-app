import SwiftUI

/// 术语解释 · 底部半屏卡（命盘页点按查词、顾问页共用）
struct GlossarySheet: View {
    let term: GlossaryTerm
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // 顶部抓取条
            Capsule().fill(BaziTheme.placeholder.opacity(0.4))
                .frame(width: 36, height: 5)
                .frame(maxWidth: .infinity)

            HStack(spacing: 10) {
                Text(term.name)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(BaziTheme.ink)
                Text(term.category)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(BaziTheme.actionBlue)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(BaziTheme.dayColumn)
                    .clipShape(Capsule())
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(BaziTheme.placeholder)
                }
            }

            Text(term.brief)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(BaziTheme.actionBlue)

            Rectangle().fill(BaziTheme.divider).frame(height: 1)

            ScrollView(showsIndicators: false) {
                Text(term.detail)
                    .font(.system(size: 14))
                    .foregroundStyle(BaziTheme.ink)
                    .lineSpacing(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Text("命理解释仅供文化参考")
                .font(.system(size: 11))
                .foregroundStyle(BaziTheme.placeholder)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 20)
        .presentationDetents([.height(360)])
        .presentationDragIndicator(.hidden)
        .presentationBackground(BaziTheme.canvas)
    }
}
