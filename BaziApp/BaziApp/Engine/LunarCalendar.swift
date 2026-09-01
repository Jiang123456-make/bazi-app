import Foundation

/// 农历引擎（1900-2100 农历转换 + 生肖 + 星座）
/// 移植自经典公开农历算法（lunarInfo 查表），用于命盘「基本信息」模块的农历日期、生肖、星座展示。
enum LunarCalendar {

    // MARK: - 农历数据表（1900-2100，每年一个十六进制数）
    // 每项含义：低 4 位 = 闰月月份（0 表示无闰月），
    // 其余位从高位到低位依次表示农历 1-12 月的大小月（1=大月30天，0=小月29天），
    // 第 16 位（0x10000）表示闰月大小（1=30天，0=29天）。

    private static let lunarInfo: [Int] = [
        0x04bd8, 0x04ae0, 0x0a570, 0x054d5, 0x0d260, 0x0d950, 0x16554, 0x056a0, 0x09ad0, 0x055d2, // 1900-1909
        0x04ae0, 0x0a5b6, 0x0a4d0, 0x0d250, 0x1d255, 0x0b540, 0x0d6a0, 0x0ada2, 0x095b0, 0x14977, // 1910-1919
        0x04970, 0x0a4b0, 0x0b4b5, 0x06a50, 0x06d40, 0x1ab54, 0x02b60, 0x09570, 0x052f2, 0x04970, // 1920-1929
        0x06566, 0x0d4a0, 0x0ea50, 0x06e95, 0x05ad0, 0x02b60, 0x186e3, 0x092e0, 0x1c8d7, 0x0c950, // 1930-1939
        0x0d4a0, 0x1d8a6, 0x0b550, 0x056a0, 0x1a5b4, 0x025d0, 0x092d0, 0x0d2b2, 0x0a950, 0x0b557, // 1940-1949
        0x06ca0, 0x0b550, 0x15355, 0x04da0, 0x0a5b0, 0x14573, 0x052b0, 0x0a9a8, 0x0e950, 0x06aa0, // 1950-1959
        0x0aea6, 0x0ab50, 0x04b60, 0x0aae4, 0x0a570, 0x05260, 0x0f263, 0x0d950, 0x05b57, 0x056a0, // 1960-1969
        0x096d0, 0x04dd5, 0x04ad0, 0x0a4d0, 0x0d4d4, 0x0d250, 0x0d558, 0x0b540, 0x0b6a0, 0x195a6, // 1970-1979
        0x095b0, 0x049b0, 0x0a974, 0x0a4b0, 0x0b27a, 0x06a50, 0x06d40, 0x0af46, 0x0ab60, 0x09570, // 1980-1989
        0x04af5, 0x04970, 0x064b0, 0x074a3, 0x0ea50, 0x06b58, 0x055c0, 0x0ab60, 0x096d5, 0x092e0, // 1990-1999
        0x0c960, 0x0d954, 0x0d4a0, 0x0da50, 0x07552, 0x056a0, 0x0abb7, 0x025d0, 0x092d0, 0x0cab5, // 2000-2009
        0x0a950, 0x0b4a0, 0x0baa4, 0x0ad50, 0x055d9, 0x04ba0, 0x0a5b0, 0x15176, 0x052b0, 0x0a930, // 2010-2019
        0x07954, 0x06aa0, 0x0ad50, 0x05b52, 0x04b60, 0x0a6e6, 0x0a4e0, 0x0d260, 0x0ea65, 0x0d530, // 2020-2029
        0x05aa0, 0x076a3, 0x096d0, 0x04afb, 0x04ad0, 0x0a4d0, 0x1d0b6, 0x0d250, 0x0d520, 0x0dd45, // 2030-2039
        0x0b5a0, 0x056d0, 0x055b2, 0x049b0, 0x0a577, 0x0a4b0, 0x0aa50, 0x1b255, 0x06d20, 0x0ada0, // 2040-2049
        0x14b63, 0x09370, 0x049f8, 0x04970, 0x064b0, 0x168a6, 0x0ea50, 0x06b20, 0x1a6c4, 0x0aae0, // 2050-2059
        0x0a2e0, 0x0d2e3, 0x0c960, 0x0d557, 0x0d4a0, 0x0da50, 0x05d55, 0x056a0, 0x0a6d0, 0x055d4, // 2060-2069
        0x052d0, 0x0a9b8, 0x0a950, 0x0b4a0, 0x0b6a6, 0x0ad50, 0x055a0, 0x0aba4, 0x0a5b0, 0x052b0, // 2070-2079
        0x0b273, 0x06930, 0x07337, 0x06aa0, 0x0ad50, 0x14b55, 0x04b60, 0x0a570, 0x054e4, 0x0d160, // 2080-2089
        0x0e968, 0x0d520, 0x0daa0, 0x16aa6, 0x056d0, 0x04ae0, 0x0a9d4, 0x0a2d0, 0x0d150, 0x0f252, // 2090-2099
        0x0d520 // 2100
    ]

