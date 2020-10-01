import FirebladeECS
import XCTest

class ComponentInstanceProviderTests: XCTestCase {
    func testProviderReturnsTheInstance() {
        let instance = MockComponent(value: .max)
        let provider1 = ComponentInstanceProvider(instance: instance)
        let providedComponent = provider1.getComponent() as? MockComponent
        XCTAssertTrue(providedComponent === instance)
    }

    func testProvidersWithSameInstanceHaveSameIdentifier() {
        let instance = MockComponent(value: .max)
        let provider1 = ComponentInstanceProvider(instance: instance)
        let provider2 = ComponentInstanceProvider(instance: instance)
        XCTAssertEqual(provider1.identifier, provider2.identifier)
    }

    func testProvidersWithDifferentInstanceHaveDifferentIdentifier() {
        let provider1 = ComponentInstanceProvider(instance: MockComponent(value: .max))
        let provider2 = ComponentInstanceProvider(instance: MockComponent(value: .max))
        XCTAssertNotEqual(provider1.identifier, provider2.identifier)
    }

    class MockComponent: Component {
        var value: Int

        init(value: Int) {
            self.value = value
        }
    }
}

class ComponentTypeProviderTests: XCTestCase {
    func testProviderReturnsAnInstanceOfType() {
        let provider = ComponentTypeProvider(type: MockComponent.self)
        let component = provider.getComponent() as? MockComponent
        XCTAssertNotNil(component)
    }

    func testProviderReturnsNewInstanceEachTime() {
        let provider = ComponentTypeProvider(type: MockComponent.self)
        let component1 = provider.getComponent() as? MockComponent
        let component2 = provider.getComponent() as? MockComponent
        XCTAssertFalse(component1 === component2)
    }

    func testProvidersWithSameTypeHaveSameIdentifier() {
        let provider1 = ComponentTypeProvider(type: MockComponent.self)
        let provider2 = ComponentTypeProvider(type: MockComponent.self)
        XCTAssertEqual(provider1.identifier, provider2.identifier)
    }

    func testProvidersWithDifferentTypeHaveDifferentIdentifier() {
        let provider1 = ComponentTypeProvider(type: MockComponent.self)
        let provider2 = ComponentTypeProvider(type: MockComponent2.self)
        XCTAssertNotEqual(provider1.identifier, provider2.identifier)
    }

    class MockComponent: Component, EmptyInitializable {
        var value: String

        required init() {
            self.value = ""
        }
    }

    class MockComponent2: Component, EmptyInitializable {
        var value: Bool

        required init() {
            self.value = false
        }
    }
}

class ComponentSingletonProviderTests: XCTestCase {
    func testProviderReturnsAnInstanceOfType() {
        let provider = ComponentSingletonProvider(type: MockComponent.self)
        let component = provider.getComponent() as? MockComponent
        XCTAssertNotNil(component)
    }

    func testProviderReturnsSameInstanceEachTime() {
        let provider = ComponentSingletonProvider(type: MockComponent.self)
        let component1 = provider.getComponent() as? MockComponent
        let component2 = provider.getComponent() as? MockComponent
        XCTAssertTrue(component1 === component2)

    }

    func testProvidersWithSameTypeHaveDifferentIdentifier() {
        let provider1 = ComponentSingletonProvider(type: MockComponent.self)
        let provider2 = ComponentSingletonProvider(type: MockComponent.self)
        XCTAssertNotEqual(provider1.identifier, provider2.identifier)
    }

    func testProvidersWithDifferentTypeHaveDifferentIdentifier() {
        let provider1 = ComponentSingletonProvider(type: MockComponent.self)
        let provider2 = ComponentSingletonProvider(type: MockComponent2.self)
        XCTAssertNotEqual(provider1.identifier, provider2.identifier)
    }

    class MockComponent: Component, EmptyInitializable {
        var value: Int

        required init() {
            self.value = 0
        }
    }

    class MockComponent2: Component, EmptyInitializable {
        var value: String

        required init() {
            self.value = ""
        }
    }
}

class DynamicComponentProviderTests: XCTestCase {
    func testProviderReturnsTheInstance() {
        let instance = MockComponent(value: 0)
        let providerMethod = DynamicComponentProvider.Closure { instance }
        let provider = DynamicComponentProvider(closure: providerMethod)
        let component = provider.getComponent() as? MockComponent
        XCTAssertTrue(component === instance)
    }

