// Report-only N-way comparison of saved result files, specified in PLAN.md ("Report v2 design" and "Statistical design v3"). A pure
// function from decoded result files to the contents of a report directory (REPORT.md, per-workload pages, SVG plots): no
// file access, no processes, no benchmark runs, and the inputs are never mutated.
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

/// One file of the report directory.
public struct RenderedFile: Equatable {
    /// Relative to the report directory, with forward slashes.
    public let path: String
    public let contents: String
}

public struct RenderedReport {
    /// REPORT.md, the overview.
    public let markdown: String
    /// Every file of the report directory in a fixed order, REPORT.md first.
    public let files: [RenderedFile]
    /// Also printed in the report's own warnings section.
    public let warnings: [String]
}

/// Errors of `BenchmarkReport.render` caused by inputs that were not validated or cannot be combined.
public enum ReportError: Error, CustomStringConvertible, Equatable {
    /// Two entries of one input share a benchmark name; names are the key into the baseline.
    case duplicateBenchmarkName(input: String, name: String)
    /// Two inputs of one series (ref SHA and component model) claim the same replicate index.
    case duplicateReplicate(series: String, index: Int)
    /// Replicates of one series were measured with different suite configurations and cannot be pooled.
    case configurationMismatch(series: String, hashes: [String])

    public var description: String {
        switch self {
        case let .duplicateBenchmarkName(input, name): "input '\(input)' lists the benchmark '\(name)' more than once"
        case let .duplicateReplicate(series, index):
            "series '\(series)' has more than one input for replicate \(index); files without replicate fields count as replicate 1 of 1"
        case let .configurationMismatch(series, hashes):
            "the replicates of series '\(series)' have different configuration hashes (\(hashes.map { String($0.prefix(12)) }.joined(separator: ", "))) and cannot be pooled"
        }
    }
}

public enum BenchmarkReport {
    /// Renders the comparison of already validated result files.
    public static func render(_ files: [BenchmarkResultFile], options: ReportOptions = ReportOptions()) throws -> RenderedReport {
        guard files.count >= 2 else { throw ResultError("a report needs at least two result files, got \(files.count)") }
        for file in files {
            var seen = Set<String>()
            for benchmark in file.benchmarks where !seen.insert(benchmark.name).inserted {
                throw ReportError.duplicateBenchmarkName(input: file.ref.requested, name: benchmark.name)
            }
        }
        let model = try ReportModel(files: files, baseline: options.baseline)
        var writer = ReportWriter(model: model, title: options.title)
        let rendered = writer.render()
        return RenderedReport(markdown: rendered[0].contents, files: rendered, warnings: model.warnings)
    }
}

struct ReportKey: Hashable {
    let identity: String
    let scale: Int
    let metric: String
}

/// The result files of one ref: same SHA and component model, one file per replicate.
struct ReportGroup {
    let label: String
    let requested: String
    let sha: String
    let componentModel: String
    let backends: [String]
    /// Indices into `ReportModel.files`, ordered by replicate index.
    let fileIndices: [Int]
    /// Replicate index per entry of `fileIndices`.
    let replicateIndices: [Int]
    /// Number of replicates the runner was asked for (1 without provenance).
    let expectedReplicates: Int
}

/// The native statistics of one replicate of one cell.
struct ReportReplicateSample {
    let replicate: Int
    let round: Int
    let sample: ReportSample
}

struct ReportSeries {
    let label: String
    let groupIndex: Int
    let backend: String
    /// Replicate samples per cell, ordered by replicate index.
    var replicates: [ReportKey: [ReportReplicateSample]] = [:]
    /// Per-cell aggregate over replicates; filled by the model.
    var cells: [ReportKey: ReportCell] = [:]
}

struct ReportModel {
    let files: [BenchmarkResultFile]
    let groups: [ReportGroup]
    let baselineGroup: Int
    var series: [ReportSeries]
    /// Metric description to its native metric, for ordering and polarity wording.
    let metrics: [String: BenchmarkMetric]
    /// Every cell of any series, sorted by workload, scale and metric order.
    let keys: [ReportKey]
    private(set) var warnings: [String]
    /// Wall-clock inference; see `ReportInference`.
    private(set) var comparisons: [ReportComparisonKey: ReportComparison] = [:]
    private(set) var drift: [ReportDriftCell] = []

