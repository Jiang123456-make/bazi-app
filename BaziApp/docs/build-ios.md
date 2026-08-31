# build-ios：在 Mac 上构建 iOS App（Xcode 操作）

> 发布两步走的第一步。把源码编译成可上传的 `.ipa`。

## 前置（一次性）

- Mac + Xcode 15+（App Store 下载）
- `BaziApp/` 文件夹已拷贝到 Mac
- 已 `brew install xcodegen`（或用 README 方法一手动拖源码）

## 步骤 1：生成工程

```bash
cd BaziApp
xcodegen generate
open BaziApp.xcodeproj
```

## 步骤 2：配置签名（首次必做）

1. Xcode 左侧选中 **BaziApp** 项目
2. 顶部 tab 选 **Signing & Capabilities**
3. **Team** 选择你的 Apple 开发者账号（免费账号也行但无法上架，需 $99/年付费账号）
4. **Bundle Identifier** 改为唯一值（默认 `com.lingxi.bazi`，建议改为 `com.yourname.bazi`）
5. ✅ 勾选 **Automatically manage signing**

如果 Team 列表为空，去 [developer.apple.com](https://developer.apple.com/account) 注册 / 登录账号，并下载证书到 Mac。

## 步骤 3：本地运行验证

1. 顶部设备选 **iPhone 15 Pro**（或你的设备）
2. **Cmd + R** 运行
3. 模拟器里点「试排示例」按钮，确认命盘显示正常

> ⚠️ 如果报错签名问题：回到步骤 2，检查 Bundle Identifier 是否唯一、Team 是否正确、Provisioning Profile 是否生成。

## 步骤 4：Archive 打包

1. **顶部设备选 `Any iOS Device`**（不是模拟器）
2. 菜单 `Product` → `Archive`
3. 等待编译完成（首次 3-5 分钟）
5. Organizer 窗口自动弹出，显示刚打包的 Archive

## 步骤 5：分发验证

1. Organizer 窗口选中刚打包的 Archive
2. 点右下 **Distribute App**
3. 选 **App Store Connect** → **Upload**
4. 选 **Automatically manage signing**（首次需要）
5. 一路 Next，最后 **Upload**

> 上传成功后，App 出现在 App Store Connect 的「我的 App」→「活动」里。耗时约 5-10 分钟。

✅ build-ios 完成。下一步：`submit-ios.md`