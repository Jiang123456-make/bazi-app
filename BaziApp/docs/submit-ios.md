# submit-ios：提交到 App Store（App Store Connect 操作）

> 发布两步走的第二步。在 App Store Connect 配置 App 信息，提交审核。

## 前置

- `build-ios.md` 已完成，App 已上传到 App Store Connect
- Apple 开发者账号已登录 [App Store Connect](https://appstoreconnect.apple.com)

## 步骤 1：创建 App

1. App Store Connect → **我的 App** → **+** → **新建 App**
2. 填写：
   - **平台**：iOS
   - **名称**：`灵犀 - 八字命理顾问`（用户搜索时看到的名字，需唯一）
   - **主要语言**：简体中文
   - **套装 ID**：选步骤 2（Signing）里设置的 Bundle Identifier
   - **SKU**：随便填一个唯一标识（如 `bazi-001`）
3. 点 **创建**

## 步骤 2：填写 App 信息

在 App Store Connect 左侧选刚创建的 App，按以下顺序填：

### 2.1 App 详情

| 字段 | 内容 |
|---|---|
| **名称** | 灵犀 - 八字命理顾问 |
| **副标题** | 你的 AI 命理顾问，专业八字排盘 |
| **类别** | 生活（主要）+ 工具（次要） |
| **内容版权** | © 2026 灵犀 |

### 2.2 描述与关键字

| 字段 | 内容（见 `docs/AppStore描述.md`） |
|---|---|
| **宣传文本** | （最新动态，可随时改） |
| **描述** | 见描述文件 |
| **关键字** | 八字, 排盘, 命理, 四柱, 算命, 运势, 命盘, 风水, 生肖 |
| **技术支持 URL** | 你的网站 / GitHub 仓库 |
| **营销 URL** | （可空） |

### 2.3 隐私政策 URL（必需）

- 不能空，必须填一个**可访问的网址**
- 把 `docs/隐私政策.md` 内容托管成网页（GitHub Pages / 腾讯云静态站最简单）
- 填托管后的网址，如 `https://yourname.github.io/bazi-privacy`

### 2.4 截图（必需）

上传各尺寸截图：

| 设备 | 尺寸（px） |
|---|---|
| 6.7" iPhone | 1290 × 2796 |
| 6.5" iPhone | 1242 × 2688 |
| 5.5" iPhone | 1242 × 2208 |
| iPad（可选） | 2048 × 2732 |

> 至少上传一组（6.7" 必填）。可从我们已有的 Ardot 设计稿（fileId `720746392525285`）导出，或在 Xcode 模拟器里 `Cmd+S` 真机截图。

## 步骤 3：版本信息

### 3.1 版本

| 字段 | | 内容 |
|---|---|---|
| **版本号** | | 1.0.0 |
| **版权** | | © 2026 灵犀 |
| **分级** | | 12+（命理内容，参考 `docs/AppStore描述.md`） |

### 3.2 构建（关联 Archive）

1. 点 **App Store Connect** 选项卡的 **+** 号
2. 选刚上传的 Build（`build-ios.md` 步骤 5 上传的）
3. 关联 → 完成

## 步骤 4：提交审核

1. 右上角 **添加以供审核**
2. 选刚填写的版本 → 点 **添加**
3. 回答 **导出合规** 问题：
   - **Is your app designed to use cryptography or does it contain or use cryptography?** → 选 **No**
4. 回答 **广告标识符 (IDFA)**：
   - 选 **No, this app does not use the Advertising Identifier (IDFA)**
5. 右上角 **提交以供审核** → **提交**

✅ 完成。Apple 审核通常 1-7 天。审核结果会邮件通知，也会在 App Store Connect 显示。

## 审核被拒怎么办？

命理类 App 最常见的拒审原因（Apple 审核指南 4.3 / 5.6）：

1. **"App 描述暗示准确预测"** → 把所有 "预测" 改成 "参考 / 解读"，"准确" 改成 "辅助"
2. **"缺少免责 / 隐私政策"** → 检查 App 内「免责声明」按钮或启动弹窗 + App Store 描述已附隐私政策 URL
4. **"分级不当"** → 选 12+ 或 17+

如果被拒，App Store Connect → **Resolution Center** 可看到 Apple 的详细理由，针对性修改后重新提交（不重新重新走 build-ios，可以直接 re-submit）。

✅ submit-ios 完成。