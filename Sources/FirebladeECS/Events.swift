//
//  Events.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.17.
//

struct EntityCreated: ECSEvent {
	let entity: Entity
}

struct EntityDestroyed: ECSEvent {
	let entity: Entity
}

struct ComponentAdded: ECSEvent {
	let component: Component
	let to: Entity
}

struct ComponentUpdated: ECSEvent {
	let component: Component
	let previous: Component
	let at: Entity
}

struct ComponentRemoved: ECSEvent {
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
