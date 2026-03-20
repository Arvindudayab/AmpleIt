import Foundation

enum AnthropicEvent {
    case textDelta(String)
    case toolUseStart(id: String, name: String)
    case toolUseDelta(String)
    case stopReason(String)
}

enum AnthropicError: LocalizedError {
    case badStatus(Int)
    case missingKey

    var errorDescription: String? {
        switch self {
        case .badStatus(let code): return "API returned status \(code)"
        case .missingKey: return "API key not set in SecretsConfig.swift"
        }
    }
}

struct AnthropicClient {

    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    private let apiVersion = "2023-06-01"

    func stream(
        messages: [[String: Any]],
        system: String,
        tools: [[String: Any]]
    ) -> AsyncThrowingStream<AnthropicEvent, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    guard !SecretsConfig.claudeAPIKey.isEmpty else {
                        throw AnthropicError.missingKey
                    }

                    var req = URLRequest(url: endpoint)
                    req.httpMethod = "POST"
                    req.setValue("application/json",          forHTTPHeaderField: "Content-Type")
                    req.setValue(SecretsConfig.claudeAPIKey,  forHTTPHeaderField: "x-api-key")
                    req.setValue(apiVersion,                  forHTTPHeaderField: "anthropic-version")

                    let body: [String: Any] = [
                        "model":      "claude-haiku-4-5-20251001",
                        "max_tokens": 1024,
                        "system":     system,
                        "messages":   messages,
                        "tools":      tools,
                        "stream":     true
                    ]
                    req.httpBody = try JSONSerialization.data(withJSONObject: body)

                    let (bytes, response) = try await URLSession.shared.bytes(for: req)
                    if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                        throw AnthropicError.badStatus(http.statusCode)
                    }

                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        let jsonStr = String(line.dropFirst(6))
                        guard jsonStr != "[DONE]",
                              let data = jsonStr.data(using: .utf8),
                              let obj  = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                        else { continue }

                        switch obj["type"] as? String ?? "" {

                        case "content_block_start":
                            if let block = obj["content_block"] as? [String: Any],
                               block["type"] as? String == "tool_use",
                               let id   = block["id"]   as? String,
                               let name = block["name"] as? String {
                                continuation.yield(.toolUseStart(id: id, name: name))
                            }

                        case "content_block_delta":
                            guard let delta = obj["delta"] as? [String: Any] else { break }
                            let dType = delta["type"] as? String ?? ""
                            if dType == "text_delta", let text = delta["text"] as? String {
                                continuation.yield(.textDelta(text))
                            } else if dType == "input_json_delta",
                                      let partial = delta["partial_json"] as? String {
                                continuation.yield(.toolUseDelta(partial))
                            }

                        case "message_delta":
                            if let d = obj["delta"] as? [String: Any],
                               let reason = d["stop_reason"] as? String {
                                continuation.yield(.stopReason(reason))
                            }

                        default: break
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
