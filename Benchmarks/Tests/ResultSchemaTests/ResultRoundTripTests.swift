import Benchmark
import ECSCompatSuite
import Foundation
import Testing
@testable import ECSBenchmarkResultSchema

private let hasFixtureBackend = CompatManifest.backends.contains("archetype")

@Suite
struct ResultRoundTripTests {
    @Test
    func enabledMetricsAreDeclaredOnce() {
        let names = CompatManifest.metrics.map(\.description)
        #expect(Set(names).count == names.count)
        let encoded = CompatManifest.metrics.compactMap { try? String(decoding: Support.canonical($0), as: UTF8.self) }
        for required in [BenchmarkMetric.wallClock, .cpuTotal, .throughput, .peakMemoryResident] {
            #expect(CompatManifest.metrics.contains(required), "\(required)")
        }
        #expect(encoded.count == names.count)
        #expect(CompatManifest.configurationDescription.contains(names.joined(separator: ",")))
    }

    /// Every enabled metric, four synthetic variants each (default, non-default units/scaling/thresholds/tags, four significant
    /// digits, zero-only), through the real writer, the encoder and the validator's decoder.
    @Test(arguments: 0 ..< 4)
    func syntheticResultsRoundTripFieldByField(variant: Int) throws {
        let directory = try Support.scratchDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        // The writer decodes its own copy; the expectation is a third, independent decode of the same bytes.
        let baselinePath = try Support.writeEnvelope(Support.syntheticEnvelope(variant: variant), in: directory)
        let expected = try JSONDecoder().decode(NativeBaselineEnvelope.self, from: Data(contentsOf: URL(fileURLWithPath: baselinePath)))

        let file = try ResultWriter.makeFile(Support.request(baseline: baselinePath), host: Support.host)
        let data = try BenchmarkResultFile.encoder().encode(file)
        let decoded = try ResultValidator.decode(data)

        #expect(decoded.baseline.results.values.first?.count == CompatManifest.metrics.count)
        try Support.expectSameEnvelope(decoded.baseline, expected)
    }

    @Test
    func variantsCoverBothPolaritiesAndZeroOnlyStatistics() throws {
        let results = (0 ..< 4).flatMap { variant in CompatManifest.metrics.map { Support.syntheticResult(metric: $0, variant: variant) } }
        #expect(results.contains { $0.statistics.prefersLarger })
        #expect(results.contains { !$0.statistics.prefersLarger })
        #expect(results.contains { $0.statistics.onlyZeroMeasurements })
        #expect(results.contains { $0.thresholds != nil })
        #expect(results.contains { !$0.tags.isEmpty })
    }

    @Test(.enabled(if: hasFixtureBackend))
    func realPluginBaselineRoundTripsFieldByField() throws {
        let directory = try Support.scratchDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let expected = try Support.loadFixtureEnvelope()
        let key = try #require(expected.results.keys.first)
        let results = try #require(expected.results[key])
        // The fixture was produced by the plugin with exactly the enabled metrics, one benchmark.
        #expect(results.map(\.metric.description) == CompatManifest.metrics.map(\.description))
        for result in results { #expect(result.statistics.measurementCount > 0) }

        let file = try ResultWriter.makeFile(Support.request(baseline: Support.fixtureURL().path), host: Support.host)
        let decoded = try ResultValidator.decode(BenchmarkResultFile.encoder().encode(file))
        try Support.expectSameEnvelope(decoded.baseline, expected)
        // Written from the file itself, not just from memory: re-read the bytes from disk.
        let path = directory.appendingPathComponent("result.json").path
        try ResultWriter.write(Support.request(baseline: Support.fixtureURL().path), to: path, host: Support.host)
        let reread = try ResultValidator.validateFile(at: path)
        try Support.expectSameEnvelope(reread.baseline, expected)
    }

    @Test(.enabled(if: hasFixtureBackend))
    func resultFileCarriesNativeBaselineReadableByThePluginLayout() throws {
        // The embedded baseline keeps the plugin's layout: the same top-level keys and a flat key/value results array.
        let file = try ResultWriter.makeFile(Support.request(baseline: Support.fixtureURL().path), host: Support.host)
        let json = try #require(JSONSerialization.jsonObject(with: BenchmarkResultFile.encoder().encode(file)) as? [String: Any])
        let baseline = try #require(json["baseline"] as? [String: Any])
        #expect(Set(baseline.keys) == ["baselineName", "machine", "results"])
        let results = try #require(baseline["results"] as? [Any])
        #expect(results.count == 2)
        let original = try #require(JSONSerialization.jsonObject(with: Data(contentsOf: Support.fixtureURL())) as? [String: Any])
        #expect(Set(try #require(original["machine"] as? [String: Any]).keys) == Set(try #require(baseline["machine"] as? [String: Any]).keys))
    }

    /// The writer must not mutate completed statistics (percentile and unit caches): the embedded statistics JSON, caches
    /// included, equals the plugin's file.
    @Test(.enabled(if: hasFixtureBackend))
    func embeddedStatisticsJSONEqualsThePluginFile() throws {
        func statistics(_ baseline: [String: Any]) throws -> [NSDictionary] {
            let flat = try #require(baseline["results"] as? [Any])
            return try stride(from: 1, to: flat.count, by: 2).flatMap { index in
                try #require(flat[index] as? [[String: Any]]).map { try #require($0["statistics"] as? NSDictionary) }
            }
        }
        let original = try #require(JSONSerialization.jsonObject(with: Data(contentsOf: Support.fixtureURL())) as? [String: Any])
        let file = try ResultWriter.makeFile(Support.request(baseline: Support.fixtureURL().path), host: Support.host)
        let written = try #require(JSONSerialization.jsonObject(with: BenchmarkResultFile.encoder().encode(file)) as? [String: Any])
        let embedded = try #require(written["baseline"] as? [String: Any])
        let expected = try statistics(original)
        #expect(expected.count == CompatManifest.metrics.count)
        #expect(try statistics(embedded) == expected)
        #expect(embedded["baselineName"] as? String == original["baselineName"] as? String)
        #expect(embedded["machine"] as? NSDictionary == original["machine"] as? NSDictionary)
    }

    @Test
    func encodingIsDeterministic() throws {
        let directory = try Support.scratchDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        // Variants without thresholds: JSON encodes enum-keyed dictionaries in unspecified order, which is native behavior.
        var envelope = Support.syntheticEnvelope(variant: 0)
        for scale in [0, 1, 1024] {
            let other = Support.syntheticEnvelope(variant: 2, name: "entity.create.empty [\(Support.backend)] / \(scale)")
            envelope.results.merge(other.results) { first, _ in first }
        }
        let path = try Support.writeEnvelope(envelope, in: directory)
        let first = try BenchmarkResultFile.encoder().encode(ResultWriter.makeFile(Support.request(baseline: path), host: Support.host))
        let second = try BenchmarkResultFile.encoder().encode(ResultWriter.makeFile(Support.request(baseline: path), host: Support.host))
        #expect(first == second)
    }
}
