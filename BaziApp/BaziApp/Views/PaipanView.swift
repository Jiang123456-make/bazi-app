import SwiftUI

/// 屏 1：排盘·输入（问真式：单盘/合盘切换 + 公农历一键互转 + 年月日时辰滚轮直选 + 最近排盘一键重排 + 底部常驻 CTA）
struct PaipanView: View {
    @Binding var chart: BaziChart?

    // MARK: - 输入状态

    /// false 单盘 / true 合盘
    @State private var hepanMode = false
    @State private var personA = BirthInput()   // 默认 1990-05-15 午时
    @State private var personB = BirthInput(name: "", gender: "女",
                                            solarYIdx: 91, solarMIdx: 5, solarDIdx: 17,
                                            lunarYIdx: 91, lunarMIdx: 4, lunarDIdx: 6,
                                            shichenIdx: 1)   // 默认 1991-06-18 子时
    @State private var place = PlaceData.unknown.name
    @State private var useTrueSolar = true
    @State private var showResult = false
    @State private var showHePan = false
    @State private var showPlacePicker = false
    @State private var history: [PaipanEntry] = []
    @State private var hePanResult: HePanResult? = nil
    /// 今日干支（今日指南卡数据源；onAppear 懒加载）
    @State private var daily: BaziChart? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 16) {
                        header
                        dailyCard
                        recentStrip
                        modeCard

                        BirthWheelCard(input: $personA, title: hepanMode ? "甲方" : nil,
                                       place: place, useTrueSolar: useTrueSolar)
                        if hepanMode {
                            BirthWheelCard(input: $personB, title: "乙方",
                                           place: place, useTrueSolar: useTrueSolar)
                        }

                        extraCard
                        Spacer().frame(height: 8)
                    }
                    .padding(.bottom, 12)
                }

                // 底部常驻操作区：排盘/合盘随时可点，不用滚回页面中间
                VStack(spacing: 2) {
                    Button(action: { hepanMode ? generateHePan() : generate() }) {
                        Text(hepanMode ? "开始合盘" : "开始排盘")
                            .font(BaziTheme.kai(18))
                            .foregroundStyle(BaziTheme.goldOnBlack)
                            .kerning(4)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(BaziTheme.blackPill)
                            .clipShape(Capsule())
                    }
                    Button(action: { loadDemo() }) {
                        Text(hepanMode ? "试排示例（双方 demo 数据）" : "试排示例（用 demo 数据）")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(BaziTheme.goldDeep)
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
            .navigationDestination(isPresented: $showHePan) {
                if let r = hePanResult {
                    HePanView(result: r)
                }
            }
            .sheet(isPresented: $showPlacePicker) {
                PlacePickerView(selection: $place)
            }
            .onAppear {
                history = PaipanHistory.load()
                if daily == nil {
                    let f = DateFormatter()
                    f.dateFormat = "yyyy-MM-dd"
                    daily = BaziCalculator.calculate(name: "今日", gender: "男",
                                                     solarDate: f.string(from: Date()),
                                                     hour: "12:00", place: "北京", useTrueSolar: false)
                }
            }
        }
    }

    // MARK: - 头部

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("排盘")
                .font(BaziTheme.largeTitle())
                .foregroundStyle(BaziTheme.ink)
            Text(hepanMode ? "输入双方生辰，合看两人八字关系" : "输入生辰，AI 智能体为你生成专属命盘")
                .font(BaziTheme.footnote(15))
                .foregroundStyle(BaziTheme.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 24)
    }

    // MARK: - 今日指南（今日干支 + 与命主日主的关系 + 宜忌）

    @ViewBuilder
    private var dailyCard: some View {
        if let d = daily {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Text("今")
                        .font(BaziTheme.kai(12))
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(BaziTheme.actionBlue)
                        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                    Text("今日 · 指南").font(BaziTheme.title(15)).foregroundStyle(BaziTheme.ink)
                    Spacer()
                    Text(d.solarDate).font(.system(size: 12)).foregroundStyle(BaziTheme.tertiary)
                }

                HStack(spacing: 10) {
                    let dg = d.pillars[2].gan
                    let dz = d.pillars[2].zhi
                    Text(dg).font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(wuxingOfGan(dg))
                    Text(dz).font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(wuxingOfZhi(dz))
                    Text("日 · \(d.pillars[2].naYin)")
                        .font(.system(size: 11)).foregroundStyle(BaziTheme.tertiary)
                    Spacer()
                    if let c = chart {
                        let ss = ShiShen.of(dayGan: String(c.dayMaster.first ?? "甲"), targetGan: dg)
                        let grade = TenGodGuide.grade(ss)
                        Text("对您 · \(ss)")
                            .font(.system(size: 12, weight: .semibold)).foregroundStyle(BaziTheme.actionBlue)
                            .padding(.horizontal, 9).padding(.vertical, 4)
                            .background(BaziTheme.dayColumn).clipShape(Capsule())
                        Text(grade.0)
                            .font(.system(size: 12, weight: .semibold)).foregroundStyle(grade.1)
                    }
                }

                if let c = chart {
                    let ss = ShiShen.of(dayGan: String(c.dayMaster.first ?? "甲"), targetGan: d.pillars[2].gan)
                    let guide = TenGodGuide.guide(ss)
                    HStack(spacing: 6) {
                        Text("宜").font(.system(size: 12, weight: .semibold)).foregroundStyle(BaziTheme.shenshaGood)
                        ForEach(guide.yi, id: \.self) { t in
                            Text(t).font(.system(size: 11))
                                .foregroundStyle(BaziTheme.shenshaGood)
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(BaziTheme.shenshaGoodBG).clipShape(Capsule())
                        }
                        Spacer(minLength: 0)
                    }
                    HStack(spacing: 6) {
                        Text("忌").font(.system(size: 12, weight: .semibold)).foregroundStyle(BaziTheme.shenshaBad)
                        ForEach(guide.ji, id: \.self) { t in
                            Text(t).font(.system(size: 11))
                                .foregroundStyle(BaziTheme.shenshaBad)
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(BaziTheme.shenshaBadBG).clipShape(Capsule())
                        }
                        Spacer(minLength: 0)
                    }
                    Text(guide.tip)
                        .font(.system(size: 12)).foregroundStyle(BaziTheme.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text("完成一次排盘后，这里会显示今日与您命局的关系和宜忌")
                        .font(.system(size: 12)).foregroundStyle(BaziTheme.tertiary)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .baziCard()
            .padding(.horizontal, 20)
        }
    }

    private func wuxingOfGan(_ g: String) -> Color {
        if let i = Gan.all.firstIndex(of: g) { return BaziTheme.wuxingColor(Gan.wuxing[i]) }
        return BaziTheme.ink
    }

    private func wuxingOfZhi(_ z: String) -> Color {
        if let i = Zhi.all.firstIndex(of: z) { return BaziTheme.wuxingColor(Zhi.wuxing[i]) }
        return BaziTheme.ink
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

    // MARK: - 模式切换（单盘 / 合盘）

    private var modeCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text("模式").font(BaziTheme.body()).foregroundStyle(BaziTheme.ink)
                Spacer()
                Picker("", selection: $hepanMode) {
                    Text("单盘").tag(false)
                    Text("合盘").tag(true)
                }
                .pickerStyle(.segmented)
                .frame(width: 140)
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 52)
        }
        .baziCard()
        .padding(.horizontal, 20)
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
            formRow(hepanMode ? "真太阳时（双方）" : "真太阳时") {
                Toggle("", isOn: $useTrueSolar)
                    .labelsHidden()
                    .tint(BaziTheme.actionBlue)
            }
        }
        .baziCard()
        .padding(.horizontal, 20)
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

    // MARK: - 动作

    private func generate() {
        guard let (y, m, d) = resolveDate(personA) else { return }
        let name = personA.name.isEmpty ? "陈先生" : personA.name
        let dateStr = String(format: "%04d-%02d-%02d", y, m, d)
        let hourStr = String(format: "%02d:00", BirthOptions.shichenList[personA.shichenIdx].hour)
        let c = BaziCalculator.calculate(
            name: name,
            gender: personA.gender,
            solarDate: dateStr,
            hour: hourStr,
            place: place,
            useTrueSolar: useTrueSolar
        )
        PaipanHistory.save(PaipanEntry(
            name: name,
            gender: personA.gender,
            dateStr: dateStr,
            hour: hourStr,
            place: place,
            useTrueSolar: useTrueSolar,
            ganzhi: c.pillars.map(\.ganzhi).joined(separator: " ")
        ))
        chart = c
        showResult = true
    }

    private func generateHePan() {
        guard let (ya, ma, da) = resolveDate(personA),
              let (yb, mb, db) = resolveDate(personB) else { return }
        let nameA = personA.name.isEmpty ? "陈先生" : personA.name
        let nameB = personB.name.isEmpty ? (personB.gender == "女" ? "王女士" : "李先生") : personB.name
        let dateA = String(format: "%04d-%02d-%02d", ya, ma, da)
        let dateB = String(format: "%04d-%02d-%02d", yb, mb, db)
        let hourA = String(format: "%02d:00", BirthOptions.shichenList[personA.shichenIdx].hour)
        let hourB = String(format: "%02d:00", BirthOptions.shichenList[personB.shichenIdx].hour)

        let ca = BaziCalculator.calculate(name: nameA, gender: personA.gender,
                                          solarDate: dateA, hour: hourA,
                                          place: place, useTrueSolar: useTrueSolar)
        let cb = BaziCalculator.calculate(name: nameB, gender: personB.gender,
                                          solarDate: dateB, hour: hourB,
                                          place: place, useTrueSolar: useTrueSolar)
        PaipanHistory.save(PaipanEntry(name: nameA, gender: personA.gender, dateStr: dateA, hour: hourA,
                                       place: place, useTrueSolar: useTrueSolar,
                                       ganzhi: ca.pillars.map(\.ganzhi).joined(separator: " ")))
        PaipanHistory.save(PaipanEntry(name: nameB, gender: personB.gender, dateStr: dateB, hour: hourB,
                                       place: place, useTrueSolar: useTrueSolar,
                                       ganzhi: cb.pillars.map(\.ganzhi).joined(separator: " ")))
        hePanResult = HePan.calculate(a: ca, b: cb)
        showHePan = true
    }

    /// 点「最近」卡片：还原输入并直接重排
    private func applyEntry(_ h: PaipanEntry) {
        hepanMode = false
        personA = BirthInput(name: h.name, gender: h.gender)
        personA.isLunar = false
        let parts = h.dateStr.split(separator: "-").compactMap { Int($0) }
        if parts.count == 3 {
            personA.solarYIdx = max(0, min(BirthOptions.years.count - 1, parts[0] - 1900))
            personA.solarMIdx = max(0, min(11, parts[1] - 1))
            personA.solarDIdx = max(0, min(personA.solarDayCount - 1, parts[2] - 1))
        }
        let hp = h.hour.split(separator: ":").compactMap { Int($0) }
        let hh = hp.first ?? 12
        // 从 index 1 起匹配时辰（0 是「时辰未知」，与午时同为 12 点）
        personA.shichenIdx = (BirthOptions.shichenList.dropFirst().firstIndex { $0.hour == hh } ?? 6) + 1
        place = h.place
        useTrueSolar = h.useTrueSolar
        generate()
    }

    private func loadDemo() {
        if hepanMode {
            personA = BirthInput(name: "陈先生", gender: "男")
            personB = BirthInput(name: "王女士", gender: "女",
                                 solarYIdx: 91, solarMIdx: 5, solarDIdx: 17,
                                 lunarYIdx: 91, lunarMIdx: 4, lunarDIdx: 6,
                                 shichenIdx: 1)
        } else {
            personA = BirthInput(name: "陈先生", gender: "男")
        }
        place = "北京"
        useTrueSolar = true
        if hepanMode { generateHePan() } else { generate() }
    }
}

