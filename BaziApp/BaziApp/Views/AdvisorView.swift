import SwiftUI
import UIKit

/// 屏 4：顾问·对话（真实 AI 接入 + 结构化回复卡 + 本地记忆系统；网络异常回退本地解读）
/// 「越用越顺手」：会话按命盘持久化、用户记忆注入提示词、👍/👎 反馈沉淀偏好、简答/详解风格。
struct AdvisorView: View {
    let chart: BaziChart?

    @State private var messages: [Message] = []
    @State private var input = ""
    @State private var isTyping = false
    @State private var style: AdvisorMemory.Style = AdvisorMemory.style
    @State private var dislikeFor: Message.ID?
    @State private var showDislikeDialog = false
    @State private var activeKey = ""   // 当前命盘的记忆 key：AI 回包判活，防旧盘回包写入新盘记忆
    @FocusState private var inputFocused: Bool

    /// 欢迎卡话题入口（标签 + 实际发送的问题）
    private let topics: [(label: String, question: String)] = [
        ("事业发展", "我的事业发展如何？"),
        ("财运分析", "我的财运怎么样？"),
        ("感情婚姻", "感情婚姻如何？"),
        ("健康提醒", "健康需要注意什么？")
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 标题 + 风格切换
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("顾问")
                            .font(BaziTheme.largeTitle())
                            .foregroundStyle(BaziTheme.ink)
                        Text("灵犀 · 阅盘 1000+ · 命理专家")
                            .font(BaziTheme.footnote(15))
                            .foregroundStyle(BaziTheme.secondary)
                    }
                    Spacer()
                    styleMenu
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 8)

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 16) {
                            ForEach(messages) { messageRow($0) }
                            if isTyping { typingRow }
                            Color.clear.frame(height: 1).id("chatBottom")
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 4)
                    }
                    .onChange(of: messages.count) { _ in scrollToBottom(proxy) }
                    .onChange(of: isTyping) { _ in scrollToBottom(proxy) }
                    .scrollDismissesKeyboard(.interactively)
                    .onTapGesture { inputFocused = false }
                }

                // 输入栏
                HStack(spacing: 8) {
                    TextField("输入你的问题…", text: $input)
                        .font(.system(size: 15))
                        .focused($inputFocused)
                        .padding(.horizontal, 16).padding(.vertical, 11)
                        .background(BaziTheme.fill)
                        .clipShape(Capsule())
                        .onSubmit { send() }
                    Button(action: send) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 18, weight: .semibold)).foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(BaziTheme.actionBlue).clipShape(Circle())
                    }
                    .disabled(isTyping)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            }
            .background(BaziTheme.canvas)
            .onAppear {
                activeKey = AdvisorMemory.chartKey(chart)
                loadContent()
            }
            .onChange(of: chart) { newChart in
                // 命盘切换：更新判活 key，历史会话留给新一次进入时加载
                activeKey = AdvisorMemory.chartKey(newChart)
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完成") { inputFocused = false }
                }
            }
            .confirmationDialog("哪里没帮到你？（会记住，下次回答规避）",
                                isPresented: $showDislikeDialog, titleVisibility: .visible) {
                ForEach(AdvisorMemory.dislikeReasonOptions, id: \.self) { reason in
                    Button(reason) {
                        AdvisorMemory.addDislikeReason(reason)
                        setLiked(-1, forID: dislikeFor)
                    }
                }
                Button("不评了", role: .cancel) { }
            }
        }
    }

    // MARK: - 头部风格切换

    private var styleMenu: some View {
        Menu {
            ForEach(AdvisorMemory.Style.allCases, id: \.self) { s in
                Button(action: {
                    AdvisorMemory.style = s
                    style = s
                }) {
                    if style == s {
                        Label(s.rawValue, systemImage: "checkmark")
                    } else {
                        Text(s.rawValue)
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "slider.horizontal.3").font(.system(size: 12))
                Text(style.rawValue).font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(BaziTheme.actionBlue)
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(BaziTheme.dayPillarBG).clipShape(Capsule())
        }
    }

    // MARK: - 消息行

    private func messageRow(_ msg: Message) -> some View {
        Group {
            if msg.isWelcome {
                welcomeCard(msg)
            } else if msg.isAI {
                aiRow(msg)
            } else {
                HStack {
                    Spacer()
                    Text(msg.text)
                        .font(.system(size: 14)).foregroundStyle(.white)
                        .padding(.horizontal, 14).padding(.vertical, 12)
                        .background(BaziTheme.actionBlue)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .frame(maxWidth: 260, alignment: .trailing)
                }
            }
        }
    }

    /// AI 消息：结构化卡片（有结论标题）或纯文本气泡（降级）
    private func aiRow(_ msg: Message) -> some View {
        HStack(alignment: .top, spacing: 8) {
            ZStack {
                Circle().fill(BaziTheme.actionBlue).frame(width: 30, height: 30)
                Text("灵").font(.system(size: 13, weight: .semibold)).foregroundStyle(.white)
            }
            if msg.title != nil {
                structuredCard(msg)
            } else {
                Text(msg.text)
                    .font(.system(size: 14)).foregroundStyle(BaziTheme.ink)
                    .lineSpacing(3)
                    .padding(.horizontal, 14).padding(.vertical, 12)
                    .background(BaziTheme.fill)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .frame(maxWidth: 280, alignment: .leading)
            }
            Spacer(minLength: 0)
        }
    }

    /// 结构化回复卡：话题 pill + 结论 + 分点（干支五行色）+ 建议 + 追问 + 反馈 + 免责
    private func structuredCard(_ msg: Message) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(msg.topic ?? "综合")
                    .font(.system(size: 11, weight: .semibold)).foregroundStyle(BaziTheme.actionBlue)
                    .padding(.horizontal, 9).padding(.vertical, 3)
                    .background(BaziTheme.dayPillarBG).clipShape(Capsule())
                Spacer()
                Text(msg.time).font(.system(size: 11)).foregroundStyle(BaziTheme.tertiary)
            }

            if let title = msg.title {
                Text(title)
                    .font(.system(size: 15, weight: .semibold)).foregroundStyle(BaziTheme.ink)
            }

            VStack(alignment: .leading, spacing: 7) {
                ForEach(Array(msg.points.enumerated()), id: \.offset) { _, point in
                    HStack(alignment: .top, spacing: 8) {
                        Circle().fill(BaziTheme.actionBlue).frame(width: 5, height: 5).padding(.top, 7)
                        Text(attributedGZ(point))
                            .font(.system(size: 14)).foregroundStyle(BaziTheme.ink)
                            .lineSpacing(3)
                    }
                }
            }

            if let tip = msg.tip, !tip.isEmpty {
                HStack(alignment: .top, spacing: 7) {
                    Image(systemName: "lightbulb")
                        .font(.system(size: 12, weight: .semibold)).foregroundStyle(BaziTheme.actionBlue)
                    Text(attributedGZ(tip))
                        .font(.system(size: 13)).foregroundStyle(BaziTheme.actionBlue)
                        .lineSpacing(2)
                }
                .padding(.horizontal, 11).padding(.vertical, 9)
                .background(BaziTheme.dayPillarBG)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            if !msg.followups.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("继续问")
                        .font(.system(size: 11)).foregroundStyle(BaziTheme.tertiary)
                    FlowLayout(spacing: 6) {
                        ForEach(msg.followups, id: \.self) { f in
                            Button(action: { ask(f) }) {
                                Text(f)
                                    .font(.system(size: 12)).foregroundStyle(BaziTheme.actionBlue)
                                    .padding(.horizontal, 11).padding(.vertical, 5)
                                    .background(BaziTheme.canvas)
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(BaziTheme.actionBlue.opacity(0.35), lineWidth: 1))
                            }
                        }
                    }
                }
            }

            if msg.historyIndex != nil {
                feedbackRow(msg)
            }

            Text("命理分析仅供文化参考")
                .font(.system(size: 11)).foregroundStyle(BaziTheme.tertiary)
        }
        .padding(14)
        .frame(maxWidth: 300, alignment: .leading)
        .background(BaziTheme.fill)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .contextMenu {
            Button(action: { UIPasteboard.general.string = msg.text }) {
                Label("复制回复", systemImage: "doc.on.doc")
            }
        }
    }

    /// 反馈行：👍 有帮助 / 👎 没帮助（沉淀为偏好，越用越顺手）
    private func feedbackRow(_ msg: Message) -> some View {
        HStack(spacing: 16) {
            Button {
                setLiked(msg.liked == 1 ? 0 : 1, forID: msg.id)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: msg.liked == 1 ? "hand.thumbsup.fill" : "hand.thumbsup")
                        .font(.system(size: 12))
                    Text("有帮助").font(.system(size: 11))
                }
                .foregroundStyle(msg.liked == 1 ? BaziTheme.actionBlue : BaziTheme.tertiary)
            }
            Button {
                if msg.liked == -1 {
                    setLiked(0, forID: msg.id)
                } else {
                    dislikeFor = msg.id
                    showDislikeDialog = true
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: msg.liked == -1 ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                        .font(.system(size: 12))
                    Text("没帮助").font(.system(size: 11))
                }
                .foregroundStyle(msg.liked == -1 ? BaziTheme.shenshaBad : BaziTheme.tertiary)
            }
            Spacer()
        }
    }

    /// 本地兜底标注条：来源可见 + 一键重试联网
    private func fallbackBar(_ msg: Message) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "wifi.exclamationmark").font(.system(size: 11))
            Text("网络不可用 · 以上为本地解读").font(.system(size: 11))
            Spacer()
            Button { retryAI(for: msg) } label: {
                Text("重试联网").font(.system(size: 12, weight: .semibold))
            }
        }
        .foregroundStyle(BaziTheme.earth)
    }

    /// 移除兜底回复，对同一问题重新请求真实 AI
    private func retryAI(for msg: Message) {
        guard !isTyping else { return }
        messages.removeAll { $0.id == msg.id }
        requestAI()
    }

    /// 欢迎卡：灵犀身份 + 命盘摘要 + 话题入口 + 免责
    private func welcomeCard(_ msg: Message) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(BaziTheme.actionBlue).frame(width: 40, height: 40)
                    Text("灵").font(.system(size: 17, weight: .semibold)).foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("灵犀 · AI 命理顾问")
                        .font(.system(size: 16, weight: .semibold)).foregroundStyle(BaziTheme.ink)
                    Text("阅盘 1000+ · 记忆已开启 · 仅存本机")
                        .font(.system(size: 12)).foregroundStyle(BaziTheme.secondary)
                }
            }
            Text(msg.text)
                .font(.system(size: 14)).foregroundStyle(BaziTheme.ink)
                .lineSpacing(4)
            if chart == nil {
                // 无盘引导：AI 顾问是产品主轴，第一屏就把用户带去创建可验证命盘
                Button {
                    NotificationCenter.default.post(name: ContentView.goPaipanNotification, object: nil)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "scope")
                        Text("创建我的命盘 · 可验证排盘")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(BaziTheme.actionBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            } else {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible())], spacing: 8) {
                    ForEach(topics, id: \.label) { t in
                        Button(action: { ask(t.question) }) {
                            Text(t.label)
                                .font(.system(size: 14)).foregroundStyle(BaziTheme.ink)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(BaziTheme.canvas)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(BaziTheme.hairline, lineWidth: 1))
                        }
                    }
                }
            }
            Text("命理分析仅供文化参考，不构成决策依据")
                .font(.system(size: 11)).foregroundStyle(BaziTheme.tertiary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(BaziTheme.fill)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var typingRow: some View {
        HStack(alignment: .top, spacing: 8) {
            ZStack {
                Circle().fill(BaziTheme.actionBlue).frame(width: 30, height: 30)
                Text("灵").font(.system(size: 13, weight: .semibold)).foregroundStyle(.white)
            }
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { _ in
                    Circle().fill(BaziTheme.tertiary).frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 16)
            .background(BaziTheme.fill)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            Spacer()
        }
    }

    // MARK: - 干支五行色（逐字符上色）

    private func attributedGZ(_ s: String) -> AttributedString {
        var attr = AttributedString()
        for ch in s {
            var part = AttributedString(String(ch))
            if let i = Gan.all.firstIndex(of: String(ch)) {
                part.foregroundColor = BaziTheme.wuxingColor(Gan.wuxing[i])
            } else if let i = Zhi.all.firstIndex(of: String(ch)) {
                part.foregroundColor = BaziTheme.wuxingColor(Zhi.wuxing[i])
            }
            attr += part
        }
        return attr
    }

    // MARK: - 数据 & 动作

    struct Message: Identifiable {
        let id = UUID()
        var topic: String?
        var title: String?
        var points: [String]
        var tip: String?
        var followups: [String]
        var historyIndex: Int?     // 对应 AdvisorMemory 历史下标（AI 消息才有，可评价）
        var liked: Int             // 1=有帮助 -1=没帮助 0=未评
        var isFallback: Bool = false  // 网络失败时的本地兜底回复（可见可重试）
        let text: String           // 用户消息原文 / AI 原始回复（含格式标记）
        let isAI: Bool
        let isWelcome: Bool
        var time: String

        static func user(_ text: String, _ time: String) -> Message {
            .init(topic: nil, title: nil, points: [], tip: nil, followups: [],
                  historyIndex: nil, liked: 0,
                  text: text, isAI: false, isWelcome: false, time: time)
        }
        static func aiPlain(_ text: String, _ time: String) -> Message {
            .init(topic: nil, title: nil, points: [], tip: nil, followups: [],
                  historyIndex: nil, liked: 0,
                  text: text, isAI: true, isWelcome: false, time: time)
        }
        static func aiStructured(topic: String?, title: String, points: [String],
                                 tip: String?, followups: [String], raw: String, _ time: String) -> Message {
            .init(topic: topic, title: title, points: points, tip: tip, followups: followups,
                  historyIndex: nil, liked: 0,
                  text: raw, isAI: true, isWelcome: false, time: time)
        }
        static func welcome(_ text: String, _ time: String) -> Message {
            .init(topic: nil, title: nil, points: [], tip: nil, followups: [],
                  historyIndex: nil, liked: 0,
                  text: text, isAI: true, isWelcome: true, time: time)
        }
    }

    private func now() -> String {
        let f = DateFormatter(); f.dateFormat = "HH:mm"; return f.string(from: Date())
    }

    private func recordTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = Calendar.current.isDateInToday(date) ? "HH:mm" : "MM-dd HH:mm"
        return f.string(from: date)
    }

    /// 首次进入：欢迎卡 + 恢复该命盘的历史会话（跨启动延续上下文）
    private func loadContent() {
        guard messages.isEmpty else { return }
        let key = AdvisorMemory.chartKey(chart)
        let hist = AdvisorMemory.history(forKey: key)

        var intro: String
        if let c = chart {
            intro = "您好，我是灵犀。已读取您的命盘（\(c.dayMaster)日主 · \(c.pattern)），可以解读事业、财运、感情与健康——点击下方话题，或直接输入提问。"
        } else {
            intro = "您好，我是灵犀，一位会记住你的 AI 命理顾问。\n还没有你的命盘：先去「排盘」创建一张（节气级精度 + 真太阳时透明换算），回来后我就能结合你的八字说话，而不是泛泛而谈。"
        }
        if !hist.isEmpty {
            intro += "\n我们已聊过 \(hist.count) 次，接着上次继续。"
        }
        messages.append(.welcome(intro, now()))

        for (i, r) in hist.enumerated() {
            messages.append(.user(r.question, recordTime(r.time)))
            var m = parseAIReply(r.answer)
            m.historyIndex = i
            m.liked = r.liked
            m.time = recordTime(r.time)
            messages.append(m)
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.25)) {
            proxy.scrollTo("chatBottom", anchor: .bottom)
        }
    }

    /// 反馈落库（同步内存中的消息状态）
    private func setLiked(_ liked: Int, forID id: Message.ID?) {
        guard let id,
              let i = messages.firstIndex(where: { $0.id == id }),
              let hIdx = messages[i].historyIndex else { return }
        let key = AdvisorMemory.chartKey(chart)
        AdvisorMemory.setFeedback(liked, at: hIdx, forKey: key)
        messages[i].liked = liked
    }

    private func ask(_ q: String) {
        guard !isTyping else { return }
        messages.append(.user(q, now()))
        requestAI()
    }

    private func send() {
        let q = input.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty, !isTyping else { return }
        input = ""
        messages.append(.user(q, now()))
        requestAI()
    }

    /// 组装完整上下文（系统提示词 + 用户记忆 + 风格 + 输出格式 + 历史对话）并请求真实 AI
    private func requestAI() {
        guard let last = messages.last, !last.isAI else { return }
        isTyping = true

        let formatPrompt = """
        【输出格式（严格遵守，各段各占一行）】
        全程纯文本：禁止使用任何 Markdown 符号（不要 **、##、- 列表符、反引号），直接输出汉字内容
        【话题】从「事业/财运/感情/健康/学业/合盘/综合」中选一个词
        【结论】一句话直接回应问题，40字内
        【分析】4-6点，每点独占一行、以数字开头（如 1. ），每点80字内；每点都必须引用具体干支、十神或生克关系作为依据，先依据后判断；运用系统提示词里的解读知识，但要用命盘信息具体化，禁止照抄
        【建议】一到两句可执行的行动建议，60字内
        【追问】3个用户最可能接着问的问题，用「|」分隔
        """

        let memKey = AdvisorMemory.chartKey(chart)
        var systemContent = AiService.buildSystemPrompt(chart: chart, query: last.text)
        let mem = AdvisorMemory.memorySummary(forKey: memKey)
        if !mem.isEmpty { systemContent += "\n" + mem }
        systemContent += "\n" + AdvisorMemory.stylePrompt
        systemContent += "\n" + formatPrompt

        var chatMessages: [AiService.ChatMessage] = []
        chatMessages.append(AiService.ChatMessage(role: "system", content: systemContent))
        // 只回放最近 6 轮（12 条）：全量重放会让 prompt 无上限膨胀，长会话触发截断与跑题；
        // 更早的上下文由 memorySummary（最近问题 + 偏好）以摘要形式承担
        let convo = messages.filter { !$0.isWelcome }
        var recent = Array(convo.suffix(12))
        if recent.first?.isAI == true { recent.removeFirst() }   // 保持 user/assistant 交替
        for m in recent {
            chatMessages.append(AiService.ChatMessage(role: m.isAI ? "assistant" : "user", content: m.text))
        }

        let userText = last.text
        AiService.chat(messages: chatMessages) { result in
            // 回包判活：请求期间命盘已切换则丢弃，防止旧盘回答写入新盘记忆
            guard AdvisorMemory.chartKey(chart) == activeKey else {
                isTyping = false
                return
            }
            isTyping = false
            var m: Message
            var failed = false
            switch result {
            case .success(let text):
                m = parseAIReply(text)
            case .failure:
                // 网络异常兜底：用本地解读，保证离线也能给出回应（可见 + 可重试）
                failed = true
                m = localAnswer(userText)
            }
            // 落库（本地兜底回复同样入库，会话可延续、可评价）
            AdvisorMemory.append(question: userText, answer: m.text, topic: m.topic ?? "综合", forKey: memKey)
            m.historyIndex = AdvisorMemory.history(forKey: memKey).count - 1
            m.isFallback = failed
            messages.append(m)
        }
    }

    // MARK: - AI 回复解析

    private func after(_ marker: String, _ line: String) -> String {
        guard line.hasPrefix(marker) else { return "" }
        return AIClean.text(String(line.dropFirst(marker.count)))
    }

    /// 去掉模型自行加的「1. 」等编号前缀（卡片用圆点自绘）
    private func stripBullet(_ s: String) -> String {
        let prefixes = ["1. ", "1.", "1、", "2. ", "2.", "2、", "3. ", "3.", "3、",
                        "4. ", "4.", "4、", "• ", "•", "· ", "- "]
        for p in prefixes where s.hasPrefix(p) {
            return String(s.dropFirst(p.count)).trimmingCharacters(in: .whitespaces)
        }
        return s
    }

    /// 解析五段式回复；缺【结论】则整段降级为纯文本气泡
    private func parseAIReply(_ raw: String) -> Message {
        var topic: String?
        var title: String?
        var tip: String?
        var points: [String] = []
        var followups: [String] = []
        var section = ""

        for rawLine in raw.components(separatedBy: .newlines) {
            // 先清行内 Markdown 修饰，模型加 **【话题】** 之类也能命中
            let line = AIClean.text(rawLine)
            guard !line.isEmpty else { continue }
            if line.hasPrefix("【话题】") {
                topic = after("【话题】", line); section = ""
            } else if line.hasPrefix("【结论】") {
                title = after("【结论】", line); section = ""
            } else if line.hasPrefix("【分析】") {
                section = "analysis"
                let rest = after("【分析】", line)
                if !rest.isEmpty { points.append(stripBullet(rest)) }
            } else if line.hasPrefix("【建议】") {
                tip = after("【建议】", line); section = ""
            } else if line.hasPrefix("【追问】") {
                section = ""
                let rest = after("【追问】", line)
                followups = rest
                    .split(whereSeparator: { "|｜、;；".contains($0) })
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
            } else if section == "analysis" {
                points.append(stripBullet(line))
            }
        }

        guard let t = title, !t.isEmpty else { return .aiPlain(AIClean.stripSectionTags(raw), now()) }
        let finalTopic = (topic?.isEmpty == false) ? topic! : "综合"
        return .aiStructured(topic: finalTopic, title: t, points: points,
                             tip: tip, followups: followups, raw: raw, now())
    }

    // MARK: - 本地兜底解读（网络不可用时使用，同样走结构化卡片）
    // 知识库驱动：命盘事实 + KnowledgeStore 专业洞察行，离线也有深度

    private func localAnswer(_ q: String) -> Message {
        let t = now()
        guard let c = chart else {
            return .aiPlain("请先在排盘页创建命盘，我就能结合您的八字详细解读了。", t)
        }

        // 话题分类
        let topic: String
        if q.contains("事业") || q.contains("工作") || q.contains("职业") || q.contains("创业") || q.contains("跳槽") {
            topic = "事业"
        } else if q.contains("财") || q.contains("钱") || q.contains("投资") {
            topic = "财运"
        } else if q.contains("感情") || q.contains("婚姻") || q.contains("恋爱") || q.contains("对象") || q.contains("合婚") {
            topic = "感情"
        } else if q.contains("健康") || q.contains("身体") || q.contains("睡眠") {
            topic = "健康"
        } else if q.contains("大运") || q.contains("流年") || q.contains("运势") || q.contains("今年") {
            topic = "大运"
        } else {
            topic = "综合"
        }

        // 命盘事实
        let dm = c.dayMaster
        let pattern = c.pattern
        let shiGan = c.pillars.count > 3 ? c.pillars[3].shiShen : "食神"
        let dayunIdx = c.currentDayunIndex
        let dy = c.dayun.indices.contains(dayunIdx) ? c.dayun[dayunIdx] : nil
        let dayunGz = dy?.ganzhi ?? "—"
        let dayunShi = dy?.shiShen ?? "—"
        let dayunYear = dy.map { "\($0.startYear)-\($0.endYear)" } ?? "—"
        let xiyong = c.xiYong.joined(separator: "、")
        let rizhi = c.pillars.count > 2 ? c.pillars[2].zhi : "—"
        // 专业洞察行（知识库首条非恒选条目的首句）
        let insight = KnowledgeStore.insightLine(chart: c, query: q)

        // 各话题组装
        var title: String
        var points: [String]
        var tip: String
        var followups: [String]

        switch topic {
        case "事业":
            title = "宜走\(xiyong)向赛道，以专业立身"
            points = [
                "\(dm)日主，\(pattern)，时干\(shiGan)透出——\(shiGan)的领域是您的表达出口，也是事业杠杆。",
            ]
            if let ins = insight { points.append("专业口径：\(ins)") }
            points.append("现行\(dayunGz)大运（\(dayunYear)，十神为\(dayunShi)），交脱前后一年最不稳，稳字当头、换运后再放量。")
            tip = "今年宜深耕专业、少争锋；把批判力转化成作品，而不是消耗在争论里。"
            followups = ["哪年事业运最强？", "适合创业还是打工？", "行业方向怎么选？"]
        case "财运":
            title = "财运靠\(c.strength.contains("弱") ? "蓄力复利" : "进取落袋")，不靠投机"
            points = [
                "身\(c.strength.contains("弱") ? "弱" : "旺")看财：\(c.strength.contains("弱") ? "身弱财旺是看得见接不住，先立印（能力与资源）再图财" : "身旺能担财，可进取但防比劫分利")。",
            ]
            if let ins = insight { points.append("专业口径：\(ins)") }
            points.append("喜用为\(xiyong)，行业五行宜往此方向布局；忌神\(c.jiShen.joined(separator: "、"))方向的钱赚得辛苦。")
            tip = "守正财、慎借贷担保；大额支出避开情绪冲动的时刻。"
            followups = ["哪几年财运最旺？", "适合什么方向投资？", "适合合伙吗？"]
        case "感情":
            title = "感情看倾向不看判决，晚成反而更稳"
            points = [
                "夫妻宫坐\(rizhi)，日主\(dm)、\(c.strength)——择偶宜看重品性与韧性，而非一时激情。",
            ]
            if let ins = insight { points.append("专业口径：\(ins)") }
            points.append("配偶星要靠岁运引出，名分没落点不等于不爱；那几年是各自长自己的时间，不是等待的时间。")
            tip = "每周留一段两人专属时间；多表达、少隐忍，仪式感比贵重礼物更重要。"
            followups = ["配偶是什么样的人？", "哪年婚缘最旺？", "我们合不合？"]
        case "健康":
            title = "规律作息，留意\(c.jiShen.joined(separator: "、"))过旺的负担"
            points = [
                "\(dm)日主，忌神\(c.jiShen.joined(separator: "、"))过旺——象上对应相关脏腑与情绪负担，属结构倾向非诊断。",
            ]
            if let ins = insight { points.append("专业口径：\(ins)") }
            points.append("命理只谈状态倾向，健康问题请遵医嘱、定期复查；规律作息与适度运动永远在第一顺位。")
            tip = "从每周三次 30 分钟快走开始，比突击健身更可持续。"
            followups = ["哪个季节要注意？", "作息上怎么调？", "情绪内耗怎么解？"]
        case "大运":
            title = "大运管十年之势，流年管当年之事"
            points = [
                "现行\(dayunGz)大运（\(dayunYear)），十神为\(dayunShi)——这是这十年的主旋律，帮扶用神则顺、引动忌神则滞。",
            ]
            if let ins = insight { points.append("专业口径：\(ins)") }
            points.append("交脱大运前后一年最不稳（换运如换天），心境动荡属正常，不作断语；伏吟年定不下来也不代表不要。")
            tip = "看十年做布局，看当年做动作；换运年守成过渡，不重仓押注。"
            followups = ["换运是在哪一年？", "下一步大运如何？", "今年流年吉凶？"]
        default:
            title = "从\(pattern)看，宜先立心再谋事"
            points = [
                "\(dm)日主，\(pattern)，喜用\(xiyong)——解读一切问题的底层是这组结构。",
            ]
            if let ins = insight { points.append("专业口径：\(ins)") }
            points.append("现行\(dayunGz)大运，用神方向的事宜顺势推进，忌神方向的事宜放缓观察。")
            tip = "命理给方向不给答案；把问题落到具体领域（事业/财运/感情/健康），解读会更准。"
            followups = ["我的事业方向？", "财运节奏如何？", "感情模式是什么？"]
        }

        let raw = "【话题】\(topic)\n【结论】\(title)\n【分析】" + points.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: " ") + "\n【建议】\(tip)\n【追问】\(followups.joined(separator: "|"))"
        return .aiStructured(topic: topic, title: title, points: points, tip: tip, followups: followups, raw: raw, t)
    }
}
