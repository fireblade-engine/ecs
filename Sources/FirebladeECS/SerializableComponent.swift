//
//  SerializableComponent.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.26.
//

/// A registrable component that can be encoded and decoded by its stable type name.
///
/// Serializable components take part in nexus snapshots, which export and import entities
/// together with their components. Component properties referencing entities are encoded
/// as entity identifiers and remapped to the imported entities on decoding.
public protocol SerializableComponent: RegistrableComponent, Codable {}