// MARK: - 生辰输入数据

/// 一个人的一次生辰输入（全部为滚轮下标）
struct BirthInput {
    var name = ""
    var gender = "男"
    /// false 公历 / true 农历
    var isLunar = false
    var solarYIdx = 90      // 1990 年
    var solarMIdx = 4       // 5 月
    var solarDIdx = 14      // 15 日
    var lunarYIdx = 90
    var lunarMIdx = 3       // 四月
    var lunarDIdx = 20      // 廿一
    /// 0 = 时辰未知，1-12 = 子时～亥时
    var shichenIdx = 7      // 午时

    var solarYear: Int { BirthOptions.years[solarYIdx] }
    var solarMonth: Int { solarMIdx + 1 }
    var solarDay: Int { solarDIdx + 1 }

    /// 公历当月天数（如 1990-02 → 28）
    var solarDayCount: Int {
        var comps = DateComponents()
        comps.year = solarYear
        comps.month = solarMonth
        let cal = Calendar(identifier: .gregorian)
        guard let date = cal.date(from: comps),
              let interval = cal.dateInterval(of: .month, for: date) else { return 31 }
        return max(28, min(31, Int(interval.duration / 86400)))
    }

    var lunarYear: Int { BirthOptions.years[lunarYIdx] }

    var lunarMonths: [BirthOptions.LunarMonth] {
        let leap = LunarCalendar.leapMonth(lunarYear)
        var list: [BirthOptions.LunarMonth] = []
        for (i, n) in BirthOptions.lunarMonthNames.enumerated() {
            list.append(BirthOptions.LunarMonth(name: n, month: i + 1, isLeap: false))
            if leap == i + 1 { list.append(BirthOptions.LunarMonth(name: "闰" + n, month: i + 1, isLeap: true)) }
        }
        return list
    }

