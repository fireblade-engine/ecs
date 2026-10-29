// Report-only N-way comparison of saved result files, specified in PLAN.md ("Step 10 design"). A pure function from decoded
// result files to a Markdown string: no file access, no processes, no benchmark runs, and the inputs are never mutated.
import Benchmark
import Foundation

public struct ReportOptions: Sendable {
    public var title: String
    /// Requested ref of the baseline input; nil selects the first input.
    public var baseline: String?

    public init(title: String = "FirebladeECS benchmark comparison", baseline: String? = nil) {
        self.title = title
        self.baseline = baseline
    }
}

public struct RenderedReport {
    public let markdown: String
    /// Also printed in the report's own warnings section.
    public let warnings: [String]
}

public enum BenchmarkReport {
    /// Renders the comparison of already validated result files.
    public static func render(_ files: [BenchmarkResultFile], options: ReportOptions = ReportOptions()) throws -> RenderedReport {
        guard files.count >= 2 else { throw ResultError("a report needs at least two result files, got \(files.count)") }
        let baselineIndex = try resolveBaseline(files, options.baseline)
        let model = ReportModel(files: files, baselineIndex: baselineIndex)
        var writer = ReportWriter(model: model, title: options.title)
        return RenderedReport(markdown: writer.render(), warnings: model.warnings)
    }

    static func resolveBaseline(_ files: [BenchmarkResultFile], _ requested: String?) throws -> Int {
        guard let requested else { return 0 }
        let matches = files.indices.filter { files[$0].ref.requested == requested }
        guard let first = matches.first else {
            let available = Set(files.map(\.ref.requested)).sorted().joined(separator: ", ")
            throw ResultError("unknown baseline '\(requested)'; the inputs are: \(available)")
        }
        guard Set(matches.map { files[$0].ref.sha }).count == 1 else {
            throw ResultError("baseline '\(requested)' is ambiguous: several inputs request it with different SHAs")
        }
        return first
    }
}

struct ReportKey: Hashable {
    let identity: String
    let scale: Int
    let metric: String
}

struct ReportSeries {
    let label: String
    let fileIndex: Int
    let backend: String
    var samples: [ReportKey: ReportSample] = [:]
}

struct ReportModel {
    let files: [BenchmarkResultFile]
    let baselineIndex: Int
    let fileLabels: [String]
    let series: [ReportSeries]
    /// Metric description to its native metric, for ordering and polarity wording.
    let metrics: [String: BenchmarkMetric]
    let warnings: [String]

    init(files: [BenchmarkResultFile], baselineIndex: Int) {
        self.files = files
        self.baselineIndex = baselineIndex
        let labels = Self.makeFileLabels(files)
        fileLabels = labels

        var metrics: [String: BenchmarkMetric] = [:]
        var series: [ReportSeries] = []
        for (index, file) in files.enumerated() {
            let byName = Dictionary(uniqueKeysWithValues: file.benchmarks.map { ($0.name, $0) })
            var perBackend: [String: ReportSeries] = [:]
            for backend in file.ref.backends {
                perBackend[backend] = ReportSeries(label: "\(labels[index]) (\(file.ref.componentModel), \(backend))", fileIndex: index, backend: backend)
            }
            for (identifier, results) in file.baseline.results {
                guard let benchmark = byName[identifier.name] else { continue }
                for result in results {
                    metrics[result.metric.description] = result.metric
                    perBackend[benchmark.backend]?.samples[ReportKey(identity: benchmark.identity, scale: benchmark.scale, metric: result.metric.description)] = ReportSample(result)
                }
            }
            series += file.ref.backends.compactMap { perBackend[$0] }
        }
        self.series = series
        self.metrics = metrics

        var warnings: [String] = []
        let bySHA = Dictionary(grouping: files.indices, by: { files[$0].ref.sha })
        for sha in bySHA.keys.sorted() where bySHA[sha]!.count > 1 {
            let names = bySHA[sha]!.map { "'\(labels[$0])'" }.joined(separator: ", ")
            warnings.append("Inputs \(names) share ref SHA \(sha); they are compared anyway.")
        }
        let hashes = Set(files.map(\.suite.configurationHash))
        if hashes.count > 1 {
            let detail = files.indices.map { "\(labels[$0]): \(String(files[$0].suite.configurationHash.prefix(12)))" }.joined(separator: "; ")
            warnings.append("Configuration hashes differ across inputs (\(detail)); the runs did not use the same suite configuration, so differences may not reflect the refs alone.")
        }
        self.warnings = warnings
    }

    static func makeFileLabels(_ files: [BenchmarkResultFile]) -> [String] {
        let requestedCounts = Dictionary(files.map { ($0.ref.requested, 1) }, uniquingKeysWith: +)
        var labels = files.map { requestedCounts[$0.ref.requested]! > 1 ? "\($0.ref.requested)@\($0.ref.sha.prefix(12))" : $0.ref.requested }
        var seen: [String: Int] = [:]
        for index in labels.indices {
            let count = (seen[labels[index]] ?? 0) + 1
            seen[labels[index]] = count
            if count > 1 { labels[index] += " #\(count)" }
        }
        return labels
    }

    /// Index of the series a series is compared with: the baseline series of the same backend, else the baseline's only backend.
    func pairedSeries(for index: Int) -> Int? {
        let candidates = series.indices.filter { series[$0].fileIndex == baselineIndex }
        if let same = candidates.first(where: { series[$0].backend == series[index].backend }) { return same }
        return candidates.count == 1 ? candidates[0] : nil
    }

    var keys: [ReportKey] {
        let all = Set(series.flatMap { $0.samples.keys })
        return all.sorted { lhs, rhs in
            if lhs.identity != rhs.identity { return lhs.identity < rhs.identity }
            if lhs.scale != rhs.scale { return lhs.scale < rhs.scale }
            return metricOrder(lhs.metric) < metricOrder(rhs.metric)
        }
    }

    private func metricOrder(_ description: String) -> String {
        let preferred = ["wallClock", "cpuTotal", "throughput", "peakMemoryResident", "mallocCountTotal"]
        let raw = metrics[description]?.rawDescription ?? description
        let rank = preferred.firstIndex(of: raw) ?? preferred.count
        return "\(rank)-\(description)"
    }
}
