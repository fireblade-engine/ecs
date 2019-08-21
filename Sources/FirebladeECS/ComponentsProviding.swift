//
//  ComponentsProviding.swift
//  
//
//  Created by Christian Treffs on 21.08.19.
//

public protocol ComponentsProviding {
    associatedtype Components
    associatedtype ComponentTypes
    init(_ types: ComponentTypes)
    var componentTypes: [Component.Type] { get }
    static func getComponents(nexus: Nexus, entityId: EntityIdentifier) -> Components
}
