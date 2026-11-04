import Benchmark
import ECSCompatSuite
import Foundation
import Testing
@testable import ECSBenchmarkResultSchema

enum Support {
    static let packageRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    static let realPackageResolved = packageRoot.appendingPathComponent("Package.resolved").path

    static let sha = String(repeating: "ab", count: 20)
    static let suiteSHA = String(repeating: "cd", count: 20)

    static func fixtureURL() throws -> URL {
        try #require(Bundle.module.url(forResource: "native-baseline", withExtension: "json", subdirectory: "Fixtures"))
    }

    static func loadFixtureEnvelope() throws -> NativeBaselineEnvelope {
        try JSONDecoder().decode(NativeBaselineEnvelope.self, from: Data(contentsOf: fixtureURL()))
    }

    static func scratchDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("result-schema-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    static let host = ResultHost(osName: "macOS", osVersion: "26.0.0", architecture: "arm64", cpuModel: "Test CPU", coreCount: 10, physicalMemoryBytes: 68_719_476_736)

    static func request(baseline: String, resolved: String? = nil) -> WriteRequest {
        WriteRequest(
            baselinePath: baseline, runID: "run-1", startedAt: "2026-10-29T10:00:00Z", finishedAt: "2026-10-29T10:05:00Z",
            requestedRef: "1.4.3", refSHA: sha, suiteSHA: suiteSHA, filter: "^entity.create.empty .* / 16$",
            packageResolvedPath: resolved ?? realPackageResolved, swiftVersion: "Apple Swift version 6.4\nTarget: arm64-apple-macosx26.0"
        )
    }

    static func writeEnvelope(_ envelope: NativeBaselineEnvelope, in directory: URL) throws -> String {
        let path = directory.appendingPathComponent("baseline.json")
        try JSONEncoder().encode(envelope).write(to: path)
        return path.path
    }

    /// Re-encodes a value into canonical JSON (sorted keys) for structural comparison.
    static func canonical(_ value: some Encodable) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(value)
    }

    /// Field-by-field comparison of two native results. Both must be fresh decodes whose statistics caches nobody touched, because
    /// `percentiles()` and `units()` populate caches; comparing them is the last thing done to either side.
    static func expectSameResult(_ actual: BenchmarkResult, _ expected: BenchmarkResult, _ label: String) throws {
        #expect(try canonical(actual.metric) == canonical(expected.metric), "\(label) metric")
        #expect(actual.metric.description == expected.metric.description, "\(label) metric description")
        #expect(actual.timeUnits == expected.timeUnits, "\(label) timeUnits")
        #expect(actual.scalingFactor == expected.scalingFactor, "\(label) scalingFactor")
        #expect(actual.warmupIterations == expected.warmupIterations, "\(label) warmupIterations")
        // Thresholds hold enum-keyed dictionaries, which JSON encodes in unspecified order: compare the dictionaries.
        #expect((actual.thresholds == nil) == (expected.thresholds == nil), "\(label) thresholds presence")
        #expect(actual.thresholds?.relative == expected.thresholds?.relative, "\(label) relative thresholds")
        #expect(actual.thresholds?.absolute == expected.thresholds?.absolute, "\(label) absolute thresholds")
        #expect(actual.tags == expected.tags, "\(label) tags")

        let a = actual.statistics
        let e = expected.statistics
        #expect(a.timeUnits == e.timeUnits, "\(label) statistics units")
        #expect(a.prefersLarger == e.prefersLarger, "\(label) polarity")
        #expect(a.measurementCount == e.measurementCount, "\(label) measurement count")
        #expect(a.onlyZeroMeasurements == e.onlyZeroMeasurements, "\(label) only zero")
        #expect(try canonical(a.histogram) == canonical(e.histogram), "\(label) histogram")
        #expect(a.histogram.mean == e.histogram.mean, "\(label) mean")
        #expect(a.histogram.stdDeviation == e.histogram.stdDeviation, "\(label) stddev")
        #expect(a.histogram.min == e.histogram.min, "\(label) min")
        #expect(a.histogram.max == e.histogram.max, "\(label) max")
        #expect(a.average == e.average, "\(label) average")
        #expect(a.percentiles() == e.percentiles(), "\(label) default percentiles")
        let integers = (0 ... 100).map(Double.init)
        #expect(a.percentiles(for: integers) == e.percentiles(for: integers), "\(label) integer percentiles")
        #expect(a.units() == e.units(), "\(label) resolved units")
    }

    static func expectSameEnvelope(_ actual: NativeBaselineEnvelope, _ expected: NativeBaselineEnvelope) throws {
        #expect(actual.baselineName == expected.baselineName)
        #expect(actual.machine == expected.machine)
        #expect(Set(actual.results.keys) == Set(expected.results.keys))
        for (identifier, expectedResults) in expected.results {
            let actualResults = try #require(actual.results[identifier])
            #expect(actualResults.count == expectedResults.count)
            for (index, expectedResult) in expectedResults.enumerated() {
                try expectSameResult(actualResults[index], expectedResult, "\(identifier.name) \(expectedResult.metric.description)")
            }
        }
    }

    /// Synthetic native result for one metric with non-default metadata.
    static func syntheticResult(metric: BenchmarkMetric, variant: Int) -> BenchmarkResult {
        let prefersLarger = metric.polarity == .prefersLarger
        let units: Statistics.Units = variant == 0 ? .automatic : .kilo
        let statistics = Statistics(maximumMeasurement: 1_000_000_000, numberOfSignificantDigits: variant == 2 ? .four : .three, units: units, prefersLarger: prefersLarger)
        switch variant {
        case 3:
            for _ in 0 ..< 5 { statistics.add(0) }
        default:
            for value in stride(from: 100, through: 250_000, by: 997) { statistics.add(value * (variant + 1)) }
        }
        return BenchmarkResult(
            metric: metric,
            timeUnits: variant == 1 ? .microseconds : .nanoseconds,
            scalingFactor: variant == 1 ? .kilo : .one,
            warmupIterations: 3 + variant,
            thresholds: variant == 1 ? BenchmarkThresholds(relative: [.p50: 5.0, .p99: 10.0], absolute: [.p90: 1_000]) : nil,
            tags: variant == 1 ? ["tag": "value", "other": "x"] : [:],
            statistics: statistics
        )
    }

    /// Envelope with one registered benchmark carrying every enabled metric in the given variant.
    static func syntheticEnvelope(variant: Int, name: String = Support.registeredName) -> NativeBaselineEnvelope {
        let results = CompatManifest.metrics.map { syntheticResult(metric: $0, variant: variant) }
        return NativeBaselineEnvelope(
            baselineName: "synthetic",
            machine: NativeBenchmarkMachine(hostname: "h", processors: 10, processorType: "arm64", memory: 64, kernelVersion: "Darwin"),
            results: [NativeBenchmarkIdentifier(target: CompatManifest.benchmarkTarget, name: name): results]
        )
    }

    /// A backend name registered for the compiled revision.
    static var backend: String { CompatManifest.backends[0] }
    static var registeredName: String { "entity.create.empty [\(backend)] / 16" }
}