    var lunarMonth: BirthOptions.LunarMonth { lunarMonths[min(lunarMIdx, lunarMonths.count - 1)] }

    var lunarDayCount: Int {
        let lm = lunarMonth
        return lm.isLeap ? LunarCalendar.leapDays(lunarYear) : LunarCalendar.monthDays(lunarYear, lm.month)
    }
}

/// 滚轮 / 时辰 / 农历月共用常量
enum BirthOptions {
    static let years = Array(1900...2099)
    static let lunarMonthNames = ["正月", "二月", "三月", "四月", "五月", "六月",
                                  "七月", "八月", "九月", "十月", "冬月", "腊月"]

    struct LunarMonth {
        let name: String
        let month: Int
        let isLeap: Bool
    }

    /// 时辰表（index 0 = 时辰未知，按午时试排）
    struct ShiChen {
        let name: String
        let hour: Int
        let range: String
    }
    static let shichenList: [ShiChen] = [
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
}

// MARK: - 单人生辰输入卡（称谓/性别/历法 + 年月日时辰滚轮 + 真太阳时换算提示）

private struct BirthWheelCard: View {
    @Binding var input: BirthInput
    /// 合盘模式下显示「甲方 / 乙方」分组标题；单盘为 nil
    let title: String?
    let place: String
    let useTrueSolar: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title {
                Text(title).font(.system(size: 12)).foregroundStyle(BaziTheme.tertiary)
                    .padding(.horizontal, 4)
            }

