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
    private let baseURL = "http://localhost:8091"

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
    
    /// 提交复述文本给LLM评测
    func evaluateRetell(contentId: String, originalTitle: String, originalContent: String,
                        keyPoints: [String], retellText: String) async throws -> RetellEvaluationResponse {
        guard let url = URL(string: "\(baseURL)/api/daily-content/evaluate-retell") else {
            throw ApiError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30  // LLM可能较慢，给足时间
        
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
}
