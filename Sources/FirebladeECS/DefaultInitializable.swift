//
//  DefaultInitializable.swift
//  FirebladeECS
//
//  Created by Igor Kravchenko on 29.09.2020.
//

/// Requires initializer with default values.
/// In case of component - makes sure it can be instantiated by component provider
public protocol DefaultInitializable {
    init()
}

public typealias ComponentInitializable = Component & DefaultInitializable
