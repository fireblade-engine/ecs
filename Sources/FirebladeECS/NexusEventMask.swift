//
//  NexusEventMask.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 25.10.26.
//

/// The kinds of events a ``NexusEventDelegate`` subscribes to.
public struct NexusEventMask: OptionSet, Sendable {
    public let rawValue: UInt8

    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    /// Entity, component and family membership changes: ``EntityCreated``, ``EntityDestroyed``, ``ComponentAdded``,
    /// ``ComponentRemoved``, ``FamilyMemberAdded`` and ``FamilyMemberRemoved``.
    ///
    /// Informational: structural events are always delivered, as in FirebladeECS 1, whether the mask contains this
    /// option or not.
    public static let structural = NexusEventMask(rawValue: 1 << 0)

    /// Changes of component values: ``ComponentReplaced``, ``ComponentModified`` and ``ComponentsModified``.
    public static let valueChanges = NexusEventMask(rawValue: 1 << 1)

    /// All events.
    public static let all: NexusEventMask = [.structural, .valueChanges]
}
