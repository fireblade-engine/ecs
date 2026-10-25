// swiftlint:disable identifier_name
// Mut closures are not tested: Swift 6.2 assert compilers crash in SILGen on them (see Spikes/S1/REPORT.md).
import S1FamilyAPI
import Testing

struct Pos: S1Component { static let componentIndex = 0; var x = 0.0; var y = 0.0 }
struct Vel: S1Component { static let componentIndex = 1; var x = 0.0; var y = 0.0 }
struct Hp: S1Component { static let componentIndex = 2; var points = 0 }
struct Tag: S1Component { static let componentIndex = 3; var label = 0 }

@Suite struct FamilyTests {
    @Test func oneReadOneWrite() {
        let world = World()
        for i in 0 ..< 5 {
            let e = world.createEntity()
            world.add(Pos(x: Double(i)), to: e)
            world.add(Vel(), to: e)
        }
        let family = Family(world: world, reading: Reading(Pos.self), writing: Writing(Vel.self))
        family.forEach { (w: inout (Vel), p: Pos) in w.x = p.x * 2 }
        #expect(world.get(Vel.self, of: 3)?.x == 6)
    }

    @Test func twoReadTwoWrite() {
        let world = World()
        for i in 0 ..< 4 {
            let e = world.createEntity()
            world.add(Pos(x: Double(i)), to: e)
            world.add(Vel(x: 1), to: e)
            world.add(Hp(points: 10), to: e)
            world.add(Tag(), to: e)
        }
        let family = Family(world: world, reading: Reading(Pos.self, Vel.self), writing: Writing(Hp.self, Tag.self))
        family.forEach { (w: inout (Hp, Tag), p: Pos, v: Vel) in
            w.0.points += Int(p.x + v.x)
            w.1.label = 7
        }
        #expect(world.get(Hp.self, of: 2)?.points == 13)
        #expect(world.get(Tag.self, of: 2)?.label == 7)
    }

    @Test func oneReadThreeWrite() {
        let world = World()
        let e = world.createEntity()
        world.add(Pos(x: 2), to: e)
        world.add(Vel(), to: e)
        world.add(Hp(), to: e)
        world.add(Tag(), to: e)
        let family = Family(world: world, reading: Reading(Pos.self), writing: Writing(Vel.self, Hp.self, Tag.self))
        family.forEach { (w: inout (Vel, Hp, Tag), p: Pos) in
            w.0.x = p.x
            w.1.points = 1
            w.2.label = 2
        }
        #expect(world.get(Vel.self, of: e)?.x == 2)
        #expect(world.get(Hp.self, of: e)?.points == 1)
        #expect(world.get(Tag.self, of: e)?.label == 2)
    }

    @Test func fourReadZeroWriteAndZeroReadFourWrite() {
        let world = World()
        let e = world.createEntity()
        world.add(Pos(x: 1), to: e)
        world.add(Vel(x: 2), to: e)
        world.add(Hp(points: 3), to: e)
        world.add(Tag(label: 4), to: e)
        let read = Family(world: world, reading: Reading(Pos.self, Vel.self, Hp.self, Tag.self), writing: Writing())
        var sum = 0.0
        read.forEach { (_: inout (), p: Pos, v: Vel, h: Hp, t: Tag) in sum += p.x + v.x + Double(h.points + t.label) }
        #expect(sum == 10)
        let write = Family(world: world, reading: Reading(), writing: Writing(Pos.self, Vel.self, Hp.self, Tag.self))
        write.forEach { (w: inout (Pos, Vel, Hp, Tag)) in
            w.0.x = 5
            w.1.x = 6
            w.2.points = 7
            w.3.label = 8
        }
        #expect(world.get(Pos.self, of: e)?.x == 5)
        #expect(world.get(Tag.self, of: e)?.label == 8)
    }

    @Test func membershipWithUnequalStorages() {
        let world = World()
        var withBoth: [Int] = []
        for i in 0 ..< 10 {
            let e = world.createEntity()
            if i % 2 == 0 { world.add(Pos(x: Double(i)), to: e) }
            if i % 3 == 0 { world.add(Vel(), to: e) }
            if i % 2 == 0, i % 3 == 0 { withBoth.append(e) }
        }
        let family = Family(world: world, reading: Reading(Pos.self), writing: Writing(Vel.self))
        var visited: [Int] = []
        family.forEach { (w: inout (Vel), p: Pos) in
            visited.append(Int(p.x))
            w.x = 1
        }
        #expect(Set(visited) == Set(withBoth))
        for e in 0 ..< 10 {
            #expect((world.get(Vel.self, of: e)?.x == 1) == withBoth.contains(e) || world.get(Vel.self, of: e) == nil)
        }
        #expect(visited.count == 2)
    }
}
