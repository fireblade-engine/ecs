//
//  NexusEventDelegate.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 20.08.19.
//

/// A delegate for receiving Nexus events and errors.
public protocol NexusEventDelegate: AnyObject, Sendable {
    /// Called when a Nexus event occurs.
    /// - Parameter event: The event that occurred.
    func nexusEvent(_ event: NexusEvent)

    /// Called when a non-fatal error occurs in the Nexus.
    /// - Parameter message: The error message.
    func nexusNonFatalError(_ message: String)
}
