import Foundation

/// Manages UserDefaults persistence for language and LLM settings
class SettingsManager {

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let selectedLanguage = "selectedLanguage"
        static let llmEnabled = "llmEnabled"
        static let llmAPIBaseURL = "llmAPIBaseURL"
        static let llmAPIKey = "llmAPIKey"
        static let llmModel = "llmModel"
    }

    // MARK: - Language

    var selectedLanguage: RecognitionLanguage {
        get {
            guard let raw = defaults.string(forKey: Keys.selectedLanguage),
                  let lang = RecognitionLanguage(rawValue: raw) else {
                return .simplifiedChinese // default
            }
            return lang
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.selectedLanguage)
        }
    }

    // MARK: - LLM Configuration

    var llmConfiguration: LLMConfiguration {
        get {
            LLMConfiguration(
                apiBaseURL: defaults.string(forKey: Keys.llmAPIBaseURL) ?? "",
                apiKey: defaults.string(forKey: Keys.llmAPIKey) ?? "",
                model: defaults.string(forKey: Keys.llmModel) ?? "",
                isEnabled: defaults.bool(forKey: Keys.llmEnabled)
            )
        }
        set {
            defaults.set(newValue.apiBaseURL, forKey: Keys.llmAPIBaseURL)
            defaults.set(newValue.apiKey, forKey: Keys.llmAPIKey)
            defaults.set(newValue.model, forKey: Keys.llmModel)
            defaults.set(newValue.isEnabled, forKey: Keys.llmEnabled)
        }
    }

    var isLLMEnabled: Bool {
        get { defaults.bool(forKey: Keys.llmEnabled) }
        set { defaults.set(newValue, forKey: Keys.llmEnabled) }
    }
}
