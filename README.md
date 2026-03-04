# Six Seven Meme Detector

A macOS demo app using [WhisperKit](https://github.com/argmaxinc/WhisperKit) for real-time speech recognition. Listens to your microphone, transcribes on-device, and shows a meme overlay when it detects the phrase **"six seven"**.

## Running it

- macOS 14.0+
- Xcode 16.0+

```bash
open Package.swift
```

Select **My Mac**, press **Cmd + R**. Grant microphone access when prompted.

First launch downloads the Whisper `base` model (~140 MB).

## Project structure

```
Sources/SixSevenMeme/
├── SixSevenMemeApp.swift          # App entry point
├── ContentView.swift              # UI: status, transcript, audio meter, controls
├── TranscriptionManager.swift     # WhisperKit streaming + phrase detection
└── MemeOverlayView.swift          # Animated meme overlay
```
