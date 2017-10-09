//
//  Events.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.17.
//

public struct EntityCreated: Event {
	let entity: Entity
}

public struct EntityDestroyed: Event {
	let entity: Entity
}

public struct ComponentAdded: Event {
	let component: Component
	let to: Entity
}

public struct ComponentUpdated: Event {
	let component: Component
	let previous: Component
	let at: Entity
}

public struct ComponentRemoved: Event {
	let component: Component
	let from: Entity
}

/*
public enum ECSEvent {

	case entityCreated(Entity)
	case entityDestroyed(Entity)

	case componentAdded(Component, to: Entity)
	case componentUpdated(Component, previous: Component, at: Entity)
	case componentRemoved(Component, from: Entity)


}
*/
