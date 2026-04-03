import AppKit
import Carbon

/// Handles text injection via clipboard + simulated Cmd+V, with CJK input method handling
class TextInjector {

    // MARK: - Public

    func inject(text: String) {
        guard !text.isEmpty else { return }

        // 1. Save current clipboard contents
        let savedClipboard = saveClipboard()

        // 2. Detect current input source
        let originalInputSource = getCurrentInputSource()
        let isCJK = isCJKInputSource(originalInputSource)

        // 3. If CJK, switch to ASCII input source
        if isCJK {
            switchToASCIIInputSource()
            // Small delay to let the input source switch take effect
            usleep(50_000) // 50ms
        }

        // 4. Write text to clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        // 5. Simulate Cmd+V
        simulatePaste()

        // 6. Restore original input source (after paste completes)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            if isCJK, let source = originalInputSource {
                self.selectInputSource(source)
            }
        }

        // 7. Restore original clipboard contents (after paste completes)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.restoreClipboard(savedClipboard)
        }
    }

    // MARK: - Clipboard Save/Restore

    private struct ClipboardItem {
        let types: [NSPasteboard.PasteboardType]
        let data: [NSPasteboard.PasteboardType: Data]
    }

    private func saveClipboard() -> ClipboardItem? {
        let pasteboard = NSPasteboard.general
        guard let types = pasteboard.types else { return nil }

        var data: [NSPasteboard.PasteboardType: Data] = [:]
        for type in types {
            if let d = pasteboard.data(forType: type) {
                data[type] = d
            }
        }

        return ClipboardItem(types: Array(types), data: data)
    }

    private func restoreClipboard(_ item: ClipboardItem?) {
        guard let item = item else { return }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        for type in item.types {
            if let data = item.data[type] {
                pasteboard.setData(data, forType: type)
            }
        }
    }

    // MARK: - Input Source Detection

    private func getCurrentInputSource() -> TISInputSource? {
        return TISCopyCurrentKeyboardInputSource()?.takeRetainedValue()
    }

    private func isCJKInputSource(_ source: TISInputSource?) -> Bool {
        guard let source = source else { return false }

        // Get the input source ID
        guard let idPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else {
            return false
        }
        let sourceID = Unmanaged<CFString>.fromOpaque(idPtr).takeUnretainedValue() as String

        // Known CJK input method patterns
        let cjkPatterns = [
            "SCIM",        // Simplified Chinese Input Method
            "TCIM",        // Traditional Chinese Input Method
            "Pinyin",      // Various Pinyin methods
            "Wubi",        // Wubi
            "Cangjie",     // Cangjie
            "Zhuyin",      // Zhuyin/Bopomofo
            "Japanese",    // Japanese
            "Korean",      // Korean
            "Kotoeri",     // macOS Japanese
            "Hangul",      // Korean Hangul
            "InputMethod", // Generic input method indicator
        ]

        for pattern in cjkPatterns {
            if sourceID.contains(pattern) {
                return true
            }
        }

        // Also check input source type — keyboard input modes are typically CJK
        if let typePtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceType) {
            let sourceType = Unmanaged<CFString>.fromOpaque(typePtr).takeUnretainedValue() as String
            if sourceType == kTISTypeKeyboardInputMode as String {
                return true
            }
        }

        return false
    }

    // MARK: - Input Source Switching

    private func switchToASCIIInputSource() {
        // Try to find ABC or US keyboard layout
        let asciiIDs = [
            "com.apple.keylayout.ABC",
            "com.apple.keylayout.US",
            "com.apple.keylayout.USInternational-PC",
        ]

        let properties = [
            kTISPropertyInputSourceCategory: kTISCategoryKeyboardInputSource,
        ] as CFDictionary

        guard let sources = TISCreateInputSourceList(properties, false)?.takeRetainedValue() as? [TISInputSource] else {
            return
        }

        for source in sources {
            guard let idPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else { continue }
            let sourceID = Unmanaged<CFString>.fromOpaque(idPtr).takeUnretainedValue() as String

            if asciiIDs.contains(sourceID) {
                TISSelectInputSource(source)
                return
            }
        }

        // Fallback: select first ASCII-capable keyboard
        for source in sources {
            guard let idPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else { continue }
            let sourceID = Unmanaged<CFString>.fromOpaque(idPtr).takeUnretainedValue() as String

            if sourceID.contains("keylayout") && !isCJKInputSource(source) {
                TISSelectInputSource(source)
                return
            }
        }
    }

    private func selectInputSource(_ source: TISInputSource) {
        TISSelectInputSource(source)
    }

    // MARK: - Simulate Paste (Cmd+V)

    private func simulatePaste() {
        let vKeyCode: CGKeyCode = 9 // 'V' key

        // Key down
        if let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: vKeyCode, keyDown: true) {
            keyDown.flags = .maskCommand
            keyDown.post(tap: .cghidEventTap)
        }

        // Key up
        if let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: vKeyCode, keyDown: false) {
            keyUp.flags = .maskCommand
            keyUp.post(tap: .cghidEventTap)
        }
    }
}
