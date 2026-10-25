// swiftlint:disable all
// Generated for the S2 benchmarks: 20 payload components, 16 tag components, one toggle tag.
import S2Storage

struct C0: Component { static let componentIndex = 0; var v = 1.0 }
struct C1: Component { static let componentIndex = 1; var v = 1.0 }
struct C2: Component { static let componentIndex = 2; var v = 1.0 }
struct C3: Component { static let componentIndex = 3; var v = 1.0 }
struct C4: Component { static let componentIndex = 4; var v = 1.0 }
struct C5: Component { static let componentIndex = 5; var v = 1.0 }
struct C6: Component { static let componentIndex = 6; var v = 1.0 }
struct C7: Component { static let componentIndex = 7; var v = 1.0 }
struct C8: Component { static let componentIndex = 8; var v = 1.0 }
struct C9: Component { static let componentIndex = 9; var v = 1.0 }
struct C10: Component { static let componentIndex = 10; var v = 1.0 }
struct C11: Component { static let componentIndex = 11; var v = 1.0 }
struct C12: Component { static let componentIndex = 12; var v = 1.0 }
struct C13: Component { static let componentIndex = 13; var v = 1.0 }
struct C14: Component { static let componentIndex = 14; var v = 1.0 }
struct C15: Component { static let componentIndex = 15; var v = 1.0 }
struct C16: Component { static let componentIndex = 16; var v = 1.0 }
struct C17: Component { static let componentIndex = 17; var v = 1.0 }
struct C18: Component { static let componentIndex = 18; var v = 1.0 }
struct C19: Component { static let componentIndex = 19; var v = 1.0 }
struct T0: Component { static let componentIndex = 20 }
struct T1: Component { static let componentIndex = 21 }
struct T2: Component { static let componentIndex = 22 }
struct T3: Component { static let componentIndex = 23 }
struct T4: Component { static let componentIndex = 24 }
struct T5: Component { static let componentIndex = 25 }
struct T6: Component { static let componentIndex = 26 }
struct T7: Component { static let componentIndex = 27 }
struct T8: Component { static let componentIndex = 28 }
struct T9: Component { static let componentIndex = 29 }
struct T10: Component { static let componentIndex = 30 }
struct T11: Component { static let componentIndex = 31 }
struct T12: Component { static let componentIndex = 32 }
struct T13: Component { static let componentIndex = 33 }
struct T14: Component { static let componentIndex = 34 }
struct T15: Component { static let componentIndex = 35 }
struct Toggle: Component { static let componentIndex = 36 }

/// Sets C0 ..< C(count) on the entity, all with value 1.
func addPayload<S: NexusStorageProviding>(_ storage: S, _ entity: EntityID, count: Int) {
    if count > 0 {
        storage.set(C0(), for: entity)
    }
    if count > 1 {
        storage.set(C1(), for: entity)
    }
    if count > 2 {
        storage.set(C2(), for: entity)
    }
    if count > 3 {
        storage.set(C3(), for: entity)
    }
    if count > 4 {
        storage.set(C4(), for: entity)
    }
    if count > 5 {
        storage.set(C5(), for: entity)
    }
    if count > 6 {
        storage.set(C6(), for: entity)
    }
    if count > 7 {
        storage.set(C7(), for: entity)
    }
    if count > 8 {
        storage.set(C8(), for: entity)
    }
    if count > 9 {
        storage.set(C9(), for: entity)
    }
    if count > 10 {
        storage.set(C10(), for: entity)
    }
    if count > 11 {
        storage.set(C11(), for: entity)
    }
    if count > 12 {
        storage.set(C12(), for: entity)
    }
    if count > 13 {
        storage.set(C13(), for: entity)
    }
    if count > 14 {
        storage.set(C14(), for: entity)
    }
    if count > 15 {
        storage.set(C15(), for: entity)
    }
    if count > 16 {
        storage.set(C16(), for: entity)
    }
    if count > 17 {
        storage.set(C17(), for: entity)
    }
    if count > 18 {
        storage.set(C18(), for: entity)
    }
    if count > 19 {
        storage.set(C19(), for: entity)
    }
}

/// Adds the tag components whose bit is set in `bits` (bit i selects Ti).
func addTags<S: NexusStorageProviding>(_ storage: S, _ entity: EntityID, bits: Int) {
    if bits & 1 != 0 {
        storage.set(T0(), for: entity)
    }
    if bits & 2 != 0 {
        storage.set(T1(), for: entity)
    }
    if bits & 4 != 0 {
        storage.set(T2(), for: entity)
    }
    if bits & 8 != 0 {
        storage.set(T3(), for: entity)
    }
    if bits & 16 != 0 {
        storage.set(T4(), for: entity)
    }
    if bits & 32 != 0 {
        storage.set(T5(), for: entity)
    }
    if bits & 64 != 0 {
        storage.set(T6(), for: entity)
    }
    if bits & 128 != 0 {
        storage.set(T7(), for: entity)
    }
    if bits & 256 != 0 {
        storage.set(T8(), for: entity)
    }
    if bits & 512 != 0 {
        storage.set(T9(), for: entity)
    }
    if bits & 1024 != 0 {
        storage.set(T10(), for: entity)
    }
    if bits & 2048 != 0 {
        storage.set(T11(), for: entity)
    }
    if bits & 4096 != 0 {
        storage.set(T12(), for: entity)
    }
    if bits & 8192 != 0 {
        storage.set(T13(), for: entity)
    }
    if bits & 16384 != 0 {
        storage.set(T14(), for: entity)
    }
    if bits & 32768 != 0 {
        storage.set(T15(), for: entity)
    }
}