    func testProvidersWithSameMethodHaveSameIdentifier() {
        let instance = MockComponent(value: 0)
        let providerMethod = DynamicComponentProvider.Closure { instance }
        let provider1 = DynamicComponentProvider(closure: providerMethod)
        let provider2 = DynamicComponentProvider(closure: providerMethod)
        XCTAssertEqual(provider1.identifier, provider2.identifier)
    }

    func testProvidersWithDifferentMethodsHaveDifferentIdentifier() {
        let instance = MockComponent(value: 0)
        let providerMethod1 = DynamicComponentProvider.Closure { instance }
        let providerMethod2 = DynamicComponentProvider.Closure { instance }
        let provider1 = DynamicComponentProvider(closure: providerMethod1)
        let provider2 = DynamicComponentProvider(closure: providerMethod2)
        XCTAssertNotEqual(provider1.identifier, provider2.identifier)
    }

    class MockComponent: Component {
        let value: Int

        init(value: Int) {
            self.value = value
        }
    }
}

@testable import class FirebladeECS.EntityState

class EntityStateTests: XCTestCase {
    private var state = EntityState()

    override func setUp() {
        state = EntityState()
    }

    override func tearDown() {
        state = EntityState()
    }

    func testAddWithNoQualifierCreatesTypeProvider() {
        state.add(MockComponent.self)
        let provider = state.providers[MockComponent.identifier]
        XCTAssertNotNil(provider)
        XCTAssertTrue(provider is ComponentTypeProvider?)
        XCTAssertTrue(provider?.getComponent() is MockComponent?)
    }

    func testAddWithTypeQualifierCreatesTypeProvider() {
        state.add(MockComponent.self).withType(MockComponent2.self)
        let provider = state.providers[MockComponent.identifier]
        XCTAssertNotNil(provider)
        XCTAssertTrue(provider is ComponentTypeProvider?)
        XCTAssertTrue(provider?.getComponent() is MockComponent2?)
    }

    func testAddWithInstanceQualifierCreatesInstanceProvider() {
        let component = MockComponent()
        state.add(MockComponent.self).withInstance(component)
        let provider = state.providers[MockComponent.identifier]
        XCTAssertTrue(provider is ComponentInstanceProvider?)
        XCTAssertTrue(provider?.getComponent() === component)
    }

    func testAddWithSingletonQualifierCreatesSingletonProvider() {
        state.add(MockComponent.self).withSingleton(MockComponent.self)
        let  provider = state.providers[MockComponent.identifier]
        XCTAssertTrue(provider is ComponentSingletonProvider?)
        XCTAssertTrue(provider?.getComponent() is MockComponent?)
    }

    func testAddWithMethodQualifierCreatesDynamicProvider() {
        let dynamickProvider = DynamicComponentProvider.Closure {
            MockComponent()
        }

        state.add(MockComponent.self).withMethod(dynamickProvider)
        let provider = state.providers[MockComponent.identifier]
        XCTAssertNotNil(provider)
        XCTAssertTrue(provider is DynamicComponentProvider?)
        XCTAssertTrue(provider?.getComponent() is MockComponent)
    }

    func testGetReturnsTypeProviderByDefault() {
        state.add(MockComponent.self)
        let provider = state.get(MockComponent.self)
        XCTAssertNotNil(provider)
        XCTAssertTrue(provider is ComponentTypeProvider?)
    }

    func testGetReturnsInstanceProvider() {
        let component = MockComponent()
        state.add(MockComponent.self).withInstance(component)
        let provider = state.get(MockComponent.self)
        XCTAssertNotNil(provider)
        XCTAssertTrue(provider is ComponentInstanceProvider?)
    }

    func testGetReturnsSingletonProvider() {
        state.add(MockComponent.self).withSingleton(MockComponent.self)
        let provider = state.get(MockComponent.self)
        XCTAssertNotNil(provider)
        XCTAssertTrue(provider is ComponentSingletonProvider?)
    }

    func testGetReturnsDynamicProvider() {
        state.add(MockComponent.self).withMethod(.init { MockComponent() })
        let provider = state.get(MockComponent.self)
        XCTAssertNotNil(provider)
        XCTAssertTrue(provider is DynamicComponentProvider?)
    }

    func testGetReturnsTypeProvider() {
        state.add(MockComponent.self).withType(MockComponent.self)
        let provider = state.get(MockComponent.self)
        XCTAssertNotNil(provider)
        XCTAssertTrue(provider is ComponentTypeProvider?)
    }

