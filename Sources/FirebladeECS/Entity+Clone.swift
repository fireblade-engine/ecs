//
//  Entity+Clone.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.26.
//

extension Entity {
    /// Clones this entity and all of its components within its nexus.
    /// - Returns: The cloned entity.
    /// - Throws: ``ComponentCloneError`` if the entity does not exist or a component is not cloneable.
    /// - Complexity: O(C + M) where C is the number of components and M is the number of families.
    @discardableResult
    public func clone() throws -> Entity {
        try nexus.clone(entity: self)
    }
}
