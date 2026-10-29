import Benchmark
import Foundation
import Testing
@testable import ECSBenchmarkResultSchema

@Suite
struct ReportTests {
    private func render(_ files: [BenchmarkResultFile], baseline: String? = nil) throws -> String {
        try BenchmarkReport.render(files, options: ReportOptions(baseline: baseline)).markdown
    }

    private var all: [BenchmarkResultFile] { [ReportFixtures.classRef(), ReportFixtures.valueRef(), ReportFixtures.scaledRef()] }

    /// The table row `label` of the section whose heading line starts with `heading`.
    private func row(_ report: String, section: String, metric: String, label: String) throws -> String {
        let lines = report.components(separatedBy: "\n")
        let start = try #require(lines.firstIndex(of: section))
        let metricStart = try #require(lines[start...].firstIndex { $0.hasPrefix("#### \(metric)") })
        let line = lines[metricStart...].prefix { !$0.hasPrefix("```") }.first { $0.hasPrefix("| \(label) |") }
        return try #require(line)
    }

    @Test
    func fixturesAreValid() throws {
        for file in all { try ResultValidator.validate(file) }
        #expect(all.count >= 3)
    }

    @Test
    func reportsEveryStatisticBeyondP50() throws {
        let report = try render(all)
        let section = "### `\(ReportFixtures.w1)` / 16"
        let labels = ["measurements", "mean", "std dev", "p0", "p25", "p50", "p75", "p90", "p99", "p100"]
        for label in labels { _ = try row(report, section: section, metric: "Time (wall clock)", label: label) }
        let mean = try row(report, section: section, metric: "Time (wall clock)", label: "mean")
        #expect(mean.contains("| 1.7001 μs |"), "baseline mean (package precision) shown in μs: \(mean)")
        let p99 = try row(report, section: section, metric: "Time (wall clock)", label: "p99")
        #expect(p99.contains("| 4 μs |"))
        let p75 = try row(report, section: section, metric: "Time (wall clock)", label: "p75")
        #expect(p75.contains("| 2 μs |"))
        let count = try row(report, section: section, metric: "Time (wall clock)", label: "measurements")
        #expect(count.contains("| 10 |"))
    }

    @Test
    func backendPairingComparesWithTheBaselinesOnlyBackend() throws {
        let report = try render(all)
        #expect(report.contains("| 1.4.3 (class, default) | baseline |"))
        #expect(report.contains("| main (value, archetype) | 1.4.3 (class, default) |"))
        #expect(report.contains("| main (value, sparseSet) | 1.4.3 (class, default) |"))
        #expect(report.contains("| candidate (value, archetype) | 1.4.3 (class, default) |"))
    }

    @Test
    func backendPairingPrefersTheSameBackendName() throws {
        // With the value ref as baseline, the class ref's `default` backend matches none of its two backends.
        let report = try render(all, baseline: "main")
        #expect(report.contains("| 1.4.3 (class, default) | unavailable (the baseline has several backends and none is `default`) |"))
        #expect(report.contains("| main (value, archetype) | baseline |"))
        #expect(report.contains("| main (value, sparseSet) | baseline |"))
        #expect(report.contains("| candidate (value, archetype) | main (value, archetype) |"))
    }

    @Test
    func missingMetricAndWorkloadPrintUnavailable() throws {
        let report = try render(all)
        let section = "### `\(ReportFixtures.w1)` / 16"
        // archetype has no throughput, and neither does the candidate.
        let throughput = try row(report, section: section, metric: "Throughput", label: "p50")
        let cells = throughput.components(separatedBy: " | ")
        #expect(cells[2] == "unavailable")
        #expect(cells.last == "unavailable |")
        // w2 is missing for sparseSet and the candidate; w3 for everything but the candidate.
        let w2 = try row(report, section: "### `\(ReportFixtures.w2)` / 16", metric: "Time (wall clock)", label: "p50")
        #expect(w2.components(separatedBy: " | ")[3] == "unavailable")
        let w3 = try row(report, section: "### `\(ReportFixtures.w3)` / 16", metric: "Time (wall clock)", label: "p50")
        #expect(w3.contains("| unavailable | unavailable | unavailable |"))
        #expect(w3.contains("| 1 μs (delta unavailable) |"))
        // Scale 64 exists only in the class ref.
        let scale64 = try row(report, section: "### `\(ReportFixtures.w1)` / 64", metric: "Time (wall clock)", label: "p50")
        #expect(scale64.contains("| unavailable | unavailable | unavailable |"))
    }

