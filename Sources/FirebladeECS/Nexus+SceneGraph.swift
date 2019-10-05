//
//  Nexus+SceneGraph.swift
//
//
//  Created by Christian Treffs on 30.09.19.
//

extension Nexus {
    public final func addChild(_ child: Entity, to parent: Entity) -> Bool {
        let inserted: Bool
        if childrenByParentEntity[parent.identifier] == nil {
            childrenByParentEntity[parent.identifier] = [child.identifier]
            inserted = true
        } else {
            let (isNewMember, _) = childrenByParentEntity[parent.identifier]!.insert(child.identifier)
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
        let removed: Bool = childrenByParentEntity[parent]?.remove(child) != nil
        if removed {
            delegate?.nexusEvent(ChildRemoved(parent: parent, child: child))
        }
        return removed
    }

    public final func removeAllChildren(from parent: Entity) {
        self.removeAllChildren(from: parent.identifier)
    }

    public final func removeAllChildren(from parentId: EntityIdentifier) {
        childrenByParentEntity[parentId]?.forEach { removeChild($0, from: parentId) }
        return childrenByParentEntity[parentId] = nil
    }

    public final func numChildren(for entity: Entity) -> Int {
        return childrenByParentEntity[entity.identifier]?.count ?? 0
    }
}
