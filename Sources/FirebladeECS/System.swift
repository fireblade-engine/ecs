//
//  System.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.17.
//

public enum SystemState {
	case running, paused, inactive
}

public protocol System: class {
	//var state: SystemState { set get }
	func startup()
	func shutdown()
}