    @Test
    func compatibleUnitsAndScalesAreConvertedToOneUnitPerRow() throws {
        let report = try render(all)
        let section = "### `\(ReportFixtures.w1)` / 16"
        // archetype: 500x the baseline values labelled in microseconds -> p50 500 μs vs 1 μs.
        let p0 = try row(report, section: section, metric: "Time (wall clock)", label: "p0")
        #expect(p0.contains("| 1 μs |"))
        #expect(p0.contains("| 500 μs (Δ +499 μs, ×500, +49900%, worse) |"), "\(p0)")
        // sparseSet: identical to the baseline.
        #expect(p0.contains("| 1 μs (Δ 0 μs, ×1, 0%, unchanged) |"), "\(p0)")
        // candidate: kilo-scaled raw values (1000x per 1000 iterations) equal the baseline per iteration.
        #expect(p0.hasSuffix("| 1 μs (Δ 0 μs, ×1, 0%, unchanged) |"), "\(p0)")
        // The std dev row picks its own unit (ns) for the same series.
        let deviation = try row(report, section: section, metric: "Time (wall clock)", label: "std dev")
        #expect(deviation.contains("| 900.26 ns |"), "\(deviation)")
        // One unit across the row, also when the smallest value is in ns.
        let scale64 = try row(report, section: "### `\(ReportFixtures.w1)` / 64", metric: "Time (wall clock)", label: "p0")
        #expect(scale64.contains("| 4 μs |"))
    }

    @Test
    func incompatiblePolarityIsUnavailableNotConverted() throws {
        let report = try render(all)
        let p50 = try row(report, section: "### `\(ReportFixtures.w1)` / 16", metric: "Time (total CPU)", label: "p50")
        #expect(p50.hasSuffix("| unavailable (incompatible units) |"), "\(p50)")
        #expect(p50.contains("(Δ"))
    }

    @Test
    func zeroBaselineHasNoRatioOrPercent() throws {
        let report = try render(all)
        let p50 = try row(report, section: "### `\(ReportFixtures.w2)` / 16", metric: "Malloc (total)", label: "p50")
        #expect(p50.contains("| 0 |"), "\(p50)")
        #expect(p50.contains("(Δ +5, ratio and change unavailable: zero baseline, worse)"), "\(p50)")
        #expect(!p50.contains("inf") && !p50.contains("nan"))
    }

    @Test
    func polarityDecidesBetterOrWorse() throws {
        // Throughput: larger is better. sparseSet equals the baseline, so build a faster variant.
        var files = all
        files[1].baseline.results = Dictionary(uniqueKeysWithValues: files[1].baseline.results.map { identifier, results in
            (identifier, results.map { $0.metric == .throughput ? ReportFixtures.result(.throughput, [200_000, 400_000, 400_000, 800_000]) : $0 })
        })
        let report = try render(files)
        let p50 = try row(report, section: "### `\(ReportFixtures.w1)` / 16", metric: "Throughput", label: "p50")
        #expect(p50.contains("better"), "\(p50)")
        #expect(p50.contains("(smaller is better)") == false)
        #expect(report.contains("#### Throughput (# / s) (larger is better)"))
        #expect(report.contains("#### Time (wall clock) (smaller is better)"))
    }

