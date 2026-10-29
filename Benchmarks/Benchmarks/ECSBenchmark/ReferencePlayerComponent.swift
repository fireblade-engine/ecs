import FirebladeECS

struct ReferencePlayerComponent: Component, Sendable {
    var rng: ReferenceXoshiro128
    var type: ReferencePlayerType

    init(seed: UInt32, type: ReferencePlayerType = .npc) {
        rng = ReferenceXoshiro128(seed: seed)
        self.type = type
    }
}
