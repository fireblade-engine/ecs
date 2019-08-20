//
//  NexusEventDelegate.swift
//  
//
//  Created by Christian Treffs on 20.08.19.
//

public protocol NexusEventDelegate: class {
    func nexusEventOccurred(_ event: ECSEvent)
    func nexusRecoverableErrorOccurred(_ message: String)
}
