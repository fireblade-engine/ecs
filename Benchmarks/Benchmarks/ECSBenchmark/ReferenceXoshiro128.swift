struct ReferenceXoshiro128: Sendable {
    private(set) var state: (UInt32, UInt32, UInt32, UInt32)

    init(seed: UInt32) {
        state = (seed &+ 3, seed &+ 5, seed &+ 7, seed &+ 11)
    }

    mutating func next() -> UInt32 {
        var s0 = state.0
        var s1 = state.1
        var s2 = state.2
        var s3 = state.3
        let result = Self.rotateLeft(s1 &* 5, by: 7) &* 9
        let t = s1 << 9

        s2 ^= s0
        s3 ^= s1
        s1 ^= s2
        s0 ^= s3
        s2 ^= t
        s3 = Self.rotateLeft(s3, by: 11)
        state = (s0, s1, s2, s3)
        return result
    }

    mutating func range(_ lowerBound: UInt32, _ upperBound: UInt32) -> UInt32 {
        next() % (upperBound &- lowerBound &+ 1) &+ lowerBound
    }
}

private extension ReferenceXoshiro128 {
    static func rotateLeft(_ value: UInt32, by amount: UInt32) -> UInt32 {
        (value << amount) | (value >> (32 &- amount))
    }
}
