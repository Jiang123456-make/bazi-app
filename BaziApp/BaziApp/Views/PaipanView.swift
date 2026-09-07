import SwiftUI

/// 屏 1：排盘·输入（问真式：公农历一键切换 + 年月日时辰滚轮直选 + 最近排盘一键重排 + 真太阳时开关 + 底部常驻 CTA）
struct PaipanView: View {
    @Binding var chart: BaziChart?

    // MARK: - 输入状态（全部为滚轮下标）

    @State private var name = ""
    @State private var gender = "男"
    /// 历法：false 公历 / true 农历
    @State private var isLunar = false
    @State private var solarYIdx = 90      // 1990 年
    @State private var solarMIdx = 4       // 5 月
    @State private var solarDIdx = 14      // 15 日
    @State private var lunarYIdx = 90      // 1990 年
    @State private var lunarMIdx = 3       // 四月
    @State private var lunarDIdx = 20      // 廿一
    /// 0 = 时辰未知，1-12 = 子时～亥时
    @State private var shichenIdx = 7      // 午时
    @State private var place = PlaceData.unknown.name
    @State private var useTrueSolar = true
    @State private var showResult = false
    @State private var showPlacePicker = false
    @State private var history: [PaipanEntry] = []

    private let years = Array(1900...2099)
    private let lunarMonthNames = ["正月", "二月", "三月", "四月", "五月", "六月",
                                   "七月", "八月", "九月", "十月", "冬月", "腊月"]

    /// 时辰表（index 0 = 时辰未知，按午时试排）
    private struct ShiChen {
        let name: String
        let hour: Int
        let range: String
    }
    private let shichenList: [ShiChen] = [
        ShiChen(name: "时辰未知", hour: 12, range: "按午时试排"),
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

    /// 农历月条目（闰月跟在对应月后）
    private struct LunarMonth {
        let name: String
        let month: Int
        let isLeap: Bool
    }

    // MARK: - 派生数据

    private var solarYear: Int { years[solarYIdx] }
    private var solarMonth: Int { solarMIdx + 1 }
    private var solarDay: Int { solarDIdx + 1 }

    /// 公历当月天数（如 1990-02 → 28）
    private var solarDayCount: Int {
        var comps = DateComponents()
        comps.year = solarYear
        comps.month = solarMonth
        let cal = Calendar(identifier: .gregorian)
        guard let date = cal.date(from: comps),
              let interval = cal.dateInterval(of: .month, for: date) else { return 31 }
        return max(28, min(31, Int(interval.duration / 86400)))
    }

    private var lunarYear: Int { years[lunarYIdx] }

    private var lunarMonths: [LunarMonth] {
        let leap = LunarCalendar.leapMonth(lunarYear)
        var list: [LunarMonth] = []
        for (i, n) in lunarMonthNames.enumerated() {
            list.append(LunarMonth(name: n, month: i + 1, isLeap: false))
            if leap == i + 1 { list.append(LunarMonth(name: "闰" + n, month: i + 1, isLeap: true)) }
        }
        return list
    }

    private var lunarMonth: LunarMonth { lunarMonths[min(lunarMIdx, lunarMonths.count - 1)] }

    private var lunarDayCount: Int {
        let lm = lunarMonth
        return lm.isLeap ? LunarCalendar.leapDays(lunarYear) : LunarCalendar.monthDays(lunarYear, lm.month)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 16) {
                        header
                        recentStrip
                        formCard
                        wheelsCard
                        extraCard
                        Spacer().frame(height: 8)
                    }
                    .padding(.bottom, 12)
                }

