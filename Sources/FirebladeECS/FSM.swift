//
//  FSM.swift
//  FirebladeECS
//
//  Created by Igor Kravchenko on 29.09.2020.
//

/// Requires initializer with default values.
/// In case of component - makes sure it can be instantiated by component provider
public protocol DefaultInitializable {
    init()
}

public typealias ComponentInitializable = Component & DefaultInitializable

/// This is the Interface for component providers. Component providers are used to supply components
/// for states within an EntityStateMachine. FirebladeECS includes three standard component providers,
/// ComponentTypeProvider, ComponentInstanceProvider and ComponentSingletonProvider. Developers
/// may wish to create more.
public protocol ComponentProvider: Sendable {
    // Returns an identifier that is used to determine whether two component providers will
    // return the equivalent components.

    // If an entity is changing state and the state it is leaving and the state is
    // entering have components of the same type, then the identifiers of the component
    // provders are compared. If the two identifiers are the same then the component
    // is not removed. If they are different, the component from the old state is removed
    // and a component for the new state is added.

    /// - Returns: struct/class instance that conforms to Hashable protocol
    var identifier: AnyHashable { get }

    /// Used to request a component from the provider.
    /// - Returns: A component for use in the state that the entity is entering
    func getComponent() -> Component
}

// MARK: -

/// This component provider always returns the same instance of the component. The instance
/// is passed to the provider at initialisation.
public final class ComponentInstanceProvider: @unchecked Sendable {
    private var instance: Component

    /// Initializer
    /// - Parameter instance: The instance to return whenever a component is requested.
    public init(instance: Component) {
        self.instance = instance
    }
}

extension ComponentInstanceProvider: ComponentProvider {
    /// Used to compare this provider with others. Any provider that returns the same component
    /// instance will be regarded as equivalent.
    /// - Returns:ObjectIdentifier of instance
    public var identifier: AnyHashable {
        ObjectIdentifier(instance)
    }

    /// Used to request a component from this provider
    /// - Returns: The instance
    public func getComponent() -> Component {
        instance
    }
}

// MARK: -

/// This component provider always returns a new instance of a component. An instance
/// is created when requested and is of the type passed in to the initializer.
public final class ComponentTypeProvider: @unchecked Sendable {
    private var componentType: ComponentInitializable.Type

    /// Used to compare this provider with others. Any ComponentTypeProvider that returns
    /// the same type will be regarded as equivalent.
    /// - Returns:ObjectIdentifier of the type of the instances created
    public let identifier: AnyHashable

    /// Initializer
    /// - Parameter type: The type of the instances to be created
    public init(type: ComponentInitializable.Type) {
        componentType = type
        identifier = ObjectIdentifier(componentType.self)
    }
}

extension ComponentTypeProvider: ComponentProvider {
    /// Used to request a component from this provider
    /// - Returns: A new instance of the type provided in the initializer
    public func getComponent() -> Component {
        componentType.init()
    }
}

// MARK: -

/// This component provider always returns the same instance of the component. The instance
/// is created when first required and is of the type passed in to the initializer.
public final class ComponentSingletonProvider: @unchecked Sendable {
    private lazy var instance: Component = componentType.init()

    private var componentType: ComponentInitializable.Type

    /// Initializer
    /// - Parameter type: The type of the single instance
    public init(type: ComponentInitializable.Type) {
        componentType = type
    }
}

extension ComponentSingletonProvider: ComponentProvider {
    /// Used to compare this provider with others. Any provider that returns the same single
    /// instance will be regarded as equivalent.
    /// - Returns: ObjectIdentifier of the single instance
    public var identifier: AnyHashable {
        ObjectIdentifier(instance)
    }

    /// Used to request a component from this provider
    /// - Returns: The single instance
    public func getComponent() -> Component {
        instance
    }
}

// MARK: -

/// This component provider calls a function to get the component instance. The function must
/// return a single component of the appropriate type.
public final class DynamicComponentProvider<C: Component>: @unchecked Sendable {
    /// Wrapper for closure to make it hashable via ObjectIdentifier
    public final class Closure: @unchecked Sendable {
        let provideComponent: @Sendable () -> C

        /// Initializer
        /// - Parameter provideComponent: Swift closure returning component of the appropriate type
        public init(provideComponent: @escaping @Sendable () -> C) {
            self.provideComponent = provideComponent
        }
    }

    private let closure: Closure

    /// Initializer
    /// - Parameter closure: Instance of Closure class. A wrapper around closure that will
    /// return the component instance when called.
    public init(closure: Closure) {
        self.closure = closure
    }
}

extension DynamicComponentProvider: ComponentProvider {
    /// Used to compare this provider with others. Any provider that uses the function or method
    /// closure to provide the instance is regarded as equivalent.
    /// - Returns: ObjectIdentifier of closure
    public var identifier: AnyHashable {
        ObjectIdentifier(closure)
    }

