import SwiftUI

/// Scene 3 — find and fix hazards around the house (about 40 seconds).
struct SecureView: View {
    @EnvironmentObject private var game: GameState
    @State private var message = "Tap each warning sign to make your home safer."

    var body: some View {
        ZStack {
            StormSky(intensity: 0.55).ignoresSafeArea()
            CloudLayer(count: 6, speed: 18, color: .black, opacity: 0.3, heightFraction: 0.3, scale: 1.4)
                .ignoresSafeArea()
            content
        }
        .onAppear { StormAudio.shared.play(volume: 0.3) }
    }

    private var content: some View {
        VStack(spacing: 12) {
            SceneHeader(step: 2, title: "Secure the home",
                        subtitle: "The wind is picking up. Fix what you can.")

            GeometryReader { geo in
                ZStack {
                    RoomArt()
                    ForEach(Hazard.all) { hazard in
                        HazardMarker(hazard: hazard, fixed: game.isFixed(hazard.id)) {
                            fix(hazard)
                        }
                        .position(x: geo.size.width * hazard.x, y: geo.size.height * hazard.y)
                    }
                }
            }
            .aspectRatio(4 / 3, contentMode: .fit)
            .frame(maxWidth: 720)
            .padding(.horizontal)

            Text(message)
                .font(.callout)
                .multilineTextAlignment(.center)
                .frame(minHeight: 44)
                .padding(.horizontal)
                .animation(.default, value: message)

            Text("\(game.fixed.count) of \(Hazard.all.count) fixed")
                .font(.footnote.monospacedDigit())
                .foregroundStyle(.secondary)

            Spacer(minLength: 0)

            NextButton(title: "Wait out the storm", symbol: "cloud.bolt.rain.fill") {
                Haptics.shared.tap()
                game.go(.storm)
            }
            .padding(.bottom)
        }
    }

    private func fix(_ hazard: Hazard) {
        guard !game.isFixed(hazard.id) else {
            message = hazard.tip
            return
        }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { game.fix(hazard.id) }
        message = "\(hazard.fixedLabel). \(hazard.tip)"
        Haptics.shared.success()
    }
}

private struct HazardMarker: View {
    let hazard: Hazard
    let fixed: Bool
    let action: () -> Void
    @State private var pulse = false
    @State private var burst = false

    var body: some View {
        Button(action: action) {
            ZStack {
                // A ring that bursts outward the moment the hazard is fixed.
                Circle()
                    .stroke(Theme.accent, lineWidth: 3)
                    .frame(width: 48, height: 48)
                    .scaleEffect(burst ? 2.4 : 1)
                    .opacity(fixed && !burst ? 0.9 : 0)
                Circle()
                    .fill(fixed ? Theme.accent : Theme.warn)
                    .frame(width: 48, height: 48)
                    .shadow(color: (fixed ? Theme.accent : Theme.warn).opacity(0.6), radius: pulse && !fixed ? 14 : 4)
                Image(systemName: fixed ? "checkmark" : hazard.symbol)
                    .font(.title3.bold())
                    .foregroundStyle(Theme.night)
                    .symbolEffect(.bounce, value: fixed)
            }
            .scaleEffect(pulse && !fixed ? 1.1 : 1)
        }
        .onChange(of: fixed) { _, isFixed in
            guard isFixed else { return }
            burst = false
            withAnimation(.easeOut(duration: 0.6)) { burst = true }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(fixed ? "\(hazard.name), \(hazard.fixedLabel)" : hazard.name)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { pulse = true }
        }
    }
}

/// A simple living room drawn entirely with SwiftUI shapes.
private struct RoomArt: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack(alignment: .topLeading) {
                // Wall and floor
                Rectangle().fill(Color(red: 0.22, green: 0.26, blue: 0.36))
                Rectangle()
                    .fill(Color(red: 0.30, green: 0.24, blue: 0.20))
                    .frame(height: h * 0.28)
                    .offset(y: h * 0.72)

                // Window with the storm outside
                ZStack {
                    StormSky(intensity: 0.7)
                    CloudLayer(count: 4, speed: 30, color: .white, opacity: 0.18, heightFraction: 0.5, scale: 0.5)
                    SwayingTree(strength: 1)
                    RainView(intensity: 0.5)
                    Rectangle().fill(Color.white.opacity(0.25)).frame(width: 3)
                    Rectangle().fill(Color.white.opacity(0.25)).frame(height: 3)
                }
                .frame(width: w * 0.30, height: h * 0.34)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.35), lineWidth: 4))
                .offset(x: w * 0.07, y: h * 0.13)

                // Breaker panel
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(red: 0.45, green: 0.47, blue: 0.52))
                    .frame(width: w * 0.08, height: h * 0.14)
                    .offset(x: w * 0.82, y: h * 0.19)

                // Door
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(red: 0.38, green: 0.28, blue: 0.22))
                    .frame(width: w * 0.16, height: h * 0.50)
                    .offset(x: w * 0.60, y: h * 0.22)

                // Table
                Rectangle()
                    .fill(Color(red: 0.50, green: 0.38, blue: 0.28))
                    .frame(width: w * 0.24, height: h * 0.04)
                    .offset(x: w * 0.40, y: h * 0.64)
                Rectangle()
                    .fill(Color(red: 0.42, green: 0.32, blue: 0.24))
                    .frame(width: w * 0.02, height: h * 0.12)
                    .offset(x: w * 0.42, y: h * 0.68)
                Rectangle()
                    .fill(Color(red: 0.42, green: 0.32, blue: 0.24))
                    .frame(width: w * 0.02, height: h * 0.12)
                    .offset(x: w * 0.60, y: h * 0.68)

                // Kitchen counter
                Rectangle()
                    .fill(Color(red: 0.55, green: 0.57, blue: 0.62))
                    .frame(width: w * 0.20, height: h * 0.18)
                    .offset(x: w * 0.78, y: h * 0.62)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .accessibilityHidden(true)
    }
}
