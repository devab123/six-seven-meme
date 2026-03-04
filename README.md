# Six Seven Meme Detector

A macOS demo app exploring [WhisperKit](https://github.com/argmaxinc/WhisperKit) real-time streaming transcription. The app listens to your microphone, transcribes speech on-device using Whisper, and triggers a meme overlay when it detects the phrase **"six seven"**.

Built to learn the WhisperKit streaming API and test keyword detection with on-device speech recognition.

## What it does

1. Downloads and loads a Whisper model on first launch (cached locally after that)
2. Captures live microphone audio using WhisperKit's `AudioProcessor`
3. Transcribes audio in a sliding window every ~2 seconds
4. Checks the transcription for "six seven" and shows an animated overlay when detected
5. Displays a real-time audio level meter and live transcription text

## What I learned

- **Model size matters for short phrases.** The `tiny` model frequently misheard "six seven" as "sixty-seven" or ignored it entirely. Switching to `base` improved accuracy noticeably, though it's still not perfect for keyword spotting.
- **Sliding window + purge pattern works well.** Using `purgeAudioSamples(keepingLast:)` to keep 5 seconds of trailing context between transcription windows avoids unbounded memory growth while giving the model overlap for continuity.
- **`DecodingOptions` help.** Setting `language: "en"` and `temperature: 0` (greedy decoding) gives more consistent results than letting the model auto-detect language each window.

## Open questions

- Is there a recommended approach for **keyword/phrase spotting** with WhisperKit, vs. full transcription? Seems like the model isn't optimized for short trigger phrases.
- Would a **larger model** (`small` or `distil-large-v3`) significantly improve short-phrase detection, or is there a better architecture for this use case?
- Is there a way to use WhisperKit's **VAD (voice activity detection)** to only transcribe when speech is detected, rather than on a fixed timer?

## Running it

### Requirements

- macOS 14.0+
- Xcode 16.0+

### Steps

1. Open the project in Xcode:
   ```bash
   open Package.swift
   ```
2. Select **My Mac** as the run destination
3. Press **Cmd + R**
4. Grant microphone access when prompted
5. Click **Start Listening** and say "six seven"

> First launch downloads the Whisper `base` model (~140 MB). Subsequent launches use the cached version.

### Tip

Click **Test Meme** to preview the overlay animation without needing to speak.

## Project structure

```
Sources/SixSevenMeme/
├── SixSevenMemeApp.swift          # App entry point
├── ContentView.swift              # Main UI: status, transcript, audio meter, controls
├── TranscriptionManager.swift     # WhisperKit streaming + phrase detection
└── MemeOverlayView.swift          # Animated meme overlay
```

## Built with

- [WhisperKit](https://github.com/argmaxinc/WhisperKit) — on-device speech recognition for Apple Silicon
- SwiftUI — macOS app UI
- CoreML — model inference (via WhisperKit)