    /// 农历月份名（正月～腊月）
    private static let monthNames = ["正", "二", "三", "四", "五", "六", "七", "八", "九", "十", "冬", "腊"]
    /// 农历日名（初一～三十）
    private static let dayNames = [
        "初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八", "初九", "初十",
        "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十",
        "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九", "三十"
    ]
    /// 农历数字月名（一月～十二月，用于「某年某月」表述）
    private static let numMonthNames = ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十", "十一", "十二"]

    // MARK: - 基础查询

    /// 某年闰月月份（0 表示无闰月）
    static func leapMonth(_ year: Int) -> Int {
        guard year >= 1900 && year < 2100 else { return 0 }
        return lunarInfo[year - 1900] & 0xf
    }

    /// 某年闰月天数
    static func leapDays(_ year: Int) -> Int {
        guard leapMonth(year) != 0 else { return 0 }
        return (lunarInfo[year - 1900] & 0x10000) != 0 ? 30 : 29
    }

    /// 某年某农历月天数
    static func monthDays(_ year: Int, _ month: Int) -> Int {
        guard year >= 1900 && year < 2100 else { return 30 }
        return (lunarInfo[year - 1900] & (0x10000 >> month)) != 0 ? 30 : 29
    }

    /// 某农历年总天数
    static func yearDays(_ year: Int) -> Int {
        var sum = 348 // 12 个月 × 29 天
        var i = 0x8000
        while i > 0x8 {
            sum += (lunarInfo[year - 1900] & i) != 0 ? 1 : 0
            i >>= 1
        }
        return sum + leapDays(year)
    }

    // MARK: - 公历 → 农历

    /// 公历日期 → 农历（年、月、日、是否闰月），采用经典查表算法
    static func solarToLunar(year: Int, month: Int, day: Int) -> (year: Int, month: Int, day: Int, isLeap: Bool) {
        // 锚点：1900-01-31 = 农历 1900 年正月初一
        let baseJDN = BaziCalculator.julianDay(year: 1900, month: 1, day: 31)
        let targetJDN = BaziCalculator.julianDay(year: year, month: month, day: day)
        var offset = targetJDN - baseJDN

        // 定位农历年
        var lunarYear = 1900
        var temp = yearDays(lunarYear)
        while offset >= temp {
            offset -= temp
            lunarYear += 1
            temp = yearDays(lunarYear)
        }

        let leap = leapMonth(lunarYear)
        var isLeap = false
        var lunarMonth = 1
        var i = 1
        while i < 13 && offset > 0 {
            // 闰月跟在对应月份之后
            if leap > 0 && i == (leap + 1) && !isLeap {
                i -= 1
                isLeap = true
                temp = leapDays(lunarYear)
            } else {
                temp = monthDays(lunarYear, i)
            }
            if isLeap && i == (leap + 1) { isLeap = false }
            offset -= temp
            i += 1
        }

        if offset == 0 && leap > 0 && i == leap + 1 {
            if isLeap { isLeap = false } else { isLeap = true; i -= 1 }
        }
        if offset < 0 { offset += temp; i -= 1 }

        lunarMonth = i
        return (lunarYear, lunarMonth, offset + 1, isLeap)
    }

    /// 农历日期字符串（如「庚午年 四月十一」或「闰四月十一」）
    static func lunarString(solarYear: Int, month: Int, day: Int, ganzhiYear: String) -> String {
        let l = solarToLunar(year: solarYear, month: month, day: day)
        let monthStr = (l.isLeap ? "闰" : "") + monthNames[l.month - 1] + "月"
        let dayStr = dayNames[l.day - 1]
        return "\(ganzhiYear)年 \(monthStr)\(dayStr)"
    }

    // MARK: - 生肖（按年柱地支）

    static let shengXiaoMap: [String: String] = [
        "子": "鼠", "丑": "牛", "寅": "虎", "卯": "兔", "辰": "龙", "巳": "蛇",
        "午": "马", "未": "羊", "申": "猴", "酉": "鸡", "戌": "狗", "亥": "猪"
    ]

    /// 年柱地支 → 生肖
    static func shengXiao(yearPillar: String) -> String {
        guard let zhi = yearPillar.last else { return "" }
        return shengXiaoMap[String(zhi)] ?? ""
    }

    // MARK: - 星座（公历日期）

    /// 公历 → 星座
    static func xingZuo(month: Int, day: Int) -> String {
        let zodiacs = ["摩羯座", "水瓶座", "双鱼座", "白羊座", "金牛座", "双子座",
                       "巨蟹座", "狮子座", "处女座", "天秤座", "天蝎座", "射手座"]
        // 每个星座的分界日
        let splitDays = [20, 19, 21, 20, 21, 22, 23, 23, 23, 24, 23, 22]
        let idx = month - 1
        if day < splitDays[idx] {
            return zodiacs[(idx + 11) % 12]
        }
        return zodiacs[idx]
    }
}
