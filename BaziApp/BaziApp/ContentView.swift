import SwiftUI

/// 根视图：4 个 Tab（排盘 / 报告 / 顾问 / 我的）
struct ContentView: View {
    @State private var selection = 0
    @State private var chart: BaziChart? = nil

    var body: some View {
        TabView(selection: $selection) {
            PaipanView(chart: $chart)
                .tabItem { Label("排盘", systemImage: "scope") }
                .tag(0)

            ReportView(chart: chart)
                .tabItem { Label("报告", systemImage: "doc.text") }
                .tag(1)

            AdvisorView(chart: chart)
                .tabItem { Label("顾问", systemImage: "bubble.left.and.bubble.right") }
                .tag(2)

            ProfileView(chart: chart)
                .tabItem { Label("我的", systemImage: "person") }
                .tag(3)
        }
        .tint(BaziTheme.actionBlue)
    }
}

#Preview {
    ContentView()
}
