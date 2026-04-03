import AppKit
import Speech
import AVFoundation

class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusBarManager: StatusBarManager!
    private var hotkeyManager: HotkeyManager!
    private var speechManager: SpeechRecognitionManager!
    private var floatingWindowManager: FloatingWindowManager!
    private var textInjector: TextInjector!
    private var llmService: LLMService!
    private var settingsManager: SettingsManager!

    private var isRecording = false
    private var hasHandledCurrentRecordingResult = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        settingsManager = SettingsManager()
        llmService = LLMService(settingsManager: settingsManager)
        textInjector = TextInjector()
        floatingWindowManager = FloatingWindowManager()
        speechManager = SpeechRecognitionManager(settingsManager: settingsManager)
        speechManager.delegate = self

        statusBarManager = StatusBarManager(
            settingsManager: settingsManager,
            onLanguageChanged: { [weak self] in
                self?.speechManager.updateLanguage()
            },
            onOpenSettings: { [weak self] in
                self?.openSettingsWindow()
            }
        )

        hotkeyManager = HotkeyManager(
            onFnDown: { [weak self] in self?.startRecording() },
            onFnUp: { [weak self] in self?.stopRecording() }
        )

        requestPermissions()
        hotkeyManager.start()
    }

    // MARK: - Recording Control

    private func startRecording() {
        guard !isRecording else { return }
        isRecording = true
        hasHandledCurrentRecordingResult = false

        DispatchQueue.main.async { [weak self] in
            self?.floatingWindowManager.show()
            self?.speechManager.startRecognition()
        }
    }

    private func stopRecording() {
        guard isRecording else { return }
        isRecording = false

        DispatchQueue.main.async { [weak self] in
            self?.speechManager.stopRecognition()
        }
    }

    private func handleFinalText(_ text: String) {
        guard !hasHandledCurrentRecordingResult else { return }
        hasHandledCurrentRecordingResult = true

        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            floatingWindowManager.hide()
            return
        }

        let llmConfig = settingsManager.llmConfiguration
        if llmConfig.isEnabled && !llmConfig.apiKey.isEmpty && !llmConfig.apiBaseURL.isEmpty {
            floatingWindowManager.showRefining()
            llmService.refine(text: text) { [weak self] result in
                DispatchQueue.main.async {
                    let finalText = result ?? text
                    self?.floatingWindowManager.hide()
                    self?.textInjector.inject(text: finalText)
                }
            }
        } else {
            floatingWindowManager.hide()
            textInjector.inject(text: text)
        }
    }

    // MARK: - Settings

    private var settingsWindowController: SettingsWindowController?

    private func openSettingsWindow() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController(
                settingsManager: settingsManager,
                llmService: llmService
            )
        }
        settingsWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Permissions

    private func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { status in
            if status != .authorized {
                print("Speech recognition not authorized: \(status.rawValue)")
            }
        }

        AVAudioApplication.requestRecordPermission { granted in
            if !granted {
                print("Microphone access not granted")
            }
        }
    }
}

// MARK: - SpeechRecognitionDelegate

extension AppDelegate: SpeechRecognitionDelegate {
    func speechRecognition(didUpdateRMSLevel level: Float) {
        floatingWindowManager.updateRMS(level: level)
    }

    func speechRecognition(didUpdatePartialResult text: String) {
        floatingWindowManager.updateText(text)
    }

    func speechRecognition(didFinishWithResult text: String) {
        handleFinalText(text)
    }

    func speechRecognition(didFailWithError error: Error) {
        hasHandledCurrentRecordingResult = true
        print("Speech recognition error: \(error.localizedDescription)")
        floatingWindowManager.hide()
    }
}