    init(files: [BenchmarkResultFile], baseline requested: String?) throws {
        self.files = files
        // Group by (ref SHA, component model), in order of first appearance.
        var order: [String] = []
        var members: [String: [Int]] = [:]
        for (index, file) in files.enumerated() {
            let key = "\(file.ref.sha)\n\(file.ref.componentModel)"
            if members[key] == nil { order.append(key) }
            members[key, default: []].append(index)
        }
        let labels = Self.makeGroupLabels(order.map { files[members[$0]![0]].ref })
        var groups: [ReportGroup] = []
        var warnings: [String] = []
        for (position, key) in order.enumerated() {
            let indices = members[key]!
            let first = files[indices[0]].ref
            func replicateIndex(_ file: Int) -> Int { files[file].run.replicate?.index ?? 1 }
            var seen = Set<Int>()
            for file in indices where !seen.insert(replicateIndex(file)).inserted {
                throw ReportError.duplicateReplicate(series: "\(labels[position]) (\(first.componentModel))", index: replicateIndex(file))
            }
            let hashes = Set(indices.map { files[$0].suite.configurationHash })
            if hashes.count > 1 {
                throw ReportError.configurationMismatch(series: "\(labels[position]) (\(first.componentModel))", hashes: hashes.sorted())
            }
            let ordered = indices.sorted { replicateIndex($0) < replicateIndex($1) }
            let expected = max(1, ordered.map { files[$0].run.replicate?.count ?? 1 }.max() ?? 1)
            let present = ordered.map(replicateIndex)
            let missing = (1 ... expected).filter { !present.contains($0) }
            if !missing.isEmpty {
                warnings.append("Incomplete replicate set for '\(labels[position])' (\(first.componentModel)): \(present.count) of \(expected) replicates present, missing \(missing.map(String.init).joined(separator: ", ")). Intervals and tests use the replicates that exist.")
            }
            if Set(ordered.map { files[$0].run.replicate?.count ?? 1 }).count > 1 {
                warnings.append("The replicates of '\(labels[position])' (\(first.componentModel)) disagree on the requested replicate count; the largest, \(expected), is used.")
            }
            var backendSeen = Set<String>()
            let backends = ordered.flatMap { files[$0].ref.backends }.filter { backendSeen.insert($0).inserted }
            groups.append(ReportGroup(
                label: labels[position], requested: first.requested, sha: first.sha, componentModel: first.componentModel, backends: backends,
                fileIndices: ordered, replicateIndices: present, expectedReplicates: expected
            ))
        }
        self.groups = groups

        baselineGroup = try Self.resolveBaseline(files, groups, requested)

        var metrics: [String: BenchmarkMetric] = [:]
        var series: [ReportSeries] = []
        for (groupIndex, group) in groups.enumerated() {
            var perBackend: [String: ReportSeries] = [:]
            for backend in group.backends {
                perBackend[backend] = ReportSeries(label: "\(group.label) (\(group.componentModel), \(backend))", groupIndex: groupIndex, backend: backend)
            }
            for (position, fileIndex) in group.fileIndices.enumerated() {
                let file = files[fileIndex]
                let byName = Dictionary(uniqueKeysWithValues: file.benchmarks.map { ($0.name, $0) })
                let round = file.run.replicate?.round ?? 1
                for (identifier, results) in file.baseline.results.sorted(by: { $0.key.name < $1.key.name }) {
                    guard let benchmark = byName[identifier.name] else { continue }
                    for result in results {
                        metrics[result.metric.description] = result.metric
                        let key = ReportKey(identity: benchmark.identity, scale: benchmark.scale, metric: result.metric.description)
                        perBackend[benchmark.backend]?.replicates[key, default: []].append(
                            ReportReplicateSample(replicate: group.replicateIndices[position], round: round, sample: ReportSample(result))
                        )
                    }
                }
            }
            series += group.backends.compactMap { perBackend[$0] }
        }
        for index in series.indices {
            for (key, samples) in series[index].replicates {
                series[index].cells[key] = ReportCell(samples)
            }
        }
        self.series = series
        self.metrics = metrics
        keys = Self.sortedKeys(series, metrics)
        self.warnings = warnings

        self.warnings += groupWarnings()
        let analysis = ReportInference.analyse(self)
        comparisons = analysis.comparisons
        drift = analysis.drift
    }

    private func groupWarnings() -> [String] {
        var warnings: [String] = []
        let hashes = Set(groups.map { files[$0.fileIndices[0]].suite.configurationHash })
        if hashes.count > 1 {
            let detail = groups.map { "\($0.label): \(String(files[$0.fileIndices[0]].suite.configurationHash.prefix(12)))" }.joined(separator: "; ")
            warnings.append("Configuration hashes differ across refs (\(detail)); the runs did not use the same suite configuration, so differences may not reflect the refs alone.")
        }
        let counts = groups.map { $0.fileIndices.count }
        if Set(counts).count > 1 {
            let detail = groups.map { "\($0.label): \($0.fileIndices.count)" }.joined(separator: "; ")
            warnings.append("Refs have different numbers of replicates (\(detail)); every comparison uses the replicates each side has.")
        }
        let batches = groups.map { Set($0.fileIndices.compactMap { files[$0].run.batchId }) }
        if batches.contains(where: { $0.count > 1 }) || Set(batches.filter { !$0.isEmpty }).count > 1 {
            warnings.append("The inputs come from more than one runner batch (batch ids differ); replicates and refs were not interleaved in a single run, so drift is not controlled across them.")
        }
        warnings += comparabilityWarnings()
        return warnings
    }

