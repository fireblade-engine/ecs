//
//  EventHandling.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.17.
//

// MARK: - event
public protocol Event: UniqueEventIdentifiable { }
public extension Event {
	static var uet: UET { return UET(Self.self) }
	var uet: UET { return Self.uet }
}

// MARK: - event handler
public struct EventHandlerRef {
	unowned var eventHandlerClassRefUnowned: EventHandler
	let eventHandler: (Event) -> Void
}

public protocol EventHandler: class {
	func subscribe<E: Event>(event eventHandler: @escaping (E) -> Void)
	func unsubscribe<E: Event>(event eventHandler: @escaping (E) -> Void)

	weak var delegate: EventHub? { get set }
}

public extension EventHandler {

	fileprivate func unowned(_ closure: @escaping (EventHandler) -> Void) {
		#if DEBUG
			let preActionCount: Int = retainCount(self)
		#endif
		let unownedClosure = { [unowned self] in
			closure(self)
		}
		unownedClosure()
		#if DEBUG
			let postActionCount: Int = retainCount(self)
			assert(postActionCount == preActionCount, "retain count missmatch [\(preActionCount)] -> [\(postActionCount)]")
		#endif
	}

	/// Subscribe with an event handler closure to receive events of type T
	///
	/// - Parameter eventHandler: event handler closure
	public func subscribe<E: Event>(event eventHandler: @escaping (E) -> Void) {
		unowned {
			self.delegate?.subscribe(classRef: $0, eventHandler: eventHandler)
		}
	}

	/// Unsubscribe from an event handler closure to stop receiving events of type T
	///
	/// - Parameter eventHandler: event handler closure
	public func unsubscribe<E: Event>(event eventHandler: @escaping (E) -> Void) {
		unowned {
			self.delegate?.unsubscribe(classRef: $0, eventHandler: eventHandler)
		}
	}

}

public extension ContiguousArray where Element == EventHandlerRef {
	public func index(is eventHandler: EventHandler) -> Int? { // FIXME: this my be costly
		return index { (eventHandlerRef: EventHandlerRef) -> Bool in
			return eventHandlerRef.eventHandlerClassRefUnowned === eventHandler
		}
	}

}

// MARK: - event dispatcher
public protocol EventDispatcher: class {
	func dispatch<E: Event>(_ event: E)
}
