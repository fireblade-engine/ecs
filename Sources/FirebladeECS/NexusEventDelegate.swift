//
//  NexusEventDelegate.swift
//
//
//  Created by Christian Treffs on 20.08.19.
//

public protocol NexusEventDelegate: class {
    func nexusEvent(_ event: NexusEvent)
    func nexusNonFatalError(_ message: String)
}
