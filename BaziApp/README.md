# 八字 App（灵犀）— SwiftUI iOS 应用

一款基于四柱八字命理的 iOS 应用，内置 AI 命理顾问「灵犀」。苹果设计语言（Action Blue + 极简留白），问真八字风格的专业排盘。

## 功能

- **排盘**：输入生辰 → 专业八字排盘（四柱、藏干、十神、纳音、十二长生、空亡、五行、神煞、大运、流年）
- **命盘图**：方形命盘（年/月/日/时四柱环绕日主）
- **报告**：综合评分 + AI 解读 + 四维分析 + 10 年运势 + 今日宜忌
- **顾问**：AI 命理顾问「灵犀」对话
- **我的**：命盘摘要、排盘历史、设置
- **离线排盘**：八字算法完全在本机计算，隐私数据不离开设备

## 目录结构

```
BaziApp/
├── BaziApp/
│   ├── BaziAppApp.swift          # App 入口
│   ├── ContentView.swift         # 根视图（4 Tab）
│   ├── Theme/BaziTheme.swift     # 视觉系统（颜色/字体/卡片）
│   ├── Models/BaziChart.swift    # 命盘数据模型 + 五行/十神/纳音常量
│   ├── Engine/BaziCalculator.swift # 排盘引擎（离线，移植自 bazi-paipan）
│   ├── Views/
│   │   ├── PaipanView.swift      # 屏1 排盘输入
│   │   ├── ChartView.swift       # 屏2 排盘结果
│   │   ├── ReportView.swift      # 屏3 命理报告
│   │   ├── AdvisorView.swift     # 屏4 顾问对话
│   │   └── ProfileView.swift     # 屏5 我的
│   └── Assets.xcassets/          # 资源（App 图标等）
└── docs/                          # 上架材料（隐私政策/免责声明/描述）
```

## 环境要求

- **本地构建**：macOS 14+ / Xcode 15+（含 iOS 17 SDK）
- **无 Mac 也可上架**：走 GitHub Actions 云构建（见 `docs/云构建上架.md`），云端 macOS 自动编译 + 上传 TestFlight
- iOS 部署目标：**iOS 17+**

## 如何构建运行

### 方法一：Xcode 新建工程 + 拖入源码（推荐）

1. 打开 Xcode → `File > New > Project` → 选 **iOS App** → 命名为 `BaziApp`
2. 创建后，把本仓库 `BaziApp/` 目录下的所有 `.swift` 文件拖入 Xcode 工程的 `BaziApp` group：
   - `BaziAppApp.swift`、`ContentView.swift`
   - `Theme/`、`Models/`、`Engine/`、`Views/` 下的所有文件
   - 拖入时勾选 `Copy items if needed` + target 选 `BaziApp`
3. 删除 Xcode 模板自带的默认 `ContentView.swift`（避免重名冲突）
4. 选一个模拟器（如 iPhone 15 Pro）→ `Cmd+R` 运行

### 方法二：用 XcodeGen（推荐，一键生成）

本仓库已提供 `project.yml` 配置。在 Mac 上安装 [XcodeGen](https://github.com/yonaskolb/XcodeGen)（`brew install xcodegen`）后：

```bash
cd BaziApp
xcodegen generate        # 生成 BaziApp.xcodeproj
open BaziApp.xcodeproj
```

完整上架流程见 `docs/发布清单.md`；**无 Mac 的云构建上架**见 `docs/云构建上架.md`。

## 上架 App Store 全流程

### 1. 准备资质

- **Apple 开发者账号**：https://developer.apple.com ，个人 $99/年
- 在 App Store Connect（https://appstoreconnect.apple.com）创建 App

### 2. 构建签名

1. Xcode 中配置签名：`Signing & Capabilities` → 勾选 `Automatically manage signing` → 选择你的 Team
2. 准备 App 图标（见 `Assets.xcassets/AppIcon.appiconset/`，替换占位图标为 1024×1024 正式图标）
3. 设备选 `Any iOS Device` → `Product > Archive` 打包

### 3. 提交

1. Archive 成功后，在 Organizer 窗口点 `Distribute App` → `App Store Connect`
2. 上传后到 App Store Connect 填写：App 名称、描述（见 `docs/AppStore描述.md`）、隐私政策链接（见 `docs/隐私政策.md`）、截图（1024×1024 或对应尺寸）、类别（生活/工具）、年龄分级
3. 提交审核

### 4. 审核合规要点（命理类 App 重点）

- **定位为「传统文化娱乐参考」**，不要宣传"算命预测未来"等迷信表述
- **必须有免责声明**：App 内展示 + App Store 描述（见 `docs/免责声明.md`）
- **必须有隐私政策**：命理数据属于个人信息，需明确收集、使用、存储（见 `docs/隐私政策.md`）
- **年龄分级**：建议 12+ 或 17+（涉及命理内容）
- **隐私描述**：Xcode `Info.plist` 需添加 `NSPrivacyCollectedDataTypes` 等隐私清单（如果收集数据）

## 排盘算法说明

排盘引擎 `Engine/BaziCalculator.swift` 移植自知识库的 bazi-paipan（VSOP87 节气 + 真太阳时修正）的核心算法，锚点验证通过：

- 1990-05-15 12:00 男 = **庚午 / 辛巳 / 庚辰 / 壬午**，顺排，起运 7 岁
- 儒略日 JDN 算日柱、立春分年柱、节气分月柱、五鼠遁分时柱
- 真太阳时按出生地经度修正（北京 -14 分钟）

> 注：MVP 版节气用日级近似（精确到日），节气交界当天出生的人月柱可能有 ±1 天误差；后续可升级到 VSOP87 分钟级精度。

## 免责声明

命理分析仅供传统文化研究与娱乐参考，不构成任何决策依据。请理性看待。
