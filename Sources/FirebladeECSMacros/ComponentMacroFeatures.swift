//
//  ComponentMacroFeatures.swift
//  FirebladeECSMacros
//
//  Created by Christian Treffs on 08.10.26.
//

/// The features the ``Component(excluding:)`` macro implements.
///
/// Registration (``RegistrableComponent``) is always implemented.
public struct ComponentMacroFeatures: OptionSet, Sendable {
    /// The raw bit mask of the features.
    public let rawValue: UInt8

    /// Creates a feature set from a raw bit mask.
    /// - Parameter rawValue: The raw bit mask.
    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    /// ``CloneableComponent`` via a generated `init(cloning:context:)` and `clone(context:)`.
    public static let cloneable = ComponentMacroFeatures(rawValue: 1 << 0)

    /// ``SerializableComponent`` via generated `CodingKeys`, `init(from:)` and `encode(to:)`.
    public static let serializable = ComponentMacroFeatures(rawValue: 1 << 1)

    /// ``InspectableComponent`` via a generated `componentProperties` list.
    public static let inspectable = ComponentMacroFeatures(rawValue: 1 << 2)

    /// ``DefaultInitializable`` via a generated `init()`, if all stored properties have default values.
    public static let defaultInit = ComponentMacroFeatures(rawValue: 1 << 3)
}
