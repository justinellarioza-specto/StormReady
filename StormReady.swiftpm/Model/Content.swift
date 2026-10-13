import Foundation

// MARK: - Go-bag supplies

struct SupplyItem: Identifiable, Hashable {
    let id: String
    let name: String
    let symbol: String
    let essential: Bool
    let tip: String
}

extension SupplyItem {
    static let all: [SupplyItem] = [
        .init(id: "water", name: "Drinking water", symbol: "drop.fill", essential: true,
              tip: "Taps can stop working. Store about 4 liters per person, per day."),
        .init(id: "flashlight", name: "Flashlight", symbol: "flashlight.on.fill", essential: true,
              tip: "Power is often the first thing a storm takes."),
        .init(id: "tv", name: "Television", symbol: "tv.fill", essential: false,
              tip: "Heavy, and useless without power. Leave it."),
        .init(id: "radio", name: "Battery radio", symbol: "radio.fill", essential: true,
              tip: "Official updates still reach you when cell signal is gone."),
        .init(id: "firstaid", name: "First-aid kit", symbol: "cross.case.fill", essential: true,
              tip: "Small injuries are common while cleaning up."),
        .init(id: "console", name: "Game console", symbol: "gamecontroller.fill", essential: false,
              tip: "Fun, but it needs power you will not have."),
        .init(id: "documents", name: "IDs in a plastic bag", symbol: "doc.text.fill", essential: true,
              tip: "Floodwater ruins paper. Seal important documents."),
        .init(id: "food", name: "Canned food", symbol: "fork.knife", essential: true,
              tip: "Pick food that needs no cooking. Pack an opener."),
        .init(id: "pillow", name: "Big pillow", symbol: "bed.double.fill", essential: false,
              tip: "Bulky. A light blanket does the job better."),
        .init(id: "powerbank", name: "Charged power bank", symbol: "battery.100.bolt", essential: true,
              tip: "Keeps your phone alive to contact family."),
        .init(id: "medicine", name: "Daily medicines", symbol: "pills.fill", essential: true,
              tip: "Pharmacies may stay closed for days."),
        .init(id: "dryer", name: "Hair dryer", symbol: "wind", essential: false,
              tip: "No power, no use. Skip it.")
    ]

    static func named(_ id: String) -> SupplyItem? { all.first { $0.id == id } }
}

// MARK: - Home hazards

struct Hazard: Identifiable, Hashable {
    let id: String
    let name: String
    let symbol: String
    let fixedLabel: String
    let tip: String
    /// Position inside the room drawing, as fractions of its width and height.
    let x: Double
    let y: Double
}

extension Hazard {
    static let all: [Hazard] = [
        .init(id: "yard", name: "Loose chairs outside", symbol: "leaf.fill", fixedLabel: "Brought inside",
              tip: "Strong wind turns loose objects into flying debris.", x: 0.22, y: 0.30),
        .init(id: "breaker", name: "Main power switch", symbol: "bolt.fill", fixedLabel: "Location learned",
              tip: "Know how to switch off power if water gets in.", x: 0.86, y: 0.26),
        .init(id: "phone", name: "Phone at 20%", symbol: "battery.25", fixedLabel: "Fully charged",
              tip: "Charge every device while you still have power.", x: 0.52, y: 0.58),
        .init(id: "electronics", name: "Laptop on the floor", symbol: "laptopcomputer", fixedLabel: "Moved up high",
              tip: "Lift electronics and documents above flood level.", x: 0.36, y: 0.86),
        .init(id: "jugs", name: "Empty water jugs", symbol: "drop.fill", fixedLabel: "Filled",
              tip: "Fill clean containers before the water supply stops.", x: 0.80, y: 0.84)
    ]
}

// MARK: - Storm events

struct StormEvent: Identifiable {
    let id: String
    let headline: String
    let symbol: String
    let goodOutcome: String
    let badOutcome: String
    let check: (GameState) -> Bool
}

extension StormEvent {
    static let all: [StormEvent] = [
        .init(id: "power", headline: "The power goes out.", symbol: "lightbulb.slash.fill",
              goodOutcome: "Your flashlight lights the way to your family.",
              badOutcome: "You stumble through the dark house.",
              check: { $0.isPacked("flashlight") }),
        .init(id: "window", headline: "Something slams against the window.", symbol: "wind",
              goodOutcome: "The yard is clear. It was only rain.",
              badOutcome: "A loose chair hit the glass. It cracked.",
              check: { $0.isFixed("yard") }),
        .init(id: "flood", headline: "Water creeps under the door.", symbol: "water.waves",
              goodOutcome: "Your laptop and papers are safe up high.",
              badOutcome: "Your laptop was on the floor. It is soaked.",
              check: { $0.isFixed("electronics") || $0.isPacked("documents") }),
        .init(id: "signal", headline: "Cell signal disappears.", symbol: "antenna.radiowaves.left.and.right.slash",
              goodOutcome: "Your radio says the storm passes by dawn.",
              badOutcome: "No news. You can only wait and guess.",
              check: { $0.isPacked("radio") }),
        .init(id: "tap", headline: "The tap runs dry.", symbol: "drop.degreesign.slash",
              goodOutcome: "You planned ahead. There is water for everyone.",
              badOutcome: "There is nothing to drink until morning.",
              check: { $0.isPacked("water") || $0.isFixed("jugs") })
    ]
}
