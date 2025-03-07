//
//  Version.swift
//
//
//  Created by Christian Treffs on 14.07.20.
//

/// A struct representing a semantic version.
///
/// See <https://semver.org> for details.
public struct Version {
    /// Major version.
    public let major: UInt

    /// Minor version.
    public let minor: UInt

    /// Patch version.
    public let patch: UInt

    /// Pre-release identifiers.
    public let prereleaseIdentifiers: [String]

    /// Build metadata identifiers.
    public let buildMetadataIdentifiers: [String]

    public init(_ major: UInt, _ minor: UInt, _ patch: UInt, prereleaseIdentifiers: [String] = [], buildMetadataIdentifiers: [String] = []) {
        self.major = major
        self.minor = minor
        self.patch = patch
        self.prereleaseIdentifiers = prereleaseIdentifiers
        self.buildMetadataIdentifiers = buildMetadataIdentifiers
    }

    public init?(decoding versionString: String) {
        let prereleaseStartIndex = versionString.firstIndex(of: "-")
        let metadataStartIndex = versionString.firstIndex(of: "+")

        let requiredEndIndex = prereleaseStartIndex ?? metadataStartIndex ?? versionString.endIndex
        let requiredCharacters = versionString.prefix(upTo: requiredEndIndex)
        let requiredComponents: [UInt] = requiredCharacters
            .split(separator: ".", maxSplits: 2, omittingEmptySubsequences: false)
            .map(String.init)
            .compactMap(UInt.init)

        guard requiredComponents.count == 3 else { return nil }

        major = requiredComponents[0]
        minor = requiredComponents[1]
        patch = requiredComponents[2]

        func identifiers(start: String.Index?, end: String.Index) -> [String] {
            guard let start else { return [] }
            let identifiers = versionString[versionString.index(after: start) ..< end]
            return identifiers.split(separator: ".").map(String.init)
        }

        prereleaseIdentifiers = identifiers(
            start: prereleaseStartIndex,
            end: metadataStartIndex ?? versionString.endIndex
        )
        buildMetadataIdentifiers = identifiers(
            start: metadataStartIndex,
            end: versionString.endIndex
        )
    }

    public var versionString: String {
        var versionString = "\(major).\(minor).\(patch)"
        if !prereleaseIdentifiers.isEmpty {
            versionString += "-" + prereleaseIdentifiers.joined(separator: ".")
        }
        if !buildMetadataIdentifiers.isEmpty {
            versionString += "+" + buildMetadataIdentifiers.joined(separator: ".")
        }
        return versionString
    }
}

extension Version: Equatable {}
extension Version: Comparable {
    func isEqualWithoutPrerelease(_ other: Version) -> Bool {
        major == other.major && minor == other.minor && patch == other.patch
    }

    public static func < (lhs: Version, rhs: Version) -> Bool {
        let lhsComparators = [lhs.major, lhs.minor, lhs.patch]
        let rhsComparators = [rhs.major, rhs.minor, rhs.patch]

        if lhsComparators != rhsComparators {
            return lhsComparators.lexicographicallyPrecedes(rhsComparators)
        }

        guard !lhs.prereleaseIdentifiers.isEmpty else {
            return false // Non-prerelease lhs >= potentially prerelease rhs
        }

        guard !rhs.prereleaseIdentifiers.isEmpty else {
            return true // Prerelease lhs < non-prerelease rhs
        }

        let zippedIdentifiers = zip(lhs.prereleaseIdentifiers, rhs.prereleaseIdentifiers)
        for (lhsPrereleaseIdentifier, rhsPrereleaseIdentifier) in zippedIdentifiers {
            if lhsPrereleaseIdentifier == rhsPrereleaseIdentifier {
                continue
            }

            let typedLhsIdentifier: Any = Int(lhsPrereleaseIdentifier) ?? lhsPrereleaseIdentifier
            let typedRhsIdentifier: Any = Int(rhsPrereleaseIdentifier) ?? rhsPrereleaseIdentifier

            switch (typedLhsIdentifier, typedRhsIdentifier) {
            case let (int1 as Int, int2 as Int): return int1 < int2
            case let (string1 as String, string2 as String): return string1 < string2
            case (is Int, is String): return true // Int prereleases < String prereleases
            case (is String, is Int): return false
            default:
                return false
            }
        }

        return lhs.prereleaseIdentifiers.count < rhs.prereleaseIdentifiers.count
    }
}

extension Version: ExpressibleByStringLiteral {
    public init(stringLiteral versionString: String) {
        guard let version = Version(decoding: versionString) else {
            fatalError("Malformed version string '\(versionString)'.")
        }
        self = version
    }
}

extension Version: CustomStringConvertible {
    public var description: String {
        versionString
    }
}

extension Version: CustomDebugStringConvertible {
    public var debugDescription: String {
        versionString
    }
}

extension Version: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let versionString = try container.decode(String.self)
        guard let version = Version(decoding: versionString) else {
            throw DecodingError.dataCorruptedError(in: container,
                                                   debugDescription: "Malformed version string '\(versionString)'.")
        }

        self = version
    }
}

extension Version: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(versionString)
    }
}