                // 底部常驻操作区：排盘随时可点，不用滚回页面中间
                VStack(spacing: 2) {
                    Button(action: { generate() }) {
                        Text("开始排盘")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(BaziTheme.actionBlue)
                            .clipShape(Capsule())
                    }
                    Button(action: { loadDemo() }) {
                        Text("试排示例（用 demo 数据）")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(BaziTheme.actionBlue)
                            .padding(.vertical, 6)
                    }
                    Text("命理分析仅供文化娱乐参考，不构成决策依据")
                        .font(.system(size: 11))
                        .foregroundStyle(BaziTheme.placeholder)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 6)
                .background(BaziTheme.canvas)
                .overlay(alignment: .top) {
                    Rectangle().fill(BaziTheme.divider).frame(height: 1)
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
            .onAppear { history = PaipanHistory.load() }
        }
    }

    // MARK: - 头部

    private var header: some View {
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
    }

    // MARK: - 最近排盘（一键重排）

    @ViewBuilder
    private var recentStrip: some View {
        if !history.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("最近").font(.system(size: 12)).foregroundStyle(BaziTheme.tertiary)
                    .padding(.horizontal, 4)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(history.prefix(6)) { h in
                            Button { applyEntry(h) } label: {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(h.name.isEmpty ? "未命名" : h.name)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(BaziTheme.ink)
                                        .lineLimit(1)
                                    Text("\(h.dateStr) · \(h.ganzhi)")
                                        .font(.system(size: 10))
                                        .foregroundStyle(BaziTheme.tertiary)
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 9)
                                .frame(width: 176, alignment: .leading)
                                .background(BaziTheme.parchment)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.horizontal, -20)
            }
            .padding(.top, 4)
        }
    }

    // MARK: - 基础信息卡（称谓 / 性别 / 历法）

    private var formCard: some View {
        VStack(spacing: 0) {
            formRow("称谓") {
                TextField("如：陈先生", text: $name)
                    .multilineTextAlignment(.trailing)
                    .font(BaziTheme.body())
                    .foregroundStyle(BaziTheme.ink)
            }
            cardDivider()
            formRow("性别") {
                Picker("", selection: $gender) {
                    Text("男").tag("男")
                    Text("女").tag("女")
                }
                .pickerStyle(.segmented)
                .frame(width: 120)
            }
            cardDivider()
            formRow("历法") {
                Picker("", selection: $isLunar) {
                    Text("公历").tag(false)
                    Text("农历").tag(true)
                }
                .pickerStyle(.segmented)
                .frame(width: 120)
                .onChange(of: isLunar) { _ in syncCalendars() }
            }
        }
        .baziCard()
        .padding(.horizontal, 20)
    }

    // MARK: - 滚轮卡（年 / 月 / 日 / 时辰）

    private var wheelsCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                if isLunar {
                    wheelPicker("年", items: years.map { "\($0)年" }, selection: $lunarYIdx)
                    wheelPicker("月", items: lunarMonths.map(\.name), selection: $lunarMIdx)
                    wheelPicker("日", items: (1...max(lunarDayCount, 1)).map { LunarCalendar.dayName($0) },
                                selection: $lunarDIdx)
                } else {
                    wheelPicker("年", items: years.map { "\($0)年" }, selection: $solarYIdx)
                    wheelPicker("月", items: (1...12).map { "\($0)月" }, selection: $solarMIdx)
                    wheelPicker("日", items: (1...solarDayCount).map { "\($0)日" }, selection: $solarDIdx)
                }
                wheelPicker("时辰", items: shichenList.map(\.name), selection: $shichenIdx)
            }
            .frame(height: 118)

            Rectangle().fill(BaziTheme.divider).frame(height: 1).padding(.horizontal, 16)

            HStack(spacing: 8) {
                Image(systemName: "sun.max")
                    .font(.system(size: 12)).foregroundStyle(BaziTheme.secondary)
                Text(trueSolarHint)
                    .font(.system(size: 12))
                    .foregroundStyle(BaziTheme.secondary)
            }
            .padding(.vertical, 11)
            .padding(.horizontal, 16)
        }
        .baziCard()
        .padding(.horizontal, 20)
        .onChange(of: solarMIdx) { _ in clampSolarDay() }
        .onChange(of: solarYIdx) { _ in clampSolarDay() }
        .onChange(of: lunarYIdx) { _ in clampLunar() }
        .onChange(of: lunarMIdx) { _ in clampLunar() }
    }

    private func wheelPicker(_ label: String, items: [String], selection: Binding<Int>) -> some View {
        Picker(label, selection: selection) {
            ForEach(items.indices, id: \.self) { i in
                Text(items[i]).tag(i)
            }
        }
        .pickerStyle(.wheel)
        .frame(maxWidth: .infinity)
        .frame(height: 118)
        .clipped()
    }

    // MARK: - 出生地 / 真太阳时

    private var extraCard: some View {
        VStack(spacing: 0) {
            formRow("出生地") {
                Button {
                    showPlacePicker = true
                } label: {
                    HStack(spacing: 4) {
                        Text(place).font(BaziTheme.body()).foregroundStyle(BaziTheme.ink)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13)).foregroundStyle(BaziTheme.placeholder)
                    }
                }
            }
            cardDivider()
            formRow("真太阳时") {
                Toggle("", isOn: $useTrueSolar)
                    .labelsHidden()
                    .tint(BaziTheme.actionBlue)
            }
        }
        .baziCard()
        .padding(.horizontal, 20)
    }

    /// 真太阳时提示（含换算量；关闭时说明按北京时间）
    private var trueSolarHint: String {
        let sc = shichenList[shichenIdx]
        if !useTrueSolar {
            return "\(sc.name) \(sc.range) · 已关闭校正，按北京时间排盘"
        }
        let offset = BaziCalculator.longitudeOffset(place: place)
        let total = (sc.hour * 60 + offset + 24 * 60) % (24 * 60)
        return String(format: "%@ %@ · 真太阳时 %02d:%02d（%@%d 分）",
                      sc.name, sc.range, total / 60, total % 60,
                      offset >= 0 ? "+" : "-", abs(offset))
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
        .frame(minHeight: 52)
    }

    @ViewBuilder
    private func cardDivider() -> some View {
        Rectangle().fill(BaziTheme.divider).frame(height: 1).padding(.leading, 16)
    }

    // MARK: - 联动

    /// 公历当月天数变化时，把「日」滚轮夹回合法范围
    private func clampSolarDay() {
        if solarDIdx > solarDayCount - 1 { solarDIdx = solarDayCount - 1 }
    }

    /// 农历年/月变化时，重建闰月序列并夹回月、日范围
    private func clampLunar() {
        if lunarMIdx > lunarMonths.count - 1 { lunarMIdx = lunarMonths.count - 1 }
        if lunarDIdx > lunarDayCount - 1 { lunarDIdx = lunarDayCount - 1 }
    }

    /// 公农历切换时互转，保证切换前后是同一天
    private func syncCalendars() {
        if isLunar {
            let l = LunarCalendar.solarToLunar(year: solarYear, month: solarMonth, day: solarDay)
            lunarYIdx = max(0, min(years.count - 1, l.year - 1900))
            if let idx = lunarMonths.firstIndex(where: { $0.month == l.month && $0.isLeap == l.isLeap }) {
                lunarMIdx = idx
            }
            lunarDIdx = max(0, min(lunarDayCount - 1, l.day - 1))
        } else {
            let lm = lunarMonth
            if let s = LunarCalendar.lunarToSolar(lunarYear, lm.month, isLeap: lm.isLeap, lunarDIdx + 1) {
                solarYIdx = max(0, min(years.count - 1, s.year - 1900))
                solarMIdx = max(0, min(11, s.month - 1))
                solarDIdx = max(0, min(solarDayCount - 1, s.day - 1))
            }
        }
    }

    // MARK: - 动作

    /// 当前输入解析为公历日期（农历自动换算；超出 1900-2099 返回 nil）
    private func resolvedSolar() -> (year: Int, month: Int, day: Int)? {
        if isLunar {
            let lm = lunarMonth
            return LunarCalendar.lunarToSolar(lunarYear, lm.month, isLeap: lm.isLeap, lunarDIdx + 1)
        }
        guard solarDay >= 1, solarDay <= solarDayCount else { return nil }
        return (solarYear, solarMonth, solarDay)
    }

    private func generate() {
        guard let (y, m, d) = resolvedSolar() else { return }
        let dateStr = String(format: "%04d-%02d-%02d", y, m, d)
        let hourStr = String(format: "%02d:00", shichenList[shichenIdx].hour)
        let c = BaziCalculator.calculate(
            name: name.isEmpty ? "陈先生" : name,
            gender: gender,
            solarDate: dateStr,
            hour: hourStr,
            place: place,
            useTrueSolar: useTrueSolar
        )
        PaipanHistory.save(PaipanEntry(
            name: name.isEmpty ? "陈先生" : name,
            gender: gender,
            dateStr: dateStr,
            hour: hourStr,
            place: place,
            useTrueSolar: useTrueSolar,
            ganzhi: c.pillars.map(\.ganzhi).joined(separator: " ")
        ))
        chart = c
        showResult = true
    }

    /// 点「最近」卡片：还原输入并直接重排
    private func applyEntry(_ h: PaipanEntry) {
        name = h.name
        gender = h.gender
        place = h.place
        useTrueSolar = h.useTrueSolar
        isLunar = false
        let parts = h.dateStr.split(separator: "-").compactMap { Int($0) }
        if parts.count == 3 {
            solarYIdx = max(0, min(years.count - 1, parts[0] - 1900))
            solarMIdx = max(0, min(11, parts[1] - 1))
            solarDIdx = max(0, min(solarDayCount - 1, parts[2] - 1))
        }
        let hp = h.hour.split(separator: ":").compactMap { Int($0) }
        let hh = hp.first ?? 12
        // 从 index 1 起匹配时辰（0 是「时辰未知」，与午时同为 12 点）
        shichenIdx = (shichenList.dropFirst().firstIndex { $0.hour == hh } ?? 6) + 1
        generate()
    }

    private func loadDemo() {
        name = "陈先生"
        gender = "男"
        isLunar = false
        solarYIdx = 90; solarMIdx = 4; solarDIdx = 14
        shichenIdx = 7
        place = "北京"
        useTrueSolar = true
        generate()
    }
}
