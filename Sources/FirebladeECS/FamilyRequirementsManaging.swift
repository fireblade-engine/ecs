//
//  FamilyRequirementsManaging.swift
//
//
//  Created by Christian Treffs on 21.08.19.
//

public protocol FamilyRequirementsManaging {
    associatedtype Components
    associatedtype ComponentTypes
    associatedtype EntityAndComponents
    init(_ types: ComponentTypes)
    var componentTypes: [Component.Type] { get }
    static func components(nexus: Nexus, entityId: EntityIdentifier) -> Components
    static func entityAndComponents(nexus: Nexus, entityId: EntityIdentifier) -> EntityAndComponents
}
