import SwiftUI

// All weather effects are drawn procedurally in code: no image or video assets.

/// Deterministic pseudo-random value in 0..<1 for a given seed.
func noise(_ n: Double) -> Double {
    let v = sin(n * 12.9898 + 78.233) * 43758.5453
    return v - floor(v)
}

// MARK: - Sky

/// A sky gradient that gets darker and greener-gray as the storm grows.
struct StormSky: View {
    var intensity: Double  // 0 = calm evening, 1 = full typhoon

    var body: some View {
        LinearGradient(colors: [top, bottom], startPoint: .top, endPoint: .bottom)
    }

    private var top: Color {
        Color(red: 0.18 - 0.14 * intensity, green: 0.22 - 0.16 * intensity, blue: 0.38 - 0.27 * intensity)
    }

    private var bottom: Color {
        Color(red: 0.30 - 0.20 * intensity, green: 0.32 - 0.20 * intensity, blue: 0.42 - 0.26 * intensity)
    }
}

/// Soft clouds that drift across the screen. Stack two layers at different
/// speeds for a sense of depth.
struct CloudLayer: View {
    var count = 6
    var speed: Double = 12
    var color: Color = .white
    var opacity: Double = 0.12
    var heightFraction: Double = 0.4
    var scale: Double = 1

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                context.addFilter(.blur(radius: 10 * scale))

                for i in 0..<count {
                    let n = Double(i) * 7.3
                    let width = (140 + noise(n + 1) * 120) * scale
                    let height = width * 0.38
                    let span = size.width + width * 2
                    let drift = time * speed * (0.6 + noise(n + 2) * 0.8)
                    let x = (noise(n) * span + drift).truncatingRemainder(dividingBy: span) - width
                    let y = noise(n + 3) * size.height * heightFraction

                    var puff = Path()
                    puff.addEllipse(in: CGRect(x: x, y: y + height * 0.35, width: width, height: height * 0.65))
                    puff.addEllipse(in: CGRect(x: x + width * 0.12, y: y + height * 0.05, width: width * 0.45, height: height * 0.8))
                    puff.addEllipse(in: CGRect(x: x + width * 0.40, y: y - height * 0.15, width: width * 0.42, height: height * 0.9))
                    context.fill(puff, with: .color(color.opacity(opacity)))
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Lightning

/// A jagged lightning bolt. A new seed gives a new shape.
struct LightningBolt: Shape {
    var seed: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        var x = rect.midX + (noise(seed) - 0.5) * rect.width * 0.3
        path.move(to: CGPoint(x: x, y: rect.minY))

        let steps = 9
        for i in 1...steps {
            let y = rect.minY + rect.height * Double(i) / Double(steps)
            x += (noise(seed + Double(i) * 3.1) - 0.5) * rect.width * 0.35
            path.addLine(to: CGPoint(x: x, y: y))

            // A small side branch partway down.
            if i == 4 {
                let branchEnd = CGPoint(x: x + rect.width * 0.22 * (noise(seed + 40) > 0.5 ? 1 : -1),
                                        y: y + rect.height * 0.18)
                path.addLine(to: branchEnd)
                path.move(to: CGPoint(x: x, y: y))
            }
        }
        return path
    }
}

/// Full-screen lightning: a double flash plus a glowing bolt.
/// Increase `strikes` to trigger a new strike.
struct LightningOverlay: View {
    let strikes: Int
    @State private var visible = false
    @State private var seed = 1.0
    @State private var xFraction = 0.5

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.white.opacity(visible ? 0.30 : 0)
                if visible {
                    LightningBolt(seed: seed)
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                        .shadow(color: Color(red: 0.70, green: 0.80, blue: 1.0), radius: 10)
                        .shadow(color: Color(red: 0.55, green: 0.65, blue: 1.0), radius: 22)
                        .frame(width: geo.size.width * 0.35, height: geo.size.height * 0.55)
                        .position(x: geo.size.width * xFraction, y: geo.size.height * 0.28)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onChange(of: strikes) { _, _ in strike() }
    }

    private func strike() {
        seed = Double.random(in: 0...1000)
        xFraction = Double.random(in: 0.2...0.8)
        visible = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.07) { visible = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) { visible = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
            withAnimation(.easeOut(duration: 0.4)) { visible = false }
        }
    }
}

/// Shakes the view once each time `animatableData` goes up by 1.
struct Shake: GeometryEffect {
    var amount: CGFloat = 8
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let dx = amount * sin(animatableData * .pi * 6)
        let dy = amount * 0.4 * sin(animatableData * .pi * 5)
        return ProjectionTransform(CGAffineTransform(translationX: dx, y: dy))
    }
}

// MARK: - Wind

