// swiftlint:disable identifier_name
// Spike S1: family wrappers and the forEach variants.

public struct Reading<each R: S1Component> {
    public init(_: repeat (each R).Type) {}
}

public struct Writing<each W: S1Component> {
    public init(_: repeat (each W).Type) {}
}

/// Writes through a pointer scoped to one iteration step (Variant Mut). Escapable here: `~Escapable`/`~Copyable`
/// do not combine with parameter packs on Swift 6.4, see Spikes/S1/REPORT.md.
@dynamicMemberLookup
public struct Mut<C> {
    @usableFromInline let pointer: UnsafeMutablePointer<C>

    @inlinable public init(_ pointer: UnsafeMutablePointer<C>) {
        self.pointer = pointer
    }

    @inlinable
    public subscript<T>(dynamicMember keyPath: WritableKeyPath<C, T>) -> T {
        get { pointer.pointee[keyPath: keyPath] }
        nonmutating set { pointer.pointee[keyPath: keyPath] = newValue }
    }

    /// Whole-value access without key paths.
    @inlinable
    public var value: C {
        unsafeAddress { UnsafePointer(pointer) }
        nonmutating unsafeMutableAddress { pointer }
    }
}

public struct Family<Read, Write> {
    public let world: World
    public init(world: World, reading: Read, writing: Write) {
        self.world = world
    }
}

extension Family {
    public init<each R: S1Component, each W: S1Component>(
        world: World, reading: Reading<repeat each R>, writing: Writing<repeat each W>
    ) where Read == Reading<repeat each R>, Write == Writing<repeat each W> {
        self.world = world
    }
}

extension Family {
    /// Smallest storage across all families' component types drives iteration (membership by random access).
    @inlinable
    public func driver<each R: S1Component, each W: S1Component>(
        _ r: repeat (each R).Type, writing w: repeat (each W).Type
    ) -> AnyComponentStorage? {
        var best: AnyComponentStorage?
        func consider(_ s: AnyComponentStorage) {
            if let b = best, b.count <= s.count {
                return
            }
            best = s
        }
        _ = (repeat consider(world.storage((each R).self)))
        _ = (repeat consider(world.storage((each W).self)))
        return best
    }
}

extension Family {
    /// Variant A (inout tuple): writes first as an `inout` tuple, then reads as a flat trailing pack (the only position
    /// where a pack can follow another parameter in a callable function type).
    @inlinable
    public func forEach<each R: S1Component, each W: S1Component>(
        _ body: (inout (repeat each W), repeat each R) -> Void
    ) where Read == Reading<repeat each R>, Write == Writing<repeat each W> {
        guard let driver = driver(repeat (each R).self, writing: repeat (each W).self) else { return }
        let rs = (repeat world.storage((each R).self))
        let ws = (repeat world.storage((each W).self))
        let rb = (repeat (each rs).mutableBase())
        let wb = (repeat (each ws).mutableBase())
        for i in 0 ..< driver.count {
            let id = driver.ids[i]
            var present = true
            let rp = (repeat fetchElement(each rb, each rs, id, &present))
            let wp = (repeat fetchElement(each wb, each ws, id, &present))
            guard present else { continue }
            var w = (repeat loadElement(each wp))
            let r = (repeat loadElement(each rp))
            body(&w, repeat each r)
            _ = (repeat storeElement(each wp, each w))
        }
    }

    /// Variant Mut: reads as one tuple, writes through trailing `Mut` handles into storage.
    @inlinable
    public func forEachMut<each R: S1Component, each W: S1Component>(
        _ body: ((repeat each R), repeat Mut<each W>) -> Void
    ) where Read == Reading<repeat each R>, Write == Writing<repeat each W> {
        guard let driver = driver(repeat (each R).self, writing: repeat (each W).self) else { return }
        let rs = (repeat world.storage((each R).self))
        let ws = (repeat world.storage((each W).self))
        let rb = (repeat (each rs).mutableBase())
        let wb = (repeat (each ws).mutableBase())
        for i in 0 ..< driver.count {
            let id = driver.ids[i]
            var present = true
            let rp = (repeat fetchElement(each rb, each rs, id, &present))
            let wp = (repeat fetchElement(each wb, each ws, id, &present))
            guard present else { continue }
            body((repeat loadElement(each rp)), repeat Mut(each wp))
        }
    }
}

extension Family {
    /// Pointer to the element of `id` in `storage`, or `base` and `present = false` when `id` is absent.
    @inlinable
    func fetchElement<C: S1Component>(
        _ base: UnsafeMutablePointer<C>, _ storage: ComponentStorage<C>, _ id: Int, _ present: inout Bool
    ) -> UnsafeMutablePointer<C> {
        let index = storage.denseIndex(of: id)
        if index < 0 {
            present = false
            return base
        }
        return base + index
    }
}

extension Family {
    @inlinable
    func loadElement<C>(_ pointer: UnsafeMutablePointer<C>) -> C {
        pointer.pointee
    }

    @inlinable
    func storeElement<C>(_ pointer: UnsafeMutablePointer<C>, _ value: C) {
        pointer.pointee = value
    }
}
