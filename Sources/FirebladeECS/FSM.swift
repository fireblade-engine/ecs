public protocol EmptyInitializable {
    init()
}

public typealias ComponentInitializable = Component & EmptyInitializable

public protocol ComponentProvider {
    var identifier: AnyHashable { get }
    func getComponent() -> Component
}

// MARK: -

public struct ComponentInstanceProvider {
    private var instance: Component
    
    public init(instance: Component) {
        self.instance = instance
    }
}

extension ComponentInstanceProvider: ComponentProvider {
    public var identifier: AnyHashable {
        ObjectIdentifier(instance)
    }
    
    public func getComponent() -> Component {
        instance
    }
}

// MARK: -

public struct ComponentTypeProvider {
    private var componentType: ComponentInitializable.Type
    public let identifier: AnyHashable
    
    public init<T: ComponentInitializable>(type: T.Type) {
        componentType = type
        identifier = ObjectIdentifier(componentType.self)
    }
}

extension ComponentTypeProvider: ComponentProvider {
    public func getComponent() -> Component {
        componentType.init()
    }
}


// MARK: -

public class ComponentSingletonProvider {
    lazy private var instance: Component = {
        componentType.init()
    }()
    private var componentType: ComponentInitializable.Type
    
    public var identifier: AnyHashable {
        ObjectIdentifier(instance)
    }
    
    public init(type: ComponentInitializable.Type) {
        componentType = type
    }
}

extension ComponentSingletonProvider: ComponentProvider {
    public func getComponent() -> Component {
        instance
    }
}

// MARK: -

public struct DynamicComponentProvider {
    public class Closure {
        let closure: () -> Component
        public init(closure: @escaping () -> Component) {
            self.closure = closure
        }
    }
    private let closure: Closure

    public init(closure: Closure) {
        self.closure = closure
    }
}

extension DynamicComponentProvider: ComponentProvider {
    public var identifier: AnyHashable {
        ObjectIdentifier(closure)
    }
    
    public func getComponent() -> Component {
        closure.closure()
    }
}

// MARK: -

public class EntityState {
    internal var providers = [ComponentIdentifier: ComponentProvider]()
    
    public init() { }
    
    @discardableResult public func add<C: ComponentInitializable>(_ type: C.Type) -> StateComponentMapping {
        StateComponentMapping(creatingState: self, type: type)
    }
    
    public func get<C: ComponentInitializable>(_ type: C.Type) -> ComponentProvider? {
        providers[type.identifier]
    }
    
    public func has<C: ComponentInitializable>(_ type: C.Type) -> Bool {
        providers[type.identifier] != nil
    }
}
// MARK: -

public class StateComponentMapping {
    private var componentType: ComponentInitializable.Type
    private let creatingState: EntityState
    private var provider: ComponentProvider
    
    public init<T: ComponentInitializable>(creatingState: EntityState, type: T.Type) {
        self.creatingState = creatingState
        componentType = type
        provider = ComponentTypeProvider(type: type)
    }
    
    @discardableResult public func withInstance(_ component: Component) -> StateComponentMapping {
        setProvider(ComponentInstanceProvider(instance: component))
        return self
    }
    
    @discardableResult public func withType<T: ComponentInitializable>(_ type: T.Type) -> Self {
        setProvider(ComponentTypeProvider(type: type))
        return self
    }
    
    @discardableResult public func withSingleton<T: ComponentInitializable>(_ type: T.Type?) -> Self {
        setProvider(ComponentSingletonProvider(type: type ?? componentType))
        return self
    }
    
    @discardableResult public func withMethod(_ closure: DynamicComponentProvider.Closure) -> Self {
        setProvider(DynamicComponentProvider(closure: closure))
        return self
    }
    
    @discardableResult public func withProvider(_ provider: ComponentProvider) -> Self {
        setProvider(provider)
        return self
    }
    
    public func add<T: ComponentInitializable>(_ type: T.Type) -> StateComponentMapping {
        creatingState.add(type)
    }
    
    private func setProvider(_ provider: ComponentProvider) {
        self.provider = provider
        creatingState.providers[componentType.identifier] = provider
    }
}

// MARK: -

public class EntityStateMachine {
    private var states: [String: EntityState]
    
    private var currentState: EntityState?
    
    public var entity: Entity
    
    public init(entity: Entity) {
        self.entity = entity
        states = [:]
    }
    
    public func addState(name: String, state: EntityState) -> Self {
        states[name] = state
        return self
    }
    
    public func createState(name: String) -> EntityState {
        let state = EntityState()
        states[name] = state
        return state
    }
    
    public func changeState(name: String) {
        guard let newState = states[name] else {
            fatalError("Entity state '\(name)' doesn't exist")
        }
        
        if newState === currentState {
            return
        }
        var toAdd: [ComponentIdentifier: ComponentProvider]
        if let currentState = currentState {
            toAdd = .init()
            for t in newState.providers {
                toAdd[t.key] = t.value
            }
            
            for t in currentState.providers {
                if let other = toAdd[t.key], let current = currentState.providers[t.key],
                   current.identifier == other.identifier {
                    toAdd[t.key] = nil
                } else {
                    entity.remove(t.key)
                }
            }
        } else {
            toAdd = newState.providers
        }
        
        for t in toAdd {
            guard let component = toAdd[t.key]?.getComponent() else {
                continue
            }
            entity.assign(component)
        }
        currentState = newState
    }
}
