import SwiftUI

/// 首次启动引导（3 页）——产品定位 / 数据承诺 / 合规口径
/// 仅首次启动展示（UserDefaults `onboarding.done`），完成后不再出现。
struct OnboardingView: View {
    var onFinish: () -> Void

    @State private var page = 0

    private let pages: [(icon: String, tint: Color, title: String, lines: [String])] = [
        ("scope", BaziTheme.actionBlue, "灵犀 · 八字排盘",
         ["问真式排盘：四柱、大运、流年、命宫身宫一站生成",
          "AI 顾问结合你的命盘逐一解读，可追问可存档",
          "合盘、术语词典、报告评分，完整闭环"]),
        ("lock.shield", BaziTheme.goldDeep, "数据只属于你",
         ["所有排盘与对话记录仅保存在本机",
          "不设服务器、不上传、不同步",
          "「清除我的数据」随时一键抹除"]),
        ("leaf", BaziTheme.shenshaGood, "文化参考口径",
         ["命理内容属传统文化研究范畴",
          "仅供娱乐与自我观察参考",
          "不构成医疗、投资等任何专业建议"]),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // 跳过
            HStack {
                Spacer()
                Button("跳过") { finish() }
                    .font(.system(size: 14))
                    .foregroundStyle(BaziTheme.secondary)
                    .padding(.trailing, 20)
                    .padding(.top, 12)
            }

            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { i in
                    pageView(pages[i]).tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button {
                if page < pages.count - 1 {
                    withAnimation { page += 1 }
                } else {
                    finish()
                }
            } label: {
                Text(page < pages.count - 1 ? "下一页" : "开始使用")
                    .font(BaziTheme.kai(17))
                    .foregroundStyle(BaziTheme.goldOnBlack)
                    .kerning(3)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(BaziTheme.blackPill)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 28)
        }
        .background(BaziTheme.canvas)
    }

    private func pageView(_ p: (icon: String, tint: Color, title: String, lines: [String])) -> some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                Circle()
                    .fill(p.tint.opacity(0.08))
                    .frame(width: 128, height: 128)
                Circle()
                    .stroke(p.tint.opacity(0.35), lineWidth: 1.5)
                    .frame(width: 104, height: 104)
                Image(systemName: p.icon)
                    .font(.system(size: 42, weight: .light))
                    .foregroundStyle(p.tint)
            }
            Text(p.title)
                .font(.system(size: 24, weight: .semibold, design: .serif))
                .foregroundStyle(BaziTheme.ink)
            VStack(spacing: 12) {
                ForEach(p.lines, id: \.self) { line in
                    Text(line)
                        .font(.system(size: 14))
                        .foregroundStyle(BaziTheme.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 40)
            Spacer()
            Spacer()
        }
        .padding(.bottom, 40)
    }

    private func finish() {
        UserDefaults.standard.set(true, forKey: "onboarding.done")
        onFinish()
    }
}
