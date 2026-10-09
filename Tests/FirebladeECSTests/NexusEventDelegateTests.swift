//
//  NexusEventDelegateTests.swift
//  
//
//  Created by Christian Treffs on 25.11.20.
//

import FirebladeECS
import Testing

@Suite struct NexusEventDelegateTests {
    @Test func eventEntityCreated() {
        let nexus = Nexus()
        var entityCreatedEvents: [EntityCreated] = []
        let delegateTester = DelegateTester(onEvent: { event in
            switch event {
            case let entityCreated as EntityCreated:
                entityCreatedEvents.append(entityCreated)
            default:
                Issue.record("unexpected event \(event)")
                return
            }
        })
        nexus.delegate = delegateTester
        
        #expect(entityCreatedEvents.count == 0)
        nexus.createEntity()
        #expect(entityCreatedEvents.count == 1)
        nexus.createEntities(count: 100)
        #expect(entityCreatedEvents.count == 101)
    }
    
    @Test func eventEntityDestroyed() {
        let nexus = Nexus()
        var events: [EntityDestroyed] = []
        let delegateTester = DelegateTester(onEvent: { event in
            switch event {
            case let event as EntityDestroyed:
                events.append(event)
            case _ as EntityCreated:
                break
            default:
                Issue.record("unexpected event \(event)")
                return
            }
        })
        nexus.delegate = delegateTester
        
        #expect(events.count == 0)
        nexus.createEntities(count: 100)
        #expect(events.count == 0)
        for entitiy in nexus.makeEntitiesIterator() {
            entitiy.destroy()
        }
        #expect(events.count == 100)
    }
    
    @Test func eventComponentAdded() {
        let nexus = Nexus()
        var componentsAddedEvents: [ComponentAdded] = []
        var entityCreatedEvents: [EntityCreated] = []
        let delegateTester = DelegateTester(onEvent: { event in
            switch event {
            case let compAdded as ComponentAdded:
                componentsAddedEvents.append(compAdded)
            case let entityCreated as EntityCreated:
                entityCreatedEvents.append(entityCreated)
            default:
                Issue.record("unexpected event \(event)")
                return
            }
        })
        nexus.delegate = delegateTester
        
        #expect(componentsAddedEvents.count == 0)
        #expect(entityCreatedEvents.count == 0)
        let entity = nexus.createEntity()
        entity.assign(MyComponent(name: "0", flag: true))
        #expect(componentsAddedEvents.count == 1)
        #expect(entityCreatedEvents.count == 1)
        let entity2 = nexus.createEntity()
        entity2.assign(MyComponent(name: "0", flag: true), YourComponent(number: 2))
        #expect(componentsAddedEvents.count == 3)
        #expect(entityCreatedEvents.count == 2)
    }
    
    @Test func eventComponentRemoved() {
        let nexus = Nexus()
        var events: [ComponentRemoved] = []
        let delegateTester = DelegateTester(onEvent: { event in
            switch event {
            case let event as ComponentRemoved:
                events.append(event)
            default:
                Issue.record("unexpected event \(event)")
                return
            }
        })
        
        let entity = nexus.createEntity()
        entity.assign(
            MyComponent(name: "Hello", flag: false),
            YourComponent(number: 3.14),
            EmptyComponent()
        )
        
        #expect(entity.numComponents == 3)
        #expect(events.count == 0)
        
        nexus.delegate = delegateTester
        
        entity.remove(MyComponent.self)
        #expect(events.count == 1)
        #expect(entity.numComponents == 2)
        
        entity.remove(EmptyComponent.self)
        #expect(events.count == 2)
        #expect(entity.numComponents == 1)
        
        entity.remove(YourComponent.self)
        #expect(events.count == 3)
        #expect(entity.numComponents == 0)
        
    }
    
    @Test func familyMemeberAdded() {
        let nexus = Nexus()
        var eventsFamilyMemberRemoved: [FamilyMemberRemoved] = []
        var eventsComponentRemoved: [ComponentRemoved] = []
        var eventsEntityDestroyed: [EntityDestroyed] = []
        let delegateTester = DelegateTester(onEvent: { event in
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
                Issue.record("unexpected event \(event)")
                return
            }
        })
        
        let family = nexus.family(requiresAll: MyComponent.self, YourComponent.self)
        nexus.delegate = delegateTester
        
        family.createMember(with: MyComponent(name: "Bla", flag: true), YourComponent(number: 85))
        family.createMember(with: MyComponent(name: "Hello", flag: false), YourComponent(number: 05050))
        family.createMember(with: MyComponent(name: "asdasd", flag: true), YourComponent(number: 9494949))
     
        #expect(eventsFamilyMemberRemoved.count == 0)
        #expect(eventsComponentRemoved.count == 0)
        #expect(family.count == 3)
        #expect(eventsEntityDestroyed.count == 0)
        
        #expect(family.destroyMembers())
        
        #expect(eventsFamilyMemberRemoved.count == 3)
        #expect(eventsComponentRemoved.count == 6)
        #expect(family.count == 0)
        #expect(eventsEntityDestroyed.count == 3)
    }
    
    @Test func familyMemberRemoved() {
        let nexus = Nexus()
        var eventsMemberAdded: [FamilyMemberAdded] = []
        var eventsComponentAdded: [ComponentAdded] = []
        var eventsEntityCreated: [EntityCreated] = []
        let delegateTester = DelegateTester(onEvent: { event in
            switch event {
            case let event as FamilyMemberAdded:
                eventsMemberAdded.append(event)
            case let event as ComponentAdded:
                eventsComponentAdded.append(event)
            case let event as EntityCreated:
                eventsEntityCreated.append(event)
            default:
                Issue.record("unexpected event \(event)")
                return
            }
        })
        
        let family = nexus.family(requiresAll: MyComponent.self, YourComponent.self)
        nexus.delegate = delegateTester
        
        #expect(family.count == 0)
        #expect(eventsMemberAdded.count == 0)
        #expect(eventsComponentAdded.count == 0)
        #expect(eventsEntityCreated.count == 0)
        
        family.createMember(with: MyComponent(name: "Bla", flag: true), YourComponent(number: 85))
        #expect(family.count == 1)
        #expect(eventsMemberAdded.count == 1)
        #expect(eventsComponentAdded.count == 2)
        #expect(eventsEntityCreated.count == 1)
        
        
        family.createMember(with: MyComponent(name: "Hello", flag: false), YourComponent(number: 05050))
        #expect(family.count == 2)
        #expect(eventsMemberAdded.count == 2)
        #expect(eventsComponentAdded.count == 4)
        #expect(eventsEntityCreated.count == 2)
    }
}


fileprivate class DelegateTester: NexusEventDelegate, @unchecked Sendable {
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
