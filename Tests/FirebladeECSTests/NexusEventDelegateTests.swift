//
//  NexusEventDelegateTests.swift
//  
//
//  Created by Christian Treffs on 25.11.20.
//

import FirebladeECS
import XCTest

final class NexusEventDelegateTests: XCTestCase {
    lazy var nexus = Nexus()
    fileprivate var delegateTester: DelegateTester!

    override func setUp() {
        super.setUp()
        nexus = Nexus()
        delegateTester = nil
    }
    
    func testEventEntityCreated() {
        var entityCreatedEvents: [EntityCreated] = []
        delegateTester = DelegateTester(onEvent: { event in
            switch event {
            case let entityCreated as EntityCreated:
                entityCreatedEvents.append(entityCreated)
            default:
                XCTFail("unexpected event \(event)")
                return
            }
        })
        nexus.delegate = delegateTester
        
        XCTAssertEqual(entityCreatedEvents.count, 0)
        nexus.createEntity()
        XCTAssertEqual(entityCreatedEvents.count, 1)
        nexus.createEntities(count: 100, using: { _ in  })
        XCTAssertEqual(entityCreatedEvents.count, 101)
    }
    
    func testEventEntityDestroyed() {
        var events: [EntityDestroyed] = []
        delegateTester = DelegateTester(onEvent: { event in
            switch event {
            case let event as EntityDestroyed:
                events.append(event)
            case _ as EntityCreated:
                break
            default:
                XCTFail("unexpected event \(event)")
                return
            }
        })
        nexus.delegate = delegateTester
        
        XCTAssertEqual(events.count, 0)
        nexus.createEntities(count: 100, using: { _ in  })
        XCTAssertEqual(events.count, 0)
        for entitiy in nexus.makeEntitiesIterator() {
            entitiy.destroy()
        }
        XCTAssertEqual(events.count, 100)
    }
    
    func testEventComponentAdded() {
        var componentsAddedEvents: [ComponentAdded] = []
        var entityCreatedEvents: [EntityCreated] = []
        delegateTester = DelegateTester(onEvent: { event in
            switch event {
            case let compAdded as ComponentAdded:
                componentsAddedEvents.append(compAdded)
            case let entityCreated as EntityCreated:
                entityCreatedEvents.append(entityCreated)
            default:
                XCTFail("unexpected event \(event)")
                return
            }
        })
        nexus.delegate = delegateTester
        
        XCTAssertEqual(componentsAddedEvents.count, 0)
        XCTAssertEqual(entityCreatedEvents.count, 0)
        let entity = nexus.createEntity()
        entity.assign(MyComponent(name: "0", flag: true))
        XCTAssertEqual(componentsAddedEvents.count, 1)
        XCTAssertEqual(entityCreatedEvents.count, 1)
        let entity2 = nexus.createEntity()
        entity2.assign(MyComponent(name: "0", flag: true), YourComponent(number: 2))
        XCTAssertEqual(componentsAddedEvents.count, 3)
        XCTAssertEqual(entityCreatedEvents.count, 2)
    }
    
    func testEventComponentRemoved() {
        var events: [ComponentRemoved] = []
        delegateTester = DelegateTester(onEvent: { event in
            switch event {
            case let event as ComponentRemoved:
                events.append(event)
            default:
                XCTFail("unexpected event \(event)")
                return
            }
        })
        
        let entity = nexus.createEntity()
        entity.assign(
            MyComponent(name: "Hello", flag: false),
            YourComponent(number: 3.14),
            EmptyComponent()
        )
        
        XCTAssertEqual(entity.numComponents, 3)
        XCTAssertEqual(events.count, 0)
        
        nexus.delegate = delegateTester
        
        entity.remove(MyComponent.self)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(entity.numComponents, 2)
        
        entity.remove(EmptyComponent.self)
        XCTAssertEqual(events.count, 2)
        XCTAssertEqual(entity.numComponents, 1)
        
        entity.remove(YourComponent.self)
        XCTAssertEqual(events.count, 3)
        XCTAssertEqual(entity.numComponents, 0)
        
    }
    
