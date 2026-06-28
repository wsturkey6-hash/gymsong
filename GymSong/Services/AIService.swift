import Foundation

enum AIError: LocalizedError {
    case missingAPIKey
    case httpError(status: Int, body: String)
    case invalidResponse
    case decoding(Error)
    case network(Error)
    case blockedByModel(reason: String)
    case truncated

    var errorDescription: String? {
        switch self {
        case .missingAPIKey: return "尚未設定 Gemini API Key（請到「設定」輸入）"
        case .httpError(let status, let body): return "API 錯誤 \(status)：\(body)"
        case .invalidResponse: return "API 回應格式不正確"
        case .decoding(let err): return "解析回應失敗：\(err.localizedDescription)"
        case .network(let err): return "網路錯誤：\(err.localizedDescription)"
        case .blockedByModel(let reason): return "模型拒絕回應：\(reason)"
        case .truncated: return "AI 回應被截斷（超過 max_tokens）。試試減少週數，或在程式裡把 maxTokens 調高。"
        }
    }
}

/// Gemini Flash API client. Personal-use only — API key stored in Keychain.
struct AIService {
    nonisolated static let baseURL = "https://generativelanguage.googleapis.com/v1beta/models"
    nonisolated static let defaultModel = "gemini-2.5-flash"

    /// Send a request and return the text from the first candidate.
    /// `jsonSchema` (if provided) constrains the model output via
    /// `generationConfig.responseSchema` (with `responseMimeType: application/json`).
    static func generate(
        system: String,
        user: String,
        jsonSchema: [String: Any]? = nil,
        model: String = defaultModel,
        maxTokens: Int = 16000
    ) async throws -> String {
        guard let apiKey = KeychainStore.read(.geminiAPIKey), !apiKey.isEmpty else {
            throw AIError.missingAPIKey
        }

        guard let endpoint = URL(string: "\(baseURL)/\(model):generateContent") else {
            throw AIError.invalidResponse
        }

        var generationConfig: [String: Any] = [
            "maxOutputTokens": maxTokens,
            "temperature": 0.7,
        ]
        if let jsonSchema {
            generationConfig["responseMimeType"] = "application/json"
            generationConfig["responseSchema"] = jsonSchema
        }

        let body: [String: Any] = [
            "systemInstruction": [
                "parts": [["text": system]],
            ],
            "contents": [
                [
                    "role": "user",
                    "parts": [["text": user]],
                ],
            ],
            "generationConfig": generationConfig,
        ]

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 300
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
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
            let decoded = try JSONDecoder().decode(GenerateContentResponse.self, from: data)
            if let block = decoded.promptFeedback?.blockReason {
                throw AIError.blockedByModel(reason: block)
            }
            guard let candidate = decoded.candidates?.first else {
                throw AIError.invalidResponse
            }
            if let finish = candidate.finishReason {
                if finish == "MAX_TOKENS" {
                    throw AIError.truncated
                }
                if finish != "STOP" {
                    throw AIError.blockedByModel(reason: finish)
                }
            }
            let text = candidate.content?.parts?
                .compactMap { $0.text }
                .joined()
                ?? ""
            guard !text.isEmpty else { throw AIError.invalidResponse }
            return text
        } catch let aiError as AIError {
            throw aiError
        } catch {
            throw AIError.decoding(error)
        }
    }

    // MARK: - Response shape

    private struct GenerateContentResponse: Decodable {
        let candidates: [Candidate]?
        let promptFeedback: PromptFeedback?
        let usageMetadata: UsageMetadata?
    }

    private struct Candidate: Decodable {
        let content: Content?
        let finishReason: String?
    }

    private struct Content: Decodable {
        let role: String?
        let parts: [Part]?
    }

    private struct Part: Decodable {
        let text: String?
    }

    private struct PromptFeedback: Decodable {
        let blockReason: String?
    }

    private struct UsageMetadata: Decodable {
        let promptTokenCount: Int?
        let candidatesTokenCount: Int?
        let totalTokenCount: Int?
    }
}
