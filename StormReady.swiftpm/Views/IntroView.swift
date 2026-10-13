import SwiftUI

/// Scene 1 — the radio warning that sets the stakes (about 20 seconds).
struct IntroView: View {
    @EnvironmentObject private var game: GameState
    @State private var appeared = false
    @State private var typed = 0
    @State private var showRest = false
    @State private var strikes = 0

    private let headline = "A strong typhoon will reach your town tonight."

    var body: some View {
        ZStack {
            StormSky(intensity: 0.45).ignoresSafeArea()
            CloudLayer(count: 5, speed: 6, color: .black, opacity: 0.35, heightFraction: 0.5, scale: 1.6)
                .ignoresSafeArea()
            CloudLayer(count: 7, speed: 14, color: .white, opacity: 0.10, heightFraction: 0.45, scale: 1.1)
                .ignoresSafeArea()
            RainView(intensity: 0.35).ignoresSafeArea()
            LightningOverlay(strikes: strikes)

            VStack(spacing: 20) {
                Spacer()

                RadioBeacon()
                    .scaleEffect(appeared ? 1 : 0.6)
                    .opacity(appeared ? 1 : 0)

                Text("RADIO ALERT")
                    .font(.caption.monospaced().bold())
                    .foregroundStyle(Theme.warn)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Theme.warn.opacity(0.15), in: Capsule())

                // The untyped part is drawn invisible so the layout never jumps.
                (Text(String(headline.prefix(typed)))
                 + Text(String(headline.dropFirst(typed))).foregroundColor(.clear))
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                    .accessibilityLabel(headline)

                Text("You have a little time to get ready.\nEvery choice you make now will matter later.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .opacity(showRest ? 1 : 0)
                    .offset(y: showRest ? 0 : 12)

                Spacer()

                NextButton(title: "Get ready") {
                    Haptics.shared.tap()
                    game.go(.pack)
                }
                .padding(.bottom, 24)
                .opacity(showRest ? 1 : 0)
                .scaleEffect(showRest ? 1 : 0.9)
            }
            .padding()
            .frame(maxWidth: 640)
        }
        .task {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) { appeared = true }
            StormAudio.shared.play(volume: 0.2)
            Haptics.shared.rumble(duration: 0.8)

            try? await Task.sleep(nanoseconds: 700_000_000)
            for i in 0...headline.count {
                typed = i
                try? await Task.sleep(nanoseconds: 32_000_000)
            }
            withAnimation(.easeOut(duration: 0.7)) { showRest = true }
        }
        .task {
            // Distant lightning every few seconds while the player reads.
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(Double.random(in: 2.5...4.5) * 1_000_000_000))
                if Task.isCancelled { break }
                strikes += 1
                StormAudio.shared.thunder()
                Haptics.shared.rumble(duration: 0.8)
            }
        }
    }
}
