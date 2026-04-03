import AppKit

/// Manages the menu bar status item and its menu
class StatusBarManager {

    private var statusItem: NSStatusItem!
    private var settingsManager: SettingsManager
    private var onLanguageChanged: () -> Void
    private var onOpenSettings: () -> Void

    private var languageMenuItems: [NSMenuItem] = []
    private var llmToggleItem: NSMenuItem!

    init(settingsManager: SettingsManager,
         onLanguageChanged: @escaping () -> Void,
         onOpenSettings: @escaping () -> Void) {
        self.settingsManager = settingsManager
        self.onLanguageChanged = onLanguageChanged
        self.onOpenSettings = onOpenSettings
        setupStatusItem()
    }

    // MARK: - Setup

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: "Voice Input")
            button.image?.size = NSSize(width: 16, height: 16)
        }

        let menu = NSMenu()

        // Title
        let titleItem = NSMenuItem(title: "Voice Input", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        menu.addItem(NSMenuItem.separator())

        // Status hint
        let hintItem = NSMenuItem(title: "Hold Fn to record", action: nil, keyEquivalent: "")
        hintItem.isEnabled = false
        menu.addItem(hintItem)
        menu.addItem(NSMenuItem.separator())

        // Language submenu
        let languageMenu = NSMenu()
        let currentLanguage = settingsManager.selectedLanguage

        for language in RecognitionLanguage.allCases {
            let item = NSMenuItem(
                title: language.displayName,
                action: #selector(languageSelected(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = language
            item.state = (language == currentLanguage) ? .on : .off
            languageMenu.addItem(item)
            languageMenuItems.append(item)
        }

        let languageSubmenuItem = NSMenuItem(title: "Language", action: nil, keyEquivalent: "")
        languageSubmenuItem.submenu = languageMenu
        menu.addItem(languageSubmenuItem)

        // LLM Refinement submenu
        let llmMenu = NSMenu()

        llmToggleItem = NSMenuItem(
            title: "Enable LLM Refinement",
            action: #selector(toggleLLM(_:)),
            keyEquivalent: ""
        )
        llmToggleItem.target = self
        llmToggleItem.state = settingsManager.isLLMEnabled ? .on : .off
        llmMenu.addItem(llmToggleItem)

        llmMenu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(
            title: "Settings…",
            action: #selector(openSettings(_:)),
            keyEquivalent: ","
        )
        settingsItem.target = self
        llmMenu.addItem(settingsItem)

        let llmSubmenuItem = NSMenuItem(title: "LLM Refinement", action: nil, keyEquivalent: "")
        llmSubmenuItem.submenu = llmMenu
        menu.addItem(llmSubmenuItem)

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(
            title: "Quit Voice Input",
            action: #selector(quitApp(_:)),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    // MARK: - Actions

    @objc private func languageSelected(_ sender: NSMenuItem) {
        guard let language = sender.representedObject as? RecognitionLanguage else { return }

        settingsManager.selectedLanguage = language

        // Update checkmarks
        for item in languageMenuItems {
            item.state = (item.representedObject as? RecognitionLanguage == language) ? .on : .off
        }

        onLanguageChanged()
    }

    @objc private func toggleLLM(_ sender: NSMenuItem) {
        let newState = !settingsManager.isLLMEnabled
        settingsManager.isLLMEnabled = newState
        llmToggleItem.state = newState ? .on : .off
    }

    @objc private func openSettings(_ sender: NSMenuItem) {
        onOpenSettings()
    }

    @objc private func quitApp(_ sender: NSMenuItem) {
        NSApp.terminate(nil)
    }
}
