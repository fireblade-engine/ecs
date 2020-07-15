//
//  EntityIdentifierGenerator.swift
//
//
//  Created by Christian Treffs on 26.06.20.
//

internal final class EntityIdentifierGenerator {
    private var stack: [UInt32]

    var count: Int {
        stack.count
    }

    init() {
        stack = [0]
    }

    init(_ entityIds: [EntityIdentifier]) {
        stack = entityIds.reversed().map { UInt32($0.id) }
    }

    func nextId() -> EntityIdentifier {
        if stack.count == 1 {
            defer { stack[0] += 1 }
            return EntityIdentifier(stack[0])
        } else {
            return EntityIdentifier(stack.removeLast())
        }
    }

    func freeId(_ entityId: EntityIdentifier) {
        stack.append(UInt32(entityId.id))
    }
}
