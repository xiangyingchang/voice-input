import Foundation

/// LLM service for text refinement via OpenAI-compatible API
class LLMService {

    private let settingsManager: SettingsManager
    private let session: URLSession
    private let timeoutInterval: TimeInterval = 10.0

    private let systemPrompt = """
    You are a speech recognition post-processor. Your ONLY job is to fix obvious speech recognition errors. Be extremely conservative.

    Rules:
    1. ONLY fix clear speech recognition errors:
       - Chinese homophone errors (同音字错误), e.g., 在→再 when context requires it
       - English technical terms mistakenly converted to Chinese, e.g., 配森→Python, 杰森→JSON, 诶屁爱→API, 吉特→Git, 杰爱斯→JS, 瑞克特→React, 诺德→Node, 泰普→Type
       - Obviously garbled characters from recognition errors
    2. NEVER rewrite, rephrase, polish, or restructure the text
    3. NEVER add or remove content, punctuation changes should be minimal
    4. NEVER change the meaning or tone
    5. If the input looks correct, return it EXACTLY as-is
    6. Preserve all whitespace, line breaks, and formatting
    7. For mixed Chinese-English text, ensure technical terms are in their correct English form

    Return ONLY the corrected text, nothing else. No explanations, no markdown, no quotes.
    """

    init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeoutInterval
        config.timeoutIntervalForResource = timeoutInterval
        self.session = URLSession(configuration: config)
    }

    // MARK: - Refine Text

    /// Refine text via LLM. Returns nil on failure (caller should fallback to raw text).
    func refine(text: String, completion: @escaping (String?) -> Void) {
        let config = settingsManager.llmConfiguration

        guard !config.apiBaseURL.isEmpty, !config.apiKey.isEmpty, !config.model.isEmpty else {
            completion(nil)
            return
        }

        // Build URL
        var baseURL = config.apiBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if baseURL.hasSuffix("/") { baseURL.removeLast() }
        if !baseURL.hasSuffix("/v1") && !baseURL.hasSuffix("/chat/completions") {
            baseURL += "/v1"
        }
        let urlString = baseURL.hasSuffix("/chat/completions")
            ? baseURL
            : baseURL + "/chat/completions"

        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }

        // Build request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "model": config.model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": text]
            ],
            "temperature": 0.1, // Low temperature for conservative corrections
            "max_tokens": 4096
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(nil)
            return
        }

        let task = session.dataTask(with: request) { data, response, error in
            guard error == nil,
                  let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let first = choices.first,
                  let message = first["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                completion(nil)
                return
            }

            let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
            completion(trimmed.isEmpty ? nil : trimmed)
        }
        task.resume()
    }

    // MARK: - Test Connection

    func testConnection(config: LLMConfiguration, completion: @escaping (Bool, String) -> Void) {
        var baseURL = config.apiBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if baseURL.hasSuffix("/") { baseURL.removeLast() }
        if !baseURL.hasSuffix("/v1") && !baseURL.hasSuffix("/chat/completions") {
            baseURL += "/v1"
        }
        let urlString = baseURL.hasSuffix("/chat/completions")
            ? baseURL
            : baseURL + "/chat/completions"

        guard let url = URL(string: urlString) else {
            completion(false, "Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "model": config.model,
            "messages": [
                ["role": "user", "content": "Hello"]
            ],
            "max_tokens": 5
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(false, "Failed to build request")
            return
        }

        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(false, error.localizedDescription) }
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async { completion(false, "No response") }
                return
            }

            if httpResponse.statusCode == 200 {
                DispatchQueue.main.async { completion(true, "Connection successful! ✅") }
            } else {
                var message = "HTTP \(httpResponse.statusCode)"
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errorObj = json["error"] as? [String: Any],
                   let errorMsg = errorObj["message"] as? String {
                    message += ": \(errorMsg)"
                }
                DispatchQueue.main.async { completion(false, message) }
            }
        }
        task.resume()
    }
}
