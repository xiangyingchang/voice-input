# Voice Input

A macOS menu-bar voice input app that lets you hold the **Fn key** to record speech and automatically inject the transcribed text into the currently focused input field.

## Features

- **Hold Fn to Record** — Press and hold the Fn key to start recording, release to inject text
- **Streaming Transcription** — Real-time speech-to-text using Apple's Speech Recognition framework
- **Multi-language Support** — Simplified Chinese (default), English, Traditional Chinese, Japanese, Korean
- **Elegant Floating Window** — Capsule-shaped HUD with real-time waveform animation and live transcription
- **Smart Text Injection** — Handles CJK input methods by temporarily switching to ASCII for paste
- **LLM Refinement** — Optional AI-powered post-processing to fix speech recognition errors (OpenAI-compatible API)
- **Menu Bar Only** — Runs as a lightweight menu bar app (no Dock icon)

## Requirements

- macOS 14.0 (Sonoma) or later
- Swift 5.9+
- Xcode Command Line Tools

## Permissions

On first launch, you'll need to grant:

1. **Accessibility** — Required for global Fn key monitoring (System Settings → Privacy & Security → Accessibility)
2. **Microphone** — Required for audio recording
3. **Speech Recognition** — Required for voice-to-text conversion

## Build & Run

```bash
# Build release .app bundle
make build

# Run in debug mode
make run

# Install to /Applications
make install

# Clean build artifacts
make clean
```

## LLM Configuration

1. Click the menu bar microphone icon
2. Navigate to **LLM Refinement → Settings…**
3. Enter your OpenAI-compatible API details:
   - **API Base URL**: e.g., `https://api.openai.com` (the `/v1/chat/completions` path is appended automatically)
   - **API Key**: Your API key
   - **Model**: e.g., `gpt-4o-mini`
4. Click **Test** to verify the connection
5. Click **Save**
6. Enable refinement via **LLM Refinement → Enable LLM Refinement**

## How It Works

1. Hold the **Fn** key — a floating capsule window appears with a waveform animation
2. Speak — you'll see real-time transcription in the capsule
3. Release the **Fn** key — the transcribed text is injected into the current input field
4. If LLM refinement is enabled, the text is first processed by the AI to fix recognition errors

## Architecture

```
Sources/VoiceInput/
├── App/              # Entry point, AppDelegate, type definitions
├── Managers/         # StatusBar, Hotkey, Speech, FloatingWindow, Settings
├── Services/         # TextInjector, LLMService
└── Views/            # FloatingPanel, WaveformView, CapsuleContentView, SettingsWindow
```

## License

MIT
