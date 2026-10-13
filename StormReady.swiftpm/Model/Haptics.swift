import CoreHaptics
import UIKit

/// Thunder you can feel. Falls back silently on devices without haptics (like most iPads).
final class Haptics {
    static let shared = Haptics()

    /// Set to false to turn off all vibration (useful for debugging).
    static var isEnabled = true

    private var engine: CHHapticEngine?

    private init() {
        guard Self.isEnabled, CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        engine = try? CHHapticEngine()
        engine?.resetHandler = { [weak self] in try? self?.engine?.start() }
        try? engine?.start()
    }

    /// A rolling rumble that swells and fades, like distant thunder.
    func rumble(duration: Double = 1.2) {
        guard let engine else { return }
        let event = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.15)
            ],
            relativeTime: 0,
            duration: duration
        )
        let swell = CHHapticParameterCurve(
            parameterID: .hapticIntensityControl,
            controlPoints: [
                .init(relativeTime: 0, value: 0.2),
                .init(relativeTime: duration * 0.25, value: 1.0),
                .init(relativeTime: duration, value: 0)
            ],
            relativeTime: 0
        )
        do {
            let pattern = try CHHapticPattern(events: [event], parameterCurves: [swell])
            let player = try engine.makePlayer(with: pattern)
            try engine.start()
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            // Haptics are a bonus; the experience works without them.
        }
    }

    func tap() {
        guard Self.isEnabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    func success() {
        guard Self.isEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    func warning() {
        guard Self.isEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
