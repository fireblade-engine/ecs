// swiftlint:disable all
// Spike S1 deep dive, fallback without the Lifetimes feature: a noncopyable scoped entity handed to a closure.

public struct EntityScope: ~Copyable {
    public let id: Int
    @usableFromInline let world: World

    @inlinable
    init(id: Int, world: World) {
        self.id = id
        self.world = world
    }

    @inlinable
    public func get<C: S1Component>(_ type: C.Type) -> C? {
        world.get(type, of: id)
    }
}

extension World {
    @inlinable
    public func withEntity<Result>(_ id: Int, _ body: (borrowing EntityScope) throws -> Result) rethrows -> Result {
        try body(EntityScope(id: id, world: self))
    }
}