    func testFamilyMemeberAdded() {
        var eventsFamilyMemberRemoved: [FamilyMemberRemoved] = []
        var eventsComponentRemoved: [ComponentRemoved] = []
        var eventsEntityDestroyed: [EntityDestroyed] = []
        delegateTester = DelegateTester(onEvent: { event in
            switch event {
            case is FamilyMemberAdded,
                 is ComponentAdded,
                 is EntityCreated:
                break
            case let event as FamilyMemberRemoved:
                eventsFamilyMemberRemoved.append(event)
            case let event as ComponentRemoved:
                eventsComponentRemoved.append(event)
            case let event as EntityDestroyed:
                eventsEntityDestroyed.append(event)
            default:
                XCTFail("unexpected event \(event)")
                return
            }
        })
        
        let family = nexus.family(requiresAll: MyComponent.self, YourComponent.self)
        nexus.delegate = delegateTester
        
        family.createMember(with: (MyComponent(name: "Bla", flag: true), YourComponent(number: 85)))
        family.createMember(with: (MyComponent(name: "Hello", flag: false), YourComponent(number: 05050)))
        family.createMember(with: (MyComponent(name: "asdasd", flag: true), YourComponent(number: 9494949)))
     
        XCTAssertEqual(eventsFamilyMemberRemoved.count, 0)
        XCTAssertEqual(eventsComponentRemoved.count, 0)
        XCTAssertEqual(family.count, 3)
        XCTAssertEqual(eventsEntityDestroyed.count, 0)
        
        XCTAssertTrue(family.destroyMembers())
        
        XCTAssertEqual(eventsFamilyMemberRemoved.count, 3)
        XCTAssertEqual(eventsComponentRemoved.count, 6)
        XCTAssertEqual(family.count, 0)
        XCTAssertEqual(eventsEntityDestroyed.count, 3)
    }
    
    func testFamilyMemberRemoved() {
        var eventsMemberAdded: [FamilyMemberAdded] = []
        var eventsComponentAdded: [ComponentAdded] = []
        var eventsEntityCreated: [EntityCreated] = []
        delegateTester = DelegateTester(onEvent: { event in
            switch event {
            case let event as FamilyMemberAdded:
                eventsMemberAdded.append(event)
            case let event as ComponentAdded:
                eventsComponentAdded.append(event)
            case let event as EntityCreated:
                eventsEntityCreated.append(event)
            default:
                XCTFail("unexpected event \(event)")
                return
            }
        })
        
        let family = nexus.family(requiresAll: MyComponent.self, YourComponent.self)
        nexus.delegate = delegateTester
        
        XCTAssertEqual(family.count, 0)
        XCTAssertEqual(eventsMemberAdded.count, 0)
        XCTAssertEqual(eventsComponentAdded.count, 0)
        XCTAssertEqual(eventsEntityCreated.count, 0)
        
        family.createMember(with: (MyComponent(name: "Bla", flag: true), YourComponent(number: 85)))
        XCTAssertEqual(family.count, 1)
        XCTAssertEqual(eventsMemberAdded.count, 1)
        XCTAssertEqual(eventsComponentAdded.count, 2)
        XCTAssertEqual(eventsEntityCreated.count, 1)
        
        
        family.createMember(with: (MyComponent(name: "Hello", flag: false), YourComponent(number: 05050)))
        XCTAssertEqual(family.count, 2)
        XCTAssertEqual(eventsMemberAdded.count, 2)
        XCTAssertEqual(eventsComponentAdded.count, 4)
        XCTAssertEqual(eventsEntityCreated.count, 2)
    }
}


fileprivate class DelegateTester: NexusEventDelegate {
    var onEvent: (NexusEvent) -> ()
    var onNonFatal: (String) -> ()
    
    init(onEvent: @escaping (NexusEvent) -> Void  = { _ in },
         onNonFatal: @escaping (String) -> Void = { _ in }) {
        self.onEvent = onEvent
        self.onNonFatal = onNonFatal
    }
    
    func nexusEvent(_ event: NexusEvent) {
        onEvent(event)
    }
    
    func nexusNonFatalError(_ message: String) {
        onNonFatal(message)
    }
}
