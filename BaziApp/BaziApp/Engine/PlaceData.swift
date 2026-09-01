import Foundation

/// 出生地城市数据（含经度，用于真太阳时修正）
struct Place: Identifiable, Hashable {
    var id: String { name }
    /// 城市名
    let name: String
    /// 所属省份 / 地区
    let province: String
    /// 东经（度）
    let longitude: Double
}

enum PlaceData {

    /// 未知地区（默认北京时间：经度取 120°，时差 0）
    static let unknown = Place(name: "未知地区", province: "默认", longitude: 120.0)

    /// 地区显示顺序（直辖市 → 华北 → 东北 → 华东 → 华中 → 华南 → 西南 → 西北 → 港澳台）
    static let provinceOrder = [
        "北京", "天津", "上海", "重庆",
        "河北", "山西", "内蒙古",
        "辽宁", "吉林", "黑龙江",
        "江苏", "浙江", "安徽", "福建", "江西", "山东",
        "河南", "湖北", "湖南",
        "广东", "广西", "海南",
        "四川", "贵州", "云南", "西藏",
        "陕西", "甘肃", "青海", "宁夏", "新疆",
        "香港", "澳门", "台湾"
    ]

    /// 全部城市（省会 + 直辖市 + 计划单列市 + 主要地级市）
    static let all: [Place] = [
        // 直辖市
        Place(name: "北京", province: "北京", longitude: 116.4),
        Place(name: "天津", province: "天津", longitude: 117.2),
        Place(name: "上海", province: "上海", longitude: 121.5),
        Place(name: "重庆", province: "重庆", longitude: 106.5),

        // 河北
        Place(name: "石家庄", province: "河北", longitude: 114.5),
        Place(name: "唐山", province: "河北", longitude: 118.2),
        Place(name: "保定", province: "河北", longitude: 115.5),
        Place(name: "邯郸", province: "河北", longitude: 114.5),
        Place(name: "秦皇岛", province: "河北", longitude: 119.6),
        Place(name: "廊坊", province: "河北", longitude: 116.7),
        Place(name: "沧州", province: "河北", longitude: 116.8),
        Place(name: "邢台", province: "河北", longitude: 114.5),

        // 山西
        Place(name: "太原", province: "山西", longitude: 112.5),
        Place(name: "大同", province: "山西", longitude: 113.3),
        Place(name: "运城", province: "山西", longitude: 111.0),
        Place(name: "临汾", province: "山西", longitude: 111.5),

        // 内蒙古
        Place(name: "呼和浩特", province: "内蒙古", longitude: 111.7),
        Place(name: "包头", province: "内蒙古", longitude: 109.8),
        Place(name: "鄂尔多斯", province: "内蒙古", longitude: 109.8),
        Place(name: "赤峰", province: "内蒙古", longitude: 118.9),

        // 辽宁
        Place(name: "沈阳", province: "辽宁", longitude: 123.4),
        Place(name: "大连", province: "辽宁", longitude: 121.6),
        Place(name: "鞍山", province: "辽宁", longitude: 123.0),
        Place(name: "锦州", province: "辽宁", longitude: 121.1),

        // 吉林
        Place(name: "长春", province: "吉林", longitude: 125.3),
        Place(name: "吉林", province: "吉林", longitude: 126.5),
        Place(name: "延吉", province: "吉林", longitude: 129.5),

        // 黑龙江
        Place(name: "哈尔滨", province: "黑龙江", longitude: 126.6),
        Place(name: "大庆", province: "黑龙江", longitude: 125.1),
        Place(name: "齐齐哈尔", province: "黑龙江", longitude: 123.9),
        Place(name: "牡丹江", province: "黑龙江", longitude: 129.6),

        // 江苏
        Place(name: "南京", province: "江苏", longitude: 118.8),
        Place(name: "苏州", province: "江苏", longitude: 120.6),
        Place(name: "无锡", province: "江苏", longitude: 120.3),
        Place(name: "常州", province: "江苏", longitude: 119.9),
        Place(name: "徐州", province: "江苏", longitude: 117.2),
        Place(name: "南通", province: "江苏", longitude: 120.9),
        Place(name: "扬州", province: "江苏", longitude: 119.4),
        Place(name: "盐城", province: "江苏", longitude: 120.2),
        Place(name: "连云港", province: "江苏", longitude: 119.2),

        // 浙江
        Place(name: "杭州", province: "浙江", longitude: 120.2),
        Place(name: "宁波", province: "浙江", longitude: 121.5),
        Place(name: "温州", province: "浙江", longitude: 120.7),
        Place(name: "嘉兴", province: "浙江", longitude: 120.8),
        Place(name: "绍兴", province: "浙江", longitude: 120.6),
        Place(name: "金华", province: "浙江", longitude: 119.6),
        Place(name: "台州", province: "浙江", longitude: 121.4),

        // 安徽
        Place(name: "合肥", province: "安徽", longitude: 117.3),
        Place(name: "芜湖", province: "安徽", longitude: 118.4),
        Place(name: "蚌埠", province: "安徽", longitude: 117.4),
        Place(name: "阜阳", province: "安徽", longitude: 115.8),

        // 福建
        Place(name: "福州", province: "福建", longitude: 119.3),
        Place(name: "厦门", province: "福建", longitude: 118.1),
        Place(name: "泉州", province: "福建", longitude: 118.6),
        Place(name: "漳州", province: "福建", longitude: 117.6),
        Place(name: "莆田", province: "福建", longitude: 119.0),

        // 江西
        Place(name: "南昌", province: "江西", longitude: 115.9),
        Place(name: "赣州", province: "江西", longitude: 115.0),
        Place(name: "九江", province: "江西", longitude: 116.0),
        Place(name: "宜春", province: "江西", longitude: 114.4),

        // 山东
        Place(name: "济南", province: "山东", longitude: 117.0),
        Place(name: "青岛", province: "山东", longitude: 120.4),
        Place(name: "烟台", province: "山东", longitude: 121.4),
        Place(name: "潍坊", province: "山东", longitude: 119.2),
        Place(name: "临沂", province: "山东", longitude: 118.4),
        Place(name: "济宁", province: "山东", longitude: 116.6),
        Place(name: "威海", province: "山东", longitude: 122.1),
        Place(name: "淄博", province: "山东", longitude: 118.1),
        Place(name: "泰安", province: "山东", longitude: 117.1),
        Place(name: "日照", province: "山东", longitude: 119.5),

        // 河南
        Place(name: "郑州", province: "河南", longitude: 113.6),
        Place(name: "洛阳", province: "河南", longitude: 112.5),
        Place(name: "南阳", province: "河南", longitude: 112.5),
        Place(name: "新乡", province: "河南", longitude: 113.9),
        Place(name: "开封", province: "河南", longitude: 114.3),
        Place(name: "商丘", province: "河南", longitude: 115.7),
        Place(name: "信阳", province: "河南", longitude: 114.1),
        Place(name: "安阳", province: "河南", longitude: 114.4),
        Place(name: "许昌", province: "河南", longitude: 113.9),
        Place(name: "周口", province: "河南", longitude: 114.7),

        // 湖北
        Place(name: "武汉", province: "湖北", longitude: 114.3),
        Place(name: "宜昌", province: "湖北", longitude: 111.3),
        Place(name: "襄阳", province: "湖北", longitude: 112.1),
        Place(name: "荆州", province: "湖北", longitude: 112.2),
        Place(name: "黄冈", province: "湖北", longitude: 114.9),
        Place(name: "十堰", province: "湖北", longitude: 110.8),

        // 湖南
        Place(name: "长沙", province: "湖南", longitude: 113.0),
        Place(name: "岳阳", province: "湖南", longitude: 113.1),
        Place(name: "株洲", province: "湖南", longitude: 113.1),
        Place(name: "湘潭", province: "湖南", longitude: 112.9),
        Place(name: "衡阳", province: "湖南", longitude: 112.6),
        Place(name: "常德", province: "湖南", longitude: 111.7),

        // 广东
        Place(name: "广州", province: "广东", longitude: 113.3),
        Place(name: "深圳", province: "广东", longitude: 114.1),
        Place(name: "佛山", province: "广东", longitude: 113.1),
        Place(name: "东莞", province: "广东", longitude: 113.8),
        Place(name: "珠海", province: "广东", longitude: 113.6),
        Place(name: "汕头", province: "广东", longitude: 116.7),
        Place(name: "惠州", province: "广东", longitude: 114.4),
        Place(name: "中山", province: "广东", longitude: 113.4),
        Place(name: "江门", province: "广东", longitude: 113.1),
        Place(name: "湛江", province: "广东", longitude: 110.4),
        Place(name: "茂名", province: "广东", longitude: 110.9),

        // 广西
        Place(name: "南宁", province: "广西", longitude: 108.3),
        Place(name: "柳州", province: "广西", longitude: 109.4),
        Place(name: "桂林", province: "广西", longitude: 110.3),
        Place(name: "北海", province: "广西", longitude: 109.1),
        Place(name: "玉林", province: "广西", longitude: 110.2),

        // 海南
        Place(name: "海口", province: "海南", longitude: 110.3),
        Place(name: "三亚", province: "海南", longitude: 109.5),

        // 四川
        Place(name: "成都", province: "四川", longitude: 104.1),
        Place(name: "绵阳", province: "四川", longitude: 104.7),
        Place(name: "南充", province: "四川", longitude: 106.1),
        Place(name: "宜宾", province: "四川", longitude: 104.6),
        Place(name: "泸州", province: "四川", longitude: 105.4),
        Place(name: "乐山", province: "四川", longitude: 103.8),
        Place(name: "德阳", province: "四川", longitude: 104.4),

        // 贵州
        Place(name: "贵阳", province: "贵州", longitude: 106.6),
        Place(name: "遵义", province: "贵州", longitude: 106.9),
        Place(name: "六盘水", province: "贵州", longitude: 104.8),
        Place(name: "毕节", province: "贵州", longitude: 105.3),

        // 云南
        Place(name: "昆明", province: "云南", longitude: 102.7),
        Place(name: "大理", province: "云南", longitude: 100.2),
        Place(name: "丽江", province: "云南", longitude: 100.2),
        Place(name: "曲靖", province: "云南", longitude: 103.8),
        Place(name: "玉溪", province: "云南", longitude: 102.5),

        // 西藏
        Place(name: "拉萨", province: "西藏", longitude: 91.1),

        // 陕西
        Place(name: "西安", province: "陕西", longitude: 108.9),
        Place(name: "咸阳", province: "陕西", longitude: 108.7),
        Place(name: "宝鸡", province: "陕西", longitude: 107.1),
        Place(name: "渭南", province: "陕西", longitude: 109.5),
        Place(name: "汉中", province: "陕西", longitude: 107.0),
        Place(name: "榆林", province: "陕西", longitude: 109.7),

        // 甘肃
        Place(name: "兰州", province: "甘肃", longitude: 103.8),
        Place(name: "天水", province: "甘肃", longitude: 105.7),
        Place(name: "酒泉", province: "甘肃", longitude: 98.5),

        // 青海
        Place(name: "西宁", province: "青海", longitude: 101.8),

        // 宁夏
        Place(name: "银川", province: "宁夏", longitude: 106.3),

        // 新疆
        Place(name: "乌鲁木齐", province: "新疆", longitude: 87.6),
        Place(name: "喀什", province: "新疆", longitude: 75.9),
        Place(name: "伊犁", province: "新疆", longitude: 81.3),

        // 港澳台
        Place(name: "香港", province: "香港", longitude: 114.2),
        Place(name: "澳门", province: "澳门", longitude: 113.5),
        Place(name: "台北", province: "台湾", longitude: 121.5),
        Place(name: "高雄", province: "台湾", longitude: 120.3),
        Place(name: "台中", province: "台湾", longitude: 120.7)
    ]

    /// 按名字查经度（供真太阳时修正使用）
    static func longitude(of name: String) -> Double {
        if name == unknown.name { return unknown.longitude }
        return all.first(where: { $0.name == name })?.longitude ?? 120.0
    }

    /// 按地区分组（保持 provinceOrder 顺序）
    static func grouped() -> [(province: String, cities: [Place])] {
        let dict = Dictionary(grouping: all, by: { $0.province })
        var result: [(province: String, cities: [Place])] = []
        for p in provinceOrder {
            if let cities = dict[p] {
                result.append((province: p, cities: cities))
            }
        }
        return result
    }
}
