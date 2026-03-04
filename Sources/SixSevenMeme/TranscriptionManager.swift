import AVFoundation
import SwiftUI
import WhisperKit

@MainActor
class TranscriptionManager: ObservableObject {
    @Published var isModelLoaded = false
    @Published var isRecording = false
    @Published var transcribedText = ""
    @Published var showMeme = false
    @Published var statusMessage = "Initializing..."
    @Published var memeCount = 0
    @Published var audioLevel: Float = 0
    @Published var sampleCount = 0
    @Published var debugLog: [String] = []

    private var whisperKit: WhisperKit?
    private var transcriptionTask: Task<Void, Never>?
    private var levelMonitorTask: Task<Void, Never>?
    private let sampleRate = WhisperKit.sampleRate

    // Using "base" for a better accuracy/speed tradeoff on macOS.
    // "tiny" is faster but struggles with short phrases like "six seven".
    // On-device, "base" runs well on any Apple Silicon Mac.
    private let modelName = "base"

    private func log(_ message: String) {
        print("[SixSeven] \(message)")
        debugLog.append(message)
        if debugLog.count > 80 { debugLog.removeFirst() }
    }

    // MARK: - Setup

    func setup() async {
        log("Requesting microphone permission...")
        let granted = await AVAudioApplication.requestRecordPermission()
        guard granted else {
            log("Microphone permission DENIED")
            statusMessage = "Microphone access denied — check System Settings"
            return
        }
        log("Microphone permission granted")

        statusMessage = "Downloading \(modelName) model (first run only)..."
        log("Initializing WhisperKit with model: \(modelName)")
        do {
            let config = WhisperKitConfig(model: modelName, verbose: true)
            whisperKit = try await WhisperKit(config)
            isModelLoaded = true
            statusMessage = "Ready — click Start Listening"
            log("Model loaded: \(modelName)")
        } catch {
            statusMessage = "Failed to load model: \(error.localizedDescription)"
            log("Model load failed: \(error)")
        }
    }

    // MARK: - Recording

    func startListening() {
        guard let whisperKit else { return }

        isRecording = true
        transcribedText = ""
        statusMessage = "Listening..."

        startLevelMonitor()

        transcriptionTask = Task {
            do {
                try whisperKit.audioProcessor.startRecordingLive(callback: nil)
                log("Microphone recording started")

                while !Task.isCancelled {
                    try await Task.sleep(nanoseconds: 2_000_000_000)

                    let samples = Array(whisperKit.audioProcessor.audioSamples)
                    sampleCount = samples.count

                    guard samples.count > sampleRate else { continue }

                    let maxSamples = sampleRate * 30
                    let buffer = samples.count > maxSamples
                        ? Array(samples.suffix(maxSamples))
                        : samples

                    // English language hint improves accuracy for known-language audio
                    let options = DecodingOptions(
                        language: "en",
                        temperature: 0,
                        usePrefillPrompt: true
                    )

                    let results = await whisperKit.transcribe(
                        audioArrays: [buffer],
                        decodeOptions: options
                    )

                    if let segmentResults = results.first,
                       let segments = segmentResults {
                        let text = segments.map(\.text).joined(separator: " ")
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        transcribedText = text
                        log("Transcribed: \"\(text)\"")
                        checkForTrigger(text)
                    }

                    // Keep 5s of trailing context so the model has overlap between windows
                    whisperKit.audioProcessor.purgeAudioSamples(keepingLast: sampleRate * 5)
                }
            } catch {
                statusMessage = "Error: \(error.localizedDescription)"
                log("Recording error: \(error)")
                isRecording = false
            }
        }
    }

    func stopListening() {
        transcriptionTask?.cancel()
        levelMonitorTask?.cancel()
        whisperKit?.audioProcessor.stopRecording()
        isRecording = false
        audioLevel = 0
        statusMessage = "Stopped"
        log("Recording stopped")
    }

    // MARK: - Audio level monitoring

    private func startLevelMonitor() {
        levelMonitorTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 100_000_000)
                guard let whisperKit else { continue }
                audioLevel = whisperKit.audioProcessor.relativeEnergy.last ?? 0
            }
        }
    }

    // MARK: - Phrase detection

    private func checkForTrigger(_ text: String) {
        let lower = text.lowercased()

        // Match common transcription variants of "six seven"
        let triggers = ["six seven", "six, seven", "6 7", "six-seven", "6-7"]

        guard triggers.contains(where: { lower.contains($0) }) else { return }
        guard !showMeme else { return }

        log("Detected 'six seven'!")
        memeCount += 1
        showMeme = true

        Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            showMeme = false
        }
    }
}