            VStack(spacing: 0) {
                formRow("称谓") {
                    TextField(title == "乙方" ? "如：王女士" : "如：陈先生", text: $input.name)
                        .multilineTextAlignment(.trailing)
                        .font(BaziTheme.body())
                        .foregroundStyle(BaziTheme.ink)
                }
                cardDivider()
                formRow("性别") {
                    Picker("", selection: $input.gender) {
                        Text("男").tag("男")
                        Text("女").tag("女")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 120)
                }
                cardDivider()
                formRow("历法") {
                    Picker("", selection: $input.isLunar) {
                        Text("公历").tag(false)
                        Text("农历").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 120)
                    .onChange(of: input.isLunar) { _ in syncCalendars() }
                }
            }
            .baziCard()

            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    if input.isLunar {
                        wheelPicker("年", items: BirthOptions.years.map { "\($0)年" }, selection: $input.lunarYIdx)
                        wheelPicker("月", items: input.lunarMonths.map(\.name), selection: $input.lunarMIdx)
                        wheelPicker("日", items: (1...max(input.lunarDayCount, 1)).map { LunarCalendar.dayName($0) },
                                    selection: $input.lunarDIdx)
                    } else {
                        wheelPicker("年", items: BirthOptions.years.map { "\($0)年" }, selection: $input.solarYIdx)
                        wheelPicker("月", items: (1...12).map { "\($0)月" }, selection: $input.solarMIdx)
                        wheelPicker("日", items: (1...input.solarDayCount).map { "\($0)日" }, selection: $input.solarDIdx)
                    }
                    wheelPicker("时辰", items: Self.shichenWheelItems, selection: $input.shichenIdx,
                                width: 154, fontSize: 13)
                }
                .frame(height: 118)

                Rectangle().fill(BaziTheme.divider).frame(height: 1).padding(.horizontal, 16)

