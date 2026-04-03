# Voice Input

[中文说明](README.zh-CN.md) · [License: MIT](LICENSE)

![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5-orange)
![License](https://img.shields.io/badge/license-MIT-green)

**Voice Input** is a lightweight macOS menu-bar dictation app built for fast, keyboard-first text entry.
Hold the **Fn** key to record, release to paste the recognized text into the currently focused input field.

It uses **Apple Speech Recognition** for live transcription and can optionally pass the result through an **OpenAI-compatible LLM** to fix obvious recognition mistakes in mixed Chinese-English text.

### Why this project

If you frequently type in chat boxes, terminals, documents, and issue trackers, switching between keyboard and traditional dictation workflows is often slower than it should be. Voice Input is designed to make dictation feel like a natural extension of typing:

- **Press and hold `Fn` to talk**
- **Release to paste** into the active app
- **Stay in the flow** with a menu-bar-only experience

### Highlights

- **Hold-to-talk with `Fn`**: global key monitoring with event suppression to avoid triggering the emoji picker
- **Streaming transcription**: live speech-to-text powered by Apple's `Speech` framework
- **Default Chinese-first experience**: starts with **Simplified Chinese** out of the box
- **Language switching**: English, Simplified Chinese, Traditional Chinese, Japanese, Korean
- **Elegant floating HUD**: a frameless capsule window with real-time waveform and transcript preview
- **Real audio waveform**: waveform reacts to live RMS audio levels instead of fake canned animation
- **Reliable text injection**: paste via clipboard + simulated `Cmd+V`
- **CJK IME handling**: temporarily switches to an ASCII input source before paste, then restores the original input method
- **Optional LLM refinement**: conservatively fixes obvious recognition errors without rewriting your text
- **Menu-bar only**: runs in `LSUIElement` mode with no Dock icon

### How it works

1. Hold the **Fn** key
2. Voice Input starts recording and shows the floating capsule HUD
3. Speech is transcribed in real time using Apple Speech Recognition
4. Release **Fn** to stop recording
5. If enabled, the transcript is optionally refined through an OpenAI-compatible LLM
6. The final text is pasted into the currently focused input field

### Tech stack

- **Swift**
- **AppKit**
- **AVFoundation**
- **Speech**
- **CoreGraphics / Carbon** for event tapping and input source handling
- **OpenAI-compatible Chat Completions API** for optional text refinement

### Requirements

- **macOS 14+**
- **Apple Silicon (`arm64`)**
- **Xcode Command Line Tools**

> The repository includes a `Package.swift`, but the recommended local workflow is the provided `Makefile`, which compiles the app with `swiftc` and bundles it as `Voice Input.app`.

### Quick start

```bash
# Clone
git clone https://github.com/xiangyingchang/voice-input.git
cd voice-input

# Build the app bundle
make build

# Run a debug build
make run

# Install to /Applications
make install
```

After `make build`, the app bundle is created at:

```bash
./Voice Input.app
```

Run it directly with:

```bash
open "Voice Input.app"
```

### Permissions

On first launch, macOS will require several permissions:

1. **Accessibility**  
   Required for global `Fn` key monitoring and simulated paste events.
2. **Microphone**  
   Required for recording audio.
3. **Speech Recognition**  
   Required for live transcription.

You can manage them in **System Settings → Privacy & Security**.

### LLM refinement

Voice Input works without any LLM configuration.
The LLM layer is **optional** and is only used as a conservative post-processor.

You can configure it from the menu bar:

- **LLM Refinement → Enable LLM Refinement**
- **LLM Refinement → Settings…**

Required fields:

- **API Base URL** — for example `https://api.openai.com`
- **API Key**
- **Model** — for example `gpt-4o-mini`

The app automatically calls the OpenAI-compatible **`/v1/chat/completions`** endpoint.

The system prompt is intentionally conservative:

- Fix obvious speech recognition mistakes only
- Correct common mixed-language technical terms such as `Python`, `JSON`, `API`, `Git`, `React`, `Node`
- Do **not** rewrite, polish, or shorten correct text

### Project structure

```text
Sources/VoiceInput/
├── App/              # Entry point, app lifecycle, shared types
├── Managers/         # Hotkey, status bar, speech, window, settings
├── Services/         # Text injection and LLM refinement
├── Views/            # Floating HUD and settings window
└── Resources/        # Info.plist and app metadata
```

### Build commands

```bash
make build    # Compile and bundle Voice Input.app
make run      # Build a debug binary and launch it
make install  # Install the app into /Applications
make clean    # Remove build artifacts and the generated .app bundle
make bundle   # Bundle an already-built release binary
```

### Notes and limitations

- The current build target is **`arm64-apple-macosx14.0`**.
- The app relies on **Apple's Speech Recognition service** for streaming transcription.
- LLM refinement is best used as a light correction layer, not as a rewriting assistant.
- Some apps with unusual input security policies may behave differently with simulated paste events.

### Contributing

Issues and pull requests are welcome.

If you want to contribute, useful areas include:

- Intel Mac support
- Better packaging and notarization workflow
- More robust accessibility diagnostics
- UI polish and onboarding improvements
- Automated tests for paste and input source switching behavior

### License

MIT — see [`LICENSE`](LICENSE).
