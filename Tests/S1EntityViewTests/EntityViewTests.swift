// swiftlint:disable all
import S1EntityView
import S1FamilyAPI
import Testing

struct Pos: S1Component { static let componentIndex = 0; var x = 0.0 }
struct Vel: S1Component { static let componentIndex = 1; var x = 0.0 }

@Suite struct EntityViewTests {
    @Test func escapableViewApi() {
        let world = World()
        let id = world.createEntity()
        world.add(Pos(x: 3), to: id)
        let entity = world.entity(id)
        #expect(entity.get(Pos.self)?.x == 3)
        // `#expect(a == b)` does not compile for a ~Escapable operand (Testing's __checkBinaryOperation needs Escapable).
        #if compiler(>=6.3)
        let same = entity == world.entity(id)
        #expect(same)
        #endif
        #expect(entity.description == "Entity(\(id))")
        #if compiler(>=6.3)
        let sameHash = entity.hashValue == world.entity(id).hashValue
        #expect(sameHash)
        #endif
    }

    @Test func closureFallback() {
        let world = World()
        let id = world.createEntity()
        world.add(Pos(x: 4), to: id)
        let value = world.withEntity(id) { $0.get(Pos.self)?.x }
        #expect(value == 4)
    }

    @Test func forEachHandsOutEntities() {
        let world = World()
        for index in 0 ..< 3 {
            let id = world.createEntity()
            world.add(Pos(x: Double(index)), to: id)
            world.add(Vel(), to: id)
        }
        let family = Family(world: world, reading: Reading(Pos.self), writing: Writing(Vel.self))
        var ids: [Int] = []
        family.forEachEntity { entity in ids.append(entity.id) }
        #expect(Set(ids) == [0, 1, 2])
    }
}
