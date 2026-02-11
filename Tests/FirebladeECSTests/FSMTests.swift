//
//  FSMTests.swift
//  FirebladeECSTests
//
//  Created by Igor Kravchenko on 29.09.2020.
//

@testable import FirebladeECS
import Testing

@Suite struct ComponentInstanceProviderTests {
    @Test func providerReturnsTheInstance() {
        let instance = MockComponent(value: .max)
        let provider1 = ComponentInstanceProvider(instance: instance)
        let providedComponent = provider1.getComponent() as? MockComponent
        #expect(providedComponent === instance)
    }

    @Test func providersWithSameInstanceHaveSameIdentifier() {
        let instance = MockComponent(value: .max)
        let provider1 = ComponentInstanceProvider(instance: instance)
        let provider2 = ComponentInstanceProvider(instance: instance)
        #expect(provider1.identifier == provider2.identifier)
    }

    @Test func providersWithDifferentInstanceHaveDifferentIdentifier() {
        let provider1 = ComponentInstanceProvider(instance: MockComponent(value: .max))
        let provider2 = ComponentInstanceProvider(instance: MockComponent(value: .max))
        #expect(provider1.identifier != provider2.identifier)
    }

    class MockComponent: Component, @unchecked Sendable {
        var value: Int

        init(value: Int) {
            self.value = value
        }
    }
}

// MARK: -

@Suite struct ComponentTypeProviderTests {
    @Test func providerReturnsAnInstanceOfType() {
        let provider = ComponentTypeProvider(type: MockComponent.self)
        let component = provider.getComponent() as? MockComponent
        #expect(component != nil)
    }

    @Test func providerReturnsNewInstanceEachTime() {
        let provider = ComponentTypeProvider(type: MockComponent.self)
        let component1 = provider.getComponent() as? MockComponent
        let component2 = provider.getComponent() as? MockComponent
        #expect(component1 !== component2)
    }

    @Test func providersWithSameTypeHaveSameIdentifier() {
        let provider1 = ComponentTypeProvider(type: MockComponent.self)
        let provider2 = ComponentTypeProvider(type: MockComponent.self)
        #expect(provider1.identifier == provider2.identifier)
    }

    @Test func providersWithDifferentTypeHaveDifferentIdentifier() {
        let provider1 = ComponentTypeProvider(type: MockComponent.self)
        let provider2 = ComponentTypeProvider(type: MockComponent2.self)
        #expect(provider1.identifier != provider2.identifier)
    }

    class MockComponent: Component, DefaultInitializable, @unchecked Sendable {
        var value: String

        required init() {
            value = ""
        }
    }

    class MockComponent2: Component, DefaultInitializable, @unchecked Sendable {
        var value: Bool

        required init() {
            value = false
        }
    }
}

// MARK: -

@Suite struct ComponentSingletonProviderTests {
    @Test func providerReturnsAnInstanceOfType() {
        let provider = ComponentSingletonProvider(type: MockComponent.self)
        let component = provider.getComponent() as? MockComponent
        #expect(component != nil)
    }

    @Test func providerReturnsSameInstanceEachTime() {
        let provider = ComponentSingletonProvider(type: MockComponent.self)
        let component1 = provider.getComponent() as? MockComponent
        let component2 = provider.getComponent() as? MockComponent
        #expect(component1 === component2)

    }

    @Test func providersWithSameTypeHaveDifferentIdentifier() {
        let provider1 = ComponentSingletonProvider(type: MockComponent.self)
        let provider2 = ComponentSingletonProvider(type: MockComponent.self)
        #expect(provider1.identifier != provider2.identifier)
    }

    @Test func providersWithDifferentTypeHaveDifferentIdentifier() {
        let provider1 = ComponentSingletonProvider(type: MockComponent.self)
        let provider2 = ComponentSingletonProvider(type: MockComponent2.self)
        #expect(provider1.identifier != provider2.identifier)
    }

    class MockComponent: Component, DefaultInitializable, @unchecked Sendable {
        var value: Int

        required init() {
            value = 0
        }
    }

