import Foundation

/// Supported recognition languages
enum RecognitionLanguage: String, CaseIterable {
    case english = "en-US"
    case simplifiedChinese = "zh-CN"
    case traditionalChinese = "zh-TW"
    case japanese = "ja-JP"
    case korean = "ko-KR"

    var displayName: String {
        switch self {
        case .english: return "English"
        case .simplifiedChinese: return "简体中文"
        case .traditionalChinese: return "繁體中文"
        case .japanese: return "日本語"
        case .korean: return "한국어"
        }
    }

    var localeIdentifier: String {
        // SFSpeechRecognizer uses Locale identifiers
        // zh-CN → zh-Hans, zh-TW → zh-Hant for Apple frameworks
        switch self {
        case .english: return "en-US"
        case .simplifiedChinese: return "zh-Hans"
        case .traditionalChinese: return "zh-Hant"
        case .japanese: return "ja-JP"
        case .korean: return "ko-KR"
        }
    }
}

/// LLM configuration model
struct LLMConfiguration: Codable {
    var apiBaseURL: String
    var apiKey: String
    var model: String
    var isEnabled: Bool

    static var empty: LLMConfiguration {
        LLMConfiguration(apiBaseURL: "", apiKey: "", model: "", isEnabled: false)
    }
}

/// Speech recognition delegate protocol
protocol SpeechRecognitionDelegate: AnyObject {
    func speechRecognition(didUpdateRMSLevel level: Float)
    func speechRecognition(didUpdatePartialResult text: String)
    func speechRecognition(didFinishWithResult text: String)
    func speechRecognition(didFailWithError error: Error)
}
