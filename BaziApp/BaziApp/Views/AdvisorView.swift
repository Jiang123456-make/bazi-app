import SwiftUI

/// 屏 4：顾问·对话
struct AdvisorView: View {
    let chart: BaziChart?

    @State private var messages: [Message] = []
    @State private var input = ""
    @State private var isTyping = false

    private let quickQuestions = ["看事业", "看财运", "看感情", "看健康"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 标题
                VStack(alignment: .leading, spacing: 8) {
                    Text("顾问")
                        .font(BaziTheme.largeTitle())
                        .foregroundStyle(BaziTheme.ink)
                    Text("灵犀 · 阅盘 1000+ · 命理专家")
                        .font(BaziTheme.footnote(15))
                        .foregroundStyle(BaziTheme.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 8)

                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(messages) { msg in
                            messageRow(msg)
                        }
                        if isTyping {
                            typingRow
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                }

                // 快捷回复
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(quickQuestions, id: \.self) { q in
                            Button(action: { ask(q) }) {
                                Text(q).font(.system(size: 14)).foregroundStyle(BaziTheme.ink)
                                    .padding(.horizontal, 16).padding(.vertical, 8)
                                    .background(BaziTheme.fill).clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 8)

                // 输入栏
                HStack(spacing: 8) {
                    Button(action: {}) {
                        Image(systemName: "mic")
                            .font(.system(size: 18)).foregroundStyle(BaziTheme.secondary)
                            .frame(width: 44, height: 44)
                            .background(BaziTheme.fill).clipShape(Circle())
                    }
                    TextField("输入你的问题…", text: $input)
                        .font(.system(size: 15))
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
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            }
            .background(BaziTheme.canvas)
            .onAppear { loadGreeting() }
        }
    }

    // MARK: - 消息行

    private func messageRow(_ msg: Message) -> some View {
        VStack(spacing: 4) {
            Text(msg.time).font(.system(size: 11)).foregroundStyle(BaziTheme.tertiary)
            HStack {
                if msg.isAI {
                    HStack(alignment: .top, spacing: 8) {
                        ZStack {
                            Circle().fill(BaziTheme.actionBlue).frame(width: 32, height: 32)
                            Text("灵").font(.system(size: 14, weight: .semibold)).foregroundStyle(.white)
                        }
                        Text(msg.text)
                            .font(.system(size: 13)).foregroundStyle(BaziTheme.ink)
                            .padding(.horizontal, 14).padding(.vertical, 12)
                            .background(BaziTheme.fill)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        Spacer()
                    }
                } else {
                    HStack {
                        Spacer()
                        Text(msg.text)
                            .font(.system(size: 13)).foregroundStyle(.white)
                            .padding(.horizontal, 14).padding(.vertical, 12)
                            .background(BaziTheme.actionBlue)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                }
            }
        }
    }

    private var typingRow: some View {
        HStack {
            ZStack {
                Circle().fill(BaziTheme.actionBlue).frame(width: 32, height: 32)
                Text("灵").font(.system(size: 14, weight: .semibold)).foregroundStyle(.white)
            }
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { _ in
                    Circle().fill(BaziTheme.tertiary).frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
            .background(BaziTheme.fill)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            Spacer()
        }
    }

    // MARK: - 数据 & 动作

    struct Message: Identifiable {
        let id = UUID()
        let text: String
        let isAI: Bool
        let time: String
    }

    private func now() -> String {
        let f = DateFormatter(); f.dateFormat = "HH:mm"; return f.string(from: Date())
    }

    private func loadGreeting() {
        guard messages.isEmpty else { return }
        let dm = chart?.dayMaster ?? "庚金"
        messages.append(Message(text: "您好，我是灵犀。基于您的八字（\(dm)日主），可以为您解读事业、财运、感情与健康。", isAI: true, time: now()))
    }

    private func ask(_ q: String) {
        messages.append(Message(text: "帮我\(q)", isAI: false, time: now()))
        isTyping = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isTyping = false
            messages.append(Message(text: answer(q), isAI: true, time: now()))
        }
    }

    private func send() {
        let q = input.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return }
        input = ""
        ask(q.replacingOccurrences(of: "帮我", with: "").replacingOccurrences(of: "看", with: "看"))
    }

    private func answer(_ q: String) -> String {
        if q.contains("事业") { return "您食神生财，宜从事文化创意、口才表达、教育传媒等方向。当前大运食神主事，事业稳步上升，2028 换大运后有新的机遇。" }
        if q.contains("财运") { return "正财平稳，中年后渐入佳境。您理财观念较强，但需注意不要因朋友义气破财。" }
        if q.contains("感情") { return "配偶宫坐食神，晚婚为宜。感情中需多沟通，避免因工作忙碌忽略对方感受。" }
        if q.contains("健康") { return "金旺需注意呼吸系统与皮肤。建议规律作息，适当运动，秋季尤其注意养肺。" }
        return "这个问题我可以结合您的命盘为您详细解读，您可以具体说说想了解哪方面？"
    }
}