    class MockComponent2: Component, DefaultInitializable, @unchecked Sendable {
        var value: String

        required init() {
            value = ""
        }
    }
}

// MARK: -

@Suite struct DynamicComponentProviderTests {
    @Test func providerReturnsTheInstance() {
        let instance = MockComponent(value: 0)
        let providerMethod = DynamicComponentProvider.Closure { instance }
        let provider = DynamicComponentProvider(closure: providerMethod)
        let component = provider.getComponent() as? MockComponent
        #expect(component === instance)
    }

    @Test func providersWithSameMethodHaveSameIdentifier() {
        let instance = MockComponent(value: 0)
        let providerMethod = DynamicComponentProvider.Closure { instance }
        let provider1 = DynamicComponentProvider(closure: providerMethod)
        let provider2 = DynamicComponentProvider(closure: providerMethod)
        #expect(provider1.identifier == provider2.identifier)
    }

    @Test func providersWithDifferentMethodsHaveDifferentIdentifier() {
        let instance = MockComponent(value: 0)
        let providerMethod1 = DynamicComponentProvider.Closure { instance }
        let providerMethod2 = DynamicComponentProvider.Closure { instance }
        let provider1 = DynamicComponentProvider(closure: providerMethod1)
        let provider2 = DynamicComponentProvider(closure: providerMethod2)
        #expect(provider1.identifier != provider2.identifier)
    }

    class MockComponent: Component, @unchecked Sendable {
        let value: Int

        init(value: Int) {
            self.value = value
        }
    }
}

// MARK: -

@testable import class FirebladeECS.EntityState

@Suite struct EntityStateTests {
    @Test func addMappingWithNoQualifierCreatesTypeProvider() {
        let state = EntityState()
        state.addMapping(for: MockComponent.self)
        let provider = state.providers[MockComponent.identifier]
        #expect(provider != nil)
        #expect(provider is ComponentTypeProvider)
        #expect(provider?.getComponent() is MockComponent)
    }

    @Test func addMappingWithTypeQualifierCreatesTypeProvider() {
        let state = EntityState()
        state.addMapping(for: MockComponent.self).withType(MockComponent2.self)
        let provider = state.providers[MockComponent.identifier]
        #expect(provider != nil)
        #expect(provider is ComponentTypeProvider)
        #expect(provider?.getComponent() is MockComponent2)
    }

    @Test func addMappingWithInstanceQualifierCreatesInstanceProvider() {
        let state = EntityState()
        let component = MockComponent()
        state.addMapping(for: MockComponent.self).withInstance(component)
        let provider = state.providers[MockComponent.identifier]
        #expect(provider is ComponentInstanceProvider)
        #expect(provider?.getComponent() === component)
    }

    @Test func addMappingWithSingletonQualifierCreatesSingletonProvider() {
        let state = EntityState()
        state.addMapping(for: MockComponent.self).withSingleton(MockComponent.self)
        let  provider = state.providers[MockComponent.identifier]
        #expect(provider is ComponentSingletonProvider)
        #expect(provider?.getComponent() is MockComponent)
    }

    @Test func addMappingWithMethodQualifierCreatesDynamicProvider() {
        let state = EntityState()
        let dynamickProvider = DynamicComponentProvider.Closure {
            MockComponent()
        }

        state.addMapping(for: MockComponent.self).withMethod(dynamickProvider)
        let provider = state.providers[MockComponent.identifier]
        #expect(provider != nil)
        #expect(provider is DynamicComponentProvider<MockComponent>)
        #expect(provider?.getComponent() is MockComponent)
    }

    @Test func providerForTypeReturnsTypeProviderByDefault() {
        let state = EntityState()
        state.addMapping(for: MockComponent.self)
        let provider = state.provider(for: MockComponent.self)
        #expect(provider != nil)
        #expect(provider is ComponentTypeProvider)
    }

    @Test func providerForTypeReturnsInstanceProvider() {
        let state = EntityState()
        let component = MockComponent()
        state.addMapping(for: MockComponent.self).withInstance(component)
        let provider = state.provider(for: MockComponent.self)
        #expect(provider != nil)
        #expect(provider is ComponentInstanceProvider)
    }

