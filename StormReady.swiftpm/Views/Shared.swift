import SwiftUI

/// Procedurally drawn rain. Every streak is generated in code, no image assets.
struct RainView: View {
    var intensity: Double  // 0...1
    /// Small splashes where drops hit the ground.
    var splashes = false

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let drops = Int(180 * intensity)
                let slant = 3 + 10 * intensity

                for i in 0..<drops {
                    let n = Double(i)
                    // Nearer drops are longer, faster and brighter: a cheap depth effect.
                    let depth = 0.4 + fract(sin(n * 5.13) * 3141.59) * 0.6
                    let x = fract(sin(n * 12.9898) * 43758.5453) * (size.width + 80) - 20
                    let speed = (450 + fract(sin(n * 78.233) * 12345.678) * 450) * depth
                    let offset = fract(sin(n * 3.17) * 9876.54) * size.height
                    let y = (time * speed + offset).truncatingRemainder(dividingBy: size.height + 40) - 20
                    let length = (10 + 16 * intensity) * depth

                    var streak = Path()
                    streak.move(to: CGPoint(x: x, y: y))
                    streak.addLine(to: CGPoint(x: x - slant * depth, y: y + length))
                    context.stroke(streak,
                                   with: .color(.white.opacity((0.12 + 0.22 * intensity) * depth)),
                                   lineWidth: 0.8 + depth)
                }

                guard splashes else { return }
                for i in 0..<Int(40 * intensity) {
                    let n = Double(i) + 500
                    let phase = fract(time * 2.2 + fract(sin(n) * 999.0))
                    let x = fract(sin(n * 7.7) * 4321.0) * size.width
                    let y = size.height - 8 - fract(sin(n * 2.3) * 777.0) * 40
                    let radius = 2 + phase * 9
                    let ring = Path(ellipseIn: CGRect(x: x - radius, y: y - radius * 0.3,
                                                      width: radius * 2, height: radius * 0.6))
                    context.stroke(ring, with: .color(.white.opacity(0.35 * (1 - phase))), lineWidth: 1)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func fract(_ value: Double) -> Double { value - floor(value) }
}

/// Step indicator and title shown at the top of each playable scene.
struct SceneHeader: View {
    let step: Int
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                ForEach(1...4, id: \.self) { i in
                    Capsule()
                        .fill(i <= step ? Theme.accent : Color.white.opacity(0.2))
                        .frame(width: i == step ? 28 : 12, height: 6)
                }
            }
            .accessibilityLabel("Step \(step) of 4")

            Text(title)
                .font(.title.bold())
            Text(subtitle)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal)
        .padding(.top, 12)
    }
}

/// Large, friendly primary button used to move between scenes.
struct NextButton: View {
    let title: String
    var symbol: String = "arrow.right"
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.headline)
                .frame(maxWidth: 360)
                .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .tint(Theme.accent)
        .foregroundStyle(Theme.night)
        .controlSize(.large)
        .padding(.horizontal)
    }
}
