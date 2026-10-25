//
//  ArchetypeTable.swift
//  S2Storage
//

/// Type-erased base of one column of an archetype table. The methods are the slow, untyped paths used by
/// row moves and snapshots; typed access casts to `Column` with `unsafeDowncast`.
public class AnyColumn {
    init() {}

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
public final class Column<C: Component>: AnyColumn {
    @usableFromInline var items = ContiguousArray<C>()

    override public init() {
        super.init()
    }

    /// The address of row 0. Only valid while the table is not modified, which the storage guarantees for
    /// the duration of an iteration. Requires at least one row.
    @inlinable
    var base: UnsafeMutablePointer<C> {
        items.withUnsafeMutableBufferPointer { $0.baseAddress.unsafelyUnwrapped }
    }

    override func makeEmpty() -> AnyColumn {
        Column<C>()
    }

    override func swapRemove(_ row: Int) {
        let last = items.count - 1
        if row != last {
            items.swapAt(row, last)
        }
        items.removeLast()
    }

    override func moveAppend(from other: AnyColumn, row: Int) {
        let source = unsafeDowncast(other, to: Column<C>.self)
        let last = source.items.count - 1
        if row != last {
            source.items.swapAt(row, last)
        }
        items.append(source.items.removeLast())
    }

    override func anyValue(at row: Int) -> any Component {
        items[row]
    }

    override func assign(any component: any Component, at row: Int) -> Bool {
        guard let typed = component as? C else {
            return false
        }
        items[row] = typed
        return true
    }
}

/// All entities that share one component set: a column per component type plus the entity indices of the rows.
public final class ArchetypeTable {
    public let mask: ComponentMask
    /// The entity index of every row.
    @usableFromInline var entities = ContiguousArray<UInt32>()
    /// Indexed by component index; `nil` for components not in `mask`.
    @usableFromInline var columns: ContiguousArray<AnyColumn?>
    /// The component indices in `mask`, ascending.
    let columnIndices: [Int]
    /// Cached transitions: `addEdges[c]` is the table after adding component `c`, `-1` when unknown.
    var addEdges = ContiguousArray<Int32>()
    var removeEdges = ContiguousArray<Int32>()

    init(mask: ComponentMask, columns: [(Int, AnyColumn)]) {
        self.mask = mask
        var sparseColumns = ContiguousArray<AnyColumn?>()
        for (index, column) in columns {
            while sparseColumns.count <= index {
                sparseColumns.append(nil)
            }
            sparseColumns[index] = column
        }
        self.columns = sparseColumns
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
        return unsafeDowncast(column, to: Column<C>.self)
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
