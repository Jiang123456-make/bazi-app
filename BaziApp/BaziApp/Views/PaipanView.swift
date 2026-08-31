import SwiftUI

/// 屏 1：排盘·输入
struct PaipanView: View {
    @Binding var chart: BaziChart?

    @State private var name = ""
    @State private var solarDate = Date()
    @State private var hour = Date()
    @State private var gender = "男"
    @State private var place = "北京"
    @State private var showResult = false

    private let places = ["北京", "上海", "广州", "成都", "重庆", "西安", "武汉", "杭州"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 标题区
                    VStack(alignment: .leading, spacing: 8) {
                        Text("排盘")
                            .font(BaziTheme.largeTitle())
                            .foregroundStyle(BaziTheme.ink)
                        Text("让 AI 智能体生成你的专属命盘")
                            .font(BaziTheme.footnote(15))
                            .foregroundStyle(BaziTheme.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 24)

                    // 灵犀介绍卡
                    HStack(spacing: 14) {
                        ZStack {
                            Circle().fill(BaziTheme.actionBlue).frame(width: 44, height: 44)
                            Text("灵").font(.system(size: 20, weight: .semibold)).foregroundStyle(.white)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("灵犀").font(.system(size: 16, weight: .semibold)).foregroundStyle(.white)
                            Text("你的 AI 命理顾问 · 阅盘 1000+").font(.system(size: 12)).foregroundStyle(BaziTheme.placeholder)
                        }
                        Spacer()
                    }
                    .padding(16)
                    .background(BaziTheme.darkTile)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal, 20)

                    // 生辰表单
                    VStack(spacing: 0) {
                        formRow("姓名", content: {
                            TextField("请输入姓名", text: $name)
                                .multilineTextAlignment(.trailing)
                                .font(BaziTheme.body())
                                .foregroundStyle(BaziTheme.ink)
                        })
                        divider()
                        formRow("阳历生日", content: {
                            DatePicker("", selection: $solarDate, displayedComponents: .date)
                                .labelsHidden()
                                .tint(BaziTheme.actionBlue)
                        })
                        divider()
                        formRow("出生时辰", content: {
                            DatePicker("", selection: $hour, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .tint(BaziTheme.actionBlue)
                        })
                        divider()
                        formRow("性别", content: {
                            Picker("", selection: $gender) {
                                Text("男").tag("男")
                                Text("女").tag("女")
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 120)
                        })
                        divider()
                        formRow("出生地", content: {
                            Picker("", selection: $place) {
                                ForEach(places, id: \.self) { Text($0) }
                            }
                            .tint(BaziTheme.actionBlue)
                        })
                    }
                    .baziCard()
                    .padding(.horizontal, 20)

                    // 主 CTA
                    Button(action: { generate() }) {
                        Text("开始排盘")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(BaziTheme.actionBlue)
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, 20)

                    // 试排示例
                    Button(action: { loadDemo() }) {
                        Text("试排示例（用 demo 数据）")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(BaziTheme.actionBlue)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(BaziTheme.canvas)
                            .overlay(Capsule().stroke(BaziTheme.actionBlue, lineWidth: 1.5))
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, 20)

                    // 免责
                    Text("命理分析仅供文化参考，不构成决策依据")
                        .font(.system(size: 12))
                        .foregroundStyle(BaziTheme.placeholder)
                        .padding(.bottom, 20)
                }
            }
            .background(BaziTheme.canvas)
            .navigationDestination(isPresented: $showResult) {
                if let c = chart {
                    ChartView(chart: c)
                }
            }
        }
    }

    // MARK: - 表单行

    @ViewBuilder
    private func formRow<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(label).font(BaziTheme.body()).foregroundStyle(BaziTheme.ink)
            Spacer()
            content()
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
    }

    @ViewBuilder
    private func divider() -> some View {
        Rectangle().fill(BaziTheme.divider).frame(height: 1).padding(.leading, 16)
    }

    // MARK: - 动作

    private func generate() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: solarDate)
        let hf = DateFormatter()
        hf.dateFormat = "HH:mm"
        let hourStr = hf.string(from: hour)
        chart = BaziCalculator.calculate(name: name.isEmpty ? "陈先生" : name, gender: gender, solarDate: dateStr, hour: hourStr, place: place)
        showResult = true
    }

    private func loadDemo() {
        chart = BaziCalculator.calculate(name: "陈先生", gender: "男", solarDate: "1990-05-15", hour: "12:00", place: "北京")
        showResult = true
    }
}
