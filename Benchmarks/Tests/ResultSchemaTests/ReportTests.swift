import Benchmark
import Foundation
import Testing
@testable import ECSBenchmarkResultSchema

@Suite
struct ReportTests {
    private func render(_ files: [BenchmarkResultFile], baseline: String? = nil) throws -> String {
        try BenchmarkReport.render(files, options: ReportOptions(baseline: baseline)).markdown
    }

    private func renderFiles(_ files: [BenchmarkResultFile], baseline: String? = nil) throws -> [String: String] {
        Dictionary(uniqueKeysWithValues: try BenchmarkReport.render(files, options: ReportOptions(baseline: baseline)).files.map { ($0.path, $0.contents) })
    }

    private var all: [BenchmarkResultFile] { [ReportFixtures.classRef(), ReportFixtures.valueRef(), ReportFixtures.scaledRef()] }

    /// A second input that differs from the class fixture only in its identity.
    private func twin(_ requested: String) -> BenchmarkResultFile {
        var file = ReportFixtures.classRef()
        file.ref.requested = requested
        file.ref.sha = String(repeating: "d", count: 40)
        return file
    }

    // MARK: Helpers for the HTML tables

    /// The cells of every `<tr>` of the first table after `heading`, which itself follows the line `section`.
    private func table(_ page: String, section: String? = nil, heading: String) throws -> [[String]] {
        var lines = page.components(separatedBy: "\n")[...]
        if let section {
            let start = try #require(lines.firstIndex { $0.hasPrefix(section) })
            lines = lines[start...]
        }
        let headingIndex = try #require(lines.firstIndex { $0.hasPrefix(heading) })
        let opening = try #require(lines[headingIndex...].firstIndex(of: "<table>"))
        let closing = try #require(lines[opening...].firstIndex(of: "</table>"))
        let cells = try Regex(#"<t[dh]([^>]*)>(.*?)</t[dh]>"#)
        return lines[opening ..< closing].filter { $0.hasPrefix("<tr>") }.map { row in
            row.matches(of: cells).map { match in
                var text = String(row[match.output[2].range!])
                if let anchor = text.firstMatch(of: #/<a href="[^"]*">(.*)</a>/#) { text = String(anchor.output.1) }
                return text.replacingOccurrences(of: "&lt;", with: "<").replacingOccurrences(of: "&gt;", with: ">").replacingOccurrences(of: "&amp;", with: "&")
            }
        }
    }

    /// Body row (first cell equal to `entities`) of a table whose three header rows come first.
    private func body(_ rows: [[String]], _ entities: String) throws -> [String] {
        try #require(rows.dropFirst(3).first { $0.first == entities })
    }

    private func titles(_ page: String, of text: String) -> [String] {
        page.components(separatedBy: "\n").filter { $0.contains(">\(text)</td>") }
    }

    private let wallSection = "## Time (wall clock)"

    // Column layout of the fixture tables (index 0 is the entity count): baseline 1-3; archetype 4-10 (mean, sd, n, delta,
    // speed, change, sig); sparseSet 11-17; candidate 18-24.

    @Test
    func reportDirectoryHoldsOverviewWorkloadPagesAndPlots() throws {
        let files = try BenchmarkReport.render(all).files
        let paths = files.map(\.path)
        #expect(paths.first == "REPORT.md")
        for workload in [ReportFixtures.w1, ReportFixtures.w2, ReportFixtures.w3] {
            #expect(paths.contains("workloads/\(workload).md"))
        }
        // Only w1 has wall-clock data at entity counts above zero for the baseline series; w2 and w3 sit at 16 entities.
        for workload in [ReportFixtures.w1, ReportFixtures.w2, ReportFixtures.w3] {
            #expect(paths.contains("img/\(workload)-per-entity.svg") && paths.contains("img/\(workload)-total.svg"))
        }
        #expect(paths.count == Set(paths).count)
        #expect(paths.filter { $0.hasPrefix("workloads/") } == paths.filter { $0.hasPrefix("workloads/") }.sorted())
        let report = files[0].contents
        #expect(report.contains("![\(ReportFixtures.w1): wall-clock cost per entity](img/\(ReportFixtures.w1)-per-entity.svg)"))
        #expect(report.contains("](workloads/\(ReportFixtures.w1).md)"))
        #expect(!report.contains("mermaid"))
        #expect(try #require(files.first { $0.path == "workloads/\(ReportFixtures.w1).md" }).contents.contains("](../img/\(ReportFixtures.w1)-total.svg)"))
    }

    @Test
    func everyRenderedSVGIsWellFormedXML() throws {
        let files = try BenchmarkReport.render(all).files.filter { $0.path.hasSuffix(".svg") }
        #expect(files.count >= 6)
        for file in files {
            let parser = XMLParser(data: Data(file.contents.utf8))
            #expect(parser.parse(), "\(file.path): \(parser.parserError.map { "\($0)" } ?? "")")
            #expect(file.contents.contains(#"viewBox="0 0 960 540""#))
        }
    }

    @Test
    func tableHeaderHasThreeLevelsWithColspan() throws {
        let page = try #require(renderFiles(all)["workloads/\(ReportFixtures.w1).md"])
        let lines = page.components(separatedBy: "\n")
        let start = try #require(lines.firstIndex { $0.hasPrefix("### Time (wall clock): Entity counts up to 1,024") })
        let header = Array(lines[start...].drop { $0 != "<thead>" }.dropFirst().prefix(3))
        #expect(header[0] == #"<tr><th rowspan="3">Entities</th><th colspan="6">1.4.3 (class) - baseline</th><th colspan="24">main (value)</th><th colspan="12">candidate (value)</th></tr>"#)
        #expect(header[1] == #"<tr><th colspan="6">default</th><th colspan="12">archetype</th><th colspan="12">sparseSet</th><th colspan="12">archetype</th></tr>"#)
        let rows = try table(page, heading: "### Time (wall clock): Entity counts up to 1,024")
        #expect(rows[2].prefix(6) == ["median (μs)", "CI low (μs)", "CI high (μs)", "mean (μs)", "replicates", "iterations"])
        #expect(Array(rows[2][12 ... 17]) == ["speed (×)", "CI low (×)", "CI high (×)", "change (%)", "q", "verdict"])
        #expect(rows[2].count == 42)
        // Header and body have the same number of columns (the entity header spans the three rows).
        for row in rows.dropFirst(3) { #expect(row.count == 43) }
        // Series tables of the overview have no mean column.
        let overview = try table(render(all), heading: "#### Time (wall clock): Entity counts up to 1,024")
        #expect(overview[2].prefix(5) == ["median (μs)", "CI low (μs)", "CI high (μs)", "replicates", "iterations"])
    }

    @Test
    func unitAndDecimalsAreChosenPerColumn() throws {
        let page = try #require(renderFiles(all)["workloads/\(ReportFixtures.w1).md"])
        let rows = try table(page, heading: "### Time (wall clock): Entity counts up to 1,024")
        // Baseline medians 1000 ns and 4000 ns: the typical value is 4 μs, so the column unit is μs, three significant digits.
        #expect(try body(rows, "16")[1] == "1.00")
        #expect(try body(rows, "64")[1] == "4.00")
        // The mean column has its own unit choice: 1700 ns and 6800 ns.
        #expect(try body(rows, "16")[4] == "1.70" && body(rows, "64")[4] == "6.80")
        // The large table has its own unit choice for the same series: 4096 entities at 40 μs.
        let large = try table(page, heading: "### Time (wall clock): Entity counts above 1,024")
        #expect(large[2][0] == "median (μs)")
        #expect(try body(large, "4,096")[1] == "40.0")
        // archetype: 500 μs at 16 entities, the unit follows its own column.
        #expect(try body(rows, "16")[7] == "500")
        // Speed keeps three significant digits for its smallest value: 1000 / 500000 = 0.002.
        #expect(try body(rows, "16")[13] == "0.00200")
        // No cell shows more than three significant digits after the decimal point is used.
        for row in rows.dropFirst(3) + large.dropFirst(3) {
            for cell in row.dropFirst() where cell.contains(".") && !cell.contains(",") && !cell.hasPrefix("unavailable") && !cell.hasPrefix("n/a") {
                let digits = cell.drop { $0 == "+" || $0 == "-" }.filter(\.isNumber).drop { $0 == "0" }
                #expect(digits.count <= 3, "\(cell)")
            }
        }
    }

    @Test
    func formatPrecisionNeverExceedsThePackagesDigits() {
        #expect(ReportFormat.significantDigits == 3)
        #expect(ReportFormat.columnDecimals([1.7001, 6.8], divisor: 1) == 2)
        #expect(ReportFormat.columnDecimals([0.0123, 5], divisor: 1) == 4)
        #expect(ReportFormat.columnDecimals([900, 3000], divisor: 1) == 0)
        #expect(ReportFormat.columnDecimals([1700, 6800], divisor: 1000) == 2)
        #expect(ReportFormat.columnDecimals([1.7001], divisor: 1, cap: 1) == 1)
        #expect(ReportFormat.columnDecimals([0, 0], divisor: 1) == 0)
        #expect(ReportFormat.text(1.23456, columnDecimals: 2) == "1.23")
        #expect(ReportFormat.text(456.789, columnDecimals: 2) == "457", "a larger value of the column gets fewer decimals")
        #expect(ReportFormat.text(9.996, columnDecimals: 2) == "10.0", "rounding carries into the next magnitude")
        #expect(ReportFormat.text(0.0123456, columnDecimals: 4) == "0.0123")
        #expect(ReportFormat.text(133_638, columnDecimals: 0) == "134,000", "digits beyond the measured precision are rounded away")
        #expect(ReportFormat.text(1_234_567, columnDecimals: 0) == "1,230,000")
        #expect(ReportFormat.text(2.5, columnDecimals: 2, signed: true) == "+2.50")
        #expect(ReportFormat.text(-2.5, columnDecimals: 2, signed: true) == "-2.50")
        #expect(ReportFormat.text(0, columnDecimals: 2, signed: true) == "0")
        #expect(ReportFormat.text(1500, divisor: 1000, columnDecimals: 2) == "1.50")
        #expect(ReportFormat.text(12345.6, columnDecimals: 2) == "12,300")
        #expect(ReportFormat.grouped(65536) == "65,536" && ReportFormat.grouped(12) == "12" && ReportFormat.grouped(1_048_576) == "1,048,576")
        #expect(ReportFormat.qValue(0.0004) == "<0.001" && ReportFormat.qValue(0.0123) == "0.012")
        // Units: the median magnitude decides, so typical values show one to three integer digits.
        #expect(ReportDimension.time.unit(fitting: [50, 4000, 6000, 9_000_000]).label == "μs")
        #expect(ReportDimension.time.unit(fitting: [0, 0]).label == "ns")
    }

    @Test
    func smallAndLargeEntityCountsGetSeparateTables() throws {
        let page = try #require(renderFiles(all)["workloads/\(ReportFixtures.w1).md"])
        let small = try table(page, section: wallSection, heading: "### Time (wall clock): Entity counts up to 1,024")
        let large = try table(page, section: wallSection, heading: "### Time (wall clock): Entity counts above 1,024")
        #expect(small.dropFirst(3).map { $0[0] } == ["16", "64"])
        #expect(large.dropFirst(3).map { $0[0] } == ["4,096"])
        // The overview repeats both wall-clock tables for each workload; w3 only has small counts.
        let overview = try render(all)
        #expect(overview.components(separatedBy: "#### Time (wall clock): Entity counts above 1,024").count == 2)
        #expect(overview.components(separatedBy: "#### Time (wall clock): Entity counts up to 1,024").count == 4)
    }

    @Test
    func singleReplicateInputsGetMediansButNoInference() throws {
        let page = try #require(renderFiles(all)["workloads/\(ReportFixtures.w1).md"])
        let rows = try table(page, heading: "### Time (wall clock): Entity counts up to 1,024")
        let sixteen = try body(rows, "16")
        // Baseline: median, no CI, one replicate.
        #expect(sixteen[1] == "1.00" && sixteen[2] == "n/a (1 replicate)" && sixteen[3] == "n/a (1 replicate)" && sixteen[5] == "1")
        // archetype: 500x slower; the ratio of the two medians is shown, the interval, q and verdict are not.
        #expect(sixteen[7] == "500" && Double(sixteen[13])! < 0.01 && sixteen[16].hasPrefix("+"))
        #expect(sixteen[14] == "n/a (1 replicate)" && sixteen[15] == "n/a (1 replicate)" && sixteen[17] == "n/a (1 replicate)" && sixteen[18] == "n/a (1 replicate)")
        let report = try render(all)
        #expect(!report.contains(">faster<") && !report.contains(">slower<") && !report.contains(">equivalent<") && !report.contains(">inconclusive<"))
        #expect(report.contains("no replicate provenance"))
        // Scale 64 exists only in the baseline.
        #expect(try body(rows, "64")[7] == "unavailable" && body(rows, "64")[13] == "unavailable")
        // No drift is evaluated.
        #expect(report.contains("**Drift:** not evaluated"))
    }

    @Test
    func summaryTableHasSeparateColumnsPerScaleAndSeries() throws {
        let overview = try render(all)
        let rows = try table(overview, section: "## Summary", heading: "<table>")
        #expect(rows[0].first == "Workload")
        // main: archetype and sparseSet; candidate: archetype. Three blocks per series: 1,024, 65,536 and largest.
        #expect(rows[1].filter { $0.contains("@") }.count == 9)
        #expect(rows[1].contains("archetype @ 1,024") && rows[1].contains("archetype @ 65,536") && rows[1].contains("sparseSet @ largest"))
        #expect(Array(rows[2].prefix(4)) == ["speed (×)", "CI low (×)", "CI high (×)", "verdict"])
        #expect(rows[2].filter { $0 == "entities" }.count == 3)
        let names = rows.dropFirst(3).map { $0[0] }
        #expect(names == [ReportFixtures.w1, ReportFixtures.w2, ReportFixtures.w3].sorted())
        // w1: no data at 1,024 or 65,536, so those cells are unavailable; the largest comparable count is 4,096.
        let w1 = try body(rows, ReportFixtures.w1)
        #expect(w1[1] == "unavailable" && w1[4] == "unavailable")
        #expect(w1[9] == "4,096", "\(w1)")
        #expect(Double(w1[10])! > 3.9 && Double(w1[10])! < 4.1, "archetype is 4x faster than the baseline at 4,096 entities: \(w1)")
        #expect(w1[13] == "n/a (1 replicate)")
        // sparseSet is missing at 4096, so its largest comparable count is 16.
        #expect(w1[22] == "16", "\(w1)")
    }

    @Test
    func unavailableCarriesTheReasonAndNeverZero() throws {
        let files = try renderFiles(all)
        let page = try #require(files["workloads/\(ReportFixtures.w1).md"])
        // archetype has no throughput, and neither does the candidate.
        let throughput = try table(page, section: "## Throughput", heading: "### Throughput (# / s): Entity counts up to 1,024")
        let sixteen = try body(throughput, "16")
        #expect(sixteen[7] == "unavailable")
        #expect(sixteen[19] == "unavailable")
        #expect(page.contains(#"title="not measured for this series">unavailable</td>"#))
        // w2 is missing for sparseSet and the candidate; w3 for everything but the candidate.
        let w2 = try table(#require(files["workloads/\(ReportFixtures.w2).md"]), heading: "### Time (wall clock): Entity counts up to 1,024")
        #expect(try body(w2, "16")[19] == "unavailable")
        let w3 = try table(#require(files["workloads/\(ReportFixtures.w3).md"]), heading: "### Time (wall clock): Entity counts up to 1,024")
        let w3Row = try body(w3, "16")
        #expect(w3Row[1] == "unavailable" && w3Row[7] == "unavailable")
        #expect(w3Row[31] != "unavailable", "the candidate's own value is shown")
        #expect(w3Row[37] == "unavailable", "its speed needs the baseline, which has no w3")
        #expect(!files.values.joined().contains(">nan<") && !files.values.joined().contains(">inf<"))
    }

    @Test
    func incompatiblePolarityIsUnavailableNotConverted() throws {
        let page = try #require(renderFiles(all)["workloads/\(ReportFixtures.w1).md"])
        let rows = try table(page, section: "## Time (total CPU)", heading: "### Time (total CPU): Entity counts up to 1,024")
        let sixteen = try body(rows, "16")
        #expect(sixteen[19] == "unavailable")
        #expect(page.contains(#"title="incompatible units or polarity">unavailable</td>"#))
        #expect(sixteen.count == 25, "descriptive columns only for metrics other than wall clock")
    }

    @Test
    func otherMetricsAreDescriptiveOnly() throws {
        let page = try #require(renderFiles(all)["workloads/\(ReportFixtures.w2).md"])
        let rows = try table(page, section: "## Malloc (total)", heading: "### Malloc (total): Entity counts up to 1,024")
        let sixteen = try body(rows, "16")
        #expect(sixteen[1] == "0", "\(sixteen)")
        #expect(sixteen[7] == "5", "\(sixteen)")
        #expect(rows[2].allSatisfy { !$0.hasPrefix("speed") && $0 != "q" && $0 != "verdict" })
    }

    @Test
    func zeroWallClockMedianHasNoRatio() throws {
        var files = all
        let identifier = try #require(files[0].baseline.results.keys.first { $0.name == "\(ReportFixtures.w2) [default] / 16" })
        files[0].baseline.results[identifier] = files[0].baseline.results[identifier]!.map {
            $0.metric == .wallClock ? ReportFixtures.result(.wallClock, [0, 0, 0]) : $0
        }
        let page = try #require(renderFiles(files)["workloads/\(ReportFixtures.w2).md"])
        let rows = try table(page, heading: "### Time (wall clock): Entity counts up to 1,024")
        let sixteen = try body(rows, "16")
        #expect(sixteen[1] == "0")
        #expect(sixteen[13] == "unavailable" && sixteen[18] == "unavailable")
        #expect(page.contains(#"title="zero median: the ratio is undefined">unavailable</td>"#))
    }

    @Test
    func throughputIsLargerIsBetterAndOnlyDescribed() throws {
        let page = try #require(renderFiles(all)["workloads/\(ReportFixtures.w1).md"])
        #expect(page.contains("## Throughput (# / s) (larger is better)"))
        #expect(page.contains("## Time (wall clock) (smaller is better)"))
        let time = try table(page, heading: "### Time (wall clock): Entity counts up to 1,024")
        #expect(try Double(body(time, "16")[13])! < 1, "archetype is slower than the baseline: speed below 1")
        let throughput = try table(page, section: "## Throughput", heading: "### Throughput (# / s): Entity counts up to 1,024")
        #expect(throughput[2].allSatisfy { $0 != "verdict" && $0 != "q" })
    }

    @Test
    func percentilesFollowThePackagePolarityInTheTables() throws {
        // Larger is better: p0 is the largest value, p100 the smallest. Sample set: 1000 x5, 2000 x4, 4000 x1.
        let sample = ReportSample(ReportFixtures.result(.throughput, ReportFixtures.spread()))
        #expect(sample.prefersLarger)
        #expect(sample.value(.percentile(0)) == 4000)
        #expect(sample.value(.percentile(25)) == 2000)
        #expect(sample.value(.percentile(90)) == 1000)
        #expect(sample.value(.percentile(100)) == 1000)
        let time = ReportSample(ReportFixtures.result(.wallClock, ReportFixtures.spread()))
        #expect(!time.prefersLarger)
        #expect(time.value(.percentile(0)) == 1000)
        #expect(time.value(.percentile(90)) == 2000)
        #expect(time.value(.percentile(100)) == 4000)
        var files = all
        files[0].baseline.results = Dictionary(uniqueKeysWithValues: files[0].baseline.results.map { identifier, results in
            (identifier, results.map { $0.metric == .throughput ? ReportFixtures.result(.throughput, ReportFixtures.spread()) : $0 })
        })
        let page = try #require(renderFiles(files)["workloads/\(ReportFixtures.w1).md"])
        let rows = try table(page, section: "## Throughput", heading: "### Percentiles, entity counts up to 1,024")
        #expect(rows[2].prefix(3) == ["p0 (Kops/s)", "p25 (Kops/s)", "p50 (Kops/s)"])
        let sixteen = try body(rows, "16")
        #expect(sixteen[1] == "4.00" && sixteen[2] == "2.00" && sixteen[6] == "1.00" && sixteen[7] == "1.00", "\(sixteen)")
        #expect(page.contains("median over replicates of each replicate's percentile"))
    }

    @Test
    func metricWithoutMeasurementsIsRecordedAndPrintedUnavailable() throws {
        var files = all
        // The class ref's w2 malloc counter recorded nothing; main's archetype w2 has data.
        let identifier = try #require(files[0].baseline.results.keys.first { $0.name.hasPrefix(ReportFixtures.w2) })
        files[0].baseline.results[identifier] = files[0].baseline.results[identifier]!.map {
            $0.metric == .mallocCountTotal ? ReportFixtures.result(.mallocCountTotal, []) : $0
        }
        // Structurally valid, survives encoding and decoding.
        let decoded = try ResultValidator.decode(BenchmarkResultFile.encoder().encode(files[0]))
        #expect(decoded.baseline.results[identifier]?.contains { $0.statistics.measurementCount == 0 } == true)
        let page = try #require(renderFiles(files)["workloads/\(ReportFixtures.w2).md"])
        let rows = try table(page, section: "## Malloc (total)", heading: "### Malloc (total): Entity counts up to 1,024")
        let sixteen = try body(rows, "16")
        #expect(sixteen[1] == "unavailable" && sixteen[2] == "unavailable" && sixteen[5] == "unavailable", "\(sixteen)")
        #expect(sixteen[7] == "5", "the other series is unaffected")
        #expect(page.contains(#"title="no measurements">unavailable</td>"#))
        let percentiles = try table(page, section: "## Malloc (total)", heading: "### Percentiles, entity counts up to 1,024")
        #expect(try body(percentiles, "16")[1] == "unavailable")
        #expect(!page.contains(">nan<") && !page.contains(">inf<") && !page.contains(">-inf<"))
        // The other metrics of the ref are untouched.
        let time = try table(page, section: "## Time (wall clock)", heading: "### Time (wall clock): Entity counts up to 1,024")
        #expect(try body(time, "16")[1] != "unavailable")
    }

    @Test
    func iterationCountsDifferingBetweenSeriesDoNotWarn() throws {
        var other = twin("counts")
        let identifier = try #require(other.baseline.results.keys.first { $0.name == "\(ReportFixtures.w1) [default] / 16" })
        other.baseline.results[identifier] = other.baseline.results[identifier]!.map {
            $0.metric == .wallClock ? ReportFixtures.result(.wallClock, Array(ReportFixtures.spread().prefix(7))) : $0
        }
        let rendered = try BenchmarkReport.render([ReportFixtures.classRef(), other])
        #expect(rendered.warnings.isEmpty, "differing counts are expected with time-based sampling")
        #expect(rendered.markdown.contains("time-based sampling, so it differs between series by design"))
        #expect(!rendered.markdown.contains("Welch") && !rendered.markdown.contains("±sd") && !rendered.markdown.contains("sig."))
    }

    @Test
    func reportTextIsEscapedInHTMLAndMarkdown() throws {
        var files = all
        files[1].ref.requested = "a<b>&\"c\""
        let rendered = try BenchmarkReport.render(files)
        let page = rendered.files.first { $0.path.hasPrefix("workloads/") }!.contents
        #expect(page.contains("a&lt;b&gt;&amp;&quot;c&quot; (value)"))
        #expect(!page.contains("<b>"))
        for file in rendered.files where file.path.hasSuffix(".svg") {
            #expect(XMLParser(data: Data(file.contents.utf8)).parse(), "\(file.path)")
        }
    }

    // MARK: CLI

    private func writeInputs(_ directory: URL) throws -> [String] {
        var paths: [String] = []
        for (index, file) in all.enumerated() {
            let url = directory.appendingPathComponent("r\(index).json")
            try BenchmarkResultFile.encoder().encode(file).write(to: url)
            paths.append(url.path)
        }
        return paths
    }

    @Test
    func cliWritesReportDirectoryAfterValidatingEveryInput() throws {
        let directory = try Support.scratchDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let paths = try writeInputs(directory)
        let output = directory.appendingPathComponent("report").path
        #expect(ResultsCLI.run(["report"] + paths + ["--baseline", "main", "--title", "Fixture", "--output-dir", output]) == 0)
        let text = try String(contentsOfFile: output + "/REPORT.md", encoding: .utf8)
        #expect(text.hasPrefix("# Fixture\n"))
        #expect(text.contains("- Baseline: `main`"))
        #expect(FileManager.default.fileExists(atPath: output + "/workloads/\(ReportFixtures.w1).md"))
        #expect(FileManager.default.fileExists(atPath: output + "/img/\(ReportFixtures.w1)-per-entity.svg"))

        #expect(ResultsCLI.run(["report", paths[0], "--output-dir", output + "2", "--overwrite"]) != 0, "needs two inputs")
        #expect(ResultsCLI.run(["report"] + paths + ["--baseline", "nope", "--output-dir", output + "3"]) != 0)
        #expect(ResultsCLI.run(["report"] + paths) != 0, "needs --output-dir")
        #expect(ResultsCLI.run(["report"] + paths + ["--output", output + "4"]) != 0, "the old option is gone")
        let broken = directory.appendingPathComponent("broken.json")
        try Data("{}".utf8).write(to: broken)
        let missing = directory.appendingPathComponent("never").path
        #expect(ResultsCLI.run(["report", paths[0], broken.path, "--output-dir", missing]) != 0)
        #expect(!FileManager.default.fileExists(atPath: missing), "nothing is written when an input is invalid")
    }

    @Test
    func cliNeverOverwritesInputsOrNonEmptyOutputDirectories() throws {
        let directory = try Support.scratchDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let paths = try writeInputs(directory)
        let before = try paths.map { try Data(contentsOf: URL(fileURLWithPath: $0)) }
        func inputsUntouched() throws -> Bool { try paths.map { try Data(contentsOf: URL(fileURLWithPath: $0)) } == before }

        // The inputs' own directory is not empty: refused without --overwrite, and the JSON files survive --overwrite.
        #expect(ResultsCLI.run(["report"] + paths + ["--output-dir", directory.path]) != 0)
        #expect(try inputsUntouched())
        // An input given as the output directory (a file) is refused even with --overwrite.
        #expect(ResultsCLI.run(["report"] + paths + ["--output-dir", paths[0], "--overwrite"]) != 0)
        let link = directory.appendingPathComponent("link")
        try FileManager.default.createSymbolicLink(atPath: link.path, withDestinationPath: paths[1])
        #expect(ResultsCLI.run(["report"] + paths + ["--output-dir", link.path, "--overwrite"]) != 0)
        #expect(try inputsUntouched())

        let output = directory.appendingPathComponent("report")
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        try Data("precious".utf8).write(to: output.appendingPathComponent("notes.txt"))
        #expect(ResultsCLI.run(["report"] + paths + ["--output-dir", output.path]) != 0, "non-empty without --overwrite")
        #expect(try Data(contentsOf: output.appendingPathComponent("notes.txt")) == Data("precious".utf8))
        #expect(!FileManager.default.fileExists(atPath: output.appendingPathComponent("REPORT.md").path))

        // With --overwrite only generated files are replaced; stale generated files go, unrelated files stay.
        try FileManager.default.createDirectory(at: output.appendingPathComponent("workloads"), withIntermediateDirectories: true)
        try Data("old".utf8).write(to: output.appendingPathComponent("workloads/stale.md"))
        try Data("old".utf8).write(to: output.appendingPathComponent("REPORT.md"))
        #expect(ResultsCLI.run(["report"] + paths + ["--output-dir", output.path, "--overwrite"]) == 0)
        #expect(try String(contentsOf: output.appendingPathComponent("REPORT.md"), encoding: .utf8).hasPrefix("# FirebladeECS benchmark comparison"))
        #expect(!FileManager.default.fileExists(atPath: output.appendingPathComponent("workloads/stale.md").path))
        #expect(try Data(contentsOf: output.appendingPathComponent("notes.txt")) == Data("precious".utf8))
        #expect(try inputsUntouched())

        // A fresh or empty directory works without the flag; an existing file is refused.
        #expect(ResultsCLI.run(["report"] + paths + ["--output-dir", directory.appendingPathComponent("fresh").path]) == 0)
        let empty = directory.appendingPathComponent("empty")
        try FileManager.default.createDirectory(at: empty, withIntermediateDirectories: true)
        #expect(ResultsCLI.run(["report"] + paths + ["--output-dir", empty.path]) == 0)
        let file = directory.appendingPathComponent("file.txt")
        try Data("x".utf8).write(to: file)
        #expect(ResultsCLI.run(["report"] + paths + ["--output-dir", file.path, "--overwrite"]) != 0)
        #expect(try inputsUntouched())
    }

    @Test
    func fixturesAreValid() throws {
        for file in all { try ResultValidator.validate(file) }
        #expect(all.count >= 3)
    }

    @Test
    func backendPairingComparesWithTheBaselinesOnlyBackend() throws {
        let report = try render(all)
        #expect(report.contains("| 1.4.3 (class, default) | 1 of 1 | baseline |"))
        #expect(report.contains("| main (value, archetype) | 1 of 1 | 1.4.3 (class, default) |"))
        #expect(report.contains("| main (value, sparseSet) | 1 of 1 | 1.4.3 (class, default) |"))
        #expect(report.contains("| candidate (value, archetype) | 1 of 1 | 1.4.3 (class, default) |"))
    }

    @Test
    func backendPairingPrefersTheSameBackendName() throws {
        // With the value ref as baseline, the class ref's `default` backend matches none of its two backends.
        let report = try render(all, baseline: "main")
        #expect(report.contains("| 1.4.3 (class, default) | 1 of 1 | unavailable (the baseline has several backends and none is `default`) |"))
        #expect(report.contains("| main (value, archetype) | 1 of 1 | baseline |"))
        #expect(report.contains("| main (value, sparseSet) | 1 of 1 | baseline |"))
        #expect(report.contains("| candidate (value, archetype) | 1 of 1 | main (value, archetype) |"))
    }

    @Test
    func configurationHashMismatchWarns() throws {
        let rendered = try BenchmarkReport.render(all)
        #expect(rendered.warnings.filter { $0.contains("Configuration hashes differ") }.count == 1)
        #expect(rendered.markdown.contains("## Warnings"))
        let same = try BenchmarkReport.render([ReportFixtures.classRef(), twin("twin")])
        #expect(same.warnings.isEmpty)
        #expect(!same.markdown.contains("## Warnings"))
    }

    @Test
    func toolchainHostAndBenchmarkSetDifferencesWarn() throws {
        var toolchain = twin("tc")
        toolchain.toolchain.swiftVersion = "Apple Swift version 6.5"
        let toolchainWarnings = try BenchmarkReport.render([ReportFixtures.classRef(), toolchain]).warnings
        #expect(toolchainWarnings.count == 1 && toolchainWarnings[0].contains("Toolchains differ"))

        var host = twin("host")
        host.host.cpuModel = "Other CPU"
        let hostWarnings = try BenchmarkReport.render([ReportFixtures.classRef(), host]).warnings
        #expect(hostWarnings.count == 1 && hostWarnings[0].contains("Hosts differ"))

        // The physical memory size alone is not a reason to warn.
        var memory = twin("mem")
        memory.host.physicalMemoryBytes += 4096
        #expect(try BenchmarkReport.render([ReportFixtures.classRef(), memory]).warnings.isEmpty)

        var fewer = twin("set")
        fewer.benchmarks.removeLast()
        let removed = try #require(fewer.baseline.results.keys.first { $0.name.hasPrefix(ReportFixtures.w2) })
        fewer.baseline.results[removed] = nil
        let setWarnings = try BenchmarkReport.render([ReportFixtures.classRef(), fewer]).warnings
        #expect(setWarnings.contains { $0.contains("registered benchmark sets differ") && $0.contains(ReportFixtures.w2) })
    }

    @Test
    func twoInputsOfOneRefWithoutProvenanceAreDuplicateReplicates() throws {
        // Without replicate fields both count as replicate 1 of 1 of the same series.
        #expect(throws: ReportError.duplicateReplicate(series: "1.4.3 (class)", index: 1)) {
            try BenchmarkReport.render([ReportFixtures.classRef(), ReportFixtures.classRef()])
        }
    }

    @Test
    func refusesTooFewInputsAndUnknownBaseline() throws {
        #expect(throws: ResultError.self) { try render([]) }
        #expect(throws: ResultError.self) { try render([ReportFixtures.classRef()]) }
        #expect(throws: ResultError.self) { try render(all, baseline: "nope") }
    }

    @Test
    func renderingIsDeterministic() throws {
        let first = try renderFiles(all)
        let second = try renderFiles(all)
        #expect(first == second, "every file, including the SVGs")
        #expect(try renderFiles(all, baseline: "main") == renderFiles(all, baseline: "main"))
        #expect(try BenchmarkReport.render(all).files.map(\.path) == BenchmarkReport.render(all).files.map(\.path))
        for (path, contents) in first {
            #expect(contents.hasSuffix("\n") && !contents.contains("\r"), "\(path)")
        }
    }

    @Test
    func inputsAreNotMutated() throws {
        let files = all
        let encoder = BenchmarkResultFile.encoder()
        let before = try files.map { SHA256.hexDigest(Array(try encoder.encode($0))) }
        _ = try render(files)
        _ = try render(files, baseline: "candidate")
        let after = try files.map { SHA256.hexDigest(Array(try encoder.encode($0))) }
        #expect(before == after)
        // Reading through the native accessors afterwards still yields the fixture's own values.
        let result = try #require(files[0].baseline.results.values.first { $0.count == 4 }?.first)
        #expect(result.statistics.percentiles() == [1000, 1000, 1000, 2000, 2000, 4000, 4000])
    }

    @Test
    func resultsToolsLaunchNoProcess() throws {
        // By design the renderer is a function over decoded values; this guards the whole schema target and the executable
        // target (its main.swift) against ever acquiring a process launch.
        let forbidden = try Regex(#"\bProcess\b|\bNSTask\b|posix_spawn|\bsystem\(|\bpopen\(|\bexecv|\bfork\("#)
        var checked: [String] = []
        for target in ["ECSBenchmarkResultSchema", "ECSBenchmarkResults"] {
            let directory = Support.packageRoot.appendingPathComponent("Benchmarks/\(target)")
            let sources = try FileManager.default.contentsOfDirectory(atPath: directory.path).filter { $0.hasSuffix(".swift") }
            for source in sources {
                let text = try String(contentsOf: directory.appendingPathComponent(source), encoding: .utf8)
                #expect(text.firstMatch(of: forbidden) == nil, "\(target)/\(source) must not launch processes")
                checked.append("\(target)/\(source)")
            }
        }
        #expect(checked.contains("ECSBenchmarkResultSchema/BenchmarkReport.swift"))
        #expect(checked.contains("ECSBenchmarkResults/main.swift"))
    }

    @Test
    func reportPercentilesMatchThePackageOnAFreshCopy() throws {
        // Oracle: Statistics.percentiles() of an untouched decode of the same native result, for both polarities, with and
        // without a scaling factor. The report must never touch the caches of the copy it reads.
        let values = (1 ... 400).map { ($0 * $0 * 37) % 90_001 + 10 }
        for metric in [BenchmarkMetric.wallClock, .throughput, .mallocCountTotal, .peakMemoryResident] {
            for scaling in [BenchmarkScalingFactor.one, .kilo] {
                let original = ReportFixtures.result(metric, values, scaling: scaling)
                let fresh = try JSONDecoder().decode(BenchmarkResult.self, from: JSONEncoder().encode(original))
                let sample = ReportSample(original)
                let factor: Double = metric == .throughput ? Double(scaling.rawValue) : (metric.useScalingFactor ? 1 / Double(scaling.rawValue) : 1)
                let oracle = fresh.statistics.percentiles().map { Double($0) * factor }
                #expect(sample.percentiles == oracle, "\(metric) scaling \(scaling)")
                #expect(sample.prefersLarger == fresh.statistics.prefersLarger)
            }
        }
    }

    @Test
    func duplicateBenchmarkNamesThrowInsteadOfTrapping() throws {
        var files = all
        files[1].benchmarks.append(files[1].benchmarks[0])
        #expect(throws: ReportError.duplicateBenchmarkName(input: "main", name: files[1].benchmarks[0].name)) { try render(files) }
        #expect(throws: ResultError.self) { try ResultValidator.validate(files[1]) }
    }

    @Test
    func batchIdIsShownInProvenanceAndIsOptional() throws {
        var files = all
        files[0].run.batchId = "batch-42"
        let report = try render(files)
        #expect(report.contains("| Batch | batch-42 |"))
        #expect(report.contains("| Batch | none recorded |"))
        try ResultValidator.validate(files[0])
        files[0].run.batchId = " "
        #expect(throws: ResultError.self) { try ResultValidator.validate(files[0]) }
        // A file without the field decodes; with it, the id survives the round trip.
        let plain = try BenchmarkResultFile.encoder().encode(all[0])
        #expect(!String(decoding: plain, as: UTF8.self).contains("batchId"))
        _ = try ResultValidator.decode(plain)
        var withBatch = all[0]
        withBatch.run.batchId = "b1"
        #expect(try ResultValidator.decode(BenchmarkResultFile.encoder().encode(withBatch)).run.batchId == "b1")
    }

    @Test
    func hostCheckPassesOnThisHost() {
        #expect(ResultsCLI.run(["host-check"]) == 0)
        #expect(ResultsCLI.run(["host-check", "extra"]) != 0)
    }
}
