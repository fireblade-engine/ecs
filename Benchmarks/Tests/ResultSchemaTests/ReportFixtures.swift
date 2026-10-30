import Benchmark
import ECSCompatSuite
import Foundation
@testable import ECSBenchmarkResultSchema

/// Small synthetic result files built from native types, for the report tests. Identities come from the real manifest so the
/// files also pass the validator.
enum ReportFixtures {
    struct Entry {
        var identity: String
        var backend: String
        var scale: Int
        var results: [BenchmarkResult]
    }

    static var identities: [String] { CompatManifest.workloads.map(\.identity) }
    /// Present in every fixture.
    static var w1: String { identities[0] }
    /// Present in the first two fixtures only.
    static var w2: String { identities[1] }
    /// Present in the third fixture only.
    static var w3: String { identities[2] }

    /// Distribution with distinct values: mean 1700, p0/p25/p50 1000, p75/p90 2000, p99/p100 4000 (times `factor`).
    static func spread(_ factor: Int = 1) -> [Int] {
        Array(repeating: 1000 * factor, count: 5) + Array(repeating: 2000 * factor, count: 4) + [4000 * factor]
    }

    static func result(_ metric: BenchmarkMetric, _ values: [Int], timeUnits: BenchmarkTimeUnits = .nanoseconds, scaling: BenchmarkScalingFactor = .one, prefersLarger: Bool? = nil) -> BenchmarkResult {
        let statistics = Statistics(
            maximumMeasurement: 1_000_000_000,
            units: .automatic,
            prefersLarger: prefersLarger ?? (metric.polarity == .prefersLarger)
        )
        for value in values { statistics.add(value) }
        return BenchmarkResult(metric: metric, timeUnits: timeUnits, scalingFactor: scaling, warmupIterations: 0, statistics: statistics)
    }

    static func file(requested: String, shaByte: String, model: String, backends: [String], configurationHash: String = String(repeating: "1", count: 64), entries: [Entry]) -> BenchmarkResultFile {
        let used = Set(entries.map(\.identity))
        var results: [NativeBenchmarkIdentifier: [BenchmarkResult]] = [:]
        var benchmarks: [ResultBenchmark] = []
        for entry in entries {
            let name = "\(entry.identity) [\(entry.backend)] / \(entry.scale)"
            results[NativeBenchmarkIdentifier(target: CompatManifest.benchmarkTarget, name: name)] = entry.results
            benchmarks.append(ResultBenchmark(name: name, identity: entry.identity, backend: entry.backend, scale: entry.scale))
        }
        return BenchmarkResultFile(
            schema: ResultSchema.name,
            schemaVersion: ResultSchema.version,
            run: ResultRun(id: "run-\(requested)", startedAt: "2026-10-29T10:00:00Z", finishedAt: "2026-10-29T10:05:00Z"),
            ref: ResultRef(requested: requested, sha: String(repeating: shaByte, count: 40), componentModel: model, backends: backends),
            suite: ResultSuite(sha: Support.suiteSHA, target: CompatManifest.benchmarkTarget, filter: "^fixture$", configurationHash: configurationHash),
            packages: ResultSchema.requiredPins,
            toolchain: ResultToolchain(swiftVersion: "Apple Swift version 6.4\nTarget: arm64-apple-macosx26.0", buildMode: ResultSchema.buildMode),
            host: Support.host,
            workloads: CompatManifest.workloads.filter { used.contains($0.identity) },
            unsupported: Array(CompatManifest.unsupported.prefix(1)),
            benchmarks: benchmarks,
            baseline: NativeBaselineEnvelope(
                baselineName: "fixture",
                machine: NativeBenchmarkMachine(hostname: "h", processors: 10, processorType: "arm64", memory: 64, kernelVersion: "Darwin"),
                results: results
            )
        )
    }

    /// Class model, one backend. Scales 16, 64 and 4096 for w1 (the last lands in the large table). Zero baseline for `mallocCountTotal` of w2.
    static func classRef() -> BenchmarkResultFile {
        file(requested: "1.4.3", shaByte: "a", model: "class", backends: ["default"], entries: [
            Entry(identity: w1, backend: "default", scale: 16, results: [
                result(.wallClock, spread()),
                result(.cpuTotal, spread()),
                result(.throughput, [100_000, 200_000, 200_000, 400_000]),
                result(.peakMemoryResident, Array(repeating: 50_000_000, count: 4))
            ]),
            Entry(identity: w1, backend: "default", scale: 64, results: [result(.wallClock, spread(4))]),
            Entry(identity: w1, backend: "default", scale: 4096, results: [result(.wallClock, spread(40))]),
            Entry(identity: w2, backend: "default", scale: 16, results: [
                result(.wallClock, spread()),
                result(.mallocCountTotal, [0, 0, 0])
            ])
        ])
    }

    /// Value model, two backends. Time unit label microseconds (same raw nanoseconds), no throughput for archetype, no w2 for sparseSet.
    static func valueRef() -> BenchmarkResultFile {
        file(requested: "main", shaByte: "b", model: "value", backends: ["archetype", "sparseSet"], entries: [
            Entry(identity: w1, backend: "archetype", scale: 16, results: [
                result(.wallClock, spread(500), timeUnits: .microseconds),
                result(.cpuTotal, spread(500), timeUnits: .microseconds),
                result(.peakMemoryResident, Array(repeating: 100_000_000, count: 4))
            ]),
            Entry(identity: w1, backend: "archetype", scale: 4096, results: [result(.wallClock, spread(10))]),
            Entry(identity: w1, backend: "sparseSet", scale: 16, results: [
                result(.wallClock, spread(), timeUnits: .nanoseconds),
                result(.cpuTotal, spread()),
                result(.throughput, [100_000, 200_000, 200_000, 400_000])
            ]),
            Entry(identity: w2, backend: "archetype", scale: 16, results: [
                result(.wallClock, spread()),
                result(.mallocCountTotal, [5, 5, 5])
            ])
        ])
    }

    /// Value model, one backend, different configuration hash. Per-1000-iteration raw values with scaling factor kilo, an
    /// incompatible polarity for cpuTotal, and a workload only this file has.
    static func scaledRef() -> BenchmarkResultFile {
        file(requested: "candidate", shaByte: "c", model: "value", backends: ["archetype"], configurationHash: String(repeating: "2", count: 64), entries: [
            Entry(identity: w1, backend: "archetype", scale: 16, results: [
                result(.wallClock, spread(1000), timeUnits: .microseconds, scaling: .kilo),
                result(.cpuTotal, spread(), prefersLarger: true)
            ]),
            Entry(identity: w3, backend: "archetype", scale: 16, results: [result(.wallClock, spread())])
        ])
    }
}
