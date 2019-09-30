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
        return inserted
    }

    public final func removeChild(_ child: Entity, from parent: Entity) -> Bool {
        return parentChildrenMap[parent.identifier]?.remove(child.identifier) != nil
    }

    public final func removeAllChildren(from parent: Entity) {
        return parentChildrenMap[parent.identifier] = nil
    }

    public final func numChildren(for entity: Entity) -> Int {
        return parentChildrenMap[entity.identifier]?.count ?? 0
    }
}
