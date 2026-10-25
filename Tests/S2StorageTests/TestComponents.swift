//
//  TestComponents.swift
//  S2StorageTests
//

import S2Storage

struct Position: Component, Equatable {
    static let componentIndex = 0
    var x = 0.0
    var y = 0.0
}

struct Velocity: Component, Equatable {
    static let componentIndex = 1
    var dx = 0.0
    var dy = 0.0
}

/// Non-trivial field: owns heap storage.
struct Label: Component, Equatable {
    static let componentIndex = 2
    var text: String
}

/// Non-trivial field: owns heap storage.
struct Samples: Component, Equatable {
    static let componentIndex = 3
    var values: [Int]
}

struct Frozen: Component, Equatable {
    static let componentIndex = 4
}

struct Mass: Component, Equatable {
    static let componentIndex = 5
    var kilograms = 1.0
}

struct Charge: Component, Equatable {
    static let componentIndex = 6
    var coulombs = 0.0
}

struct Spin: Component, Equatable {
    static let componentIndex = 7
    var turns = 0.0
}

/// Counts how many instances are alive; a leak or double release shows as a wrong count.
final class Token: Sendable {
    nonisolated(unsafe) static var live = 0

    init() {
        Self.live += 1
    }

    deinit {
        Self.live -= 1
    }
}

struct Held: Component {
    static let componentIndex = 8
    let token = Token()
}
