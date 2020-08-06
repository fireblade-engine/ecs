//
//  FamilyRequirementsManaging.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 21.08.19.
//

public protocol FamilyRequirementsManaging {
    associatedtype Components
    associatedtype ComponentTypes
    associatedtype EntityAndComponents
    associatedtype RelativesDescending

    init(_ types: ComponentTypes)

    var componentTypes: [Component.Type] { get }

    static func components(nexus: Nexus, entityId: EntityIdentifier) -> Components
    static func entityAndComponents(nexus: Nexus, entityId: EntityIdentifier) -> EntityAndComponents
    static func relativesDescending(nexus: Nexus, parentId: EntityIdentifier, childId: EntityIdentifier) -> RelativesDescending

    static func createMember(nexus: Nexus, components: Components) -> Entity
}
