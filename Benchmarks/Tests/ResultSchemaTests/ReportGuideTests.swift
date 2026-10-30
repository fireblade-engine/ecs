import Foundation
import Testing
@testable import ECSBenchmarkResultSchema

@Suite
struct ReportGuideTests {
    private func report(_ files: [BenchmarkResultFile]) throws -> String {
        try #require(GuideFixtures.render(files).first { $0.path == "REPORT.md" }).contents
    }

    private func guide(_ report: String) throws -> String {
        let start = try #require(report.range(of: "## How to read this report"))
        let end = try #require(report.range(of: "\n## Workloads\n"))
        return String(report[start.lowerBound ..< end.lowerBound])
    }

    @Test
    func sectionFollowsTheSummaryIsLinkedFromTheTopAndHasSixParts() throws {
        let text = try report(GuideFixtures.replicated())
        let summary = try #require(text.range(of: "\n## Summary\n"))
        let guide = try #require(text.range(of: "\n## How to read this report\n"))
        let workloads = try #require(text.range(of: "\n## Workloads\n"))
        #expect(summary.upperBound <= guide.lowerBound && guide.upperBound <= workloads.lowerBound)
        #expect(text.contains("[How to read this report](#how-to-read-this-report)"))
        let body = try self.guide(text)
        for heading in ["### 1. What a confidence interval is", "### 2. How the verdict is decided", "### 3. Error bars are not the light band", "### 4. Reading the plots", "### 5. What `q` is", "### 6. Replicates (k) and interleaving"] {
            #expect(body.contains(heading), Comment(rawValue: heading))
        }
    }

    @Test
    func examplesUseTheNumbersOfTheReport() throws {
        let files = GuideFixtures.replicated()
        let model = try ReportModel(files: files, baseline: "1.4.3")
        let wall = try #require(model.wallClockMetric)
        // Rule: eligible = scale > 0 and a CI of non-zero width; the main example is the median-width workload at the smallest scale >= 1,024, else the largest scale.
        let eligible = model.keys.filter { $0.metric == wall && $0.scale > 0 }.compactMap { key in
            model.comparisons[ReportComparisonKey(series: 1, key: key)].map { (key, $0) }
        }.filter { ($0.1.ciHigh ?? 0) > ($0.1.ciLow ?? 0) }
        let scale = try #require(eligible.map(\.0.scale).filter { $0 >= 1_024 }.min() ?? eligible.map(\.0.scale).max())
        let pool = eligible.filter { $0.0.scale == scale }.enumerated().sorted {
            let (a, b) = ($0.element.1, $1.element.1)
            return ((a.ciHigh! - a.ciLow!) / a.speed!, $0.offset) < ((b.ciHigh! - b.ciLow!) / b.speed!, $1.offset)
        }.map(\.element)
        let first = pool[pool.count / 2]
        let body = try guide(report(files))
        let speed = ReportFormat.text(first.1.speed!, columnDecimals: ReportFormat.columnDecimals([first.1.speed!, first.1.ciLow!, first.1.ciHigh!], divisor: 1))
        #expect(body.contains("**Example from this report:** `\(first.0.identity)` at \(first.0.scale) entities"))
        #expect(body.contains("speed \(speed)×, CI "), "the first comparison with an interval gives the example numbers")
        #expect(!body.contains("CI 1.00–1.00×") && !body.contains(" at 0 entities"), "no degenerate or zero-entity examples")
        #expect(body.contains("→ the true speedup is very likely between"))
        #expect(body.contains("Narrowest CI in this report") && body.contains("light band (IQR of single iterations)"))
        #expect(body.contains("\(model.comparisons.values.filter { $0.p != nil }.count) wall-clock comparisons were tested"))
        #expect(body.contains("1.4.3: 10 of 10; main: 10 of 10"))
        #expect(body.contains("Example `faster`") && body.contains("Example `equivalent`"))
        #expect(!body.contains("Inference is unavailable in this report"))
    }

    @Test
    func degenerateCellsAreNeverUsedAsExamples() throws {
        // Equal series: CI is exactly 1-1 only when all replicates coincide; use a constant series versus a constant baseline.
        let files = GuideFixtures.ref("1.4.3", "a", model: "class", k: 10) { _, _ in 1000 }
            + GuideFixtures.ref("main", "b", model: "value", k: 10) { _, _ in 1000 }
        let body = try guide(report(files))
        #expect(body.contains("no comparison has a CI with a non-zero width"))
        #expect(!body.contains("Narrowest CI in this report"))
        #expect(!body.contains("CI 1.00–1.00×") && !body.contains("the true speedup is very likely"))
    }

    @Test
    func singleReplicateStatesThatInferenceIsUnavailable() throws {
        let body = try guide(report(GuideFixtures.single()))
        #expect(body.contains("**Inference is unavailable in this report.**"))
        #expect(body.contains("1.4.3: 1, main: 1"))
        #expect(body.contains("inference is unavailable and it cannot be called"))
        #expect(body.contains("0 faster, 0 slower, 0 equivalent, 0 inconclusive"))
        #expect(body.contains("no series has enough replicates for an error bar"))
        #expect(body.contains("no test was run"))
        #expect(!body.contains("the true speedup is very likely"))
        #expect(body.contains("### 6. Replicates (k) and interleaving") && body.contains("1.4.3: 1 of 1"))
    }
}
