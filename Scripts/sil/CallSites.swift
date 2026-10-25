// Concrete call sites whose optimized SIL Scripts/check-sil.sh inspects.
//
// Every site is `@inline(never)` and has concrete component types, so the generic inlinable code of FirebladeECS
// specializes into it. The script checks that the loops of the sites allocate nothing and call no witness or other
// function per member.

import FirebladeECS

public struct Position: Component {
    public var x: Int
    public var y: Int
}

public struct Velocity: Component {
    public var dx: Int
    public var dy: Int
}

public struct Health: Component {
    public var points: Int
}

public struct Tag: Component {
    public var value: Int
}

// MARK: forEach(reading:writing:)

@inline(never) public func site_ForEach_0R1W(_ family: Family<Position, Velocity>, _ sum: inout Int) {
    family.forEach(writing: Position.self) { position in position.x &+= 1 }
}

@inline(never) public func site_ForEach_1R0W(_ family: Family<Position, Velocity>, _ sum: inout Int) {
    var total = 0
    family.forEach(reading: Position.self) { position in total &+= position.x }
    sum = total
}

@inline(never) public func site_ForEach_1R1W(_ family: Family<Position, Velocity>, _ sum: inout Int) {
    family.forEach(reading: Velocity.self, writing: Position.self) { velocity, position in
        position.x &+= velocity.dx
    }
}

@inline(never) public func site_ForEach_2R1W(_ family: Family<Position, Velocity, Health>, _ sum: inout Int) {
    family.forEach(reading: Velocity.self, Health.self, writing: Position.self) { velocity, health, position in
        position.x &+= velocity.dx &+ health.points
    }
}

@inline(never) public func site_ForEach_1R2W(_ family: Family<Position, Velocity, Health>, _ sum: inout Int) {
    family.forEach(reading: Health.self, writing: Position.self, Velocity.self) { health, position, velocity in
        position.x &+= health.points
        velocity.dx &-= 1
    }
}

@inline(never) public func site_ForEach_4R0W(_ family: Family<Position, Velocity, Health, Tag>, _ sum: inout Int) {
    var total = 0
    family.forEach(reading: Position.self, Velocity.self, Health.self, Tag.self) { position, velocity, health, tag in
        total &+= position.x &+ velocity.dx &+ health.points &+ tag.value
    }
    sum = total
}

@inline(never) public func site_ForEach_2R2W(_ family: Family<Position, Velocity, Health, Tag>, _ sum: inout Int) {
    family.forEach(reading: Health.self, Tag.self, writing: Position.self, Velocity.self) { health, tag, position, velocity in
        position.x &+= health.points
        velocity.dx &+= tag.value
    }
}

// MARK: plain iteration

@inline(never) public func site_Sequence_1(_ family: Family<Position>, _ sum: inout Int) {
    var total = 0
    for position in family {
        total &+= position.x
    }
    sum = total
}

@inline(never) public func site_Sequence_2(_ family: Family<Position, Velocity>, _ sum: inout Int) {
    var total = 0
    for (position, velocity) in family {
        total &+= position.x &+ velocity.dx
    }
    sum = total
}

@inline(never) public func site_Sequence_EntityAndComponents_2(_ family: Family<Position, Velocity>, _ sum: inout Int) {
    var total = 0
    for (_, position, velocity) in family.entityAndComponents {
        total &+= position.x &+ velocity.dx
    }
    sum = total
}

// MARK: forEachComponentSpan (macOS 26 and later)

@available(macOS 26, *)
@inline(never) public func site_ForEachSpan_1R(_ family: Family<Position, Velocity>, _ sum: inout Int) {
    var total = 0
    family.forEachComponentSpan(reading: Position.self) { positions in
        for index in positions.indices {
            total &+= positions[index].x
        }
    }
    sum = total
}

@available(macOS 26, *)
@inline(never) public func site_ForEachSpan_1R1W(_ family: Family<Position, Velocity>, _ sum: inout Int) {
    family.forEachComponentSpan(reading: Velocity.self, writing: Position.self) { velocities, positions in
        for index in positions.indices {
            positions[index].x &+= velocities[index].dx
        }
    }
}

@available(macOS 26, *)
@inline(never) public func site_ForEachSpan_2R1W(_ family: Family<Position, Velocity, Health>, _ sum: inout Int) {
    family.forEachComponentSpan(reading: Velocity.self, Health.self, writing: Position.self) { velocities, healths, positions in
        for index in positions.indices {
            positions[index].x &+= velocities[index].dx &+ healths[index].points
        }
    }
}
