//
//  SparseSet.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 30.10.17.
//

public struct SparseComponentSet<Element: Component> {
	fileprivate typealias ComponentIdx = Int
	fileprivate typealias EntryTuple = (entityId: EntityIdentifier, component: Element)
	fileprivate var dense: ContiguousArray<EntryTuple?>
	fileprivate var sparse: [EntityIdentifier: ComponentIdx]

	public init(_ min: Int = 1024) {
		dense = ContiguousArray<EntryTuple?>()
		dense.reserveCapacity(min)

		sparse = [EntityIdentifier: ComponentIdx](minimumCapacity: min)
	}

	public var count: Int { return dense.count }
	internal var capacitySparse: Int { return sparse.count }
	internal var capacityDense: Int { return dense.count }

	public func contains(_ entityId: EntityIdentifier) -> Bool {
		guard let compIdx: ComponentIdx = sparse[entityId] else { return false }
		return compIdx < count && dense[compIdx] != nil
	}

	@discardableResult
	public mutating func add(_ element: Element, with entityId: EntityIdentifier) -> Bool {
		if contains(entityId) { return false }
		sparse[entityId] = count
		let entry: EntryTuple = EntryTuple(entityId: entityId, component: element)
		dense.append(entry)
		return true
	}

	public func get(_ entityId: EntityIdentifier) -> Element? {
		guard let compIdx: ComponentIdx = sparse[entityId] else { return nil }
		return dense[compIdx]?.component
	}

	public mutating func remove(_ entityId: EntityIdentifier) -> Element? {
		guard let compIdx: ComponentIdx = sparse[entityId] else { return nil }
		dense.swapAt(compIdx, count-1)
		sparse[entityId] = nil
		let swapped: EntryTuple = dense[compIdx]!
		sparse[swapped.entityId] = compIdx
		let removed: EntryTuple = dense.popLast()!!
		return removed.component
	}

	public mutating func clear(keepingCapacity: Bool = false) {
		dense.removeAll(keepingCapacity: keepingCapacity)
	}
}

extension SparseComponentSet: Sequence {

	public func makeIterator() -> AnyIterator<Element> {
		var iterator = dense.makeIterator()

		return AnyIterator<Element> {
			iterator.next()??.component
		}
	}
}
