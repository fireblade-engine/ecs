//
//  Nexus+SceneGraph.swift
//
//
//  Created by Christian Treffs on 30.09.19.
//

extension Nexus {
    public final func addChild(_ child: Entity, to parent: Entity) -> Bool {
        let inserted: Bool
        if parentChildrenMap[parent.identifier] == nil {
            parentChildrenMap[parent.identifier] = [child.identifier]
            inserted = true
        } else {
            let (isNewMember, _) = parentChildrenMap[parent.identifier]!.insert(child.identifier)
            inserted = isNewMember
        }
        if inserted {
            delegate?.nexusEvent(ChildAdded(parent: parent.identifier, child: child.identifier))
        }
        return inserted
    }

    public final func removeChild(_ child: Entity, from parent: Entity) -> Bool {
        return removeChild(child.identifier, from: parent.identifier)
    }

    @discardableResult
    public final func removeChild(_ child: EntityIdentifier, from parent: EntityIdentifier) -> Bool {
        let removed: Bool = parentChildrenMap[parent]?.remove(child) != nil
        if removed {
            delegate?.nexusEvent(ChildRemoved(parent: parent, child: child))
        }
        return removed
    }

    public final func removeAllChildren(from parent: Entity) {
        parentChildrenMap[parent.identifier]?.forEach { removeChild($0, from: parent.identifier) }
        return parentChildrenMap[parent.identifier] = nil
    }

    public final func numChildren(for entity: Entity) -> Int {
        return parentChildrenMap[entity.identifier]?.count ?? 0
    }
}