    /// Used to request a component from this provider
    /// - Returns: The instance returned by calling the closure
    public func getComponent() -> Component {
        closure.provideComponent()
    }
}

// MARK: -

/// Represents a state for an EntityStateMachine. The state contains any number of ComponentProviders which
/// are used to add components to the entity when this state is entered.
public class EntityState: @unchecked Sendable {
    /// A dictionary mapping component identifiers to their providers.
    var providers = [ComponentIdentifier: ComponentProvider]()

    /// Creates a new, empty entity state.
    public init() {}

    /// Add a new StateComponentMapping to this state. The mapping is a utility class that is used to
    /// map a component type to the provider that provides the component.
    /// - Parameter type: The type of component to be mapped
    /// - Returns: The component mapping to use when setting the provider for the component
    @discardableResult
    public func addMapping(for type: ComponentInitializable.Type) -> StateComponentMapping {
        StateComponentMapping(creatingState: self, type: type)
    }

    /// Get the ComponentProvider for a particular component type.
    /// - Parameter type: The type of component to get the provider for
    /// - Returns: The ComponentProvider
    public func provider(for type: ComponentInitializable.Type) -> ComponentProvider? {
        providers[type.identifier]
    }

    /// To determine whether this state has a provider for a specific component type.
    /// - Parameter type: The type of component to look for a provider for
    /// - Returns: true if there is a provider for the given type, false otherwise
    public func hasProvider(for type: ComponentInitializable.Type) -> Bool {
        providers[type.identifier] != nil
    }
}

/// This extension provides ergonomic way to add component mapping and component
/// provider at once
extension EntityState {
    /// Creates a mapping for the component type to a specific component instance.
    /// ComponentInstanceProvider is used for the mapping.
    /// - Parameter component: The component instance to use for the mapping
    /// - Returns: This EntityState, so more modifications can be applied
    @discardableResult
    @inline(__always)
    public func addInstance<C: ComponentInitializable>(_ component: C) -> Self {
        addMapping(for: C.self).withInstance(component)
        return self
    }

    /// Creates a mapping for the component type to new instances of the provided type.
    /// A ComponentTypeProvider is used for the mapping.
    /// - Parameter type: The type of components to be created by this mapping
    /// - Returns: This EntityState, so more modifications can be applied
    @inline(__always)
    @discardableResult
    public func addType(_ type: ComponentInitializable.Type) -> Self {
        addMapping(for: type).withType(type)
        return self
    }

    /// Creates a mapping for the component type to a single instance of the provided type.
    /// The instance is not created until it is first requested.
    /// A ComponentSingletonProvider is used for the mapping.
    /// - Parameter type: The type of the single instance to be created.
    /// - Returns: This EntityState, so more modifications can be applied
    @inline(__always)
    @discardableResult
    public func addSingleton(_ type: ComponentInitializable.Type) -> Self {
        addMapping(for: type).withSingleton(type)
        return self
    }

    /// Creates a mapping for the component type to a method call.
    /// A DynamicComponentProvider is used for the mapping.
    /// - Parameter closure: The Closure instance to return the component instance
    /// - Returns: This EntityState, so more modifications can be applied
    @inline(__always)
    @discardableResult
    public func addMethod<C: ComponentInitializable>(closure: DynamicComponentProvider<C>.Closure) -> Self {
        addMapping(for: C.self).withMethod(closure)
        return self
    }

    /// Creates a mapping for the component type to any ComponentProvider.
    /// - Parameter type: The type of component to be mapped
    /// - Parameter provider: The component provider to use.
    /// - Returns: This EntityState, so more modifications can be applied.
    @inline(__always)
    @discardableResult
    public func addProvider(type: (some ComponentInitializable).Type, provider: ComponentProvider) -> Self {
        addMapping(for: type).withProvider(provider)
        return self
    }
}

// MARK: -

/// Used by the EntityState class to create the mappings of components to providers via a fluent interface.
public class StateComponentMapping: @unchecked Sendable {
    private var componentType: ComponentInitializable.Type
    private let creatingState: EntityState
    private var provider: ComponentProvider

    /// Used internally, the initializer creates a component mapping. The constructor
    /// creates a ComponentTypeProvider as the default mapping, which will be replaced
    /// by more specific mappings if other methods are called.
    /// - Parameter creatingState: The EntityState that the mapping will belong to
    /// - Parameter type: The component type for the mapping
    init(creatingState: EntityState, type: ComponentInitializable.Type) {
        self.creatingState = creatingState
        componentType = type
        provider = ComponentTypeProvider(type: type)
        setProvider(provider)
    }

    /// Creates a mapping for the component type to a specific component instance. A
    /// ComponentInstanceProvider is used for the mapping.
    /// - Parameter component: The component instance to use for the mapping
    /// - Returns: This ComponentMapping, so more modifications can be applied
    @discardableResult
    public func withInstance(_ component: Component) -> StateComponentMapping {
        setProvider(ComponentInstanceProvider(instance: component))
        return self
    }