/// Leaves and debris tumbling across the screen in strong wind.
struct WindDebris: View {
    var count = 14
    var strength: Double = 1

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                for i in 0..<count {
                    let n = Double(i) + 50
                    let speed = (220 + noise(n) * 260) * strength
                    let span = size.width + 80
                    let x = (noise(n + 1) * span + time * speed).truncatingRemainder(dividingBy: span) - 40
                    let y = noise(n + 2) * size.height + sin(time * 3 + n) * 30

                    var leafContext = context
                    leafContext.translateBy(x: x, y: y)
                    leafContext.rotate(by: .radians(time * (4 + noise(n + 3) * 6) + n))

                    let size = 10 + noise(n + 5) * 8
                    let leaf = Path(ellipseIn: CGRect(x: -size / 2, y: -size / 5, width: size, height: size * 0.4))
                    let tint = noise(n + 4) > 0.5
                        ? Color(red: 0.36, green: 0.56, blue: 0.30)
                        : Color(red: 0.58, green: 0.46, blue: 0.26)
                    leafContext.fill(leaf, with: .color(tint.opacity(0.9)))
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// A tree that bends and springs back in gusts of wind.
struct SwayingTree: View {
    var strength: Double = 1

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let angle = (sin(time * 2.2) * 7 + sin(time * 5.3) * 2 + 6) * strength

                var tree = context
                tree.translateBy(x: size.width * 0.72, y: size.height)
                tree.rotate(by: .degrees(angle))

                let h = size.height
                tree.fill(Path(CGRect(x: -h * 0.025, y: -h * 0.55, width: h * 0.05, height: h * 0.55)),
                          with: .color(Color(red: 0.26, green: 0.19, blue: 0.13)))

                let canopy: [(Double, Double, Double)] = [
                    (0, -0.62, 0.20), (-0.13, -0.54, 0.15), (0.14, -0.52, 0.16), (0, -0.78, 0.14)
                ]
                for (dx, dy, r) in canopy {
                    let rect = CGRect(x: dx * h - r * h, y: dy * h - r * h, width: r * h * 2, height: r * h * 2)
                    tree.fill(Path(ellipseIn: rect), with: .color(Color(red: 0.18, green: 0.34, blue: 0.24)))
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Radio and sun

/// A radio icon sending out pulsing signal rings.
struct RadioBeacon: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    let phase = (time / 2.4 + Double(i) / 3).truncatingRemainder(dividingBy: 1)
                    Circle()
                        .stroke(Theme.warn.opacity(0.8 * (1 - phase)), lineWidth: 2)
                        .frame(width: 84 + 110 * phase, height: 84 + 110 * phase)
                }
                Circle()
                    .fill(Theme.warn.opacity(0.18))
                    .frame(width: 84, height: 84)
                Image(systemName: "radio.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(Theme.warn)
            }
            .frame(width: 200, height: 200)
        }
        .accessibilityHidden(true)
    }
}

/// Triangular rays around a center point.
struct SunRays: Shape {
    var count: Int

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let halfWidth = Double.pi / Double(count) * 0.45

        for i in 0..<count {
            let angle = Double(i) / Double(count) * 2 * .pi
            path.move(to: center)
            path.addLine(to: CGPoint(x: center.x + cos(angle - halfWidth) * radius,
                                     y: center.y + sin(angle - halfWidth) * radius))
            path.addLine(to: CGPoint(x: center.x + cos(angle + halfWidth) * radius,
                                     y: center.y + sin(angle + halfWidth) * radius))
            path.closeSubpath()
        }
        return path
    }
}

/// The morning sun rising over the horizon with slowly turning rays.
struct Sunrise: View {
    @State private var risen = false
    @State private var spin = false

    var body: some View {
        ZStack {
            SunRays(count: 12)
                .fill(Color(red: 1.0, green: 0.82, blue: 0.45).opacity(0.28))
                .frame(width: 230, height: 230)
                .rotationEffect(.degrees(spin ? 360 : 0))
            Circle()
                .fill(RadialGradient(colors: [Color(red: 1.0, green: 0.93, blue: 0.62),
                                              Color(red: 1.0, green: 0.66, blue: 0.32)],
                                     center: .center, startRadius: 4, endRadius: 52))
                .frame(width: 100, height: 100)
                .shadow(color: Color.orange.opacity(0.6), radius: 26)
        }
        .offset(y: risen ? 10 : 140)
        .frame(height: 180)
        .frame(maxWidth: .infinity)
        .clipped()
        .accessibilityHidden(true)
        .onAppear {
            withAnimation(.easeOut(duration: 2.0)) { risen = true }
            withAnimation(.linear(duration: 40).repeatForever(autoreverses: false)) { spin = true }
        }
    }
}