    func testGetReturnsPassedProvider() {
        let singletonProvider = ComponentSingletonProvider(type: MockComponent.self)
        state.add(MockComponent.self).withProvider(singletonProvider)
        let provider = state.get(MockComponent.self) as? ComponentSingletonProvider
        XCTAssertNotNil(provider)
        XCTAssertTrue(provider === singletonProvider)
    }

    class MockComponent: ComponentInitializable {
        let value: Int

        init(value: Int) {
            self.value = value
        }

        required init() {
            self.value = 0
        }
    }

    class MockComponent2: MockComponent {}
}

class EntityStateMachineTests: XCTestCase {
    var nexus = Nexus()
    var fsm = EntityStateMachine<String>(entity: .init(nexus: .init(), id: .invalid))
    var entity = Entity(nexus: .init(), id: .init(rawValue: 1))

    override func setUp() {
        nexus = Nexus()
        entity = nexus.createEntity()
        fsm = EntityStateMachine(entity: entity)
    }

    func testEnterStateAddsStatesComponents() {
        let state = EntityState()
        let component = MockComponent()
        state.add(MockComponent.self).withInstance(component)
        fsm.addState(name: "test", state: state)
        fsm.changeState(name: "test")
        XCTAssertTrue(entity.get(component: MockComponent.self) === component)
    }

    func testEnterSecondStateAddsSecondStatesComponents() {
        let state1 = EntityState()
        let component1 = MockComponent()
        state1.add(MockComponent.self).withInstance(component1)
        fsm.addState(name: "test1", state: state1)

        let state2 = EntityState()
        let component2 = MockComponent2()
        state2.add(MockComponent2.self).withInstance(component2)
        fsm.addState(name: "test2", state: state2)
        fsm.changeState(name: "test2")

        XCTAssertTrue(entity.get(component: MockComponent2.self) === component2)
    }

    func testEnterSecondStateRemovesFirstStatesComponents() {
        let state1 = EntityState()
        let component1 = MockComponent()
        state1.add(MockComponent.self).withInstance(component1)
        fsm.addState(name: "test1", state: state1)
        fsm.changeState(name: "test1")

        let state2 = EntityState()
        let component2 = MockComponent2()
        state2.add(MockComponent2.self).withInstance(component2)
        fsm.addState(name: "test2", state: state2)
        fsm.changeState(name: "test2")

        XCTAssertFalse(entity.has(MockComponent.self))
    }

    func testEnterSecondStateDoesNotRemoveOverlappingComponents() {
        class EventDelegate: NexusEventDelegate {
            init() {}

            func nexusEvent(_ event: NexusEvent) {
                XCTAssertFalse(event is ComponentRemoved, "Component was removed when it shouldn't have been.")
            }

            func nexusNonFatalError(_ message: String) {}
        }
        let delgate = EventDelegate()
        nexus.delegate = delgate
        let state1 = EntityState()
        let component1 = MockComponent()
        state1.add(MockComponent.self).withInstance(component1)
        fsm.addState(name: "test1", state: state1)
        fsm.changeState(name: "test1")

        let state2 = EntityState()
        let component2 = MockComponent2()
        state2.add(MockComponent.self).withInstance(component1)
        state2.add(MockComponent2.self).withInstance(component2)
        fsm.addState(name: "test2", state: state2)
        fsm.changeState(name: "test2")

        XCTAssertTrue(entity.get(component: MockComponent.self) === component1)
    }

    func testEnterSecondStateRemovesDifferentComponentsOfSameType() {
        let state1 = EntityState()
        let component1 = MockComponent()
        state1.add(MockComponent.self).withInstance(component1)
        fsm.addState(name: "test1", state: state1)
        fsm.changeState(name: "test1")

        let state2 = EntityState()
        let component3 = MockComponent()
        let component2 = MockComponent2()
        state2.add(MockComponent.self).withInstance(component3)
        state2.add(MockComponent2.self).withInstance(component2)
        fsm.addState(name: "test2", state: state2)
        fsm.changeState(name: "test2")

        XCTAssertTrue(entity.get(component: MockComponent.self) === component3)
    }

    class MockComponent: ComponentInitializable {
        let value: Int

        init(value: Int) {
            self.value = value
        }

        required init() {
            self.value = 0
        }
    }

    class MockComponent2: ComponentInitializable {
        let value: String

        init(value: String) {
            self.value = value
        }

        required init() {
            self.value = ""
        }
    }
}
