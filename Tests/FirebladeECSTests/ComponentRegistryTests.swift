//
//  ComponentRegistryTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 08.10.26.
//

@testable import FirebladeECS
import Testing

final class RegisteredPosition: RegistrableComponent, DefaultInitializable, @unchecked Sendable {
    var x: Int = 0
    init() {}
}

final class RenamedVelocity: RegistrableComponent, @unchecked Sendable {
    static let componentTypeName = "Velocity"
}

final class ConflictingVelocity: RegistrableComponent, @unchecked Sendable {
    static let componentTypeName = "Velocity"
}

@Suite struct ComponentRegistryTests {
    @Test func defaultTypeNameIsFullyQualified() {
        #expect(RegisteredPosition.componentTypeName == "FirebladeECSTests.RegisteredPosition")
        #expect(RenamedVelocity.componentTypeName == "Velocity")
    }

    @Test func stableIdentifierIsFNV1aOfTypeName() {
        // Reference values of 64-bit FNV-1a.
        #expect(StableComponentIdentifier(typeName: "").rawValue == 0xCBF2_9CE4_8422_2325)
        #expect(StableComponentIdentifier(typeName: "a").rawValue == 0xAF63_DC4C_8601_EC8C)
        #expect(RenamedVelocity.stableIdentifier == StableComponentIdentifier(typeName: "Velocity"))
        #expect(RenamedVelocity.stableIdentifier != RegisteredPosition.stableIdentifier)
    }

    @Test func explicitRegistration() throws {
        let nexus = Nexus()
        #expect(!nexus.isRegistered(RegisteredPosition.self))

        let record = try nexus.register(RegisteredPosition.self)
        #expect(record.typeName == RegisteredPosition.componentTypeName)
        #expect(record.identifier == RegisteredPosition.identifier)
        #expect(record.stableIdentifier == RegisteredPosition.stableIdentifier)
        #expect(record.isDefaultInitializable)
        #expect(nexus.isRegistered(RegisteredPosition.self))
        #expect(nexus.componentType(named: "FirebladeECSTests.RegisteredPosition")?.identifier == RegisteredPosition.identifier)
        #expect(nexus.componentType(for: RegisteredPosition.identifier)?.typeName == RegisteredPosition.componentTypeName)
        #expect(nexus.componentType(named: "Unknown") == nil)
    }

    @Test func registrationViaStaticMethod() throws {
        let nexus = Nexus()
        try RenamedVelocity.register(in: nexus)
        #expect(nexus.isRegistered(RenamedVelocity.self))
        #expect(nexus.componentType(named: "Velocity")?.isDefaultInitializable == false)
    }

    @Test func registeringSequenceIsSortedByName() throws {
        let nexus = Nexus()
        try nexus.register([RegisteredPosition.self, RenamedVelocity.self])
        #expect(nexus.registeredComponentTypes.map(\.typeName) == ["FirebladeECSTests.RegisteredPosition", "Velocity"])
    }

    @Test func reRegistrationIsNoOp() throws {
        let nexus = Nexus()
        try nexus.register(RegisteredPosition.self)
        try nexus.register(RegisteredPosition.self)
        #expect(nexus.registeredComponentTypes.count == 1)
    }

    @Test func duplicateTypeNameThrows() throws {
        let nexus = Nexus()
        try nexus.register(RenamedVelocity.self)
        #expect(throws: ComponentRegistryError.duplicateTypeName("Velocity")) {
            try nexus.register(ConflictingVelocity.self)
        }
        #expect(!nexus.isRegistered(ConflictingVelocity.self))
    }

    @Test func registersOnFirstAssignment() {
        let nexus = Nexus()
        nexus.createEntity(with: RegisteredPosition())
        #expect(nexus.isRegistered(RegisteredPosition.self))
    }

    @Test func plainComponentsAreNotRegistered() {
        let nexus = Nexus()
        nexus.createEntity(with: Position(x: 1, y: 2))
        #expect(!nexus.isRegistered(Position.self))
        #expect(nexus.registeredComponentTypes.isEmpty)
    }

    @Test func registrySurvivesClear() throws {
        let nexus = Nexus()
        try nexus.register(RegisteredPosition.self)
        nexus.clear()
        #expect(nexus.isRegistered(RegisteredPosition.self))
    }

    @Test func autoRegistrationConflictReportsNonFatalError() {
        final class Recorder: NexusEventDelegate, @unchecked Sendable {
            var errors: [String] = []
            func nexusEvent(_: NexusEvent) {}
            func nexusNonFatalError(_ message: String) { errors.append(message) }
        }
        let recorder = Recorder()
        let nexus = Nexus()
        nexus.delegate = recorder
        nexus.createEntity(with: RenamedVelocity())
        nexus.createEntity(with: ConflictingVelocity())

        #expect(nexus.isRegistered(RenamedVelocity.self))
        #expect(!nexus.isRegistered(ConflictingVelocity.self))
        #expect(recorder.errors.count == 1)
        #expect(nexus.numComponents == 2)
    }
}