    @Test func providerForTypeReturnsSingletonProvider() {
        let state = EntityState()
        state.addMapping(for: MockComponent.self).withSingleton(MockComponent.self)
        let provider = state.provider(for: MockComponent.self)
        #expect(provider != nil)
        #expect(provider is ComponentSingletonProvider)
    }

    @Test func providerForTypeReturnsDynamicProvider() {
        let state = EntityState()
        state.addMapping(for: MockComponent.self).withMethod(.init { MockComponent() })
        let provider = state.provider(for: MockComponent.self)
        #expect(provider != nil)
        #expect(provider is DynamicComponentProvider<MockComponent>)
    }

    @Test func providerForTypeReturnsTypeProvider() {
        let state = EntityState()
        state.addMapping(for: MockComponent.self).withType(MockComponent.self)
        let provider = state.provider(for: MockComponent.self)
        #expect(provider != nil)
        #expect(provider is ComponentTypeProvider)
    }

    @Test func providerForTypeReturnsPassedProvider() {
        let state = EntityState()
        let singletonProvider = ComponentSingletonProvider(type: MockComponent.self)
        state.addMapping(for: MockComponent.self).withProvider(singletonProvider)
        let provider = state.provider(for: MockComponent.self) as? ComponentSingletonProvider
        #expect(provider != nil)
        #expect(provider === singletonProvider)
    }

    @Test func hasProviderReturnsFalseForNotCreatedProvider() {
        let state = EntityState()
        #expect(!state.hasProvider(for: MockComponent.self))
    }

    @Test func hasProviderReturnsTrueForCreatedProvider() {
        let state = EntityState()
        state.addMapping(for: MockComponent.self)
        #expect(state.hasProvider(for: MockComponent.self))
    }

    @Test func addInstanceCreatesMappingAndSetsInstanceProviderForInstanceType() {
        let state = EntityState()
        let component = MockComponent()
        state.addInstance(component)
        #expect(state.provider(for: MockComponent.self) is ComponentInstanceProvider)
        #expect(state.provider(for: MockComponent.self)?.getComponent() === component)
    }

    @Test func addTypeCreatesMappingAndSetsTypeProviderForType() {
        let state = EntityState()
        state.addType(MockComponent.self)
        #expect(state.provider(for: MockComponent.self) is ComponentTypeProvider)
        #expect(state.provider(for: MockComponent.self)?.getComponent() != nil)
        #expect(state.provider(for: MockComponent.self)?.getComponent() is MockComponent)
    }

    @Test func addSingletonCreatesMappingAndSetsSingletonProviderForType() {
        let state = EntityState()
        state.addSingleton(MockComponent.self)
        #expect(state.provider(for: MockComponent.self) is ComponentSingletonProvider)
        #expect(state.provider(for: MockComponent.self)?.getComponent() != nil)
        #expect(state.provider(for: MockComponent.self)?.getComponent() is MockComponent)
    }

    @Test func addMethodCreatesMappingAndSetsDynamicProviderForType() {
        let state = EntityState()
        let component = MockComponent()
        state.addMethod(closure: .init { component })
        #expect(state.provider(for: MockComponent.self) is DynamicComponentProvider<MockComponent>)
        #expect(state.provider(for: MockComponent.self)?.getComponent() === component)
    }

    @Test func addProviderCreatesMappingAndSetsProvider() {
        let state = EntityState()
        let provider = ComponentSingletonProvider(type: MockComponent.self)
        state.addProvider(type: MockComponent.self, provider: provider)
        #expect(state.provider(for: MockComponent.self) is ComponentSingletonProvider)
        #expect(state.provider(for: MockComponent.self) != nil)
    }

    class MockComponent: ComponentInitializable, @unchecked Sendable {
        let value: Int

        init(value: Int) {
            self.value = value
        }

        required init() {
            value = 0
        }
    }

    class MockComponent2: MockComponent, @unchecked Sendable {}
}

