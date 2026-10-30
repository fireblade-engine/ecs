import Benchmark
import ECSCompatSuite
import Foundation
import Testing
@testable import ECSBenchmarkResultSchema

/// Synthetic multi-replicate inputs: grouping, the exact statistics wiring, BH across workloads, verdict paths, drift and the
/// failure modes of the replicate model.
@Suite
struct ReportReplicateTests {
    typealias F = ReportFixtures

    private var w4: String { F.identities[3] }

    /// Baseline replicate medians: close together, so equal series fall inside the +-5% zone.
    private func base(_ replicate: Int) -> Int { 1000 + 4 * replicate }

    /// Replicated files of one ref and backend; `median(replicate, scale)` is that replicate's wall-clock median.
    private func ref(
        _ requested: String, _ shaByte: String, model: String = "value", backend: String = "default", k: Int = 10,
        indices: [Int]? = nil, workloads: [String], scales: [Int] = [16], configurationHash: String = String(repeating: "1", count: 64),
        median: @escaping (_ workload: String, _ replicate: Int, _ scale: Int) -> Int
    ) -> [BenchmarkResultFile] {
        (indices ?? Array(1 ... k)).map { index in
            F.file(
                requested: requested, shaByte: shaByte, model: model, backends: [backend], configurationHash: configurationHash,
                replicate: ResultReplicate(index: index, count: k, round: index, position: 1, seed: 7),
                entries: workloads.flatMap { workload in
                    scales.map { scale in
                        F.Entry(identity: workload, backend: backend, scale: scale, results: [F.result(.wallClock, F.distribution(median: median(workload, index, scale)))])
                    }
                }
            )
        }
    }

    /// Baseline plus one series with a different relation per workload: w1 twice as fast, w2 twice as slow, w3 equal, w4 noisy.
    private var verdictCases: [BenchmarkResultFile] {
        let workloads = [F.w1, F.w2, F.w3, w4]
        let baseline = ref("1.4.3", "a", model: "class", workloads: workloads) { _, i, _ in base(i) }
        let series = ref("main", "b", workloads: workloads) { workload, i, _ in
            switch workload {
            case F.w1: base(i) / 2
            case F.w2: base(i) * 2
            case F.w3: base(i) + 1
            default: base(i) + (i % 2 == 0 ? 300 : -300) + 20 * i
            }
        }
        return baseline + series
    }

    private func model(_ files: [BenchmarkResultFile]) throws -> ReportModel {
        try ReportModel(files: files, baseline: "1.4.3")
    }

    private func wall(_ model: ReportModel) throws -> String { try #require(model.wallClockMetric) }

    private func comparison(_ model: ReportModel, _ identity: String, scale: Int = 16, series: Int = 1) throws -> ReportComparison {
        try #require(model.comparisons[ReportComparisonKey(series: series, key: ReportKey(identity: identity, scale: scale, metric: wall(model)))])
    }

    // MARK: Grouping

    @Test
    func filesAreGroupedIntoSeriesAndReplicates() throws {
        let m = try model(verdictCases)
        #expect(m.groups.count == 2 && m.series.count == 2)
        #expect(m.groups.map(\.fileIndices.count) == [10, 10])
        #expect(m.groups.map(\.replicateIndices) == [Array(1 ... 10), Array(1 ... 10)])
        #expect(m.warnings.isEmpty)
        let key = ReportKey(identity: F.w1, scale: 16, metric: try wall(m))
        let cell = try #require(m.series[0].cells[key])
        #expect(cell.replicates == 10 && cell.replicateMedians.count == 10)
        // Centre: median of the replicate medians; error bar: [x(2), x(9)] with exact coverage 97.9%.
        let medians = cell.replicateMedians.sorted()
        #expect(abs(cell.median - (medians[4] + medians[5]) / 2) < 1e-9)
        let interval = try #require(cell.interval)
        #expect(interval.low == medians[1] && interval.high == medians[8] && abs(interval.coverage - 0.9785) < 0.001)
        // Within-run IQR is the median over replicates of p25 and p75 (7 of 10 samples sit at the median, so p25 = median).
        #expect(cell.iqrLow <= cell.median && cell.iqrHigh >= cell.median)
    }

    @Test
    func replicateOrderOfInputsDoesNotChangeTheReport() throws {
        let files = verdictCases
        let reversed = Array(files[0 ..< 10].reversed()) + Array(files[10...].reversed())
        let a = try BenchmarkReport.render(files, options: ReportOptions(baseline: "1.4.3")).files
        let b = try BenchmarkReport.render(reversed, options: ReportOptions(baseline: "1.4.3")).files
        #expect(a == b)
    }

    @Test
    func duplicateReplicateIndexIsRejected() throws {
        var files = verdictCases
        files[3] = files[2]
        #expect(throws: ReportError.duplicateReplicate(series: "1.4.3 (class)", index: 3)) { try BenchmarkReport.render(files) }
        #expect(ReportError.duplicateReplicate(series: "s", index: 2).description.contains("replicate 2"))
    }

    @Test
    func mismatchedConfigurationHashesWithinASeriesAreRejected() throws {
        var files = verdictCases
        files[4].suite.configurationHash = String(repeating: "9", count: 64)
        #expect(throws: ReportError.configurationMismatch(series: "1.4.3 (class)", hashes: [String(repeating: "1", count: 64), String(repeating: "9", count: 64)])) {
            try BenchmarkReport.render(files)
        }
        // Between refs it stays a warning: the report is still readable, and says so.
        var other = verdictCases
        for index in 10 ..< 20 { other[index].suite.configurationHash = String(repeating: "2", count: 64) }
        let rendered = try BenchmarkReport.render(other)
        #expect(rendered.warnings.contains { $0.contains("Configuration hashes differ across refs") })
    }

