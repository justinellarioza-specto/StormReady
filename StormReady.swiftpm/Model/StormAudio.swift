import AVFoundation

/// Original rain-and-wind sound, synthesized live from filtered noise.
/// No audio files and no network: everything is generated on the device.
///
/// Safety: AVAudioEngine throws Objective-C exceptions (which close the app)
/// if the audio hardware reports an invalid format. Every step below checks
/// first and simply stays silent if audio is not available.
final class StormAudio {
    static let shared = StormAudio()

    /// Set to false to run the app completely silent (useful for debugging).
    static var isEnabled = true

    private var engine: AVAudioEngine?
    private var source: AVAudioSourceNode?
    private var failed = false

    private let state = RenderState()

    private init() {}

    /// Starts the storm sound, or changes its loudness if already playing.
    func play(volume: Float) {
        guard Self.isEnabled, !failed else { return }
        state.targetVolume = volume

        if let engine {
            if !engine.isRunning { try? engine.start() }
            return
        }

        // Let the first screen finish appearing before touching audio hardware.
        DispatchQueue.main.async { [weak self] in self?.setUp() }
    }

    /// A low thunder swell layered on top of the rain.
    func thunder() { state.rumble = 1 }

    func fadeOut() {
        state.targetVolume = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            guard let self, self.state.targetVolume == 0 else { return }
            self.engine?.pause()
        }
    }

    private func setUp() {
        guard engine == nil, !failed else { return }

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.ambient, mode: .default)
            try session.setActive(true)
        } catch {
            failed = true
            return
        }

        let newEngine = AVAudioEngine()
        let hardware = newEngine.outputNode.outputFormat(forBus: 0)
        guard hardware.sampleRate > 0, hardware.channelCount > 0,
              let format = AVAudioFormat(standardFormatWithSampleRate: hardware.sampleRate, channels: 1)
        else {
            failed = true
            return
        }

        let node = StormAudio.makeSource(state: state)
        newEngine.attach(node)
        newEngine.connect(node, to: newEngine.mainMixerNode, format: format)
        newEngine.prepare()

        do {
            try newEngine.start()
        } catch {
            failed = true
            return
        }

        engine = newEngine
        source = node
    }

    /// Built in a static, non-isolated function so the render block is never
    /// tied to the main thread. It runs on Core Audio's real-time thread.
    private static func makeSource(state: RenderState) -> AVAudioSourceNode {
        var rain: Float = 0   // bright, hissy layer
        var wind: Float = 0   // deep, slow layer

        return AVAudioSourceNode { _, _, frameCount, bufferList -> OSStatus in
            // Mono, non-interleaved: a single buffer holds every sample.
            guard let output = bufferList.pointee.mBuffers.mData?.assumingMemoryBound(to: Float.self) else {
                return noErr
            }
            for frame in 0..<Int(frameCount) {
                state.currentVolume += (state.targetVolume - state.currentVolume) * 0.0002
                state.rumble *= 0.99997

                let white = Float.random(in: -1...1)
                rain += (white - rain) * 0.35
                wind += (white - wind) * 0.004

                var sample = (rain * 0.25 + wind * (2.5 + state.rumble * 12)) * state.currentVolume
                sample = max(-0.9, min(0.9, sample))

                output[frame] = sample
            }
            return noErr
        }
    }
}

/// Plain values shared with the audio thread.
private final class RenderState {
    var targetVolume: Float = 0
    var currentVolume: Float = 0
    var rumble: Float = 0
}
