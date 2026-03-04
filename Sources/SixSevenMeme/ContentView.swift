import SwiftUI

struct ContentView: View {
    @StateObject private var manager = TranscriptionManager()
    @State private var showDebug = false

    var body: some View {
        ZStack {
            mainContent
            if manager.showMeme {
                MemeOverlayView(count: manager.memeCount)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: manager.showMeme)
        .task { await manager.setup() }
    }

    // MARK: - Layout

    private var mainContent: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if manager.isRecording {
                audioMeter
                Divider()
            }
            transcriptionArea
            if showDebug {
                Divider()
                debugPanel
            }
            Divider()
            controls
        }
        .background(Color(.windowBackgroundColor))
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            if !manager.isModelLoaded {
                ProgressView()
                    .controlSize(.small)
            } else {
                Circle()
                    .fill(statusColor)
                    .frame(width: 10, height: 10)
            }

            Text(manager.statusMessage)
                .font(.system(.body, design: .rounded, weight: .medium))
                .foregroundStyle(manager.isModelLoaded ? .secondary : .primary)

            Spacer()

            if manager.memeCount > 0 {
                Label("\(manager.memeCount)", systemImage: "flame.fill")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(.orange)
            }
        }
        .padding()
    }

    // MARK: - Audio meter

    private var audioMeter: some View {
        HStack(spacing: 8) {
            Image(systemName: "mic.fill")
                .foregroundStyle(.green)
                .font(.caption)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.green, .yellow, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, geo.size.width * CGFloat(manager.audioLevel)))
                        .animation(.linear(duration: 0.1), value: manager.audioLevel)
                }
            }
            .frame(height: 8)

            Text("\(manager.sampleCount)")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.tertiary)
                .frame(width: 70, alignment: .trailing)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.green.opacity(0.05))
    }

    // MARK: - Transcription

    private var transcriptionArea: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if manager.transcribedText.isEmpty {
                    emptyState
                } else {
                    Text(manager.transcribedText)
                        .font(.system(.title3, design: .rounded))
                        .foregroundStyle(.primary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
        }
        .frame(maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            if !manager.isModelLoaded {
                ProgressView()
                    .scaleEffect(1.5)
                    .padding(.bottom, 8)
                Text("Loading WhisperKit model...")
                    .font(.system(.title2, design: .rounded, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text("First run downloads the model.\nThis takes about a minute.")
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            } else if manager.isRecording {
                Image(systemName: "waveform")
                    .font(.system(size: 48))
                    .foregroundStyle(.green)
                    .symbolEffect(.variableColor.iterative, isActive: true)
                Text("Listening... say \"six seven\"")
                    .font(.system(.title2, design: .rounded, weight: .semibold))
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: "mic.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.tertiary)
                Text("Press Start to begin")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.tertiary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Debug

    private var debugPanel: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Debug Log")
                    .font(.system(.caption, design: .monospaced, weight: .bold))
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Hide") { showDebug = false }
                    .font(.caption)
                    .buttonStyle(.plain)
                    .foregroundStyle(.blue)
            }
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(manager.debugLog.enumerated()), id: \.offset) { i, line in
                            Text(line)
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .id(i)
                        }
                    }
                }
                .onChange(of: manager.debugLog.count) { _ in
                    if let last = manager.debugLog.indices.last {
                        proxy.scrollTo(last, anchor: .bottom)
                    }
                }
            }
        }
        .padding(8)
        .frame(height: 120)
        .background(Color(.textBackgroundColor).opacity(0.5))
    }

    // MARK: - Controls

    private var controls: some View {
        HStack(spacing: 12) {
            if manager.isRecording {
                Button(action: { manager.stopListening() }) {
                    Label("Stop", systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
                .tint(.red)
            } else {
                Button(action: { manager.startListening() }) {
                    Label("Start Listening", systemImage: "mic.fill")
                        .frame(maxWidth: .infinity)
                }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .disabled(!manager.isModelLoaded)
            }

            Button("Test Meme") {
                manager.memeCount += 1
                manager.showMeme = true
                Task {
                    try? await Task.sleep(nanoseconds: 5_000_000_000)
                    manager.showMeme = false
                }
            }
            .controlSize(.large)
            .buttonStyle(.bordered)

            Button(showDebug ? "Hide Log" : "Log") {
                showDebug.toggle()
            }
            .controlSize(.large)
            .buttonStyle(.bordered)
        }
        .padding()
    }

    private var statusColor: Color {
        if manager.isRecording { return .green }
        if manager.isModelLoaded { return .blue }
        return .orange
    }
}
