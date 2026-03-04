import SwiftUI

struct MemeOverlayView: View {
    let count: Int
    @State private var phase = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text("HOLD UP...")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
                    .opacity(phase >= 1 ? 1 : 0)

                Text("DID YOU JUST SAY")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                    .opacity(phase >= 2 ? 1 : 0)

                HStack(spacing: 20) {
                    ratingBadge("6", color: .orange)
                    ratingBadge("7", color: .pink)
                }
                .scaleEffect(phase >= 3 ? 1.0 : 0.3)
                .opacity(phase >= 3 ? 1 : 0)

                Text("💀💀💀")
                    .font(.system(size: 60))
                    .opacity(phase >= 4 ? 1 : 0)

                Text("bro really said six seven 💀")
                    .font(.system(size: 20, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )
                    .opacity(phase >= 5 ? 1 : 0)

                if count > 1 {
                    Text("detected \(count) times")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                        .padding(.top, 8)
                }
            }
        }
        .animation(.easeOut(duration: 0.4), value: phase)
        .task {
            for step in 1...5 {
                try? await Task.sleep(nanoseconds: 300_000_000)
                phase = step
            }
        }
    }

    private func ratingBadge(_ number: String, color: Color) -> some View {
        Text(number)
            .font(.system(size: 120, weight: .black, design: .rounded))
            .foregroundStyle(
                LinearGradient(
                    colors: [color, color.opacity(0.6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .shadow(color: color.opacity(0.6), radius: 20)
    }
}
