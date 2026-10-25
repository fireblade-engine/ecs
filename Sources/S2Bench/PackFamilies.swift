// swiftlint:disable all
// Generated: parameter-pack family iteration over 8, 16 and 20 components (D7 fallback).
import S2Storage

@inline(never) func sumPack8<S: NexusStorageProviding>(_ storage: S) -> Double {
    var sum = 0.0
    storage.forEach(reading: C0.self, C1.self, C2.self, C3.self, C4.self, C5.self, C6.self, C7.self, where: .none) { a0, a1, a2, a3, a4, a5, a6, a7 in
        sum += a0.v
        sum += a1.v
        sum += a2.v
        sum += a3.v
        sum += a4.v
        sum += a5.v
        sum += a6.v
        sum += a7.v
    }
    return sum
}

@inline(never) func sumPack16<S: NexusStorageProviding>(_ storage: S) -> Double {
    var sum = 0.0
    storage.forEach(reading: C0.self, C1.self, C2.self, C3.self, C4.self, C5.self, C6.self, C7.self, C8.self, C9.self, C10.self, C11.self, C12.self, C13.self, C14.self, C15.self, where: .none) { a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15 in
        sum += a0.v
        sum += a1.v
        sum += a2.v
        sum += a3.v
        sum += a4.v
        sum += a5.v
        sum += a6.v
        sum += a7.v
        sum += a8.v
        sum += a9.v
        sum += a10.v
        sum += a11.v
        sum += a12.v
        sum += a13.v
        sum += a14.v
        sum += a15.v
    }
    return sum
}

@inline(never) func sumPack20<S: NexusStorageProviding>(_ storage: S) -> Double {
    var sum = 0.0
    storage.forEach(reading: C0.self, C1.self, C2.self, C3.self, C4.self, C5.self, C6.self, C7.self, C8.self, C9.self, C10.self, C11.self, C12.self, C13.self, C14.self, C15.self, C16.self, C17.self, C18.self, C19.self, where: .none) { a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19 in
        sum += a0.v
        sum += a1.v
        sum += a2.v
        sum += a3.v
        sum += a4.v
        sum += a5.v
        sum += a6.v
        sum += a7.v
        sum += a8.v
        sum += a9.v
        sum += a10.v
        sum += a11.v
        sum += a12.v
        sum += a13.v
        sum += a14.v
        sum += a15.v
        sum += a16.v
        sum += a17.v
        sum += a18.v
        sum += a19.v
    }
    return sum
}
