import SwiftUI

/// Scene 4 — the storm arrives and earlier choices play out (about 40 seconds).
struct StormView: View {
    @EnvironmentObject private var game: GameState
    @State private var index = -1        // -1 while the storm is still building
    @State private var strikes = 0
    @State private var shakes: CGFloat = 0

    private let events = StormEvent.all

    var body: some View {
        ZStack {
            StormSky(intensity: 1).ignoresSafeArea()
            CloudLayer(count: 6, speed: 40, color: .black, opacity: 0.45, heightFraction: 0.45, scale: 1.8)
                .ignoresSafeArea()
            CloudLayer(count: 8, speed: 70, color: .white, opacity: 0.06, heightFraction: 0.5, scale: 1.2)
                .ignoresSafeArea()
            LightningOverlay(strikes: strikes)
            RainView(intensity: index < 0 ? 0.7 : 1.0, splashes: true).ignoresSafeArea()
            WindDebris(count: index < 0 ? 8 : 16, strength: index < 0 ? 0.7 : 1.2).ignoresSafeArea()

            VStack(spacing: 20) {
                SceneHeader(step: 3, title: "The storm hits",
                            subtitle: "Night falls. The wind howls.")

                Spacer()

                if index < 0 {
                    VStack(spacing: 14) {
                        Image(systemName: "hurricane")
                            .font(.system(size: 72))
                            .symbolEffect(.pulse)
                        Text("The typhoon is here…")
                            .font(.title2.bold())
                    }
                    .transition(.opacity)
                } else {
                    let event = events[index]
                    EventCard(event: event, passed: event.check(game))
                        .id(event.id)
                        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                                removal: .move(edge: .leading).combined(with: .opacity)))
                }

                Spacer()

                if index >= 0 {
                    Text("\(index + 1) of \(events.count)")
                        .font(.footnote.monospacedDigit())
                        .foregroundStyle(.secondary)
                    NextButton(title: index < events.count - 1 ? "Next" : "Morning comes",
                               symbol: index < events.count - 1 ? "arrow.right" : "sun.horizon.fill") {
                        advance()
                    }
                    .padding(.bottom)
                }
            }
            .frame(maxWidth: 640)
            .modifier(Shake(animatableData: shakes))
        }
        .onAppear {
            StormAudio.shared.play(volume: 0.7)
            StormAudio.shared.thunder()
            Haptics.shared.rumble(duration: 2.0)
            strikes += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                if index < 0 { advance() }
            }
        }
    }

    private func advance() {
        guard index < events.count - 1 else {
            StormAudio.shared.fadeOut()
            game.go(.plan)
            return
        }

        strike()
        withAnimation(.easeInOut(duration: 0.45)) { index += 1 }

        let passed = events[index].check(game)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if passed { Haptics.shared.success() } else { Haptics.shared.warning() }
        }
    }

    /// Lightning: a bolt you see, a shake, a rumble you hear and a rumble you feel.
    private func strike() {
        strikes += 1
        withAnimation(.linear(duration: 0.45)) { shakes += 1 }
        StormAudio.shared.thunder()
        Haptics.shared.rumble(duration: 1.0)
    }
}

private struct EventCard: View {
    let event: StormEvent
    let passed: Bool

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: event.symbol)
                .font(.system(size: 48))
                .foregroundStyle(.white)
            Text(event.headline)
                .font(.title.bold())
                .multilineTextAlignment(.center)

            Label(passed ? event.goodOutcome : event.badOutcome,
                  systemImage: passed ? "checkmark.shield.fill" : "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundStyle(passed ? Theme.accent : Theme.warn)
                .multilineTextAlignment(.leading)
                .padding()
                .frame(maxWidth: .infinity)
                .background((passed ? Theme.accent : Theme.warn).opacity(0.15),
                            in: RoundedRectangle(cornerRadius: 16))
        }
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28))
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
    }
}
