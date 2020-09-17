import FirebladeECS
import XCTest

class ComponentInstanceProviderTests: XCTestCase {
    func testProviderReturnsTheInstance() {
        let instance = MockComponent(value: .max)
        let provider1 = ComponentInstanceProvider(instance: instance)
        let providedComponent: MockComponent? = provider1.getComponent()
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
        let component: MockComponent? = provider.getComponent()
        XCTAssertNotNil(component)
    }
    
    func testProviderReturnsNewInstanceEachTime() {
        let provider = ComponentTypeProvider(type: MockComponent.self)
        let component1: MockComponent? = provider.getComponent()
        let component2: MockComponent? = provider.getComponent()
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
        let component: MockComponent? = provider.getComponent()
        XCTAssertNotNil(component)
    }

    func testProviderReturnsSameInstanceEachTime() {
        let provider = ComponentSingletonProvider(type: MockComponent.self)
        let component1: MockComponent? = provider.getComponent()
        let component2: MockComponent? = provider.getComponent()
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
        let component: MockComponent? = provider.getComponent()
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
