import Foundation

enum AIError: LocalizedError {
    case missingAPIKey
    case httpError(status: Int, body: String)
    case invalidResponse
    case decoding(Error)
    case network(Error)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey: return "尚未設定 Claude API Key（請到「設定」輸入）"
        case .httpError(let status, let body): return "API 錯誤 \(status)：\(body)"
        case .invalidResponse: return "API 回應格式不正確"
        case .decoding(let err): return "解析回應失敗：\(err.localizedDescription)"
        case .network(let err): return "網路錯誤：\(err.localizedDescription)"
        }
    }
}

/// Claude API client. Personal-use only — API key stored in Keychain.
struct AIService {
    nonisolated static let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    nonisolated static let apiVersion = "2023-06-01"
    nonisolated static let defaultModel = "claude-sonnet-4-6"

    /// Send a request and return the first text block from the response.
    /// `jsonSchema` (if provided) constrains the model output via `output_config.format`.
    static func generate(
        system: String,
        user: String,
        jsonSchema: [String: Any]? = nil,
        model: String = defaultModel,
        maxTokens: Int = 16000
    ) async throws -> String {
        guard let apiKey = KeychainStore.read(.anthropicAPIKey), !apiKey.isEmpty else {
            throw AIError.missingAPIKey
        }

        var body: [String: Any] = [
            "model": model,
            "max_tokens": maxTokens,
            "system": system,
            "messages": [
                ["role": "user", "content": user],
            ],
        ]
        if let jsonSchema {
            body["output_config"] = [
                "format": [
                    "type": "json_schema",
                    "schema": jsonSchema,
                ],
            ]
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 300
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(apiVersion, forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw AIError.network(error)
        }

        guard let http = response as? HTTPURLResponse else { throw AIError.invalidResponse }
        guard http.statusCode == 200 else {
            let snippet = String(data: data, encoding: .utf8) ?? "<binary>"
            throw AIError.httpError(status: http.statusCode, body: snippet)
        }

        do {
            let decoded = try JSONDecoder().decode(MessagesResponse.self, from: data)
            guard let text = decoded.content.first(where: { $0.type == "text" })?.text, !text.isEmpty else {
                throw AIError.invalidResponse
            }
            return text
        } catch let aiError as AIError {
            throw aiError
        } catch {
            throw AIError.decoding(error)
        }
    }

    // MARK: - Response shape

    private struct MessagesResponse: Decodable {
        let content: [ContentBlock]
        let stopReason: String?
        let usage: Usage?

        enum CodingKeys: String, CodingKey {
            case content
            case stopReason = "stop_reason"
            case usage
        }
    }

    private struct ContentBlock: Decodable {
        let type: String
        let text: String?
    }

    private struct Usage: Decodable {
        let inputTokens: Int?
        let outputTokens: Int?

        enum CodingKeys: String, CodingKey {
            case inputTokens = "input_tokens"
            case outputTokens = "output_tokens"
        }
    }
}
