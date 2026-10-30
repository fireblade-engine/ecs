import Benchmark
import Foundation
import Testing
@testable import ECSBenchmarkResultSchema

/// The fast report read path must reproduce the native histogram arithmetic exactly.
@Suite
struct ReportHistogramReaderTests {
    private func values(seed: UInt64, count: Int, maximum: Int) -> [Int] {
        var state = seed
        return (0 ..< count).map { _ in
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            // Mix of small, medium and huge magnitudes, with zeros.
            let magnitude = Int(state >> 60) % 4
            let raw = Int(state >> 20) % (maximum >> (magnitude * 8) + 1)
            return raw
        }
    }

    @Test
    func storedHistogramsMatchTheNativeMeanAndPercentiles() throws {
        let metrics: [BenchmarkMetric] = [.wallClock, .throughput, .peakMemoryResident, .mallocCountTotal]
        var entries: [ReportFixtures.Entry] = []
        var results: [BenchmarkResult] = []
        for (offset, metric) in metrics.enumerated() {
            for (sample, size) in [(1, 1), (2, 7), (3, 500), (4, 20000)] {
                results.append(ReportFixtures.result(metric, values(seed: UInt64(offset * 10 + sample), count: size, maximum: 900_000_000)))
            }
        }
        // Metrics may appear once per benchmark, so spread the results over benchmarks.
        for (index, result) in results.enumerated() {
            entries.append(ReportFixtures.Entry(identity: ReportFixtures.w1, backend: "default", scale: index + 1, results: [result]))
        }
        let file = ReportFixtures.file(requested: "1.4.3", shaByte: "a", model: "class", backends: ["default"], entries: entries)
        let directory = try Support.scratchDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let path = directory.appendingPathComponent("file.json").path
        try BenchmarkResultFile.encoder().encode(file).write(to: URL(fileURLWithPath: path))

        let loaded = try ResultValidator.loadForReport(at: path)
        #expect(loaded.storedHistograms.count == results.count)
        for (identifier, original) in file.baseline.results {
            let fast = try #require(loaded.baseline.results[identifier])
            #expect(fast.count == original.count)
            for (a, b) in zip(fast, original) {
                let expected = ReportSample(b)
                let actual = ReportSample(a, stored: loaded.storedHistograms)
                #expect(actual.measurementCount == expected.measurementCount)
                #expect(actual.mean == expected.mean, "\(identifier.name) mean")
                #expect(actual.percentiles == expected.percentiles, "\(identifier.name) percentiles")
            }
        }
    }

    @Test
    func strippedFileLeavesNoCountsArray() throws {
        let file = ReportFixtures.classRef()
        let original = try BenchmarkResultFile.encoder().encode(file)
        let stripped = try StrippedResultFile(original)
        let text = String(decoding: stripped.data, as: UTF8.self)
        #expect(!text.contains(#""counts":[0"#) && !text.contains(#""counts":[1"#))
        #expect(stripped.data.count < original.count)
        #expect(!stripped.histograms.isEmpty)
    }

    @Test
    func truncatedCountsAreRejected() {
        #expect(throws: ResultError.self) { _ = try StrippedResultFile(Data(#"{"histogram":{"counts":[1,2"#.utf8)) }
    }
}