    @Test
    func incompleteReplicateSetsWarnInTheReportAndTheWarningList() throws {
        var files = verdictCases
        files.remove(at: 12)
        files.remove(at: 12)
        let rendered = try BenchmarkReport.render(files, options: ReportOptions(baseline: "1.4.3"))
        let warning = try #require(rendered.warnings.first { $0.contains("Incomplete replicate set") })
        #expect(warning.contains("'main'") && warning.contains("8 of 10") && warning.contains("missing 3, 4"))
        #expect(rendered.markdown.contains("## Warnings") && rendered.markdown.contains("missing 3, 4"))
        #expect(rendered.warnings.contains { $0.contains("different numbers of replicates") })
    }

    // MARK: Statistics wiring and verdicts

    @Test
    func verdictPathsOfExactStatistics() throws {
        let m = try model(verdictCases)
        let faster = try comparison(m, F.w1)
        #expect(faster.verdict == .faster && abs(faster.speed! - 2) < 0.05)
        #expect(faster.ciLow! > 1.05 && faster.ciHigh! >= faster.speed! && faster.q! < 0.05 && faster.p! < 0.001)
        #expect(abs(faster.change! - (1 / faster.speed! - 1) * 100) < 1e-9)
        #expect(faster.coverage! > 0.95)
        let slower = try comparison(m, F.w2)
        #expect(slower.verdict == .slower && abs(slower.speed! - 0.5) < 0.02 && slower.ciHigh! < 1 / 1.05)
        let equal = try comparison(m, F.w3)
        #expect(equal.verdict == .equivalent, "\(equal)")
        let noisy = try comparison(m, w4)
        #expect(noisy.verdict == .inconclusive, "\(noisy)")
        // The exact smallest attainable p for 10 against 10 is 2 / C(20, 10).
        #expect(abs(faster.p! - 2 / 184_756) < 1e-9)
    }

    @Test
    func tablesAndSummaryShowIntervalsQAndVerdicts() throws {
        let rendered = try BenchmarkReport.render(verdictCases, options: ReportOptions(baseline: "1.4.3"))
        let text = rendered.markdown
        for verdict in ["faster", "slower", "equivalent", "inconclusive"] {
            #expect(text.contains(">\(verdict)</td>"), "\(verdict)")
        }
        #expect(!text.contains("n/a (1 replicate)"))
        let page = try #require(rendered.files.first { $0.path == "workloads/\(F.w1).md" }).contents
        // 10 replicates, a CI on the median, q below 0.001 and the speed with its CI.
        let rows = try ReportTableParser.rows(page, heading: "### Time (wall clock): Entity counts up to 1,024")
        let row = try #require(rows.dropFirst(3).first { $0.first == "16" })
        #expect(row[5] == "10" && row[2] != "n/a" && !row[2].hasPrefix("n/a") && !row[3].hasPrefix("n/a"))
        #expect(row[18] == "faster" && row[17] == "&lt;0.001")
        #expect(Double(row[13])! > 1.9 && Double(row[14])! > 1.05 && Double(row[15])! > Double(row[14])!)
        #expect(row[16].hasPrefix("-"), "change (%) of a faster series is negative: \(row[16])")
    }

