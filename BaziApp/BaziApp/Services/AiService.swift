import Foundation

/// 灵犀 AI 命理顾问 —— 真实大模型接入（代理模式）
/// 复用「甲亢健康管理」已部署的 DeepSeek 代理后端，App 端不内置任何 Key，上架安全。
struct AiService {

    // MARK: - 配置

    /// 云端代理地址（与甲亢 App 共用，服务端持有 DeepSeek Key）
    static let proxyURL = "https://f4275409583b4794b00844db012418ae.app.workbuddy.link"

    /// 可选：代理鉴权 Token（与服务端 APP_TOKEN 一致；服务端未设置则留空）
    static let appToken = ""

    /// 模型名
    static let model = "deepseek-chat"

    // MARK: - 系统提示词

    /// 组装命理顾问系统提示词
    static func buildSystemPrompt(chart: BaziChart?) -> String {
        var lines: [String] = [
            "你是「灵犀」，是「灵犀命理」App 内置的 AI 命理顾问，一位深谙八字命理、语气温和有洞察力的传统文化顾问。",
            "回答要求：",
            "1. 结合用户的八字命盘进行解读，专业、有依据，不编造命盘信息；",
            "2. 语气温和、有共情，像一位值得信赖的长辈或朋友；",
            "3. 回答控制在 200 字以内，分点清晰、口语化；",
            "4. 命理分析仅供文化参考，不构成决策依据，不承诺吉凶祸福的确定性；",
            "5. 涉及婚姻、投资、健康、法律等重大决策时，提醒用户理性决策、勿迷信。"
        ]
        if let c = chart {
            lines.append("用户当前命盘信息（据此解读）：")
            lines.append(chartSummary(c))
        }
        lines.append("现在请回答用户的提问。")
        return lines.joined(separator: "\n")
    }

    /// 命盘摘要文本
    static func chartSummary(_ c: BaziChart) -> String {
        let pillars = c.pillars.map { "\($0.ganzhi)(\($0.shiShen))" }.joined(separator: " ")
        let dayun = c.dayun.indices.contains(c.currentDayunIndex) ? c.dayun[c.currentDayunIndex].ganzhi : "—"
        let wuxing = c.wuxingCount.sorted { $0.key < $1.key }.map { "\($0.key)\($0.value)" }.joined(separator: " ")
        return [
            "姓名：\(c.name)（\(c.gender)）",
            "八字四柱：\(pillars)",
            "日主：\(c.dayMaster)，\(c.strength)",
            "五行：\(wuxing)",
            "喜用神：\(c.xiYong.joined(separator: "、"))，忌神：\(c.jiShen.joined(separator: "、"))",
            "当前大运：\(dayun)"
        ].joined(separator: "；")
    }

    // MARK: - 数据模型

    struct ChatMessage: Codable {
        let role: String
        let content: String
    }

    private struct ChatRequest: Codable {
        let model: String
        let messages: [ChatMessage]
    }

    private struct ChatResponse: Codable {
        struct Choice: Codable {
            struct Msg: Codable { let content: String }
            let message: Msg
        }
        let choices: [Choice]
    }

    // MARK: - 请求

    /// 发送对话请求，回调返回模型回复文本（主线程回调）
    static func chat(messages: [ChatMessage], completion: @escaping (Result<String, AiError>) -> Void) {
        guard let url = URL(string: proxyURL + "/v1/chat") else {
            completion(.failure(.invalidURL))
            return
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !appToken.isEmpty {
            req.setValue(appToken, forHTTPHeaderField: "X-App-Token")
        }
        req.timeoutInterval = 30
        req.httpBody = try? JSONEncoder().encode(ChatRequest(model: model, messages: messages))

        URLSession.shared.dataTask(with: req) { data, resp, err in
            DispatchQueue.main.async {
                if let err = err {
                    completion(.failure(friendlyError(err)))
                    return
                }
                guard let http = resp as? HTTPURLResponse else {
                    completion(.failure(.network))
                    return
                }
                guard http.statusCode == 200, let data = data else {
                    completion(.failure(httpError(status: http.statusCode, data: data)))
                    return
                }
                do {
                    let decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
                    let text = decoded.choices.first?.message.content
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    if let text, !text.isEmpty {
                        completion(.success(text))
                    } else {
                        completion(.failure(.empty))
                    }
                } catch {
                    completion(.failure(.parse))
                }
            }
        }.resume()
    }

    // MARK: - 错误

    enum AiError: LocalizedError {
        case invalidURL
        case network
        case empty
        case parse
        case status(Int, String)

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "服务地址无效"
            case .network: return "网络连接失败，请检查网络后重试"
            case .empty: return "AI 返回为空，请重试"
            case .parse: return "AI 响应解析失败，请重试"
            case .status(let code, let msg):
                return "AI 服务暂时不可用\(msg.isEmpty ? "" : "：" + msg)（\(code)）"
            }
        }
    }

    private static func friendlyError(_ err: Error) -> AiError {
        let ns = err as NSError
        if ns.domain == NSURLErrorDomain { return .network }
        return .status(-1, err.localizedDescription)
    }

    private static func httpError(status: Int, data: Data?) -> AiError {
        var msg = ""
        if let data,
           let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let e = obj["error"] as? [String: Any],
           let m = e["message"] as? String {
            msg = m
        }
        switch status {
        case 401: return .status(status, "代理鉴权失败")
        case 402: return .status(status, "AI 账户余额不足")
        case 429: return .status(status, "请求过于频繁，请稍后再试")
        case 502, 504: return .status(status, "AI 代理服务暂时不可用")
        default: return .status(status, msg)
        }
    }
}
