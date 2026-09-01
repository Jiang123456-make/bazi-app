import SwiftUI

/// 屏 1：排盘·输入
struct PaipanView: View {
    @Binding var chart: BaziChart?

    @State private var name = ""
    @State private var solarDate = Date()
    @State private var shichenIndex = 6   // 默认午时
    @State private var gender = "男"
    @State private var place = PlaceData.unknown.name
    @State private var showResult = false
    @State private var showPlacePicker = false

    /// 十二时辰（子→亥），含代表小时与对应钟表时段
    private struct ShiChen {
        let name: String
        let hour: Int
        let range: String
    }
    private let shichenList: [ShiChen] = [
        ShiChen(name: "子时", hour: 0,  range: "23:00-00:59"),
        ShiChen(name: "丑时", hour: 1,  range: "01:00-02:59"),
        ShiChen(name: "寅时", hour: 3,  range: "03:00-04:59"),
        ShiChen(name: "卯时", hour: 5,  range: "05:00-06:59"),
        ShiChen(name: "辰时", hour: 7,  range: "07:00-08:59"),
        ShiChen(name: "巳时", hour: 9,  range: "09:00-10:59"),
        ShiChen(name: "午时", hour: 11, range: "11:00-12:59"),
        ShiChen(name: "未时", hour: 13, range: "13:00-14:59"),
        ShiChen(name: "申时", hour: 15, range: "15:00-16:59"),
        ShiChen(name: "酉时", hour: 17, range: "17:00-18:59"),
        ShiChen(name: "戌时", hour: 19, range: "19:00-20:59"),
        ShiChen(name: "亥时", hour: 21, range: "21:00-22:59")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 标题区
                    VStack(alignment: .leading, spacing: 8) {
                        Text("排盘")
                            .font(BaziTheme.largeTitle())
                            .foregroundStyle(BaziTheme.ink)
                        Text("输入生辰，AI 智能体为你生成专属命盘")
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
                                .environment(\.locale, Locale(identifier: "zh_CN"))
                        })
                        divider()
                        formRow("出生时辰", content: {
                            Picker("", selection: $shichenIndex) {
                                ForEach(0..<shichenList.count, id: \.self) { i in
                                    Text(shichenList[i].name).tag(i)
                                }
                            }
                            .pickerStyle(.menu)
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
                            Button {
                                showPlacePicker = true
                            } label: {
                                HStack(spacing: 4) {
                                    Text(place).font(BaziTheme.body()).foregroundStyle(BaziTheme.ink)
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13)).foregroundStyle(BaziTheme.placeholder)
                                }
                            }
                        })
                    }
                    .baziCard()
                    .padding(.horizontal, 20)

                    // 时辰 / 真太阳时提示
                    HStack(spacing: 8) {
                        Image(systemName: "sun.max")
                            .font(.system(size: 13)).foregroundStyle(BaziTheme.secondary)
                        Text("\(shichenList[shichenIndex].name) \(shichenList[shichenIndex].range) · 排盘时按出生地自动校正真太阳时")
                            .font(.system(size: 12))
                            .foregroundStyle(BaziTheme.secondary)
                    }
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
            .sheet(isPresented: $showPlacePicker) {
                PlacePickerView(selection: $place)
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
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let dateStr = formatter.string(from: solarDate)
        let hourStr = String(format: "%02d:00", shichenList[shichenIndex].hour)
        chart = BaziCalculator.calculate(
            name: name.isEmpty ? "陈先生" : name,
            gender: gender,
            solarDate: dateStr,
            hour: hourStr,
            place: place
        )
        showResult = true
    }

    private func loadDemo() {
        chart = BaziCalculator.calculate(name: "陈先生", gender: "男", solarDate: "1990-05-15", hour: "12:00", place: "北京")
        showResult = true
    }
}
