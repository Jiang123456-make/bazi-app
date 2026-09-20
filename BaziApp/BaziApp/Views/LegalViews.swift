import SwiftUI

/// 免责声明 / 隐私政策 / 关于 —— 我的页「设置」三张 Sheet
/// 审核合规项：免责声明（Guideline 1.4.1）+ 数据说明；备案号通过后在此展示。

// MARK: - 免责声明

struct DisclaimerSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        sheetScaffold(title: "免责声明") {
            card {
                sheetBody("本应用（灵犀命理）提供的八字排盘、命理解读、合盘与 AI 对话内容，仅限传统文化研究与个人娱乐参考，不构成医疗建议、心理诊断、投资理财建议或其他任何专业决策依据。")
                sheetBody("涉及健康、财务、婚姻等重大事项，请咨询相关领域持证专业人士。因使用本应用内容做出的任何决定，由用户自行承担。")
            }
        }
    }
}

// MARK: - 隐私政策

struct PrivacySheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        sheetScaffold(title: "隐私政策") {
            card {
                privacyRow("数据存储",
                           "所有排盘、合盘、会话与偏好数据仅保存在设备本机（UserDefaults），我们不设自有服务器，不上传、不同步。")
                sheetBody(" ")  // 分隔留白
                privacyRow("AI 服务",
                           "使用「顾问」联网功能时，仅发送你当次输入的问题文本及命盘摘要给大模型服务，不含姓名、出生地等身份信息，且不留存。")
                sheetBody(" ")
                privacyRow("随时删除",
                           "「清除我的数据」可一键抹除本机全部数据，无需联系我们。")
            }
        }
    }

    private func privacyRow(_ title: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.system(size: 15, weight: .semibold)).foregroundStyle(BaziTheme.ink)
            Text(detail).font(.system(size: 13)).foregroundStyle(BaziTheme.secondary).lineSpacing(5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - 关于

struct AboutSheet: View {
    @Environment(\.dismiss) private var dismiss
    /// ICP 备案号：备案通过后填入即自动展示（不必再改布局）
    private static let icpNumber: String? = nil

    @State private var devTaps = 0
    @State private var showDevInfo = false
    @State private var check: BaziSelfCheck.Result?

    private var versionText: String {
        let ver = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(ver) (\(build))"
    }

    var body: some View {
        sheetScaffold(title: "关于") {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(BaziTheme.actionBlue, lineWidth: 1.5)
                        .frame(width: 56, height: 56)
                    Text("灵")
                        .font(.system(size: 26, weight: .semibold, design: .serif))
                        .foregroundStyle(BaziTheme.goldDeep)
                }
                VStack(spacing: 4) {
                    Text("灵犀命理")
                        .font(.system(size: 20, weight: .semibold, design: .serif))
                        .foregroundStyle(BaziTheme.ink)
                    Text("本机排盘 · 数据不出设备")
                        .font(.system(size: 12)).foregroundStyle(BaziTheme.secondary)
                }

                card {
                    aboutRow("版本", versionText)
                    Divider().overlay(BaziTheme.divider)
                    if let icp = Self.icpNumber {
                        aboutRow("备案号", icp)
                        Divider().overlay(BaziTheme.divider)
                    }
                    aboutRow("内容口径", "仅供文化参考")
                }

                if showDevInfo {
                    devCard
                }
            }
            .onAppear {
                if check == nil {
                    Task.detached(priority: .utility) {
                        let result = BaziSelfCheck.run()
                        await MainActor.run { self.check = result }
                    }
                }
            }
        }
    }

    /// 开发者模式：连点版本号 7 次解锁引擎自检详情（调试卡不暴露给普通用户）
    private var devCard: some View {
        card {
            HStack {
                Text("引擎自检").font(.system(size: 15, weight: .semibold)).foregroundStyle(BaziTheme.ink)
                Spacer()
                Text(check.map { $0.summary } ?? "校验中…")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(check.map { $0.passed == $0.total } ?? true ? BaziTheme.shenshaGood : BaziTheme.shenshaBad)
            }
            if let check {
                ForEach(check.items.filter { !$0.ok }.isEmpty
                        ? Array(check.items.prefix(6))
                        : check.items.filter { !$0.ok },
                        id: \.name) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: item.ok ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(item.ok ? BaziTheme.shenshaGood : BaziTheme.shenshaBad)
                            .padding(.top, 1)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.name).font(.system(size: 12)).foregroundStyle(BaziTheme.ink)
                            Text(item.detail).font(.system(size: 10)).foregroundStyle(BaziTheme.secondary)
                        }
                    }
                }
                Text("对拍基线：历法事实锚点 / 立春节气交界 / 晚子时 / 极端经度 / 大运起运 / 命宫身宫。")
                    .font(.system(size: 10)).foregroundStyle(BaziTheme.tertiary)
            } else {
                Text("正在后台校验…").font(.system(size: 12)).foregroundStyle(BaziTheme.tertiary)
            }
        }
    }

    private func aboutRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.system(size: 14)).foregroundStyle(BaziTheme.ink)
            Spacer()
            Text(value)
                .font(.system(size: 14)).foregroundStyle(BaziTheme.secondary)
                .onTapGesture {
                    if label == "版本" {
                        devTaps += 1
                        if devTaps >= 7 { showDevInfo = true }
                    }
                }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 共用脚手架

private func sheetScaffold<Content: View>(title: String,
                                          @ViewBuilder content: () -> Content) -> some View {
    NavigationStack {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                content()
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(BaziTheme.canvas)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
    .presentationDetents([.height(520)])
    .presentationDragIndicator(.hidden)
    .presentationBackground(BaziTheme.canvas)
}

private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    VStack(alignment: .leading, spacing: 12) { content() }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(BaziTheme.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(BaziTheme.hairline, lineWidth: 1)
        )
}

private func sheetBody(_ text: String) -> some View {
    Text(text)
        .font(.system(size: 13))
        .foregroundStyle(BaziTheme.ink)
        .lineSpacing(6)
        .frame(maxWidth: .infinity, alignment: .leading)
}