    /// Creates a mapping for the component type to new instances of the provided type.
    /// The type should be the same as or extend the type for this mapping. A ComponentTypeProvider
    /// is used for the mapping.
    /// - Parameter type: The type of components to be created by this mapping
    /// - Returns: This ComponentMapping, so more modifications can be applied
    @discardableResult
    public func withType(_ type: ComponentInitializable.Type) -> Self {
        setProvider(ComponentTypeProvider(type: type))
        return self
    }

    /// Creates a mapping for the component type to a single instance of the provided type.
    /// The instance is not created until it is first requested. The type should be the same
    /// as or extend the type for this mapping. A ComponentSingletonProvider is used for
    /// the mapping.
    /// - Parameter type: The type of the single instance to be created. If omitted, the type of the
    /// mapping is used.
    /// - Returns: This ComponentMapping, so more modifications can be applied
    @discardableResult
    public func withSingleton(_ type: ComponentInitializable.Type?) -> Self {
        setProvider(ComponentSingletonProvider(type: type ?? componentType))
        return self
    }

    /// Creates a mapping for the component type to a method call. A
    /// DynamicComponentProvider is used for the mapping.
    /// - Parameter closure: The Closure instance to return the component instance
    /// - Returns: This ComponentMapping, so more modifications can be applied
    @discardableResult
    public func withMethod(_ closure: DynamicComponentProvider<some Component>.Closure) -> Self {
        setProvider(DynamicComponentProvider(closure: closure))
        return self
    }

    /// Creates a mapping for the component type to any ComponentProvider.
    /// - Parameter provider: The component provider to use.
    /// - Returns: This ComponentMapping, so more modifications can be applied.
    @discardableResult
    public func withProvider(_ provider: ComponentProvider) -> Self {
        setProvider(provider)
        return self
    }

    /// Maps through to the addMapping method of the EntityState that this mapping belongs to
    /// so that a fluent interface can be used when configuring entity states.
    /// - Parameter type: The type of component to add a mapping to the state for
    /// - Returns: The new ComponentMapping for that type
    @discardableResult
    public func add(_ type: ComponentInitializable.Type) -> StateComponentMapping {
        creatingState.addMapping(for: type)
    }

    private func setProvider(_ provider: ComponentProvider) {
        self.provider = provider
        creatingState.providers[componentType.identifier] = provider
    }
}

// MARK: -

/// This is a state machine for an entity. The state machine manages a set of states,
/// each of which has a set of component providers. When the state machine changes the state, it removes
/// components associated with the previous state and adds components associated with the new state.
/// - Parameter StateIdentifier: Generic hashable state name type
public class EntityStateMachine<StateIdentifier: Hashable>: @unchecked Sendable {
    private var states: [StateIdentifier: EntityState]

    /// The current state of the state machine.
    private var currentState: EntityState?

    /// The entity whose state machine this is
    public var entity: Entity

    /// Initializer. Creates an EntityStateMachine.
    /// - Parameter entity: The entity to manage state for.
    public init(entity: Entity) {
        self.entity = entity
        states = [:]
    }

    /// Add a state to this state machine.
    /// - Parameter name: The name of this state - used to identify it later in the changeState method call.
    /// - Parameter state: The state.
    /// - Returns: This state machine, so methods can be chained.
    @discardableResult
    public func addState(name: StateIdentifier, state: EntityState) -> Self {
        states[name] = state
        return self
    }

    /// Create a new state in this state machine.
    /// - Parameter name: The name of the new state - used to identify it later in the changeState method call.
    /// - Returns: The new EntityState object that is the state. This will need to be configured with
    /// the appropriate component providers.
    public func createState(name: StateIdentifier) -> EntityState {
        let state = EntityState()
        states[name] = state
        return state
    }

    /// Change to a new state. The components from the old state will be removed and the components
    /// for the new state will be added.
    /// - Parameter name: The name of the state to change to.
    public func changeState(name: StateIdentifier) {
        guard let newState = states[name] else {
            assertionFailure("Entity state '\(name)' doesn't exist")
            return
        }

        if newState === currentState {
            return
        }

        var toAdd: [ComponentIdentifier: ComponentProvider]

        if let currentState {
            toAdd = .init()
            for (identifier, provider) in newState.providers {
                toAdd[identifier] = provider
            }

            for (identifier, _) in currentState.providers {
                if let other = toAdd[identifier], let current = currentState.providers[identifier],
                   current.identifier == other.identifier
                {
                    toAdd[identifier] = nil
                } else {
                    entity.remove(identifier)
                }
            }
        } else {
            toAdd = newState.providers
        }

        for (_, provider) in toAdd {
            entity.assign(provider.getComponent())
        }
        currentState = newState
    }
}
