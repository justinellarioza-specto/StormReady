import SwiftUI

@main
struct StormReadyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
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
