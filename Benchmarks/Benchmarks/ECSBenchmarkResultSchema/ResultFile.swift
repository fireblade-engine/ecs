import Benchmark
import ECSCompatSuite

// The per-ref result file: an app-owned wrapper with full provenance around the plugin's native baseline envelope.
// The schema is specified in Documentation/Benchmarks/PLAN.md ("Step 8 design").
import Foundation

public enum ResultSchema {
    public static let name = "fireblade-ecs-benchmark-result"
    public static let version = 1
    public static let buildMode = "release"

    /// The only configured metric the package may legitimately leave out of a benchmark: Benchmark 1.38.1 computes throughput as
    /// `round(1e9 / ns)` per iteration and records it only `if throughput > 0` (BenchmarkExecutor.swift), so a benchmark whose
    /// iterations all take about 2 s or longer has no throughput metric at all. Every other metric is mandatory.
    public static var optionalMetric: String { BenchmarkMetric.throughput.description }

    /// The recorded reason for a missing `optionalMetric`.
    public static let optionalMetricReason = "throughput not recorded by Benchmark 1.38.1: an iteration of about 2 s or longer rounds to 0 operations per second and the package records only throughput above 0"

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
    /// Position of this result in a replicated run (`Scripts/benchmark-run-refs.sh --replicates`). Optional and additive: a file
    /// without it counts as replicate 1 of 1. `startedAt`/`finishedAt` above are the replicate's own start and end.
    public var replicate: ResultReplicate?
}

public struct ResultReplicate: Codable, Equatable, Sendable {
    /// 1-based index of this replicate of its ref.
    public var index: Int
    /// Number of replicates requested per ref.
    public var count: Int
    /// 1-based round in which the replicate ran (each round runs every ref once).
    public var round: Int
    /// 1-based position of the ref within its round's shuffled order.
    public var position: Int
    /// Seed of the deterministic per-round shuffle.
    public var seed: UInt64

    public init(index: Int, count: Int, round: Int, position: Int, seed: UInt64) {
        self.index = index
        self.count = count
        self.round = round
        self.position = position
        self.seed = seed
    }
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
    /// Configured metrics the package did not record for this benchmark, each with the reason. Optional and additive: absent
    /// means every configured metric was recorded, so the schema version stays 1. Only `ResultSchema.optionalMetric` is allowed.
    public var unrecordedMetrics: [UnrecordedMetric]?

    public init(name: String, identity: String, backend: String, scale: Int, unrecordedMetrics: [UnrecordedMetric]? = nil) {
        self.name = name
        self.identity = identity
        self.backend = backend
        self.scale = scale
        self.unrecordedMetrics = unrecordedMetrics
    }
}

public struct UnrecordedMetric: Codable, Equatable, Sendable {
    /// The metric's description, as in the baseline (for example `Throughput (# / s)`).
    public var metric: String
    public var reason: String

    public init(metric: String, reason: String) {
        self.metric = metric
        self.reason = reason
    }
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
    /// Set only by `ResultValidator.loadForReport`: the histograms behind `baseline`, whose counts arrays were not decoded (see
    /// `StrippedResultFile`). Keyed by the ordinal stored in each decoded histogram's `highestTrackableValue`. Not part of the file.
    var storedHistograms: [UInt64: StoredHistogram] = [:]

    private enum CodingKeys: String, CodingKey {
        case schema, schemaVersion, run, ref, suite, packages, toolchain, host, workloads, unsupported, benchmarks, baseline
    }

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
