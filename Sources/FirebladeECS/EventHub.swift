//
//  EventHub.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 09.10.17.
//

public protocol EventHub: class {
	func subscribe<E: Event>(classRef eventHandlerRefUnowned: EventHandler, eventHandler: @escaping (E) -> Void)
	func unsubscribe<E: Event>(classRef eventHandlerRefUnowned: EventHandler, eventHandler: @escaping (E) -> Void)

	weak var sniffer: EventSniffer? { get set }
}

public class DefaultEventHub: EventHub, EventDispatcher {

	public var sniffer: EventSniffer?

	public init() { }

	private var listeners: [UET: ContiguousArray<EventHandlerRef>] = [:]

	private func typeEvent<E: Event>(opaqueEvent: Event, eventHandler: @escaping (E) -> Void ) {
		guard let typedEvent: E = opaqueEvent as? E else {
			fatalError() // TODO: meaningful message
		}
		eventHandler(typedEvent)
	}

	private func push(listener newListener: EventHandlerRef, `for` uet: UET) {
		if listeners[uet] == nil {
			listeners[uet] = []
			listeners.reserveCapacity(1)
		}
		listeners[uet]?.append(newListener)
	}
}

// MARK: - event center
extension DefaultEventHub {

	final public func subscribe<E: Event>(classRef unownedListenerRef: EventHandler, eventHandler handler: @escaping (E) -> Void) {
		let eventListener: EventHandlerRef = EventHandlerRef(eventHandlerClassRefUnowned: unownedListenerRef,
															 eventHandler: { self.typeEvent(opaqueEvent: $0, eventHandler: handler)	})

		push(listener: eventListener, for: E.uet)
		sniffer?.subscriber(subsribed: E.uet)
	}

	final public func unsubscribe<E: Event>(classRef listenerRef: EventHandler, eventHandler handler: @escaping (E) -> Void) {
		let uet: UET = E.uet

		if let removeIdx: Int = listeners[uet]?.index(is: listenerRef) {
			let removed = listeners[uet]?.remove(at: removeIdx)
			assert(removed != nil)
			sniffer?.subscriber(unsubsribed: uet)
		}

	}

}

// MARK: - event dispatcher delegate
extension DefaultEventHub {
	final public func dispatch<E: Event>(_ event: E) {
		let uet: UET = E.uet
		listeners[uet]?.forEach {
			$0.eventHandler(event)
		}
		sniffer?.dispatched(event: event)
	}

}

// MARK: - event dumper
public protocol EventSniffer: class {
	func subscriber(subsribed to: UET)
	func subscriber(unsubsribed from: UET)
	func dispatched<E: Event>(event: E)
}
