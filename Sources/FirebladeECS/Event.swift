//
//  Event.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.17.
//

protocol ECSEvent: UniqueEventIdentifiable { }
extension ECSEvent {
	static var uet: UET { return UET(Self.self) }
	var uet: UET { return Self.uet }
}

// MARK: - event dispachter protocol
 protocol EventHandler: class {
	func subscribe<E: ECSEvent>(event eventHandler: @escaping (E) -> Void)
	func unsubscribe<E: ECSEvent>(event eventHandler: @escaping (E) -> Void)

	unowned var listenerRef: EventHandler { get }
}

extension EventHandler {

	unowned var listenerRef: EventHandler {
		return self
	}

	/// Subscribe with an event handler closure to receive events of type T
	///
	/// - Parameter eventHandler: event handler closure
	func subscribe<E: ECSEvent>(event eventHandler: @escaping (E) -> Void) {
		EventHub.shared.add(listener: listenerRef, handler: eventHandler)
	}

	/// Unsubscribe from an event handler closure to stop receiving events of type T
	///
	/// - Parameter eventHandler: event handler closure
	func unsubscribe<E: ECSEvent>(event eventHandler: @escaping (E) -> Void) {
		EventHub.shared.remove(listener: listenerRef, handler: eventHandler)
	}

}

protocol EventSender: class {
	func dispatch<E: ECSEvent>(event: E)
}

extension EventSender {
	/// Dispatch an event of type E
	///
	/// - Parameter event: event of type E
	func dispatch<E: ECSEvent>(event: E) {
		EventHub.shared.dispatch(event)
	}
}

// MARK: - event hub central
fileprivate typealias EventListener = (weakRef: EventHandler, eventHandler: (ECSEvent) -> Void )
final class EventHub {

	static let shared: EventHub = EventHub()

	private var listeners: [UET: ContiguousArray<EventListener>] = [:]

	private init() {}

}

extension ContiguousArray where Element == EventListener {
	func index(is listenerRef: EventHandler) -> Int? {
		return index { (eventListener: EventListener) -> Bool in
			return eventListener.weakRef === listenerRef
		}
	}

}

extension EventHub {

	private static func relayEvent<E: ECSEvent>(opaqueEvent: ECSEvent, eventHandler: @escaping (E) -> Void ) {
		guard let typedEvent: E = opaqueEvent as? E else {
			fatalError() // TODO: meaningful message
		}
		eventHandler(typedEvent)
	}

	final func add<E: ECSEvent>(listener listenerRef: EventHandler, handler: @escaping (E) -> Void) {
		let eventListener: EventListener = (weakRef: listenerRef,
											eventHandler: {	EventHub.relayEvent(opaqueEvent: $0, eventHandler: handler)	})

		push(listener: eventListener, for: E.uet)
	}

	private func push(listener newListener: EventListener, `for` uet: UET) {
		if listeners[uet] == nil {
			listeners[uet] = []
			listeners.reserveCapacity(1)
		}
		listeners[uet]?.append(newListener)
	}

}

extension EventHub {

	final func remove<E: ECSEvent>(listener listenerRef: EventHandler, handler: @escaping (E) -> Void) {
		let uet: UET = E.uet

		if let removeIdx: Int = listeners[uet]?.index(is: listenerRef) {
			let removed = listeners[uet]?.remove(at: removeIdx)
			assert(removed != nil)
		}

	}

}

extension EventHub {

	final func dispatch<E: ECSEvent>(_ event: E) {
		let uet: UET = E.uet
		listeners[uet]?.forEach {
			$0.eventHandler(event)
		}
	}

}

/*
extension EventHandler {
	func subscribe<T: Event>(event eventHandler: @escaping (T) -> Void, syncOnQueue queue: WorkQueue)
	func subscribe<T: Event>(event eventHandler: @escaping (T) -> Void, asyncOnQueue queue: WorkQueue)
}

extension EventSender {

	/// Subscribe with a synchronous dispatched event handler closure to receive events of type T
	///
	/// - Parameters:
	///   - eventHandler: event handler closure
	///   - queue: queue to handle events
	func subscribe<T: Event>(event eventHandler: @escaping (T) -> Void, syncOnQueue queue: WorkQueue) {
		EventHub.shared.addSyncListener(owner: type(of: self), syncOnQueue: queue, handler: eventHandler)
	}

	/// Subscribe with an asynchronous dispatched event handler closure to receive events of type T
	///
	/// - Parameters:
	///   - eventHandler: event handler closure
	///   - queue: queue to handle events on
	func subscribe<T: Event>(event eventHandler: @escaping (T) -> Void, asyncOnQueue queue: WorkQueue) {
		EventHub.shared.addAsyncListener(owner: type(of: self), asyncOnQueue: queue, handler: eventHandler)
	}
}

extension EventHub {

	final func addSyncListener<T: Event>(owner: AnyClass, syncOnQueue queue: WorkQueue, handler: @escaping (T) -> Void) {
		let syncListener: Listener = (owner: owner, handler: { event in
			guard let tEvent: T = event as? T else { fatalError("can not cast event to required type") }
			queue.syncExec { handler(tEvent) }
		})
		addToList(eventType: T.eventType, listener: syncListener)
	}

	final func addAsyncListener<T: Event>(owner: AnyClass, asyncOnQueue queue: WorkQueue, handler: @escaping (T) -> Void) {
		let asyncListener: Listener = (owner: owner, handler: { event in
			guard let tEvent: T = event as? T else { fatalError("can not cast event to required type") }
			queue.asyncExec { handler(tEvent) }
		})
		addToList(eventType: T.eventType, listener: asyncListener)
	}
}
*/
