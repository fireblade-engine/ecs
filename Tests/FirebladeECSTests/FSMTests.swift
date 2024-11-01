////
////  FSMTests.swift
////  FirebladeECSTests
////
////  Created by Igor Kravchenko on 29.09.2020.
////
//
//import FirebladeECS
//import XCTest
//
//class ComponentInstanceProviderTests: XCTestCase {
//    func testProviderReturnsTheInstance() {
//        let instance = MockComponent(value: .max)
//        let provider1 = ComponentInstanceProvider(instance: instance)
//        let providedComponent = provider1.getComponent() as? MockComponent
//        XCTAssertTrue(providedComponent === instance)
//    }
//
//    func testProvidersWithSameInstanceHaveSameIdentifier() {
//        let instance = MockComponent(value: .max)
//        let provider1 = ComponentInstanceProvider(instance: instance)
//        let provider2 = ComponentInstanceProvider(instance: instance)
//        XCTAssertEqual(provider1.identifier, provider2.identifier)
//    }
//
//    func testProvidersWithDifferentInstanceHaveDifferentIdentifier() {
//        let provider1 = ComponentInstanceProvider(instance: MockComponent(value: .max))
//        let provider2 = ComponentInstanceProvider(instance: MockComponent(value: .max))
//        XCTAssertNotEqual(provider1.identifier, provider2.identifier)
//    }
//
//    class MockComponent: Component {
//        var value: Int
//
//        init(value: Int) {
//            self.value = value
//        }
//    }
//}
//
//// MARK: -
//
//class ComponentTypeProviderTests: XCTestCase {
//    func testProviderReturnsAnInstanceOfType() {
//        let provider = ComponentTypeProvider(type: MockComponent.self)
//        let component = provider.getComponent() as? MockComponent
//        XCTAssertNotNil(component)
//    }
//
//    func testProviderReturnsNewInstanceEachTime() {
//        let provider = ComponentTypeProvider(type: MockComponent.self)
//        let component1 = provider.getComponent() as? MockComponent
//        let component2 = provider.getComponent() as? MockComponent
//        XCTAssertFalse(component1 === component2)
//    }
//
//    func testProvidersWithSameTypeHaveSameIdentifier() {
//        let provider1 = ComponentTypeProvider(type: MockComponent.self)
//        let provider2 = ComponentTypeProvider(type: MockComponent.self)
//        XCTAssertEqual(provider1.identifier, provider2.identifier)
//    }
//
//    func testProvidersWithDifferentTypeHaveDifferentIdentifier() {
//        let provider1 = ComponentTypeProvider(type: MockComponent.self)
//        let provider2 = ComponentTypeProvider(type: MockComponent2.self)
//        XCTAssertNotEqual(provider1.identifier, provider2.identifier)
//    }
//
//    class MockComponent: Component, DefaultInitializable {
//        var value: String
//
//        required init() {
//            value = ""
//        }
//    }
//
//    class MockComponent2: Component, DefaultInitializable {
//        var value: Bool
//
//        required init() {
//            value = false
//        }
//    }
//}
//
//// MARK: -
//
//class ComponentSingletonProviderTests: XCTestCase {
//    func testProviderReturnsAnInstanceOfType() {
//        let provider = ComponentSingletonProvider(type: MockComponent.self)
//        let component = provider.getComponent() as? MockComponent
//        XCTAssertNotNil(component)
//    }
//
//    func testProviderReturnsSameInstanceEachTime() {
//        let provider = ComponentSingletonProvider(type: MockComponent.self)
//        let component1 = provider.getComponent() as? MockComponent
//        let component2 = provider.getComponent() as? MockComponent
//        XCTAssertTrue(component1 === component2)
//
//    }
//
//    func testProvidersWithSameTypeHaveDifferentIdentifier() {
//        let provider1 = ComponentSingletonProvider(type: MockComponent.self)
//        let provider2 = ComponentSingletonProvider(type: MockComponent.self)
//        XCTAssertNotEqual(provider1.identifier, provider2.identifier)
//    }
//
//    func testProvidersWithDifferentTypeHaveDifferentIdentifier() {
//        let provider1 = ComponentSingletonProvider(type: MockComponent.self)
//        let provider2 = ComponentSingletonProvider(type: MockComponent2.self)
//        XCTAssertNotEqual(provider1.identifier, provider2.identifier)
//    }
//
//    class MockComponent: Component, DefaultInitializable {
//        var value: Int
//
//        required init() {
//            value = 0
//        }
//    }
//
//    class MockComponent2: Component, DefaultInitializable {
//        var value: String
//
//        required init() {
//            value = ""
//        }
//    }
//}
//
//// MARK: -
//
//class DynamicComponentProviderTests: XCTestCase {
//    func testProviderReturnsTheInstance() {
//        let instance = MockComponent(value: 0)
//        let providerMethod = DynamicComponentProvider.Closure { instance }
//        let provider = DynamicComponentProvider(closure: providerMethod)
//        let component = provider.getComponent() as? MockComponent
//        XCTAssertTrue(component === instance)
//    }
//
//    func testProvidersWithSameMethodHaveSameIdentifier() {
//        let instance = MockComponent(value: 0)
//        let providerMethod = DynamicComponentProvider.Closure { instance }
//        let provider1 = DynamicComponentProvider(closure: providerMethod)
//        let provider2 = DynamicComponentProvider(closure: providerMethod)
//        XCTAssertEqual(provider1.identifier, provider2.identifier)
//    }
//
//    func testProvidersWithDifferentMethodsHaveDifferentIdentifier() {
//        let instance = MockComponent(value: 0)
//        let providerMethod1 = DynamicComponentProvider.Closure { instance }
//        let providerMethod2 = DynamicComponentProvider.Closure { instance }
//        let provider1 = DynamicComponentProvider(closure: providerMethod1)
//        let provider2 = DynamicComponentProvider(closure: providerMethod2)
//        XCTAssertNotEqual(provider1.identifier, provider2.identifier)
//    }
//
//    class MockComponent: Component {
//        let value: Int
//
//        init(value: Int) {
//            self.value = value
//        }
//    }
//}
//
//// MARK: -
//
//@testable import class FirebladeECS.EntityState
//
//class EntityStateTests: XCTestCase {
//    private var state = EntityState()
//
//    override func setUp() {
//        state = EntityState()
//    }
//
//    override func tearDown() {
//        state = EntityState()
//    }
//
//    func testAddMappingWithNoQualifierCreatesTypeProvider() {
//        state.addMapping(for: MockComponent.self)
//        let provider = state.providers[MockComponent.identifier]
//        XCTAssertNotNil(provider)
//        XCTAssertTrue(provider is ComponentTypeProvider?)
//        XCTAssertTrue(provider?.getComponent() is MockComponent?)
//    }
//
//    func testAddMappingWithTypeQualifierCreatesTypeProvider() {
//        state.addMapping(for: MockComponent.self).withType(MockComponent2.self)
//        let provider = state.providers[MockComponent.identifier]
//        XCTAssertNotNil(provider)
//        XCTAssertTrue(provider is ComponentTypeProvider?)
//        XCTAssertTrue(provider?.getComponent() is MockComponent2?)
//    }
//
//    func testAddMappingWithInstanceQualifierCreatesInstanceProvider() {
//        let component = MockComponent()
//        state.addMapping(for: MockComponent.self).withInstance(component)
//        let provider = state.providers[MockComponent.identifier]
//        XCTAssertTrue(provider is ComponentInstanceProvider?)
//        XCTAssertTrue(provider?.getComponent() === component)
//    }
//
//    func testAddMappingWithSingletonQualifierCreatesSingletonProvider() {
//        state.addMapping(for: MockComponent.self).withSingleton(MockComponent.self)
//        let  provider = state.providers[MockComponent.identifier]
//        XCTAssertTrue(provider is ComponentSingletonProvider?)
//        XCTAssertTrue(provider?.getComponent() is MockComponent?)
//    }
//
//    func testAddMappingWithMethodQualifierCreatesDynamicProvider() {
//        let dynamickProvider = DynamicComponentProvider.Closure {
//            MockComponent()
//        }
//
//        state.addMapping(for: MockComponent.self).withMethod(dynamickProvider)
//        let provider = state.providers[MockComponent.identifier]
//        XCTAssertNotNil(provider)
//        XCTAssertTrue(provider is DynamicComponentProvider<MockComponent>?)
//        XCTAssertTrue(provider?.getComponent() is MockComponent)
//    }
//
//    func testProviderForTypeReturnsTypeProviderByDefault() {
//        state.addMapping(for: MockComponent.self)
//        let provider = state.provider(for: MockComponent.self)
//        XCTAssertNotNil(provider)
//        XCTAssertTrue(provider is ComponentTypeProvider?)
//    }
//
//    func testProviderForTypeReturnsInstanceProvider() {
//        let component = MockComponent()
//        state.addMapping(for: MockComponent.self).withInstance(component)
//        let provider = state.provider(for: MockComponent.self)
//        XCTAssertNotNil(provider)
//        XCTAssertTrue(provider is ComponentInstanceProvider?)
//    }
//
//    func testProviderForTypeReturnsSingletonProvider() {
//        state.addMapping(for: MockComponent.self).withSingleton(MockComponent.self)
//        let provider = state.provider(for: MockComponent.self)
//        XCTAssertNotNil(provider)
//        XCTAssertTrue(provider is ComponentSingletonProvider?)
//    }
//
//    func testProviderForTypeReturnsDynamicProvider() {
//        state.addMapping(for: MockComponent.self).withMethod(.init { MockComponent() })
//        let provider = state.provider(for: MockComponent.self)
//        XCTAssertNotNil(provider)
//        XCTAssertTrue(provider is DynamicComponentProvider<MockComponent>?)
//    }
//
//    func testProviderForTypeReturnsTypeProvider() {
//        state.addMapping(for: MockComponent.self).withType(MockComponent.self)
//        let provider = state.provider(for: MockComponent.self)
//        XCTAssertNotNil(provider)
//        XCTAssertTrue(provider is ComponentTypeProvider?)
//    }
//
//    func testProviderForTypeReturnsPassedProvider() {
//        let singletonProvider = ComponentSingletonProvider(type: MockComponent.self)
//        state.addMapping(for: MockComponent.self).withProvider(singletonProvider)
//        let provider = state.provider(for: MockComponent.self) as? ComponentSingletonProvider
//        XCTAssertNotNil(provider)
//        XCTAssertTrue(provider === singletonProvider)
//    }
//
//    func testHasProviderReturnsFalseForNotCreatedProvider() {
//        XCTAssertFalse(state.hasProvider(for: MockComponent.self))
//    }
//
//    func testHasProviderReturnsTrueForCreatedProvider() {
//        state.addMapping(for: MockComponent.self)
//        XCTAssertTrue(state.hasProvider(for: MockComponent.self))
//    }
//
//    func testAddInstanceCreatesMappingAndSetsInstanceProviderForInstanceType() {
//        let component = MockComponent()
//        state.addInstance(component)
//        XCTAssertTrue(state.provider(for: MockComponent.self) is ComponentInstanceProvider?)
//        XCTAssert(state.provider(for: MockComponent.self)?.getComponent() === component)
//    }
//
//    func testAddTypeCreatesMappingAndSetsTypeProviderForType() {
//        state.addType(MockComponent.self)
//        XCTAssertTrue(state.provider(for: MockComponent.self) is ComponentTypeProvider?)
//        XCTAssertNotNil(state.provider(for: MockComponent.self)?.getComponent())
//        XCTAssertTrue(state.provider(for: MockComponent.self)?.getComponent() is MockComponent?)
//    }
//
//    func testAddSingletonCreatesMappingAndSetsSingletonProviderForType() {
//        state.addSingleton(MockComponent.self)
//        XCTAssertTrue(state.provider(for: MockComponent.self) is ComponentSingletonProvider?)
//        XCTAssertNotNil(state.provider(for: MockComponent.self)?.getComponent())
//        XCTAssertTrue(state.provider(for: MockComponent.self)?.getComponent() is MockComponent?)
//    }
//
//    func testAddMethodCreatesMappingAndSetsDynamicProviderForType() {
//        let component = MockComponent()
//        state.addMethod(closure: .init { component })
//        XCTAssertTrue(state.provider(for: MockComponent.self) is DynamicComponentProvider<MockComponent>?)
//        XCTAssertTrue(state.provider(for: MockComponent.self)?.getComponent() === component)
//    }
//
//    func testAddProviderCreatesMappingAndSetsProvider() {
//        let provider = ComponentSingletonProvider(type: MockComponent.self)
//        state.addProvider(type: MockComponent.self, provider: provider)
//        XCTAssert(state.provider(for: MockComponent.self) is ComponentSingletonProvider?)
//        XCTAssertNotNil(state.provider(for: MockComponent.self))
//    }
//
//    class MockComponent: ComponentInitializable {
//        let value: Int
//
//        init(value: Int) {
//            self.value = value
//        }
//
//        required init() {
//            value = 0
//        }
//    }
//
//    class MockComponent2: MockComponent {}
//}
//
//// MARK: -
//
//class EntityStateMachineTests: XCTestCase {
//    var nexus = Nexus()
//    var fsm = EntityStateMachine<String>(entity: .init(nexus: .init(), id: .invalid))
//    var entity = Entity(nexus: .init(), id: .init(rawValue: 1))
//
//    override func setUp() {
//        nexus = Nexus()
//        entity = nexus.createEntity()
//        fsm = EntityStateMachine(entity: entity)
//    }
//
//    func testEnterStateAddsStatesComponents() {
//        let state = EntityState()
//        let component = MockComponent()
//        state.addMapping(for: MockComponent.self).withInstance(component)
//        fsm.addState(name: "test", state: state)
//        fsm.changeState(name: "test")
//        XCTAssertTrue(entity.get(component: MockComponent.self) === component)
//    }
//
//    func testEnterSecondStateAddsSecondStatesComponents() {
//        let state1 = EntityState()
//        let component1 = MockComponent()
//        state1.addMapping(for: MockComponent.self).withInstance(component1)
//        fsm.addState(name: "test1", state: state1)
//
//        let state2 = EntityState()
//        let component2 = MockComponent2()
//        state2.addMapping(for: MockComponent2.self).withInstance(component2)
//        fsm.addState(name: "test2", state: state2)
//        fsm.changeState(name: "test2")
//
//        XCTAssertTrue(entity.get(component: MockComponent2.self) === component2)
//    }
//
//    func testEnterSecondStateRemovesFirstStatesComponents() {
//        let state1 = EntityState()
//        let component1 = MockComponent()
//        state1.addMapping(for: MockComponent.self).withInstance(component1)
//        fsm.addState(name: "test1", state: state1)
//        fsm.changeState(name: "test1")
//
//        let state2 = EntityState()
//        let component2 = MockComponent2()
//        state2.addMapping(for: MockComponent2.self).withInstance(component2)
//        fsm.addState(name: "test2", state: state2)
//        fsm.changeState(name: "test2")
//
//        XCTAssertFalse(entity.has(MockComponent.self))
//    }
//
//    func testEnterSecondStateDoesNotRemoveOverlappingComponents() {
//        class EventDelegate: NexusEventDelegate {
//            init() {}
//
//            func nexusEvent(_ event: NexusEvent) {
//                XCTAssertFalse(event is ComponentRemoved, "Component was removed when it shouldn't have been.")
//            }
//
//            func nexusNonFatalError(_ message: String) {}
//        }
//        let delgate = EventDelegate()
//        nexus.delegate = delgate
//        let state1 = EntityState()
//        let component1 = MockComponent()
//        state1.addMapping(for: MockComponent.self).withInstance(component1)
//        fsm.addState(name: "test1", state: state1)
//        fsm.changeState(name: "test1")
//
//        let state2 = EntityState()
//        let component2 = MockComponent2()
//        state2.addMapping(for: MockComponent.self).withInstance(component1)
//        state2.addMapping(for: MockComponent2.self).withInstance(component2)
//        fsm.addState(name: "test2", state: state2)
//        fsm.changeState(name: "test2")
//
//        XCTAssertTrue(entity.get(component: MockComponent.self) === component1)
//    }
//
//    func testEnterSecondStateRemovesDifferentComponentsOfSameType() {
//        let state1 = EntityState()
//        let component1 = MockComponent()
//        state1.addMapping(for: MockComponent.self).withInstance(component1)
//        fsm.addState(name: "test1", state: state1)
//        fsm.changeState(name: "test1")
//
//        let state2 = EntityState()
//        let component3 = MockComponent()
//        let component2 = MockComponent2()
//        state2.addMapping(for: MockComponent.self).withInstance(component3)
//        state2.addMapping(for: MockComponent2.self).withInstance(component2)
//        fsm.addState(name: "test2", state: state2)
//        fsm.changeState(name: "test2")
//
//        XCTAssertTrue(entity.get(component: MockComponent.self) === component3)
//    }
//
//    func testCreateStateAddsState() {
//        let state = fsm.createState(name: "test")
//        let component = MockComponent()
//        state.addMapping(for: MockComponent.self).withInstance(component)
//        fsm.changeState(name: "test")
//        XCTAssertTrue(entity.get(component: MockComponent.self) === component)
//    }
//
//    func testCreateStateDoesNotChangeState() {
//        let state = fsm.createState(name: "test")
//        let component = MockComponent()
//        state.addMapping(for: MockComponent.self).withInstance(component)
//        XCTAssertNil(entity.get(component: MockComponent.self))
//    }
//
//    func testCallChangeStateWithSameNameLeavesEntityComponentsIntact() {
//        let state = fsm.createState(name: "test")
//        let component1 = MockComponent()
//        let component2 = MockComponent2()
//        state.addMapping(for: MockComponent.self).withInstance(component1)
//        state.addMapping(for: MockComponent2.self).withInstance(component2)
//        let name = "test"
//        fsm.changeState(name: name)
//        XCTAssertTrue(entity.get(component: MockComponent.self) === component1)
//        XCTAssertTrue(entity.get(component: MockComponent2.self) === component2)
//        fsm.changeState(name: name)
//        XCTAssertTrue(entity.get(component: MockComponent.self) === component1)
//        XCTAssertTrue(entity.get(component: MockComponent2.self) === component2)
//    }
//
//    func testGetsDeinitedWhileBeingStronglyReferencedByComponentAssignedToEntity() {
//        class Marker: Component {
//            let fsm: EntityStateMachine<String>
//            init(fsm: EntityStateMachine<String>) {
//                self.fsm = fsm
//            }
//        }
//
//        let nexus = Nexus()
//        var entity = nexus.createEntity()
//        var markerComponent = Marker(fsm: EntityStateMachine<String>(entity: entity))
//        entity.assign(markerComponent)
//        weak var weakMarker = markerComponent
//        weak var weakFsm = markerComponent.fsm
//        nexus.destroy(entity: entity)
//        entity = nexus.createEntity()
//        markerComponent = .init(fsm: .init(entity: entity))
//        XCTAssertNil(weakMarker)
//        XCTAssertNil(weakFsm)
//    }
//
//    class MockComponent: ComponentInitializable {
//        let value: Int
//
//        init(value: Int) {
//            self.value = value
//        }
//
//        required init() {
//            value = 0
//        }
//    }
//
//    class MockComponent2: ComponentInitializable {
//        let value: String
//
//        init(value: String) {
//            self.value = value
//        }
//
//        required init() {
//            self.value = ""
//        }
//    }
//}
//
//// MARK: -
//
//class StateComponentMappingTests: XCTestCase {
//    func testAddReturnsSameMappingForSameComponentType() {
//        let state = EntityState()
//        let mapping = state.addMapping(for: MockComponent.self)
//        XCTAssertFalse(mapping === mapping.add(MockComponent.self))
//    }
//
//    func testAddReturnsSameMappingForDifferentComponentTypes() {
//        let state = EntityState()
//        let mapping = state.addMapping(for: MockComponent.self)
//        XCTAssertFalse(mapping === mapping.add(MockComponent2.self))
//    }
//
//    func testAddAddsProviderToState() {
//        let state = EntityState()
//        let mapping = state.addMapping(for: MockComponent.self)
//        mapping.add(MockComponent2.self)
//        XCTAssertTrue(state.hasProvider(for: MockComponent.self))
//    }
//
//    class MockComponent: ComponentInitializable {
//        let value: Int
//
//        init(value: Int) {
//            self.value = value
//        }
//
//        required init() {
//            self.value = 0
//        }
//    }
//
//    class MockComponent2: ComponentInitializable {
//        let value: String
//
//        init(value: String) {
//            self.value = value
//        }
//
//        required init() {
//            self.value = ""
//        }
//    }
//}
