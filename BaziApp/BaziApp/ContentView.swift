import SwiftUI

/// 根视图：4 个 Tab（顾问 / 排盘 / 报告 / 我的）+ 首次启动引导
/// v1.1 差异化：AI 顾问升为第一屏（4.3(b) 应对——产品主轴 = 会记忆的 AI 命理顾问）
struct ContentView: View {
    @State private var selection = 0
    @State private var chart: BaziChart? = nil
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "onboarding.done")

    /// 空状态页「去排盘」的跨页跳转通道
    static let goPaipanNotification = Notification.Name("goPaipan")

    var body: some View {
        TabView(selection: $selection) {
            AdvisorView(chart: chart)
                .tabItem { Label("顾问", systemImage: "bubble.left.and.bubble.right") }
                .tag(0)

            PaipanView(chart: $chart)
                .tabItem { Label("排盘", systemImage: "scope") }
                .tag(1)

            ReportView(chart: chart)
                .tabItem { Label("报告", systemImage: "doc.text") }
                .tag(2)

            ProfileView(chart: $chart)
                .tabItem { Label("我的", systemImage: "person") }
                .tag(3)
        }
        .tint(BaziTheme.actionBlue)
        .onReceive(NotificationCenter.default.publisher(for: Self.goPaipanNotification)) { _ in
            selection = 1
        }
        .onAppear {
            if !showOnboarding { DailyReminder.applyStartupPreference() }
        }
        .onChange(of: showOnboarding) { newValue in
            // 引导结束时（首次安装完成引导）也按偏好对齐一次每日提醒
            if !newValue { DailyReminder.applyStartupPreference() }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView { showOnboarding = false }
        }
    }
}

#Preview {
    ContentView()
}
