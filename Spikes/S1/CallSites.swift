// swiftlint:disable all
// Concrete, non-generic call sites so the optimizer specializes the generic forEach variants.
// Compiled by check-sil.sh together with Sources/S1FamilyAPI; not part of any package target.

public struct CPos: S1Component { public static let componentIndex = 0; var x = 0.0; var y = 0.0 }
public struct CVel: S1Component { public static let componentIndex = 1; var x = 0.0; var y = 0.0 }
public struct CHp: S1Component { public static let componentIndex = 2; var points = 0 }
public struct CTag: S1Component { public static let componentIndex = 3; var label = 0 }

public typealias F1R1W = Family<Reading<CPos>, Writing<CVel>>
public typealias F2R2W = Family<Reading<CPos, CVel>, Writing<CHp, CTag>>
public typealias F1R3W = Family<Reading<CPos>, Writing<CVel, CHp, CTag>>
public typealias F4R0W = Family<Reading<CPos, CVel, CHp, CTag>, Writing<>>
public typealias F0R4W = Family<Reading<>, Writing<CPos, CVel, CHp, CTag>>

@inline(never) public func site_A_1R1W(_ f: F1R1W) { f.forEach { (w: inout (CVel), p: CPos) in w.x = p.x + w.y } }
@inline(never) public func site_A_2R2W(_ f: F2R2W) { f.forEach { (w: inout (CHp, CTag), p: CPos, v: CVel) in w.0.points += Int(p.x + v.x); w.1.label = 1 } }
@inline(never) public func site_A_1R3W(_ f: F1R3W) { f.forEach { (w: inout (CVel, CHp, CTag), p: CPos) in w.0.x = p.x; w.1.points = 1; w.2.label = 2 } }
@inline(never) public func site_A_4R0W(_ f: F4R0W, _ sum: inout Double) { var s = 0.0; f.forEach { (_: inout (), p: CPos, v: CVel, h: CHp, t: CTag) in s += p.x + v.x + Double(h.points + t.label) }; sum = s }
@inline(never) public func site_A_0R4W(_ f: F0R4W) { f.forEach { (w: inout (CPos, CVel, CHp, CTag)) in w.0.x = 1; w.1.x = 2; w.2.points = 3; w.3.label = 4 } }

@inline(never) public func site_Mut_1R1W(_ f: F1R1W) { f.forEachMut { (p: CPos, v: Mut<CVel>) in v.x = p.x + v.y } }
@inline(never) public func site_Mut_2R2W(_ f: F2R2W) { f.forEachMut { (r: (CPos, CVel), h: Mut<CHp>, t: Mut<CTag>) in h.points += Int(r.0.x + r.1.x); t.label = 1 } }
@inline(never) public func site_Mut_1R3W(_ f: F1R3W) { f.forEachMut { (p: CPos, v: Mut<CVel>, h: Mut<CHp>, t: Mut<CTag>) in v.x = p.x; h.points = 1; t.label = 2 } }
@inline(never) public func site_Mut_0R4W(_ f: F0R4W) { f.forEachMut { (_: (), p: Mut<CPos>, v: Mut<CVel>, h: Mut<CHp>, t: Mut<CTag>) in p.x = 1; v.x = 2; h.points = 3; t.label = 4 } }
// `value` accessor instead of key-path dynamic members.
@inline(never) public func site_MutValue_1R1W(_ f: F1R1W) { f.forEachMut { (p: CPos, v: Mut<CVel>) in v.value.x = p.x + v.value.y } }