// MARK: -

@Suite struct EntityStateMachineTests {
    @Test func enterStateAddsStatesComponents() {
        let nexus = Nexus()
        let entity = nexus.createEntity()
        let fsm = EntityStateMachine<String>(entity: entity)
        let state = EntityState()
        let component = MockComponent()
        state.addMapping(for: MockComponent.self).withInstance(component)
        fsm.addState(name: "test", state: state)
        fsm.changeState(name: "test")
        #expect(entity.get(component: MockComponent.self) === component)
    }

    @Test func enterSecondStateAddsSecondStatesComponents() {
        let nexus = Nexus()
        let entity = nexus.createEntity()
        let fsm = EntityStateMachine<String>(entity: entity)
        let state1 = EntityState()
        let component1 = MockComponent()
        state1.addMapping(for: MockComponent.self).withInstance(component1)
        fsm.addState(name: "test1", state: state1)

        let state2 = EntityState()
        let component2 = MockComponent2()
        state2.addMapping(for: MockComponent2.self).withInstance(component2)
        fsm.addState(name: "test2", state: state2)
        fsm.changeState(name: "test2")

        #expect(entity.get(component: MockComponent2.self) === component2)
    }

    @Test func enterSecondStateRemovesFirstStatesComponents() {
        let nexus = Nexus()
        let entity = nexus.createEntity()
        let fsm = EntityStateMachine<String>(entity: entity)
        let state1 = EntityState()
        let component1 = MockComponent()
        state1.addMapping(for: MockComponent.self).withInstance(component1)
        fsm.addState(name: "test1", state: state1)
        fsm.changeState(name: "test1")

        let state2 = EntityState()
        let component2 = MockComponent2()
        state2.addMapping(for: MockComponent2.self).withInstance(component2)
        fsm.addState(name: "test2", state: state2)
        fsm.changeState(name: "test2")

        #expect(!entity.has(MockComponent.self))
    }

    @Test func enterSecondStateDoesNotRemoveOverlappingComponents() {
        let nexus = Nexus()
        let entity = nexus.createEntity()
        let fsm = EntityStateMachine<String>(entity: entity)
        class EventDelegate: NexusEventDelegate, @unchecked Sendable {
            init() {}

            func nexusEvent(_ event: NexusEvent) {
                if event is ComponentRemoved {
                    Issue.record("Component was removed when it shouldn't have been.")
                }
            }

            func nexusNonFatalError(_ message: String) {}
        }
        let delgate = EventDelegate()
        nexus.delegate = delgate
        let state1 = EntityState()
        let component1 = MockComponent()
        state1.addMapping(for: MockComponent.self).withInstance(component1)
        fsm.addState(name: "test1", state: state1)
        fsm.changeState(name: "test1")

        let state2 = EntityState()
        let component2 = MockComponent2()
        state2.addMapping(for: MockComponent.self).withInstance(component1)
        state2.addMapping(for: MockComponent2.self).withInstance(component2)
        fsm.addState(name: "test2", state: state2)
        fsm.changeState(name: "test2")

        #expect(entity.get(component: MockComponent.self) === component1)
    }

    @Test func enterSecondStateRemovesDifferentComponentsOfSameType() {
        let nexus = Nexus()
        let entity = nexus.createEntity()
        let fsm = EntityStateMachine<String>(entity: entity)
        let state1 = EntityState()
        let component1 = MockComponent()
        state1.addMapping(for: MockComponent.self).withInstance(component1)
        fsm.addState(name: "test1", state: state1)
        fsm.changeState(name: "test1")

        let state2 = EntityState()
        let component3 = MockComponent()
        let component2 = MockComponent2()
        state2.addMapping(for: MockComponent.self).withInstance(component3)
        state2.addMapping(for: MockComponent2.self).withInstance(component2)
        fsm.addState(name: "test2", state: state2)
        fsm.changeState(name: "test2")

        #expect(entity.get(component: MockComponent.self) === component3)
    }

