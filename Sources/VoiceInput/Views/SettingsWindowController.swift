import AppKit

/// Settings window for LLM configuration
class SettingsWindowController: NSWindowController {

    private let settingsManager: SettingsManager
    private let llmService: LLMService

    private var apiBaseURLField: NSTextField!
    private var apiKeyField: NSSecureTextField!
    private var modelField: NSTextField!
    private var testButton: NSButton!
    private var saveButton: NSButton!
    private var statusLabel: NSTextField!
    private var showPasswordButton: NSButton!
    private var plainApiKeyField: NSTextField!
    private var isPasswordVisible = false

    init(settingsManager: SettingsManager, llmService: LLMService) {
        self.settingsManager = settingsManager
        self.llmService = llmService

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 310),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "LLM Refinement Settings"
        window.center()
        window.isReleasedWhenClosed = false

        super.init(window: window)

        setupUI()
        loadSettings()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Setup

    private func setupUI() {
        guard let contentView = window?.contentView else { return }

        let padding: CGFloat = 20
        let labelWidth: CGFloat = 100
        let fieldHeight: CGFloat = 24
        var y: CGFloat = 250

        // API Base URL
        let urlLabel = createLabel("API Base URL:", frame: NSRect(x: padding, y: y, width: labelWidth, height: fieldHeight))
        contentView.addSubview(urlLabel)

        apiBaseURLField = NSTextField(frame: NSRect(x: padding + labelWidth + 8, y: y, width: 330, height: fieldHeight))
        apiBaseURLField.placeholderString = "https://api.openai.com"
        apiBaseURLField.font = NSFont.systemFont(ofSize: 13)
        contentView.addSubview(apiBaseURLField)

        // API Key
        y -= 40
        let keyLabel = createLabel("API Key:", frame: NSRect(x: padding, y: y, width: labelWidth, height: fieldHeight))
        contentView.addSubview(keyLabel)

        apiKeyField = NSSecureTextField(frame: NSRect(x: padding + labelWidth + 8, y: y, width: 295, height: fieldHeight))
        apiKeyField.placeholderString = "sk-..."
        apiKeyField.font = NSFont.systemFont(ofSize: 13)
        contentView.addSubview(apiKeyField)

        plainApiKeyField = NSTextField(frame: NSRect(x: padding + labelWidth + 8, y: y, width: 295, height: fieldHeight))
        plainApiKeyField.placeholderString = "sk-..."
        plainApiKeyField.font = NSFont.systemFont(ofSize: 13)
        plainApiKeyField.isHidden = true
        contentView.addSubview(plainApiKeyField)

        showPasswordButton = NSButton(frame: NSRect(x: padding + labelWidth + 308, y: y, width: 30, height: fieldHeight))
        showPasswordButton.bezelStyle = .inline
        showPasswordButton.image = NSImage(systemSymbolName: "eye", accessibilityDescription: "Show API Key")
        showPasswordButton.isBordered = false
        showPasswordButton.target = self
        showPasswordButton.action = #selector(togglePasswordVisibility(_:))
        contentView.addSubview(showPasswordButton)

        // Model
        y -= 40
        let modelLabel = createLabel("Model:", frame: NSRect(x: padding, y: y, width: labelWidth, height: fieldHeight))
        contentView.addSubview(modelLabel)

        modelField = NSTextField(frame: NSRect(x: padding + labelWidth + 8, y: y, width: 330, height: fieldHeight))
        modelField.placeholderString = "gpt-4o-mini"
        modelField.font = NSFont.systemFont(ofSize: 13)
        contentView.addSubview(modelField)

        // Status label
        y -= 40
        statusLabel = NSTextField(labelWithString: "")
        statusLabel.frame = NSRect(x: padding, y: y, width: 440, height: fieldHeight)
        statusLabel.font = NSFont.systemFont(ofSize: 12)
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.lineBreakMode = .byTruncatingTail
        contentView.addSubview(statusLabel)

        // Buttons
        y -= 44

        testButton = NSButton(frame: NSRect(x: padding, y: y, width: 90, height: 32))
        testButton.title = "Test"
        testButton.bezelStyle = .rounded
        testButton.target = self
        testButton.action = #selector(testConnection(_:))
        contentView.addSubview(testButton)

        saveButton = NSButton(frame: NSRect(x: 380, y: y, width: 80, height: 32))
        saveButton.title = "Save"
        saveButton.bezelStyle = .rounded
        saveButton.keyEquivalent = "\r"
        saveButton.target = self
        saveButton.action = #selector(saveSettings(_:))
        contentView.addSubview(saveButton)
    }

    private func createLabel(_ text: String, frame: NSRect) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.frame = frame
        label.font = NSFont.systemFont(ofSize: 13)
        label.alignment = .right
        return label
    }

    // MARK: - Load / Save

    private func loadSettings() {
        let config = settingsManager.llmConfiguration
        apiBaseURLField.stringValue = config.apiBaseURL
        apiKeyField.stringValue = config.apiKey
        plainApiKeyField.stringValue = config.apiKey
        modelField.stringValue = config.model
    }

    @objc private func saveSettings(_ sender: Any) {
        let apiKey = isPasswordVisible ? plainApiKeyField.stringValue : apiKeyField.stringValue
        var config = settingsManager.llmConfiguration
        config.apiBaseURL = apiBaseURLField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        config.apiKey = apiKey
        config.model = modelField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        settingsManager.llmConfiguration = config

        statusLabel.textColor = .systemGreen
        statusLabel.stringValue = "Settings saved ✅"

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.statusLabel.stringValue = ""
        }
    }

    @objc private func testConnection(_ sender: Any) {
        let apiKey = isPasswordVisible ? plainApiKeyField.stringValue : apiKeyField.stringValue
        let config = LLMConfiguration(
            apiBaseURL: apiBaseURLField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines),
            apiKey: apiKey,
            model: modelField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines),
            isEnabled: true
        )

        statusLabel.textColor = .secondaryLabelColor
        statusLabel.stringValue = "Testing connection…"
        testButton.isEnabled = false

        llmService.testConnection(config: config) { [weak self] success, message in
            self?.testButton.isEnabled = true
            self?.statusLabel.textColor = success ? .systemGreen : .systemRed
            self?.statusLabel.stringValue = message
        }
    }

    @objc private func togglePasswordVisibility(_ sender: Any) {
        isPasswordVisible.toggle()

        if isPasswordVisible {
            plainApiKeyField.stringValue = apiKeyField.stringValue
            apiKeyField.isHidden = true
            plainApiKeyField.isHidden = false
            showPasswordButton.image = NSImage(systemSymbolName: "eye.slash", accessibilityDescription: "Hide API Key")
        } else {
            apiKeyField.stringValue = plainApiKeyField.stringValue
            plainApiKeyField.isHidden = true
            apiKeyField.isHidden = false
            showPasswordButton.image = NSImage(systemSymbolName: "eye", accessibilityDescription: "Show API Key")
        }
    }
}
