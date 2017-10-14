//
//  ComponentStorage.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 10.10.17.
//

/*
public typealias ComponentIndex = Int
public protocol ComponentStorage {

	@discardableResult func add<C: Component>(_ component: C) -> Bool

	func makeIterator<C: Component>(_ componentType: C.Type) -> AnyIterator<C>
	func makeIterator(_ componentId: ComponentIdentifier) -> AnyIterator<Component>

	func has<C: Component>(_ component: C) -> Bool
	func has<C: Component>(_ componentType: C.Type) -> Bool
	func has(_ componentId: ComponentIdentifier) -> Bool

	func get<C: Component>(_ componentType: C.Type) -> Component?
	subscript<C: Component>(_ componentType: C.Type) -> Component? { get }

	func get(_ componentId: ComponentIdentifier) -> Component?
	subscript(_ componentId: ComponentIdentifier) -> Component? { get }

	@discardableResult func remove<C: Component>(_ component: C) -> Bool
	@discardableResult func remove<C: Component>(_ componentType: C.Type) -> Bool
	@discardableResult func remove(_ componentId: ComponentIdentifier) -> Bool

	func clear()
}

class GeneralComponentStorage: ComponentStorage {

	fileprivate var componentMap: [ComponentIdentifier: ContiguousArray<Component>] = [:]

	
	func add<C>(_ component: C) -> Bool where C : Component {
		if var comps: ContiguousArray<Component> = componentMap[component.uct] {
			comps.append(component)
		} else {
			componentMap[component.uct] = ContiguousArray<Component>()
			componentMap[component.uct]!.append(component)
		}
		return true
	}

	func makeIterator<C>(_ componentType: C.Type) -> AnyIterator<C> where C : Component {
		fatalError()
	}

	func makeIterator(_ componentId: ComponentIdentifier) -> AnyIterator<Component> {
		fatalError()
	}

	func has<C>(_ component: C) -> Bool where C : Component {
		fatalError()
	}

	func has<C>(_ componentType: C.Type) -> Bool where C : Component {
		fatalError()
	}

	func has(_ componentId: ComponentIdentifier) -> Bool {
		fatalError()
	}

	func get<C>(_ componentType: C.Type) -> Component? where C : Component {
		fatalError()
	}

	subscript<C>(componentType: C.Type) -> Component? where C: Component {
		fatalError()
	}

	func get(_ componentId: ComponentIdentifier) -> Component? {
		fatalError()
	}

	subscript(componentId: ComponentIdentifier) -> Component? {
		fatalError()
	}

	func remove<C>(_ component: C) -> Bool where C : Component {
		fatalError()
	}

	func remove<C>(_ componentType: C.Type) -> Bool where C : Component {
		fatalError()
	}

	func remove(_ componentId: ComponentIdentifier) -> Bool {
		fatalError()
	}

	func clear() {
		fatalError()
	}

}
*/
