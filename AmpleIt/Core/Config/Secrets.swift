import Foundation

enum Secrets {
    /// Anthropic API key, injected via Secrets.xcconfig → Info.plist at build time.
    static var anthropicAPIKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "ANTHROPIC_API_KEY") as? String,
              !key.isEmpty,
              key != "YOUR_ANTHROPIC_API_KEY_HERE",
              !key.hasPrefix("$(") else {
            print("[Secrets] ANTHROPIC_API_KEY is missing or not substituted. Copy Secrets.template.xcconfig → Secrets.xcconfig, set your key, and assign the xcconfig to your build configuration in Xcode.")
            return ""
        }
        return key
    }
}
