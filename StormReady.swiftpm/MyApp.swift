import SwiftUI

/// TEST MODE: set to false to launch straight into the game.
let diagnosticLaunch = false

@main
struct StormReadyApp: App {
    var body: some Scene {
        WindowGroup {
            Group {
                if diagnosticLaunch {
                    DiagnosticView()
                } else {
                    ContentView()
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}

/// A plain screen with no animation, sound or drawing.
/// If this opens, the project itself is fine; then tap each button
/// to find which scene closes the app.
struct DiagnosticView: View {
    @State private var choice: GameScene?
    @State private var showRain = false
    @StateObject private var game = GameState()

    var body: some View {
        if let choice {
            ZStack(alignment: .topLeading) {
                Theme.night.ignoresSafeArea()
                switch choice {
                case .intro:  IntroView()
                case .pack:   PackView()
                case .secure: SecureView()
                case .storm:  StormView()
                case .plan:   PlanView()
                }
                Button("Back to test menu") { self.choice = nil }
                    .buttonStyle(.bordered)
                    .padding()
            }
            .environmentObject(game)
        } else if showRain {
            ZStack(alignment: .topLeading) {
                Theme.night.ignoresSafeArea()
                RainView(intensity: 0.8)
                Button("Back to test menu") { showRain = false }
                    .buttonStyle(.bordered)
                    .padding()
            }
        } else {
            VStack(spacing: 14) {
                Text("StormReady test menu")
                    .font(.title.bold())
                Text("If you can read this, the project opens fine. Tap each button in order and note which one makes the app close.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: 420)

                Button("1. Rain animation only") { showRain = true }
                Button("2. Intro scene") { choice = .intro }
                Button("3. Pack scene") { choice = .pack }
                Button("4. Secure scene") { choice = .secure }
                Button("5. Storm scene") { choice = .storm }
                Button("6. Plan scene") { choice = .plan }
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
    }
}

/// Routes between the five scenes of the experience.
struct ContentView: View {
    @StateObject private var game = GameState()

    var body: some View {
        ZStack {
            Theme.night.ignoresSafeArea()

            switch game.scene {
            case .intro:  IntroView().transition(.opacity)
            case .pack:   PackView().transition(.opacity)
            case .secure: SecureView().transition(.opacity)
            case .storm:  StormView().transition(.opacity)
            case .plan:   PlanView().transition(.opacity)
            }
        }
        .environmentObject(game)
        .animation(.easeInOut(duration: 0.6), value: game.scene)
    }
}

enum Theme {
    static let night  = Color(red: 0.07, green: 0.09, blue: 0.15)
    static let dusk   = Color(red: 0.16, green: 0.20, blue: 0.32)
    static let card   = Color.white.opacity(0.08)
    static let accent = Color(red: 0.36, green: 0.82, blue: 0.75)
    static let warn   = Color(red: 0.98, green: 0.62, blue: 0.30)
}
