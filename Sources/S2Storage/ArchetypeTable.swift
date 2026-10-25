//
//  ArchetypeTable.swift
//  S2Storage
//

/// Type-erased base of one column of an archetype table. The methods are the slow, untyped paths used by
/// row moves and snapshots; typed access casts to `Column` with `unsafeDowncast`.
public class AnyColumn {
    /// The component type of this column; guards `unsafeDowncast` against two types sharing an index.
    @usableFromInline let typeID: ObjectIdentifier

    init(typeID: ObjectIdentifier) {
        self.typeID = typeID
    }

    /// A column of the same component type with no rows.
    func makeEmpty() -> AnyColumn {
        fatalError("abstract")
    }

    /// Removes `row` by swapping the last row into its place.
    func swapRemove(_ row: Int) {
        fatalError("abstract")
    }

    /// Removes `row` of `other` (swap-remove) and appends its value here. `other` has the same type.
    func moveAppend(from other: AnyColumn, row: Int) {
        fatalError("abstract")
    }

    func anyValue(at row: Int) -> any Component {
        fatalError("abstract")
    }

    func assign(any component: any Component, at row: Int) -> Bool {
        fatalError("abstract")
    }
}

/// One component type's values of an archetype table; row `i` belongs to `ArchetypeTable.entities[i]`.
///
/// The values live in a hand-managed buffer, so moving a row between tables is a single
/// `moveInitialize` per column instead of three generic `ContiguousArray` operations (`swapAt`,
/// `removeLast`, `append`) that run unspecialized behind the class's virtual methods. Elements are
/// initialized and deinitialized by hand; `deinit` releases the live ones.
public final class Column<C: Component>: AnyColumn {
    /// Address of row 0; dangling (never dereferenced) while `capacity` is 0.
    @exclusivity(unchecked) @usableFromInline var base: UnsafeMutablePointer<C>
    @exclusivity(unchecked) @usableFromInline var count = 0
    @exclusivity(unchecked) @usableFromInline var capacity = 0

    public init() {
        base = UnsafeMutablePointer<C>(bitPattern: MemoryLayout<C>.alignment).unsafelyUnwrapped
        super.init(typeID: ObjectIdentifier(C.self))
    }

    deinit {
        base.deinitialize(count: count)
        if capacity > 0 {
            base.deallocate()
        }
    }

    @inlinable
    subscript(row: Int) -> C {
        unsafeAddress { UnsafePointer(base + row) }
        unsafeMutableAddress { base + row }
    }

    @inlinable
    func append(_ value: C) {
        if count == capacity {
            grow()
        }
        (base + count).initialize(to: value)
        count += 1
    }

    @usableFromInline
    func grow() {
        let newCapacity = max(8, capacity * 2)
        let newBase = UnsafeMutablePointer<C>.allocate(capacity: newCapacity)
        newBase.moveInitialize(from: base, count: count)
        if capacity > 0 {
            base.deallocate()
        }
        base = newBase
        capacity = newCapacity
    }

    /// Fills the hole at `row` (already deinitialized or moved out) with the last row.
    @inlinable
    func fillHole(_ row: Int) {
        let last = count - 1
        if row != last {
            (base + row).moveInitialize(from: base + last, count: 1)
        }
        count = last
    }

    override func makeEmpty() -> AnyColumn {
        Column<C>()
    }

    override func swapRemove(_ row: Int) {
        (base + row).deinitialize(count: 1)
        fillHole(row)
    }

    override func moveAppend(from other: AnyColumn, row: Int) {
        let source = unsafeDowncast(other, to: Column<C>.self)
        if count == capacity {
            grow()
        }
        (base + count).moveInitialize(from: source.base + row, count: 1)
        count += 1
        source.fillHole(row)
    }

    override func anyValue(at row: Int) -> any Component {
        self[row]
    }

    override func assign(any component: any Component, at row: Int) -> Bool {
        guard let typed = component as? C else {
            return false
        }
        self[row] = typed
        return true
    }
}

/// All entities that share one component set: a column per component type plus the entity indices of the rows.
public final class ArchetypeTable {
    public let mask: ComponentMask
    /// The entity index of every row.
    @exclusivity(unchecked) @usableFromInline var entities = ContiguousArray<UInt32>()
    /// Indexed by component index; `nil` for components not in `mask`.
    @exclusivity(unchecked) @usableFromInline var columns: ContiguousArray<AnyColumn?>
    /// The same columns without reference counting, for iteration loops. `columns` keeps them alive.
    @exclusivity(unchecked) @usableFromInline var unmanagedColumns: ContiguousArray<Unmanaged<AnyColumn>?>
    /// The component indices in `mask`, ascending.
    let columnIndices: [Int]
    /// Cached transitions: `addEdges[c]` is the table after adding component `c`, `-1` when unknown.
    @exclusivity(unchecked) var addEdges = ContiguousArray<Int32>()
    @exclusivity(unchecked) var removeEdges = ContiguousArray<Int32>()

    init(mask: ComponentMask, columns: [(Int, AnyColumn)]) {
        self.mask = mask
        var sparseColumns = ContiguousArray<AnyColumn?>()
        var unmanaged = ContiguousArray<Unmanaged<AnyColumn>?>()
        for (index, column) in columns {
            while sparseColumns.count <= index {
                sparseColumns.append(nil)
                unmanaged.append(nil)
            }
            sparseColumns[index] = column
            unmanaged[index] = Unmanaged.passUnretained(column)
        }
        self.columns = sparseColumns
        unmanagedColumns = unmanaged
        columnIndices = columns.map(\.0)
    }

    public var rowCount: Int {
        entities.count
    }

    @inlinable
    func column<C: Component>(_: C.Type) -> Column<C>? {
        let index = C.componentIndex
        guard index < columns.count, let column = columns[index] else {
            return nil
        }
        precondition(column.typeID == ObjectIdentifier(C.self), "component index \(index) is used by two component types")
        return unsafeDowncast(column, to: Column<C>.self)
    }

    /// Address of row 0 of the column for `C`, without retaining the column. The table must have the column
    /// and at least one row.
    @inlinable
    func base<C: Component>(_: C.Type) -> UnsafeMutablePointer<C> {
        unmanagedColumns[C.componentIndex].unsafelyUnwrapped._withUnsafeGuaranteedRef { column in
            precondition(column.typeID == ObjectIdentifier(C.self), "component index \(C.componentIndex) is used by two component types")
            return unsafeDowncast(column, to: Column<C>.self).base
        }
    }

    func edge(_ edges: ContiguousArray<Int32>, _ componentIndex: Int) -> Int {
        componentIndex < edges.count ? Int(edges[componentIndex]) : -1
    }

    func setEdge(_ edges: inout ContiguousArray<Int32>, _ componentIndex: Int, to table: Int) {
        while edges.count <= componentIndex {
            edges.append(-1)
        }
        edges[componentIndex] = Int32(table)
    }
}
