import SwiftUI

/// Scene 5 — a personal family plan built from the player's choices (about 30 seconds).
struct PlanView: View {
    @EnvironmentObject private var game: GameState
    @State private var appeared = false

    private var results: [(event: StormEvent, passed: Bool)] { game.results }
    private var score: Int { results.filter { $0.passed }.count }

    private var verdict: (title: String, line: String) {
        switch score {
        case 5:    return ("You were ready.", "Your family made it through safe and calm.")
        case 3...4: return ("You made it through.", "A few things went wrong. Now you know what to fix.")
        default:   return ("A long, hard night.", "Everyone is safe, but it could have been easier.")
        }
    }

    private var missingSupplies: [SupplyItem] {
        SupplyItem.all.filter { $0.essential && !game.isPacked($0.id) }
    }

    private var unfixedHazards: [Hazard] {
        Hazard.all.filter { !game.isFixed($0.id) }
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.22, green: 0.30, blue: 0.50),
                                    Color(red: 0.62, green: 0.46, blue: 0.44),
                                    Color(red: 0.92, green: 0.64, blue: 0.44)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            CloudLayer(count: 5, speed: 5, color: Color(red: 1.0, green: 0.88, blue: 0.78),
                       opacity: 0.22, heightFraction: 0.4, scale: 1.3)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    SceneHeader(step: 4, title: "Morning", subtitle: "The sky clears. Here is your plan.")

                    Sunrise()

                    HStack(spacing: 20) {
                        ScoreRing(score: score, total: results.count)

                        VStack(alignment: .leading, spacing: 6) {
                            Text(verdict.title).font(.title.bold())
                            Text(verdict.line).foregroundStyle(.secondary)
                            Text("moments handled well")
                                .font(.footnote)
                                .foregroundStyle(Theme.accent)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 20))
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 24)

                    card(title: "In your go-bag", symbol: "backpack.fill") {
                        if game.packed.isEmpty {
                            Text("Nothing. Next time, pack before the wind starts.")
                                .foregroundStyle(.secondary)
                        } else {
                            FlowChips(items: game.packed.compactMap(SupplyItem.named))
                        }
                    }

                    if !missingSupplies.isEmpty || !unfixedHazards.isEmpty {
                        card(title: "Do this before a real storm", symbol: "checklist") {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(missingSupplies) { item in
                                    bullet(symbol: item.symbol, text: "Pack \(item.name.lowercased()). \(item.tip)")
                                }
                                ForEach(unfixedHazards) { hazard in
                                    bullet(symbol: hazard.symbol, text: hazard.tip)
                                }
                            }
                        }
                    }

                    card(title: "Talk with your family", symbol: "person.3.fill") {
                        VStack(alignment: .leading, spacing: 12) {
                            bullet(symbol: "mappin.and.ellipse", text: "Agree on one meeting place if you get separated.")
                            bullet(symbol: "phone.fill", text: "Write down emergency numbers on paper, not just in your phone.")
                        }
                    }

                    NextButton(title: "Play again", symbol: "arrow.counterclockwise") {
                        Haptics.shared.tap()
                        game.restart()
                    }
                    .padding(.vertical)
                }
                .padding()
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear {
            // Let the sun rise first, then bring in the results.
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.9)) { appeared = true }
            Haptics.shared.success()
        }
    }

    private func card<Content: View>(title: String, symbol: String,
                                     @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: symbol).font(.headline)
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 20))
    }

    private func bullet(symbol: String, text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: symbol).foregroundStyle(Theme.accent).frame(width: 22)
            Text(text).font(.callout)
        }
    }
}

/// Packed items shown as small chips that wrap onto new lines.
private struct FlowChips: View {
    let items: [SupplyItem]
    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 8, alignment: .leading)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(items) { item in
                Label(item.name, systemImage: item.symbol)
                    .font(.footnote.weight(.medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(item.essential ? Theme.accent.opacity(0.2) : Theme.warn.opacity(0.2),
                                in: Capsule())
            }
        }
    }
}

/// A ring that fills up to the player's score, counting up as it goes.
private struct ScoreRing: View {
    let score: Int
    let total: Int
    @State private var progress: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 10)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Theme.accent, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int((progress * Double(total)).rounded()))/\(total)")
                .font(.title2.bold().monospacedDigit())
                .contentTransition(.numericText())
        }
        .frame(width: 96, height: 96)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(score) of \(total)")
        .onAppear {
            let target = total > 0 ? Double(score) / Double(total) : 0
            withAnimation(.easeOut(duration: 1.4).delay(1.2)) { progress = target }
        }
    }
}
