// swiftlint:disable all
// Generated: parameter-pack family iteration over 8, 16 and 20 components (D7 fallback).
import S2Storage

@inline(never) func sumPack8(_ storage: S2Nexus) -> Double {
    var bits: UInt64 = 0
    storage.forEach(reading: C0.self, C1.self, C2.self, C3.self, C4.self, C5.self, C6.self, C7.self, where: .none) { a0, a1, a2, a3, a4, a5, a6, a7 in
        bits ^= a0.v.bitPattern
        bits ^= a1.v.bitPattern
        bits ^= a2.v.bitPattern
        bits ^= a3.v.bitPattern
        bits ^= a4.v.bitPattern
        bits ^= a5.v.bitPattern
        bits ^= a6.v.bitPattern
        bits ^= a7.v.bitPattern
    }
    return Double(bitPattern: bits)
}

@inline(never) func sumPack16(_ storage: S2Nexus) -> Double {
    var bits: UInt64 = 0
    storage.forEach(reading: C0.self, C1.self, C2.self, C3.self, C4.self, C5.self, C6.self, C7.self, C8.self, C9.self, C10.self, C11.self, C12.self, C13.self, C14.self, C15.self, where: .none) { a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15 in
        bits ^= a0.v.bitPattern
        bits ^= a1.v.bitPattern
        bits ^= a2.v.bitPattern
        bits ^= a3.v.bitPattern
        bits ^= a4.v.bitPattern
        bits ^= a5.v.bitPattern
        bits ^= a6.v.bitPattern
        bits ^= a7.v.bitPattern
        bits ^= a8.v.bitPattern
        bits ^= a9.v.bitPattern
        bits ^= a10.v.bitPattern
        bits ^= a11.v.bitPattern
        bits ^= a12.v.bitPattern
        bits ^= a13.v.bitPattern
        bits ^= a14.v.bitPattern
        bits ^= a15.v.bitPattern
    }
    return Double(bitPattern: bits)
}

@inline(never) func sumPack20(_ storage: S2Nexus) -> Double {
    var bits: UInt64 = 0
    storage.forEach(reading: C0.self, C1.self, C2.self, C3.self, C4.self, C5.self, C6.self, C7.self, C8.self, C9.self, C10.self, C11.self, C12.self, C13.self, C14.self, C15.self, C16.self, C17.self, C18.self, C19.self, where: .none) { a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19 in
        bits ^= a0.v.bitPattern
        bits ^= a1.v.bitPattern
        bits ^= a2.v.bitPattern
        bits ^= a3.v.bitPattern
        bits ^= a4.v.bitPattern
        bits ^= a5.v.bitPattern
        bits ^= a6.v.bitPattern
        bits ^= a7.v.bitPattern
        bits ^= a8.v.bitPattern
        bits ^= a9.v.bitPattern
        bits ^= a10.v.bitPattern
        bits ^= a11.v.bitPattern
        bits ^= a12.v.bitPattern
        bits ^= a13.v.bitPattern
        bits ^= a14.v.bitPattern
        bits ^= a15.v.bitPattern
        bits ^= a16.v.bitPattern
        bits ^= a17.v.bitPattern
        bits ^= a18.v.bitPattern
        bits ^= a19.v.bitPattern
    }
    return Double(bitPattern: bits)
}
