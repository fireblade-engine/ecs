//
//  EntityTable.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 25.10.26.
//

extension Nexus {
    /// Entity bookkeeping shared by every storage: which identifier lives in each slot, and the per-entity component bitset.
    ///
    /// Slots are addressed by `EntityIdentifier.index`; the identifiers themselves (and their generations) come from the
    /// nexus' ``EntityIdentifierGenerator``. A slot holds `EntityIdentifier.invalid` while it is free.
    ///
    /// The table is O(highest slot index ever used) in memory and `livingIds` is O(that index): it never shrinks while the nexus lives,
    /// which is fine for generators that keep indices tightly packed, as the default generator does.
    /// Restoring a snapshot rejects indices above `Nexus.maxRestoredEntityIndex`.
    @usableFromInline
    struct EntityTable {
        @usableFromInline var slots = ContiguousArray<EntityIdentifier>()
        @usableFromInline var masks = ContiguousArray<ComponentMask>()

        /// The number of living entities.
        @usableFromInline private(set) var liveCount = 0

        @usableFromInline
        init() {}

        /// Whether `entityId` is the identifier currently living in its slot.
        @inlinable
        func isAlive(_ entityId: EntityIdentifier) -> Bool {
            let index = Int(entityId.index)
            return index < slots.count && slots[index] == entityId && entityId.isValid
        }

        /// The identifier living in a slot, if any.
        @usableFromInline
        func current(at index: EntityIdentifier.Index) -> EntityIdentifier? {
            let index = Int(index)
            guard index < slots.count, slots[index].isValid else {
                return nil
            }
            return slots[index]
        }

        /// The component set of a living entity.
        @inlinable
        func mask(of entityId: EntityIdentifier) -> ComponentMask? {
            isAlive(entityId) ? masks[Int(entityId.index)] : nil
        }

        /// The identifiers of all living entities, ascending by slot index.
        @usableFromInline var livingIds: [EntityIdentifier] {
            slots.filter(\.isValid)
        }

        /// Occupies the slot of `entityId` with an entity without components.
        /// - Precondition: The slot is free.
        @usableFromInline
        mutating func insert(_ entityId: EntityIdentifier) {
            let index = Int(entityId.index)
            if index >= slots.count {
                let missing = index + 1 - slots.count
                slots.append(contentsOf: repeatElement(.invalid, count: missing))
                masks.append(contentsOf: repeatElement(ComponentMask(), count: missing))
            }
            precondition(!slots[index].isValid, "the entity identifier generator provided \(entityId), but its slot is in use by \(slots[index])")
            slots[index] = entityId
            liveCount += 1
        }

        /// Frees the slot of a living entity and clears its component set. The caller removes the components first.
        @usableFromInline
        mutating func remove(_ entityId: EntityIdentifier) -> Bool {
            guard isAlive(entityId) else {
                return false
            }
            slots[Int(entityId.index)] = .invalid
            masks[Int(entityId.index)] = ComponentMask()
            liveCount -= 1
            return true
        }

        /// Sets the whole component set of a living entity at once.
        @inlinable
        mutating func setMask(_ mask: ComponentMask, of entityId: EntityIdentifier) {
            masks[Int(entityId.index)] = mask
        }

        @inlinable
        mutating func insert(_ componentIndex: Int, into entityId: EntityIdentifier) {
            masks[Int(entityId.index)].insert(componentIndex)
        }

        @inlinable
        mutating func remove(_ componentIndex: Int, from entityId: EntityIdentifier) {
            masks[Int(entityId.index)].remove(componentIndex)
        }
    }
}