                HStack(spacing: 8) {
                    Image(systemName: "sun.max")
                        .font(.system(size: 12)).foregroundStyle(BaziTheme.secondary)
                    Text(hint)
                        .font(.system(size: 12))
                        .foregroundStyle(BaziTheme.secondary)
                }
                .padding(.vertical, 11)
                .padding(.horizontal, 16)
            }
            .baziCard()
            .onChange(of: input.solarMIdx) { _ in clampSolarDay() }
            .onChange(of: input.solarYIdx) { _ in clampSolarDay() }
            .onChange(of: input.lunarYIdx) { _ in clampLunar() }
            .onChange(of: input.lunarMIdx) { _ in clampLunar() }
        }
        .padding(.horizontal, 20)
    }

    /// 时辰滚轮条目：时辰名 + 24 小时制时段（如「午时 11:00-12:59」）
    static let shichenWheelItems: [String] = BirthOptions.shichenList.map {
        $0.name == "时辰未知" ? "未知 · 按午时试排" : "\($0.name) \($0.range)"
    }

    /// 真太阳时提示（含换算量；关闭时说明按北京时间）
    private var hint: String {
        let sc = BirthOptions.shichenList[input.shichenIdx]
        if !useTrueSolar {
            return "\(sc.name) \(sc.range) · 已关闭校正，按北京时间排盘"
        }
        let offset = BaziCalculator.longitudeOffset(place: place)
        let total = (sc.hour * 60 + offset + 24 * 60) % (24 * 60)
        return String(format: "%@ %@ · 真太阳时 %02d:%02d（%@%d 分）",
                      sc.name, sc.range, total / 60, total % 60,
                      offset >= 0 ? "+" : "-", abs(offset))
    }

    private func wheelPicker(_ label: String, items: [String], selection: Binding<Int>,
                             width: CGFloat? = nil, fontSize: CGFloat = 15) -> some View {
        let picker = Picker(label, selection: selection) {
            ForEach(items.indices, id: \.self) { i in
                Text(items[i])
                    .font(.system(size: fontSize))
                    .tag(i)
            }
        }
        .pickerStyle(.wheel)
        .font(.system(size: fontSize))
        return Group {
            if let w = width {
                picker.frame(width: w)
            } else {
                picker.frame(maxWidth: .infinity)
            }
        }
        .frame(height: 118)
        .clipped()
    }

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

    private func clampSolarDay() {
        if input.solarDIdx > input.solarDayCount - 1 { input.solarDIdx = input.solarDayCount - 1 }
    }

    private func clampLunar() {
        if input.lunarMIdx > input.lunarMonths.count - 1 { input.lunarMIdx = input.lunarMonths.count - 1 }
        if input.lunarDIdx > input.lunarDayCount - 1 { input.lunarDIdx = input.lunarDayCount - 1 }
    }

    /// 公农历切换时互转，保证切换前后是同一天
    private func syncCalendars() {
        if input.isLunar {
            let l = LunarCalendar.solarToLunar(year: input.solarYear, month: input.solarMonth, day: input.solarDay)
            input.lunarYIdx = max(0, min(BirthOptions.years.count - 1, l.year - 1900))
            if let idx = input.lunarMonths.firstIndex(where: { $0.month == l.month && $0.isLeap == l.isLeap }) {
                input.lunarMIdx = idx
            }
            input.lunarDIdx = max(0, min(input.lunarDayCount - 1, l.day - 1))
        } else {
            let lm = input.lunarMonth
            if let s = LunarCalendar.lunarToSolar(input.lunarYear, lm.month, isLeap: lm.isLeap, input.lunarDIdx + 1) {
                input.solarYIdx = max(0, min(BirthOptions.years.count - 1, s.year - 1900))
                input.solarMIdx = max(0, min(11, s.month - 1))
                input.solarDIdx = max(0, min(input.solarDayCount - 1, s.day - 1))
            }
        }
    }
}

/// 输入解析为公历日期（农历自动换算；超出 1900-2099 返回 nil）
private func resolveDate(_ input: BirthInput) -> (year: Int, month: Int, day: Int)? {
    if input.isLunar {
        let lm = input.lunarMonth
        return LunarCalendar.lunarToSolar(input.lunarYear, lm.month, isLeap: lm.isLeap, input.lunarDIdx + 1)
    }
    guard input.solarDay >= 1, input.solarDay <= input.solarDayCount else { return nil }
    return (input.solarYear, input.solarMonth, input.solarDay)
}