    /// A second input that differs from the class fixture only in its identity.
    private func twin(_ requested: String) -> BenchmarkResultFile {
        var file = ReportFixtures.classRef()
        file.ref.requested = requested
        file.ref.sha = String(repeating: "d", count: 40)
        return file
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
    func measurementCountDifferencesBetweenSeriesWarn() throws {
        var other = twin("counts")
        let identifier = try #require(other.baseline.results.keys.first { $0.name == "\(ReportFixtures.w1) [default] / 16" })
        other.baseline.results[identifier] = other.baseline.results[identifier]!.map {
            $0.metric == .wallClock ? ReportFixtures.result(.wallClock, Array(ReportFixtures.spread().prefix(7))) : $0
        }
        let rendered = try BenchmarkReport.render([ReportFixtures.classRef(), other])
        let warning = try #require(rendered.warnings.first { $0.contains("different measurement counts") })
        #expect(warning.hasPrefix("1 metric rows") && warning.contains(ReportFixtures.w1) && warning.contains("Time (wall clock)"), "\(warning)")
    }

    @Test
    func duplicateInputsWarnButRender() throws {
        let rendered = try BenchmarkReport.render([ReportFixtures.classRef(), ReportFixtures.classRef()])
        #expect(rendered.warnings.contains { $0.contains("share ref SHA") })
        #expect(rendered.markdown.contains("1.4.3@aaaaaaaaaaaa (class, default)"))
        #expect(rendered.markdown.contains("1.4.3@aaaaaaaaaaaa #2 (class, default)"), "labels stay unique")
    }

    @Test
    func refusesTooFewInputsAndUnknownBaseline() throws {
        #expect(throws: ResultError.self) { try render([]) }
        #expect(throws: ResultError.self) { try render([ReportFixtures.classRef()]) }
        #expect(throws: ResultError.self) { try render(all, baseline: "nope") }
    }

    @Test
    func renderingIsDeterministic() throws {
        let first = try render(all)
        let second = try render(all)
        #expect(first == second)
        #expect(try render(all, baseline: "main") == render(all, baseline: "main"))
        #expect(first.hasSuffix("\n") && !first.contains("\r"))
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
    func mermaidBlocksFollowTheXYChartGrammar() throws {
        let report = try render(all)
        let blocks = report.components(separatedBy: "```mermaid\n").dropFirst().map { $0.components(separatedBy: "```")[0] }
        #expect(blocks.count == 8, "one block per identity, scale and metric")
        for block in blocks {
            let lines = block.split(separator: "\n").map(String.init)
            #expect(lines.first == "xychart-beta")
            #expect(lines[1].hasPrefix("    title \"") && lines[1].hasSuffix("\""))
            let xLine = try #require(lines.first { $0.hasPrefix("    x-axis [") })
            let barLine = try #require(lines.first { $0.hasPrefix("    bar [") })
            let yLine = try #require(lines.first { $0.hasPrefix("    y-axis \"p50") })
            #expect(yLine.hasSuffix("\""))
            let labels = xLine.dropFirst("    x-axis [".count).dropLast().components(separatedBy: "\", \"")
            let values = barLine.dropFirst("    bar [".count).dropLast().components(separatedBy: ", ")
            #expect(labels.count == values.count)
            #expect(labels.first?.hasPrefix("\"") == true && labels.last?.hasSuffix("\"") == true)
            for value in values { #expect(Double(value) != nil, "numeric y value: \(value)") }
        }
        // Throughput chart: unit in the axis title; unavailable series left out of the chart.
        #expect(report.contains("    y-axis \"p50 (μs)\""))
        #expect(report.contains("    y-axis \"p50 (Kops/s)\"") || report.contains("    y-axis \"p50 (ops/s)\""))
        #expect(!report.contains("    bar [unavailable"))
    }

    @Test
    func reportCodeLaunchesNoProcess() throws {
        // By design the renderer is a function over decoded values; this guards the whole schema target (including everything
        // the report path could call) against ever acquiring a process launch.
        let directory = Support.packageRoot.appendingPathComponent("Benchmarks/ECSBenchmarkResultSchema")
        let sources = try FileManager.default.contentsOfDirectory(atPath: directory.path).filter { $0.hasSuffix(".swift") }
        #expect(sources.contains("BenchmarkReport.swift"))
        let forbidden = try Regex(#"\bProcess\b|\bNSTask\b|posix_spawn|\bsystem\(|\bpopen\(|\bexecv|\bfork\("#)
        for source in sources {
            let text = try String(contentsOf: directory.appendingPathComponent(source), encoding: .utf8)
            #expect(text.firstMatch(of: forbidden) == nil, "\(source) must not launch processes")
        }
    }

    @Test
    func cliWritesReportAfterValidatingEveryInput() throws {
        let directory = try Support.scratchDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        var paths: [String] = []
        for (index, file) in all.enumerated() {
            let url = directory.appendingPathComponent("r\(index).json")
            try BenchmarkResultFile.encoder().encode(file).write(to: url)
            paths.append(url.path)
        }
        let output = directory.appendingPathComponent("report.md").path
        #expect(ResultsCLI.run(["report"] + paths + ["--baseline", "main", "--title", "Fixture", "--output", output]) == 0)
        let text = try String(contentsOfFile: output, encoding: .utf8)
        #expect(text.hasPrefix("# Fixture\n"))
        #expect(text.contains("- Baseline: `main`"))

        #expect(ResultsCLI.run(["report", paths[0], "--output", output, "--overwrite"]) != 0, "needs two inputs")
        #expect(ResultsCLI.run(["report"] + paths + ["--baseline", "nope", "--output", output, "--overwrite"]) != 0)
        #expect(ResultsCLI.run(["report"] + paths) != 0, "needs --output")
        let broken = directory.appendingPathComponent("broken.json")
        try Data("{}".utf8).write(to: broken)
        let missing = directory.appendingPathComponent("never.md").path
        #expect(ResultsCLI.run(["report", paths[0], broken.path, "--output", missing]) != 0)
        #expect(!FileManager.default.fileExists(atPath: missing), "nothing is written when an input is invalid")
    }

    @Test
    func cliNeverOverwritesInputsOrExistingOutputs() throws {
        let directory = try Support.scratchDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        var paths: [String] = []
        for (index, file) in all.enumerated() {
            let url = directory.appendingPathComponent("r\(index).json")
            try BenchmarkResultFile.encoder().encode(file).write(to: url)
            paths.append(url.path)
        }
        let before = try paths.map { try Data(contentsOf: URL(fileURLWithPath: $0)) }
        func inputsUntouched() throws -> Bool { try paths.map { try Data(contentsOf: URL(fileURLWithPath: $0)) } == before }

        // Output equal to an input, spelled differently, through a symlink, and as a hard link: all refused, even with --overwrite.
        let link = directory.appendingPathComponent("link.md")
        try FileManager.default.createSymbolicLink(atPath: link.path, withDestinationPath: paths[1])
        let hard = directory.appendingPathComponent("hard.md")
        try FileManager.default.linkItem(atPath: paths[2], toPath: hard.path)
        let dotted = directory.path + "/./sub/../r0.json"
        try FileManager.default.createDirectory(at: directory.appendingPathComponent("sub"), withIntermediateDirectories: true)
        for output in [paths[0], dotted, link.path, hard.path] {
            #expect(ResultsCLI.run(["report"] + paths + ["--output", output]) != 0, "refused: \(output)")
            #expect(ResultsCLI.run(["report"] + paths + ["--output", output, "--overwrite"]) != 0, "refused with --overwrite: \(output)")
            #expect(try inputsUntouched(), "inputs unchanged after refusing \(output)")
        }

        // Existing output: refused without --overwrite and left unchanged; replaced with it.
        let output = directory.appendingPathComponent("report.md")
        try Data("precious".utf8).write(to: output)
        #expect(ResultsCLI.run(["report"] + paths + ["--output", output.path]) != 0)
        #expect(try Data(contentsOf: output) == Data("precious".utf8))
        #expect(ResultsCLI.run(["report"] + paths + ["--output", output.path, "--overwrite"]) == 0)
        #expect(try String(contentsOf: output, encoding: .utf8).hasPrefix("# FirebladeECS benchmark comparison"))
        #expect(try inputsUntouched())

        // A fresh output path works without the flag; a directory is refused.
        #expect(ResultsCLI.run(["report"] + paths + ["--output", directory.appendingPathComponent("fresh.md").path]) == 0)
        #expect(ResultsCLI.run(["report"] + paths + ["--output", directory.appendingPathComponent("sub").path, "--overwrite"]) != 0)
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
        let report = try render(files)
        let section = "### `\(ReportFixtures.w2)` / 16"
        let count = try row(report, section: section, metric: "Malloc (total)", label: "measurements")
        #expect(count.contains("| 0 |"), "\(count)")
        let p50 = try row(report, section: section, metric: "Malloc (total)", label: "p50")
        #expect(p50.contains("| unavailable (no measurements) |"), "\(p50)")
        let mean = try row(report, section: section, metric: "Malloc (total)", label: "mean")
        #expect(mean.contains("| unavailable (no measurements) |"), "\(mean)")
        #expect(!report.contains("| nan"), "no NaN values")
        #expect(!report.contains("| inf") && !report.contains("| -inf") && !report.contains("(Δ nan"))
        // The other metrics of the ref are untouched.
        #expect(try row(report, section: section, metric: "Time (wall clock)", label: "p50").contains("| 1 μs |"))
    }

    @Test
    func hostCheckPassesOnThisHost() {
        #expect(ResultsCLI.run(["host-check"]) == 0)
        #expect(ResultsCLI.run(["host-check", "extra"]) != 0)
    }
}
