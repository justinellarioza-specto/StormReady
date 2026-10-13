import SwiftUI

/// Scene 2 — choose what fits in a six-slot go-bag (about 40 seconds).
struct PackView: View {
    @EnvironmentObject private var game: GameState
    @State private var message = "Tap or drag items into your bag. It only has 6 slots."
    @State private var bagBump = false
    @State private var tilesShown = false

    private let columns = [GridItem(.adaptive(minimum: 104), spacing: 12)]

    var body: some View {
        ZStack {
            StormSky(intensity: 0.3).ignoresSafeArea()
            CloudLayer(count: 6, speed: 10, color: .white, opacity: 0.08, heightFraction: 0.35, scale: 1.3)
                .ignoresSafeArea()
            RainView(intensity: 0.12).ignoresSafeArea()
            content
        }
        .onAppear {
            withAnimation(.easeOut) { tilesShown = true }
        }
    }

    private var content: some View {
        VStack(spacing: 0) {
            SceneHeader(step: 1, title: "Pack the go-bag",
                        subtitle: "If you have to leave fast, what comes with you?")

            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(Array(SupplyItem.all.enumerated()), id: \.element.id) { index, item in
                        ItemTile(item: item, packed: game.isPacked(item.id))
                            .scaleEffect(tilesShown ? 1 : 0.6)
                            .opacity(tilesShown ? 1 : 0)
                            .animation(.spring(response: 0.45, dampingFraction: 0.65)
                                        .delay(0.04 * Double(index)), value: tilesShown)
                            .onTapGesture { toggle(item) }
                            .draggable(item.id) {
                                ItemTile(item: item, packed: false).frame(width: 104)
                            }
                            .accessibilityAddTraits(.isButton)
                            .accessibilityValue(game.isPacked(item.id) ? "In bag" : "Not packed")
                    }
                }
                .padding()
            }

            Text(message)
                .font(.callout)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 44)
                .padding(.horizontal)
                .animation(.default, value: message)

            bag
        }
        .frame(maxWidth: 820)
    }

    private var bag: some View {
        VStack(spacing: 12) {
            HStack {
                Label {
                    Text("Your go-bag")
                } icon: {
                    Image(systemName: "backpack.fill")
                        .foregroundStyle(Theme.accent)
                        .symbolEffect(.bounce, value: game.packed.count)
                }
                .font(.headline)
                Spacer()
                Text("\(game.packed.count) / \(GameState.bagSlots)")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(game.bagIsFull ? Theme.warn : .secondary)
            }

            HStack(spacing: 8) {
                ForEach(0..<GameState.bagSlots, id: \.self) { slot in
                    slotView(slot)
                }
            }
            .scaleEffect(bagBump ? 1.04 : 1)

            NextButton(title: "Done packing") {
                Haptics.shared.tap()
                game.go(.secure)
            }
        }
        .padding()
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 24))
        .padding()
        .dropDestination(for: String.self) { ids, _ in
            guard let id = ids.first, let item = SupplyItem.named(id), !game.isPacked(id) else { return false }
            toggle(item)
            return true
        }
    }

    @ViewBuilder
    private func slotView(_ slot: Int) -> some View {
        let item = slot < game.packed.count ? SupplyItem.named(game.packed[slot]) : nil
        RoundedRectangle(cornerRadius: 12)
            .strokeBorder(Color.white.opacity(item == nil ? 0.25 : 0), style: StrokeStyle(lineWidth: 1.5, dash: [5]))
            .background(
                RoundedRectangle(cornerRadius: 12).fill(item == nil ? Color.clear : Theme.accent.opacity(0.25))
            )
            .overlay {
                if let item {
                    Image(systemName: item.symbol)
                        .font(.title3)
                        .foregroundStyle(Theme.accent)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(height: 48)
            .onTapGesture { if let item { toggle(item) } }
            .accessibilityLabel(item.map { "Slot \(slot + 1): \($0.name)" } ?? "Slot \(slot + 1): empty")
    }

    private func toggle(_ item: SupplyItem) {
        let wasPacked = game.isPacked(item.id)
        let changed = withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
            game.togglePacked(item.id)
        }

        guard changed else {
            message = "Your bag is full. Tap an item in the bag to take it out."
            Haptics.shared.warning()
            return
        }

        if wasPacked {
            message = "Took out: \(item.name)."
            Haptics.shared.tap()
        } else {
            message = item.tip
            Haptics.shared.tap()
            withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) { bagBump = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring()) { bagBump = false }
            }
        }
    }
}

private struct ItemTile: View {
    let item: SupplyItem
    let packed: Bool

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: item.symbol)
                .font(.system(size: 30))
                .frame(height: 36)
            Text(item.name)
                .font(.footnote.weight(.medium))
                .multilineTextAlignment(.center)
                .lineLimit(2, reservesSpace: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(packed ? Theme.accent.opacity(0.22) : Theme.card, in: RoundedRectangle(cornerRadius: 16))
        .overlay(alignment: .topTrailing) {
            if packed {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Theme.accent)
                    .padding(6)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(packed ? Theme.accent : Color.clear, lineWidth: 1.5)
        )
        .contentShape(RoundedRectangle(cornerRadius: 16))
    }
}
