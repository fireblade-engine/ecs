// swiftlint:disable all
// Spike S1 deep dive: a ~Escapable Entity view. Reference only, not a 2.0 deliverable.
import S1FamilyAPI

/// A view of one entity that cannot outlive the world borrow it was created from.
public struct Entity: ~Escapable {
    public let id: Int
    @usableFromInline let world: Unmanaged<World>

    @_lifetime(borrow world)
    @inlinable
    public init(_ id: Int, in world: borrowing World) {
        self.id = id
        self.world = Unmanaged.passUnretained(world as World)
    }

    @inlinable
    public func get<C: S1Component>(_ type: C.Type) -> C? {
        world._withUnsafeGuaranteedRef { $0.get(type, of: id) }
    }
}

extension World {
    /// `nexus.entity(_:)` returning the non-escapable view.
    @_lifetime(borrow self)
    public func entity(_ id: Int) -> Entity {
        Entity(id, in: self)
    }
}

#if compiler(>=6.3) // Equatable/Hashable on ~Escapable need a toolchain newer than 6.2.
    extension Entity: Equatable {
        public static func == (lhs: borrowing Entity, rhs: borrowing Entity) -> Bool {
            lhs.id == rhs.id
        }
    }

    extension Entity: Hashable {
        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
#endif

/// `extension Entity: CustomStringConvertible` fails on Swift 6.4: "type 'Entity' does not conform to protocol 'Escapable'".
extension Entity {
    public var description: String {
        "Entity(\(id))"
    }
}

extension Family {
    /// forEach handing out an `Entity` view per step.
    @inlinable
    public func forEachEntity<each R: S1Component, each W: S1Component>(
        _ body: (Entity) -> Void
    ) where Read == Reading<repeat each R>, Write == Writing<repeat each W> {
        guard let driver = driver(repeat (each R).self, writing: repeat (each W).self) else { return }
        for index in 0 ..< driver.count {
            body(Entity(driver.ids[index], in: world))
        }
    }
}
