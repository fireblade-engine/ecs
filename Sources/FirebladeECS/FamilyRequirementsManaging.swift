//
//  FamilyRequirementsManaging.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 21.08.19.
//

/// A protocol defining the requirements for a family.
///
/// This protocol is used to define the components required by a family and how to retrieve them.
public protocol FamilyRequirementsManaging {
    /// A tuple of component instances.
    associatedtype Components
    /// A tuple of component types.
    associatedtype ComponentTypes
    /// A tuple containing the entity and its components.
    associatedtype EntityAndComponents

    /// Initializes with component types.
    /// - Parameter types: The component types.
    init(_ types: ComponentTypes)

    /// The component types required by this family.
    var componentTypes: [Component.Type] { get }

    /// Retrieves the components for a given entity.
    /// - Parameters:
    ///   - nexus: The nexus instance.
    ///   - entityId: The entity identifier.
    /// - Returns: The components.
    static func components(nexus: Nexus, entityId: EntityIdentifier) -> Components

    /// Retrieves the entity and its components.
    /// - Parameters:
    ///   - nexus: The nexus instance.
    ///   - entityId: The entity identifier.
    /// - Returns: The entity and components.
    static func entityAndComponents(nexus: Nexus, entityId: EntityIdentifier) -> EntityAndComponents

    /// Creates a new member entity with the given components.
    /// - Parameters:
    ///   - nexus: The nexus instance.
    ///   - components: The components to assign.
    /// - Returns: The created entity.
    static func createMember(nexus: Nexus, components: Components) -> Entity
}
