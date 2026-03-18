import Foundation

enum Secrets {
    /// Anthropic API key, injected via Secrets.xcconfig → Info.plist at build time.
    static var anthropicAPIKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "ANTHROPIC_API_KEY") as? String,
              !key.isEmpty,
              key != "YOUR_ANTHROPIC_API_KEY_HERE" else {
            assertionFailure("ANTHROPIC_API_KEY is missing. Copy Secrets.template.xcconfig → Secrets.xcconfig and set your key.")
            return ""
        }
        return key
    }
}
