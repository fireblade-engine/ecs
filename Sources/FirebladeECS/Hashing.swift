//
//  Hashing.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 16.10.17.
//

#if arch(x86_64) || arch(arm64) // 64 bit
private let kFibA: UInt = 0x9e3779b97f4a7c15 // = 11400714819323198485 aka Fibonacci Hash a value for 2^64; calculate by: 2^64 / (golden ratio)
#elseif arch(i386) || arch(arm) // 32 bit
private let kFibA: UInt = 0x9e3779b9 // = 2654435769 aka Fibonacci Hash a value for 2^32; calculate by: 2^32 / (golden ratio)
#else
#error("unsupported architecture")
#endif

/// entity id ^ component identifier hash
public typealias EntityComponentHash = Int

/// component object identifier hash value
public typealias ComponentTypeHash = Int

// MARK: - hash combine
/// Calculates the combined hash of two values. This implementation is based on boost::hash_combine.
/// Will always produce the same result for the same combination of seed and value during the single run of a program.
///
/// - Parameters:
///   - seed: seed hash.
///   - value: value to be combined with seed hash.
/// - Returns: combined hash value.
public func hash(combine seed: Int, _ value: Int) -> Int {
    /// http://www.boost.org/doc/libs/1_65_1/doc/html/hash/combine.html
    /// http://www.boost.org/doc/libs/1_65_1/doc/html/hash/reference.html#boost.hash_combine
    /// http://www.boost.org/doc/libs/1_65_1/boost/functional/hash/hash.hpp
    /// http://book.huihoo.com/data-structures-and-algorithms-with-object-oriented-design-patterns-in-c++/html/page214.html
    /// https://stackoverflow.com/a/35991300
    /// https://stackoverflow.com/a/4948967
    /*
     let phi = (1.0 + sqrt(5.0)) / 2 // golden ratio
     let a32 = pow(2.0,32.0) / phi
     let a64 = pow(2.0,64.0) / phi
     */
    var uSeed = UInt(bitPattern: seed)
    let uValue = UInt(bitPattern: value)
    uSeed ^= uValue &+ kFibA &+ (uSeed << 6) &+ (uSeed >> 2)
    return Int(bitPattern: uSeed)
}

/// Calculates the combined hash value of the elements. This implementation is based on boost::hash_range.
/// Is sensitive to the order of the elements.
/// - Parameter hashValues: sequence of hash values to combine.
/// - Returns: combined hash value.
public func hash<S: Sequence>(combine hashValues: S) -> Int where S.Element == Int {
    /// http://www.boost.org/doc/libs/1_65_1/doc/html/hash/reference.html#boost.hash_range_idp517643120
    return hashValues.reduce(0) { hash(combine: $0, $1) }
}

/// Calculates the combined hash value of the elements. This implementation is based on boost::hash_range.
/// Is sensitive to the order of the elements.
/// - Parameter hashValues: sequence of hash values to combine.
/// - Returns: combined hash value.
public func hash<H: Sequence>(combine hashables: H) -> Int where H.Element: Hashable {
    /// http://www.boost.org/doc/libs/1_65_1/doc/html/hash/reference.html#boost.hash_range_idp517643120
    return hashables.reduce(0) { hash(combine: $0, $1.hashValue) }
}

// MARK: - entity component hash
extension EntityComponentHash {
    internal static func compose(entityId: EntityIdentifier, componentTypeHash: ComponentTypeHash) -> EntityComponentHash {
        let entityIdSwapped = UInt(entityId.id).byteSwapped // needs to be 64 bit
        let componentTypeHashUInt = UInt(bitPattern: componentTypeHash)
        let hashUInt: UInt = componentTypeHashUInt ^ entityIdSwapped
        return Int(bitPattern: hashUInt)
    }

    internal static func decompose(_ hash: EntityComponentHash, with entityId: EntityIdentifier) -> ComponentTypeHash {
        let entityIdSwapped = UInt(entityId.id).byteSwapped
        let entityIdSwappedInt = Int(bitPattern: entityIdSwapped)
        return hash ^ entityIdSwappedInt
    }

    internal static func decompose(_ hash: EntityComponentHash, with componentTypeHash: ComponentTypeHash) -> EntityIdentifier {
        let entityId: Int = (hash ^ componentTypeHash).byteSwapped
        return EntityIdentifier(UInt32(truncatingIfNeeded: entityId))
    }
}

// MARK: - string hashing
/// https://stackoverflow.com/a/52440609
public enum StringHashing {
    /// *Waren Singer djb2*
    ///
    /// <https://stackoverflow.com/a/43149500>
    public static func singer_djb2(_ utf8String: String) -> UInt {
        var hash = UInt(5381)
        var iter = utf8String.unicodeScalars.makeIterator()
        while let char = iter.next() {
            hash = 127 * (hash & 0x00ffffffffffffff) + UInt(char.value)
        }
        return hash
    }

    /// *Dan Bernstein djb2*
    ///
    /// This algorithm (k=33) was first reported by dan bernstein many years ago in comp.lang.c.
    /// Another version of this algorithm (now favored by bernstein) uses xor: hash(i) = hash(i - 1) * 33 ^ str[i];
    /// The magic of number 33 (why it works better than many other constants, prime or not) has never been adequately explained.
    ///
    /// <http://www.cse.yorku.ca/~oz/hash.html>
    public static func bernstein_djb2(_ string: String) -> UInt {
        var hash: UInt = 5381
        var iter = string.unicodeScalars.makeIterator()
        while let char = iter.next() {
            hash = (hash << 5) &+ hash &+ UInt(char.value)
            //hash = ((hash << 5) + hash) + UInt(c.value)
        }
        return hash
    }

    /// *sdbm*
    ///
    /// This algorithm was created for sdbm (a public-domain reimplementation of ndbm) database library.
    /// It was found to do well in scrambling bits, causing better distribution of the keys and fewer splits.
    /// It also happens to be a good general hashing function with good distribution.
    ///
    /// <http://www.cse.yorku.ca/~oz/hash.html>
    public static func sdbm(_ string: String) -> UInt {
        var hash: UInt = 0
        var iter = string.unicodeScalars.makeIterator()
        while let char = iter.next() {
            hash = (UInt(char.value) &+ (hash << 6) &+ (hash << 16))
        }
        return hash
    }
}