    /// Differences between refs that make a comparison less trustworthy: toolchain, host (without the physical memory size,
    /// which can differ by reporting rounding between otherwise identical machines), the set of registered benchmarks. Replicates of
    /// one ref that differ show up as a value with several alternatives. Measurement counts legitimately differ between series
    /// (time-based sampling), so the report states that once instead of warning.
    private func comparabilityWarnings() -> [String] {
        var warnings: [String] = []
        func values(_ group: ReportGroup, _ describe: (BenchmarkResultFile) -> String) -> String {
            Set(group.fileIndices.map { describe(files[$0]) }).sorted().joined(separator: " | ")
        }
        func describe(_ perGroup: [String]) -> String {
            groups.indices.map { "\(groups[$0].label): \(perGroup[$0])" }.joined(separator: "; ")
        }

        let toolchains = groups.map { values($0) { "\($0.toolchain.swiftVersion.replacingOccurrences(of: "\n", with: " / ")) (\($0.toolchain.buildMode))" } }
        if Set(toolchains).count > 1 {
            warnings.append("Toolchains differ across refs or replicates (\(describe(toolchains))).")
        }
        let hosts = groups.map { values($0) { "\($0.host.osName) \($0.host.osVersion), \($0.host.architecture), \($0.host.cpuModel), \($0.host.coreCount) cores" } }
        if Set(hosts).count > 1 {
            warnings.append("Hosts differ across refs or replicates (\(describe(hosts))); results of different machines are not comparable.")
        }
        // Backend names are part of a benchmark name and legitimately differ between refs, so compare workload and scale.
        let sets = groups.map { group in
            Set(group.fileIndices.flatMap { files[$0].benchmarks.map { "\($0.identity) / \($0.scale)" } })
        }
        if Set(sets).count > 1 {
            let union = sets.reduce(into: Set<String>()) { $0.formUnion($1) }
            let notEverywhere = union.filter { entry in sets.contains { !$0.contains(entry) } }.sorted()
            let shown = notEverywhere.prefix(5).map { "`\($0)`" }.joined(separator: ", ")
            warnings.append("The registered benchmark sets differ across refs: \(notEverywhere.count) workload and scale combinations are not in every ref (\(shown)\(notEverywhere.count > 5 ? ", ..." : "")).")
        }
        return warnings
    }

    static func makeGroupLabels(_ refs: [ResultRef]) -> [String] {
        let requestedCounts = Dictionary(refs.map { ($0.requested, 1) }, uniquingKeysWith: +)
        var labels = refs.map { requestedCounts[$0.requested]! > 1 ? "\($0.requested)@\($0.sha.prefix(12))" : $0.requested }
        var seen: [String: Int] = [:]
        for index in labels.indices {
            let count = (seen[labels[index]] ?? 0) + 1
            seen[labels[index]] = count
            if count > 1 {
                labels[index] += " #\(count)"
            }
        }
        return labels
    }

    static func resolveBaseline(_ files: [BenchmarkResultFile], _ groups: [ReportGroup], _ requested: String?) throws -> Int {
        guard let requested else { return 0 }
        let matches = groups.indices.filter { groups[$0].requested == requested }
        guard let first = matches.first else {
            let available = Set(groups.map(\.requested)).sorted().joined(separator: ", ")
            throw ResultError("unknown baseline '\(requested)'; the inputs are: \(available)")
        }
        guard Set(matches.map { groups[$0].sha }).count == 1 else {
            throw ResultError("baseline '\(requested)' is ambiguous: several inputs request it with different SHAs")
        }
        return first
    }

    /// Index of the series a series is compared with: the baseline series of the same backend, else the baseline's only backend.
    func pairedSeries(for index: Int) -> Int? {
        let candidates = series.indices.filter { series[$0].groupIndex == baselineGroup }
        if let same = candidates.first(where: { series[$0].backend == series[index].backend }) {
            return same
        }
        return candidates.count == 1 ? candidates[0] : nil
    }

    private static func sortedKeys(_ series: [ReportSeries], _ metrics: [String: BenchmarkMetric]) -> [ReportKey] {
        func metricOrder(_ description: String) -> String {
            let preferred = ["wallClock", "cpuTotal", "throughput", "peakMemoryResident", "mallocCountTotal"]
            let raw = metrics[description]?.rawDescription ?? description
            let rank = preferred.firstIndex(of: raw) ?? preferred.count
            return "\(rank)-\(description)"
        }
        let order = Dictionary(uniqueKeysWithValues: Set(metrics.keys).map { ($0, metricOrder($0)) })
        return Set(series.flatMap { $0.replicates.keys }).sorted { lhs, rhs in
            if lhs.identity != rhs.identity {
                return lhs.identity < rhs.identity
            }
            if lhs.scale != rhs.scale {
                return lhs.scale < rhs.scale
            }
            return order[lhs.metric]! < order[rhs.metric]!
        }
    }

    /// The description of the wall-clock metric, when any input has it.
    var wallClockMetric: String? {
        metrics.first { $0.value.rawDescription == "wallClock" }?.key
    }

    func isBaseline(_ series: Int) -> Bool {
        self.series[series].groupIndex == baselineGroup
    }
}