    @Test func createStateAddsState() {
        let nexus = Nexus()
        let entity = nexus.createEntity()
        let fsm = EntityStateMachine<String>(entity: entity)
        let state = fsm.createState(name: "test")
        let component = MockComponent()
        state.addMapping(for: MockComponent.self).withInstance(component)
        fsm.changeState(name: "test")
        #expect(entity.get(component: MockComponent.self) === component)
    }

    @Test func createStateDoesNotChangeState() {
        let nexus = Nexus()
        let entity = nexus.createEntity()
        let fsm = EntityStateMachine<String>(entity: entity)
        let state = fsm.createState(name: "test")
        let component = MockComponent()
        state.addMapping(for: MockComponent.self).withInstance(component)
        #expect(entity.get(component: MockComponent.self) == nil)
    }

    @Test func callChangeStateWithSameNameLeavesEntityComponentsIntact() {
        let nexus = Nexus()
        let entity = nexus.createEntity()
        let fsm = EntityStateMachine<String>(entity: entity)
        let state = fsm.createState(name: "test")
        let component1 = MockComponent()
        let component2 = MockComponent2()
        state.addMapping(for: MockComponent.self).withInstance(component1)
        state.addMapping(for: MockComponent2.self).withInstance(component2)
        let name = "test"
        fsm.changeState(name: name)
        #expect(entity.get(component: MockComponent.self) === component1)
        #expect(entity.get(component: MockComponent2.self) === component2)
        fsm.changeState(name: name)
        #expect(entity.get(component: MockComponent.self) === component1)
        #expect(entity.get(component: MockComponent2.self) === component2)
    }

    @Test func getsDeinitedWhileBeingStronglyReferencedByComponentAssignedToEntity() {
        class Marker: Component, @unchecked Sendable {
            let fsm: EntityStateMachine<String>
            init(fsm: EntityStateMachine<String>) {
                self.fsm = fsm
            }
        }

        let nexus = Nexus()
        var entity: Entity? = nexus.createEntity()
        var markerComponent: Marker? = Marker(fsm: EntityStateMachine<String>(entity: entity!))
        entity?.assign(markerComponent!)
        weak var weakMarker = markerComponent
        weak var weakFsm = markerComponent?.fsm
        nexus.destroy(entity: entity!)
        entity = nexus.createEntity()
        markerComponent = .init(fsm: .init(entity: entity!))
        
        withExtendedLifetime(weakMarker) { _ in }
        withExtendedLifetime(weakFsm) { _ in }
        
        #expect(weakMarker == nil)
        #expect(weakFsm == nil)
    }

    class MockComponent: ComponentInitializable, @unchecked Sendable {
        let value: Int

        init(value: Int) {
            self.value = value
        }

        required init() {
            value = 0
        }
    }

    class MockComponent2: ComponentInitializable, @unchecked Sendable {
        let value: String

        init(value: String) {
            self.value = value
        }

        required init() {
            self.value = ""
        }
    }
}

// MARK: -

@Suite struct StateComponentMappingTests {
    @Test func testAddReturnsSameMappingForSameComponentType() {
        let state = EntityState()
        let mapping = state.addMapping(for: MockComponent.self)
        #expect(mapping !== mapping.add(MockComponent.self))
    }

    @Test func testAddReturnsSameMappingForDifferentComponentTypes() {
        let state = EntityState()
        let mapping = state.addMapping(for: MockComponent.self)
        #expect(mapping !== mapping.add(MockComponent2.self))
    }

    @Test func testAddAddsProviderToState() {
        let state = EntityState()
        let mapping = state.addMapping(for: MockComponent.self)
        _ = mapping.add(MockComponent2.self)
        #expect(state.hasProvider(for: MockComponent.self))
    }

    class MockComponent: ComponentInitializable, @unchecked Sendable {
        let value: Int

        init(value: Int) {
            self.value = value
        }

        required init() {
            value = 0
        }
    }

    class MockComponent2: ComponentInitializable, @unchecked Sendable {
        let value: String

        init(value: String) {
            self.value = value
        }

        required init() {
            self.value = ""
        }
    }
}