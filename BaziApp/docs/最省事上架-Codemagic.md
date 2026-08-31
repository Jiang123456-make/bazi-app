# 灵犀八字 · 最省事上架（Codemagic 自动签名版）

> 用 Codemagic 的「自动代码签名」，**证书和描述文件由它自动生成**，你不再需要手动去苹果后台点 CSR / 证书 / 描述文件那一堆。全程只需做一次苹果操作（生成 API Key），其余我全代办。

## 你的操作清单（总共就 5 步，每步 1-2 分钟）

| 步骤 | 做什么 | 耗时 |
|---|---|---|
| ① | GitHub 建一个**私有**仓库 | 1 分钟 |
| ② | 注册 Codemagic（免费）并连上仓库 | 2 分钟 |
| ③ | App Store Connect 生成一个 API Key（.p8） | 2 分钟 |
| ④ | 把 API Key 填进 Codemagic | 1 分钟 |
| ⑤ | 点「开始构建」→ 之后自动上 TestFlight | 1 分钟 |

> 相比之前的 GitHub Actions 方案，这里**省掉了**：手动生成 CSR、上传换证书、合成 .p12、建描述文件、填 8 个 secrets。因为 Codemagic 用 API Key 全自动帮你搞定了。

---

## 第 ① 步：建 GitHub 私有仓库

1. github.com 登录 → 右上角 **＋** → **New repository**
2. 名字填 `bazi-app`，选 **Private**（私密）→ Create
3. 把仓库地址发我（形如 `https://github.com/你的用户名/bazi-app.git`），**我帮你推代码**（包括已经写好的 `codemagic.yaml`）

---

## 第 ② 步：注册 Codemagic 并连仓库

1. 打开 [codemagic.io](https://codemagic.io) → 用 GitHub 账号一键登录（免费，无需信用卡）
2. 点 **Add application** → 选你的 GitHub 仓库 `bazi-app`
3. 选 **iOS App** 项目类型 → 它会自动检测到 `codemagic.yaml` 和 XcodeGen 配置

---

## 第 ③ 步：App Store Connect 生成 API Key（唯一一次苹果操作）

1. 打开 [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → 登录你的付费账号
2. 右上角头像 → **Users and Access** → **Integrations** 标签
3. 找到 **App Store Connect API** → 点 **＋**（或 Generate API Key）
4. **Name** 填 `Codemagic`，**Access** 选 **App Manager** → Generate
5. 下载 `.p8` 文件（**只能下这一次**），同时记下两个值：
   - **Key ID**（形如 `ABC123DEF4`）
   - **Issuer ID**（形如 `xxxx-xxxx-...`，页面上方也能看到）
6. 还要记下 **Team ID**：回 [developer.apple.com/account](https://developer.apple.com/account) → **Membership** → **Team ID**（形如 `9X8XXXXXXX`）

---

## 第 ④ 步：把 API Key 填进 Codemagic

1. Codemagic 里，左侧 **Teams** → **Integrations** → **App Store Connect**
2. 添加 API Key：填 Key ID、Issuer ID，上传 `.p8` 文件
3. 再点 **Environment variables** → 添加 3 个变量（Secret 类型）：
   - `APP_STORE_CONNECT_PRIVATE_KEY` = 用记事本打开 `.p8`，把里面全部内容粘进去
   - `APP_STORE_CONNECT_KEY_IDENTIFIER` = 你的 Key ID
   - `APP_STORE_CONNECT_ISSUER_ID` = 你的 Issuer ID

---

## 第 ⑤ 步：开始构建

1. 回到你的 app 的构建页 → 点 **Start new build**
2. Codemagic 会**自动**：生成分发证书 → 创建描述文件 → 编译 → 签名 → 打包 → 上传 TestFlight
3. 等 10-20 分钟 → 变绿 ✅ 就成功了
4. 回 appstoreconnect → **TestFlight** 标签就能看到 build

> ⚠️ 如果 Codemagic 报「找不到 bundle id」之类的错，说明需要先注册 App ID：到 developer.apple.com → **Identifiers** → **＋** → App ID → bundle id 填 `com.lingxi.bazi` → Register。1 分钟，一次性。做完重新点构建即可。

---

## 最后：正式上架 App Store（测试通过后）

1. appstoreconnect → **My Apps** → **＋** → New App → 填名称 `灵犀`、语言、bundle id `com.lingxi.bazi`
2. 补齐信息：截图、描述（`docs/AppStore描述.md`）、隐私政策（`docs/隐私政策.md`）、年龄分级
3. 提交 **App Review** 审核 → 通过后点 **Release** 上架

---

## 常见问题

- **Q：Codemagic 免费吗？** 免费 plan 每月约 500 构建分钟，单个 App 完全够用；偶尔构建免费额度用不完。
- **Q：证书要续期吗？** Codemagic 自动管理，过期了重新构建时它会自动更新，你不管。
- **Q：会绑定死 Codemagic 吗？** 不会，证书在你的 Apple 账号名下，随时可迁走。

## 现在就开始

**告诉我 GitHub 仓库地址**（第 ① 步建好的），我先推代码。剩下的按上面 ②~⑤ 做，卡哪一步随时问我。
