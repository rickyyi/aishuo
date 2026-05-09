import Foundation

enum ApiError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
    case serverError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的服务器地址"
        case .networkError(let error):
            return "网络连接失败: \(error.localizedDescription)"
        case .invalidResponse:
            return "服务器响应异常"
        case .decodingError(let error):
            return "数据解析失败: \(error.localizedDescription)"
        case .serverError(let statusCode):
            return "服务器错误: \(statusCode)"
        }
    }
}

class ApiService {
    static let shared = ApiService()

    // 服务器地址，可根据实际部署修改
    // 模拟器访问本地服务使用 localhost
    // 真机测试需改为电脑局域网IP
    private let baseURL = "http://127.0.0.1:8091"

    private let session: URLSession
    private let decoder: JSONDecoder

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)

        self.decoder = JSONDecoder()
    }

    /// 获取今日每日内容
    func fetchTodayContent() async throws -> DailyContent {
        guard let url = URL(string: "\(baseURL)/api/daily-content/today") else {
            throw ApiError.invalidURL
        }

        return try await fetchContent(from: url)
    }

    /// 获取下一条内容（强制刷新）
    func fetchNextContent() async throws -> DailyContent {
        guard let url = URL(string: "\(baseURL)/api/daily-content/next") else {
            throw ApiError.invalidURL
        }

        return try await fetchContent(from: url)
    }

    /// 通用的内容请求方法
    private func fetchContent(from url: URL) async throws -> DailyContent {
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            throw ApiError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ApiError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw ApiError.serverError(statusCode: httpResponse.statusCode)
        }

        do {
            return try decoder.decode(DailyContent.self, from: data)
        } catch {
            throw ApiError.decodingError(error)
        }
    }

    /// 获取所有每日内容
    func fetchAllContents() async throws -> [DailyContent] {
        guard let url = URL(string: "\(baseURL)/api/daily-content") else {
            throw ApiError.invalidURL
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            throw ApiError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ApiError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw ApiError.serverError(statusCode: httpResponse.statusCode)
        }

        do {
            return try decoder.decode([DailyContent].self, from: data)
        } catch {
            throw ApiError.decodingError(error)
        }
    }
    
    /// 提交复述文本给LLM评测（非流式，完整响应）
    func evaluateRetell(contentId: String, originalTitle: String, originalContent: String,
                        keyPoints: [String], retellText: String) async throws -> RetellEvaluationResponse {
        guard let url = URL(string: "\(baseURL)/api/daily-content/evaluate-retell") else {
            throw ApiError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        let body: [String: Any] = [
            "contentId": contentId,
            "originalTitle": originalTitle,
            "originalContent": originalContent,
            "keyPoints": keyPoints,
            "retellText": retellText
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw ApiError.networkError(error)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ApiError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw ApiError.serverError(statusCode: httpResponse.statusCode)
        }
        
        do {
            return try decoder.decode(RetellEvaluationResponse.self, from: data)
        } catch {
            throw ApiError.decodingError(error)
        }
    }
    
    // MARK: - SSE 流式评测
    
    /// SSE 流式评测复述文本，onToken 逐 token 回调
    func evaluateRetellStream(
        contentId: String, originalTitle: String, originalContent: String,
        keyPoints: [String], retellText: String,
        onToken: @escaping (String) -> Void
    ) async throws -> RetellEvaluationResponse {
        guard let url = URL(string: "\(baseURL)/api/daily-content/evaluate-retell/stream") else {
            throw ApiError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 60
        
        let body: [String: Any] = [
            "contentId": contentId,
            "originalTitle": originalTitle,
            "originalContent": originalContent,
            "keyPoints": keyPoints,
            "retellText": retellText
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let reader = SSEStreamReader(onToken: onToken)
        
        return try await withCheckedThrowingContinuation { continuation in
            reader.onFinish = { accumulatedText in
                let jsonStr = self.extractJsonFromResponse(accumulatedText)
                guard let data = jsonStr.data(using: .utf8) else {
                    continuation.resume(throwing: ApiError.invalidResponse)
                    return
                }
                do {
                    let result = try self.decoder.decode(RetellEvaluationResponse.self, from: data)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: ApiError.decodingError(error))
                }
            }
            reader.onError = { error in
                continuation.resume(throwing: ApiError.networkError(error))
            }
            
            let session = URLSession(configuration: .default, delegate: reader, delegateQueue: nil)
            let task = session.dataTask(with: request)
            task.resume()
            // 让 session 在任务完成后释放
            _ = session
        }
    }
    
    /// 从 LLM 流式响应中提取 JSON（移除可能的 Markdown 包裹）
    private func extractJsonFromResponse(_ text: String) -> String {
        var trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("```") {
            if let start = trimmed.firstIndex(of: "\n") {
                trimmed = String(trimmed[trimmed.index(after: start)...])
            }
            trimmed = trimmed.replacingOccurrences(of: "```", with: "")
        }
        return trimmed.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - 场景对话
    
    /// SSE 流式生成场景案例
    func startScenarioStream(
        sceneName: String,
        sceneDescription: String,
        difficulty: String,
        onToken: @escaping (String) -> Void
    ) async throws -> String {
        guard let url = URL(string: "\(baseURL)/api/scenario/start") else {
            throw ApiError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 60
        
        let body: [String: Any] = [
            "sceneName": sceneName,
            "sceneDescription": sceneDescription,
            "difficulty": difficulty
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let reader = SSEStreamReader(onToken: onToken)
        
        return try await withCheckedThrowingContinuation { continuation in
            reader.onFinish = { accumulatedText in
                continuation.resume(returning: accumulatedText)
            }
            reader.onError = { error in
                continuation.resume(throwing: ApiError.networkError(error))
            }
            
            let session = URLSession(configuration: .default, delegate: reader, delegateQueue: nil)
            let task = session.dataTask(with: request)
            task.resume()
            _ = session
        }
    }
    
    /// SSE 流式自定义场景生成——根据用户话题生成场景案例
    func customStartScenarioStream(
        topic: String,
        onToken: @escaping (String) -> Void
    ) async throws -> String {
        guard let url = URL(string: "\(baseURL)/api/scenario/custom-start") else {
            throw ApiError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 60
        
        let body: [String: Any] = ["topic": topic]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let reader = SSEStreamReader(onToken: onToken)
        
        return try await withCheckedThrowingContinuation { continuation in
            reader.onFinish = { accumulatedText in
                continuation.resume(returning: accumulatedText)
            }
            reader.onError = { error in
                continuation.resume(throwing: ApiError.networkError(error))
            }
            
            let session = URLSession(configuration: .default, delegate: reader, delegateQueue: nil)
            let task = session.dataTask(with: request)
            task.resume()
            _ = session
        }
    }
    
    /// SSE 流式对话续接——以角色身份生成下一句回复
    func chatScenarioStream(
        sceneName: String,
        sceneDescription: String,
        difficulty: String,
        messages: [(role: String, content: String)],
        onToken: @escaping (String) -> Void
    ) async throws -> String {
        guard let url = URL(string: "\(baseURL)/api/scenario/chat") else {
            throw ApiError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 60
        
        let msgItems: [[String: String]] = messages.map { ["role": $0.role, "content": $0.content] }
        let body: [String: Any] = [
            "sceneName": sceneName,
            "sceneDescription": sceneDescription,
            "difficulty": difficulty,
            "messages": msgItems
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let reader = SSEStreamReader(onToken: onToken)
        
        return try await withCheckedThrowingContinuation { continuation in
            reader.onFinish = { accumulatedText in
                continuation.resume(returning: accumulatedText)
            }
            reader.onError = { error in
                continuation.resume(throwing: ApiError.networkError(error))
            }
            
            let session = URLSession(configuration: .default, delegate: reader, delegateQueue: nil)
            let task = session.dataTask(with: request)
            task.resume()
            _ = session
        }
    }
    
    /// 评测完整对话会话
    func evaluateScenario(
        sceneName: String,
        sceneDescription: String,
        roundCount: Int,
        duration: TimeInterval,
        messages: [(role: String, content: String)]
    ) async throws -> ScenarioEvaluationResponse {
        guard let url = URL(string: "\(baseURL)/api/scenario/evaluate") else {
            throw ApiError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        let msgItems: [[String: String]] = messages.map { ["role": $0.role, "content": $0.content] }
        let body: [String: Any] = [
            "sceneName": sceneName,
            "sceneDescription": sceneDescription,
            "roundCount": roundCount,
            "duration": Int(duration),
            "messages": msgItems
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw ApiError.networkError(error)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ApiError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw ApiError.serverError(statusCode: httpResponse.statusCode)
        }
        
        do {
            return try decoder.decode(ScenarioEvaluationResponse.self, from: data)
        } catch {
            throw ApiError.decodingError(error)
        }
    }
}

// MARK: - SSE 流式读取委托

private class SSEStreamReader: NSObject, URLSessionDataDelegate {
    private let onToken: (String) -> Void
    var onFinish: ((String) -> Void)?
    var onError: ((Error) -> Void)?
    
    private var buffer = ""
    private var accumulatedText = ""
    
    init(onToken: @escaping (String) -> Void) {
        self.onToken = onToken
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let chunk = String(data: data, encoding: .utf8) else { return }
        buffer += chunk
        processBuffer()
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            // 检查是否是正常结束（NSURLErrorDomain -1 或 nil domain 1 的 cancelled）
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
                // 用户取消是正常的
                return
            }
            // 检查是否是流正常结束（一些环境下连接关闭会报 -1 错误）
            if nsError.domain == NSPOSIXErrorDomain && nsError.code == 1 {
                // EPERM - 流读取完成后连接关闭是正常的
            } else {
                onError?(error)
                return
            }
        }
        // 处理 buffer 中剩余内容
        processBuffer()
        onFinish?(accumulatedText)
    }
    
    private func processBuffer() {
        while let newlineRange = buffer.range(of: "\n") {
            let line = String(buffer[buffer.startIndex..<newlineRange.lowerBound])
            buffer = String(buffer[newlineRange.upperBound...])
            
            if line.hasPrefix("data:") {
                // 兼容 "data:content" 和 "data: content" 两种格式，同时处理 "\r" 末尾
                let trimmed = line.dropFirst(5).trimmingCharacters(in: .whitespacesAndNewlines)
                accumulatedText += trimmed
                onToken(trimmed)
            }
        }
    }
}
