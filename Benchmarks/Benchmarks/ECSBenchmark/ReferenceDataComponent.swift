import FirebladeECS

struct ReferenceDataComponent: Component, Sendable {
    static let defaultSeed: UInt32 = 340_383

    var thingy: Int32
    var dingy: Double
    var mingy: Bool
    var seed: UInt32
    var rng: ReferenceXoshiro128
    var numgy: UInt32

    init(seed: UInt32 = Self.defaultSeed) {
        thingy = 0
        dingy = 0
        mingy = false
        self.seed = seed
        var rng = ReferenceXoshiro128(seed: seed)
        numgy = rng.next()
        self.rng = rng
    }
}
