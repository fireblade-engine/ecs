// swiftlint:disable identifier_name
// Spike S1: minimal value-type storage with type-erased storages indexed by a static component index.

/// A component with a statically assigned dense index into the world's storage table.
public protocol S1Component {
    static var componentIndex: Int { get }
}

/// Type-erased base. Holds the entity-id side of a sparse set so the driver storage can be iterated without knowing `C`.
open class AnyComponentStorage {
    public final var ids: ContiguousArray<Int> = []
    public final var sparse: [Int] = []
    public init() {}
    public final var count: Int {
        ids.count
    }
}

public final class ComponentStorage<C: S1Component>: AnyComponentStorage {
    public var dense: ContiguousArray<C> = []

    @inlinable
    public func denseIndex(of id: Int) -> Int {
        id < sparse.count ? sparse[id] : -1
    }

    public func set(_ component: C, for id: Int) {
        let existing = denseIndex(of: id)
        if existing >= 0 {
            dense[existing] = component
            return
        }
        if id >= sparse.count {
            sparse.append(contentsOf: repeatElement(-1, count: id + 1 - sparse.count))
        }
        sparse[id] = dense.count
        dense.append(component)
        ids.append(id)
    }

    /// Base pointer of the dense array. Valid only while no structural change happens (spike simplification).
    @inlinable
    public func mutableBase() -> UnsafeMutablePointer<C> {
        dense.withUnsafeMutableBufferPointer { $0.baseAddress ?? UnsafeMutablePointer(bitPattern: MemoryLayout<C>.alignment).unsafelyUnwrapped }
    }
}

public final class World {
    @usableFromInline var storages: ContiguousArray<AnyComponentStorage?> = []
    private var nextID = 0

    public init() {}

    public func createEntity() -> Int {
        defer { nextID += 1 }
        return nextID
    }

    public func add<C: S1Component>(_ component: C, to id: Int) {
        storage(C.self).set(component, for: id)
    }

    public func get<C: S1Component>(_: C.Type, of id: Int) -> C? {
        let s = storage(C.self)
        let i = s.denseIndex(of: id)
        return i >= 0 ? s.dense[i] : nil
    }

    /// Typed access via `unsafeDowncast`, creating the storage on first use.
    @inlinable
    public func storage<C: S1Component>(_: C.Type) -> ComponentStorage<C> {
        let index = C.componentIndex
        if index >= storages.count {
            storages.append(contentsOf: repeatElement(nil, count: index + 1 - storages.count))
        }
        if let existing = storages[index] {
            return unsafeDowncast(existing, to: ComponentStorage<C>.self)
        }
        let created = ComponentStorage<C>()
        storages[index] = created
        return created
    }
}