    @Test
    func benjaminiHochbergRunsAcrossEveryWorkloadAndScale() throws {
        // 6 replicates: the smallest attainable p is 2 / C(12, 6) = 0.00216. Two separated cells among 60 identical ones have
        // q = 0.00216 * 62 / 2 = 0.067, so they are not significant, although each raw p is far below 0.05.
        let scales = Array(1 ... 60) + [1000, 2000]
        func build(_ scales: [Int]) throws -> ReportModel {
            let baseline = ref("1.4.3", "a", model: "class", k: 6, workloads: [F.w1], scales: scales) { _, i, _ in base(i) }
            let series = ref("main", "b", k: 6, workloads: [F.w1], scales: scales) { _, i, scale in scale >= 1000 ? base(i) / 2 : base(i) }
            return try model(baseline + series)
        }
        let many = try build(scales)
        let separated = try comparison(many, F.w1, scale: 1000)
        #expect(abs(separated.p! - 2.0 / 924) < 1e-9)
        #expect(abs(separated.q! - 2.0 / 924 * 62 / 2) < 1e-9, "q = \(separated.q!)")
        #expect(separated.verdict == .inconclusive, "raw p < 0.05 but q > 0.05")
        #expect(try comparison(many, F.w1, scale: 5).q == 1)
        // Without the filler the same cells pass.
        let few = try build([1, 2, 1000, 2000])
        #expect(try comparison(few, F.w1, scale: 1000).verdict == .faster)
        #expect(try comparison(few, F.w1, scale: 1000).q! < 0.05)
        // The count of tests in the methods section covers all workloads and scales.
        let report = try BenchmarkReport.render(
            ref("1.4.3", "a", model: "class", k: 6, workloads: [F.w1], scales: scales) { _, i, _ in base(i) }
                + ref("main", "b", k: 6, workloads: [F.w1], scales: scales) { _, i, _ in base(i) },
            options: ReportOptions(baseline: "1.4.3")
        )
        #expect(report.markdown.contains("across all 62 wall-clock comparisons"))
    }

    @Test
    func fewReplicatesGiveNoIntervalButStillAMedian() throws {
        // k = 4 per side: no 95% interval of the median (needs 6), but the speed CI exists (C(8,4) = 70 >= 40).
        let baseline = ref("1.4.3", "a", model: "class", k: 4, workloads: [F.w1]) { _, i, _ in base(i) }
        let series = ref("main", "b", k: 4, workloads: [F.w1]) { _, i, _ in base(i) / 2 }
        let m = try model(baseline + series)
        let cell = try #require(m.series[0].cells[ReportKey(identity: F.w1, scale: 16, metric: wall(m))])
        #expect(cell.interval == nil && cell.median > 0)
        let item = try comparison(m, F.w1)
        #expect(item.ciLow != nil && item.coverage! > 0.95)
        // p = 2 / C(8, 4) = 0.029 and a single test: q = p < 0.05, so the verdict is decided by the CI alone.
        #expect(abs(item.p! - 2.0 / 70) < 1e-9 && item.verdict == .faster)
    }

    @Test
    func singleReplicateOnOneSideMakesTheVerdictNotAvailable() throws {
        let baseline = [F.classRef()]
        let series = ref("main", "b", workloads: [F.w1]) { _, i, _ in base(i) }
        let rendered = try BenchmarkReport.render(baseline + series, options: ReportOptions(baseline: "1.4.3"))
        #expect(rendered.markdown.contains("n/a (1 replicate)"))
        #expect(!rendered.markdown.contains(">faster<") && !rendered.markdown.contains(">slower<"))
        #expect(rendered.warnings.contains { $0.contains("different numbers of replicates") })
    }

    // MARK: Drift

    @Test
    func driftIsReportedWhenAtLeastThreeReplicatesTrend() throws {
        // A monotone trend over 5 rounds has an exact two-sided p of 2 / 120.
        let baseline = ref("1.4.3", "a", model: "class", k: 5, workloads: [F.w1]) { _, i, _ in 1000 + 40 * i }
        let series = ref("main", "b", k: 5, workloads: [F.w1]) { _, i, _ in 800 + (i % 2 == 0 ? 10 : -10) }
        let m = try model(baseline + series)
        #expect(m.drift.count == 2)
        let trending = try #require(m.drift.first { $0.series == 0 })
        #expect(abs(trending.p - 2.0 / 120) < 1e-9 && trending.isFlagged && trending.tau == 1)
        let report = try BenchmarkReport.render(baseline + series, options: ReportOptions(baseline: "1.4.3")).markdown
        #expect(report.contains("**Drift:**") && report.contains("1 cell shows a significant trend"))
        #expect(report.contains("1.4.3 (class, default)") && report.contains("/ `\(F.w1)` @ 16"))
        let methods = try #require(report.components(separatedBy: "## Methods").last)
        #expect(methods.contains("Benjamini–Hochberg adjusted across 2 tests"))
    }

