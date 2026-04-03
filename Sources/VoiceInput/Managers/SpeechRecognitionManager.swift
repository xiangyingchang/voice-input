import AVFoundation
import Speech

/// Manages AVAudioEngine + SFSpeechRecognizer for streaming recognition and RMS levels
class SpeechRecognitionManager {

    weak var delegate: SpeechRecognitionDelegate?

    private let settingsManager: SettingsManager
    private let audioEngine: AVAudioEngine
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    private var lastPartialResult: String = ""
    private var isStopping = false
    private var hasCompletedRecognition = false
    private var isInputTapInstalled = false
    private var finalizeWorkItem: DispatchWorkItem?

    init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
        self.audioEngine = AVAudioEngine()
        updateRecognizer()
    }

    // MARK: - Language

    func updateLanguage() {
        updateRecognizer()
    }

    private func updateRecognizer() {
        let locale = Locale(identifier: settingsManager.selectedLanguage.localeIdentifier)
        speechRecognizer = SFSpeechRecognizer(locale: locale)
    }

    // MARK: - Start Recognition

    func startRecognition() {
        finalizeWorkItem?.cancel()
        finalizeWorkItem = nil
        cleanupRecognitionTask()

        if audioEngine.isRunning {
            audioEngine.stop()
        }
        removeInputTapIfNeeded()

        updateRecognizer()

        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            print("Speech recognizer not available for language: \(settingsManager.selectedLanguage.rawValue)")
            delegate?.speechRecognition(didFailWithError: NSError(
                domain: "SpeechRecognition",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Speech recognizer not available"]
            ))
            return
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true

        // On-device recognition when available (macOS 14+)
        if #available(macOS 14, *) {
            request.requiresOnDeviceRecognition = false // Allow cloud for better accuracy
        }

        recognitionRequest = request
        lastPartialResult = ""
        isStopping = false
        hasCompletedRecognition = false

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                let text = result.bestTranscription.formattedString
                self.lastPartialResult = text

                if result.isFinal {
                    DispatchQueue.main.async {
                        guard self.isStopping else { return }
                        self.finishRecognitionIfNeeded(with: text)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.delegate?.speechRecognition(didUpdatePartialResult: text)
                    }
                }
            }

            if let error = error {
                // NSError code 216 = "Recognition was cancelled" — ignore it
                let nsError = error as NSError
                if nsError.code == 216 || nsError.code == 209 { return }

                DispatchQueue.main.async {
                    guard !self.hasCompletedRecognition else { return }
                    self.cleanupRecognitionTask()
                    self.delegate?.speechRecognition(didFailWithError: error)
                }
            }
        }

        // Configure audio engine
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            guard let self = self else { return }

            // Send audio to speech recognizer
            self.recognitionRequest?.append(buffer)

            // Calculate RMS level
            let rms = self.calculateRMS(buffer: buffer)
            DispatchQueue.main.async {
                self.delegate?.speechRecognition(didUpdateRMSLevel: rms)
            }
        }
        isInputTapInstalled = true

        do {
            audioEngine.prepare()
            try audioEngine.start()
        } catch {
            print("Audio engine failed to start: \(error)")
            cleanupRecognitionTask()
            removeInputTapIfNeeded()
            delegate?.speechRecognition(didFailWithError: error)
        }
    }

    // MARK: - Stop Recognition

    func stopRecognition() {
        isStopping = true

        if audioEngine.isRunning {
            audioEngine.stop()
        }
        removeInputTapIfNeeded()
        recognitionRequest?.endAudio()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.finishRecognitionIfNeeded(with: self.lastPartialResult)
        }

        finalizeWorkItem?.cancel()
        finalizeWorkItem = workItem

        let delay: TimeInterval = lastPartialResult.isEmpty ? 0.35 : 0.8
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    // MARK: - Finalization

    private func finishRecognitionIfNeeded(with text: String) {
        guard !hasCompletedRecognition else { return }

        hasCompletedRecognition = true
        finalizeWorkItem?.cancel()
        finalizeWorkItem = nil
        cleanupRecognitionTask()

        delegate?.speechRecognition(didFinishWithResult: text)
    }

    private func cleanupRecognitionTask() {
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
    }

    private func removeInputTapIfNeeded() {
        guard isInputTapInstalled else { return }
        audioEngine.inputNode.removeTap(onBus: 0)
        isInputTapInstalled = false
    }

    // MARK: - RMS Calculation

    private func calculateRMS(buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else { return 0 }

        let channelCount = Int(buffer.format.channelCount)
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return 0 }

        var sum: Float = 0
        for frame in 0..<frameLength {
            for channel in 0..<channelCount {
                let sample = channelData[channel][frame]
                sum += sample * sample
            }
        }

        let rms = sqrt(sum / Float(frameLength * channelCount))

        // Normalize to 0-1 range (typical speech RMS is 0.01 to 0.3)
        let normalized = min(1.0, max(0.0, rms / 0.15))
        return normalized
    }
}
