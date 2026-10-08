//
//  CloneableComponent.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.26.
//

/// A component that can create a copy of itself for another entity.
///
/// Cloning entities via ``Nexus/clone(entity:)``, ``Nexus/clone(entities:)`` or ``Nexus/clone(into:)``
/// requires every component of the cloned entities to be cloneable.
public protocol CloneableComponent: Component {
    /// Creates a copy of this component.
    ///
    /// Pass every stored property through `ComponentCloneContext.clone(_:)` so that references
    /// to other entities are remapped to their clones.
    /// - Parameter context: The context mapping source entities to their clones.
    /// - Returns: A new component instance.
    func clone(context: ComponentCloneContext) -> Self
}
