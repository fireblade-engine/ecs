import ECSCompatSuite

// The per-ref result file: an app-owned wrapper with full provenance around the plugin's native baseline envelope.
// The schema is specified in Documentation/Benchmarks/PLAN.md ("Step 8 design").
import Foundation

public enum ResultSchema {
    public static let name = "fireblade-ecs-benchmark-result"
    public static let version = 1
    public static let buildMode = "release"

    /// The only Benchmark and hdrhistogram-swift revisions whose native encoding this tool reads and writes
    /// (Benchmarks/Package.resolved at the time of writing). Anything else is refused.
    public static let requiredPins: [PackagePin] = [
        PackagePin(identity: "benchmark", version: "1.38.1", revision: "ca4a9d300fc15d38132853c2e30462337b33c43f"),
        PackagePin(identity: "hdrhistogram-swift", version: "0.2.0", revision: "c2e1210df04b4fff47e53f2f9dad9cc45ae15d63")
    ]
}

public struct PackagePin: Codable, Equatable, Sendable {
    public var identity: String
    public var version: String?
    public var revision: String

    public init(identity: String, version: String?, revision: String) {
        self.identity = identity
        self.version = version
        self.revision = revision
    }
}

public struct ResultRun: Codable, Equatable, Sendable {
    public var id: String
    /// ISO 8601 UTC.
    public var startedAt: String
    public var finishedAt: String
    /// One id per runner invocation (`Scripts/benchmark-run-refs.sh`), shared by all results of that invocation. Optional and
    /// additive: files without it still decode and validate, so the schema version stays 1.
    public var batchId: String?
}

public struct ResultRef: Codable, Equatable, Sendable {
    public var requested: String
    public var sha: String
    public var componentModel: String
    public var backends: [String]
}

public struct ResultSuite: Codable, Equatable, Sendable {
    public var sha: String
    public var target: String
    public var filter: String
    /// SHA-256 (hex) over suite SHA, filter, enabled metrics and the iteration constants.
    public var configurationHash: String
}

public struct ResultToolchain: Codable, Equatable, Sendable {
    public var swiftVersion: String
    public var buildMode: String
}

public struct ResultHost: Codable, Equatable, Sendable {
    public var osName: String
    public var osVersion: String
    public var architecture: String
    public var cpuModel: String
    /// Logical cores.
    public var coreCount: Int
    public var physicalMemoryBytes: UInt64
}

public struct ResultBenchmark: Codable, Equatable, Sendable {
    /// The native benchmark name, key into the baseline.
    public var name: String
    public var identity: String
    public var backend: String
    public var scale: Int
}

public struct BenchmarkResultFile: Codable {
    public var schema: String
    public var schemaVersion: Int
    public var run: ResultRun
    public var ref: ResultRef
    public var suite: ResultSuite
    public var packages: [PackagePin]
    public var toolchain: ResultToolchain
    public var host: ResultHost
    public var workloads: [CompatManifest.Workload]
    public var unsupported: [CompatManifest.Unsupported]
    public var benchmarks: [ResultBenchmark]
    public var baseline: NativeBaselineEnvelope

    public static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return encoder
    }
}

public struct ResultError: Error, CustomStringConvertible {
    public let description: String
    public init(_ description: String) {
        self.description = description
    }
}

/// Configuration hash: SHA-256 over the suite SHA, the filter and the suite configuration (enabled metrics, iteration constants).
public func configurationHash(suiteSHA: String, filter: String, configuration: String) -> String {
    SHA256.hexDigest("suite=\(suiteSHA)\nfilter=\(filter)\n\(configuration)")
}
