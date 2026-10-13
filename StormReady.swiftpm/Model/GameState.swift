import SwiftUI

enum GameScene: Int, CaseIterable {
    case intro, pack, secure, storm, plan
}

/// Single source of truth for everything the player decides.
final class GameState: ObservableObject {
    static let bagSlots = 6

    @Published var scene: GameScene = .intro
    @Published private(set) var packed: [String] = []   // item ids, in packing order
    @Published private(set) var fixed: Set<String> = [] // hazard ids

    var bagIsFull: Bool { packed.count >= Self.bagSlots }

    func go(_ next: GameScene) { scene = next }

    func isPacked(_ id: String) -> Bool { packed.contains(id) }
    func isFixed(_ id: String) -> Bool { fixed.contains(id) }

    /// Returns false when the bag is full and the item could not be added.
    @discardableResult
    func togglePacked(_ id: String) -> Bool {
        if let index = packed.firstIndex(of: id) {
            packed.remove(at: index)
            return true
        }
        guard !bagIsFull else { return false }
        packed.append(id)
        return true
    }

    func fix(_ id: String) { fixed.insert(id) }

    var results: [(event: StormEvent, passed: Bool)] {
        StormEvent.all.map { ($0, $0.check(self)) }
    }

    func restart() {
        packed = []
        fixed = []
        scene = .intro
    }
}