    // MARK: Output

    @Test
    func methodsStateProtocolEstimatorsAndLimits() throws {
        let rendered = try BenchmarkReport.render(verdictCases, options: ReportOptions(baseline: "1.4.3"))
        let methods = try #require(rendered.markdown.components(separatedBy: "## Methods").last?.components(separatedBy: "## Provenance").first)
        for expected in [
            "k = 10", "interleaved rounds", "seed 7", "batch `batch-1`", "97.9%", "Hodges–Lehmann", "Mann–Whitney", "Benjamini–Hochberg",
            "δ = 5%", "[1/1.05, 1.05]", "Kendall", "built once", "recorded host and toolchain", "relinks the build before each replicate"
        ] {
            #expect(methods.contains(expected), "\(expected)")
        }
        #expect(!rendered.markdown.contains("Welch"))
    }

    @Test
    func plotsCarryErrorBarsBandsAndTheRelativeLayers() throws {
        let workloads = [F.w1]
        let baseline = ref("1.4.3", "a", model: "class", workloads: workloads, scales: [16, 64, 256]) { _, i, scale in base(i) * scale }
        let series = ref("main", "b", workloads: workloads, scales: [16, 64, 256]) { _, i, scale in base(i) * scale / 2 }
        let files = try BenchmarkReport.render(baseline + series, options: ReportOptions(baseline: "1.4.3")).files
        let paths = files.map(\.path)
        for suffix in ["per-entity", "total", "relative", "total-linear"] {
            #expect(paths.contains("img/\(F.w1)-\(suffix).svg"), "\(suffix)")
        }
        func svg(_ suffix: String) throws -> String { try #require(files.first { $0.path == "img/\(F.w1)-\(suffix).svg" }).contents }
        for file in files where file.path.hasSuffix(".svg") {
            let parser = XMLParser(data: Data(file.contents.utf8))
            #expect(parser.parse(), "\(file.path): \(parser.parserError.map { "\($0)" } ?? "")")
        }
        #expect(try svg("per-entity").contains(#"<path class="errbar"#) && svg("per-entity").contains("Error bars: CI of the median, 97.9%"))
        #expect(try svg("per-entity").contains(#"<polygon class="band"#))
        let relative = try svg("relative")
        #expect(relative.contains(#"<rect class="zone""#) && relative.contains(#"<polygon class="ribbon"#) && relative.contains(#"<line class="ref""#))
        #expect(!relative.components(separatedBy: "\n").contains { $0.contains("marker c1 hollow") }, "all points are significant: filled")
        #expect(try svg("total-linear").contains("Entities (linear scale)"))
        // REPORT.md embeds per-entity, total and relative; the detail page adds the linear plot.
        let report = try #require(files.first { $0.path == "REPORT.md" }).contents
        #expect(report.contains("(img/\(F.w1)-per-entity.svg)") && report.contains("(img/\(F.w1)-total.svg)") && report.contains("(img/\(F.w1)-relative.svg)"))
        #expect(!report.contains("total-linear"))
        #expect(try #require(files.first { $0.path == "workloads/\(F.w1).md" }).contents.contains("(../img/\(F.w1)-total-linear.svg)"))
    }

    @Test
    func replicatedOutputIsByteIdentical() throws {
        let first = try BenchmarkReport.render(verdictCases, options: ReportOptions(baseline: "1.4.3")).files
        let second = try BenchmarkReport.render(verdictCases, options: ReportOptions(baseline: "1.4.3")).files
        #expect(first == second)
        #expect(first.map(\.contents).allSatisfy { !$0.contains("\r") && $0.hasSuffix("\n") })
    }
}

/// Table cells of the first HTML table after a heading line.
enum ReportTableParser {
    static func rows(_ page: String, heading: String) throws -> [[String]] {
        let lines = page.components(separatedBy: "\n")[...]
        let headingIndex = try #require(lines.firstIndex { $0.hasPrefix(heading) })
        let opening = try #require(lines[headingIndex...].firstIndex(of: "<table>"))
        let closing = try #require(lines[opening...].firstIndex(of: "</table>"))
        let cells = try Regex(#"<t[dh]([^>]*)>(.*?)</t[dh]>"#)
        return lines[opening ..< closing].filter { $0.hasPrefix("<tr>") }.map { row in
            row.matches(of: cells).map { String(row[$0.output[2].range!]) }
        }
    }
}
