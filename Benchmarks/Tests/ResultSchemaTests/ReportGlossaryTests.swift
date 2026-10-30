import Foundation
import Testing
@testable import ECSBenchmarkResultSchema

/// Replicated and single-replicate report fixtures shared by the glossary and guide tests.
enum GuideFixtures {
    typealias F = ReportFixtures

    static func ref(_ requested: String, _ shaByte: String, model: String, k: Int, median: @escaping (String, Int) -> Int) -> [BenchmarkResultFile] {
        let workloads = [F.w1, F.w2, F.w3]
        return (1 ... k).map { index in
            F.file(
                requested: requested, shaByte: shaByte, model: model, backends: ["default"],
                replicate: k == 1 ? nil : ResultReplicate(index: index, count: k, round: index, position: 1, seed: 7),
                entries: workloads.map { workload in
                    F.Entry(identity: workload, backend: "default", scale: 16, results: [
                        F.result(.wallClock, F.distribution(median: median(workload, index))),
                        F.result(.throughput, [100_000, 200_000, 200_000, 400_000]),
                        F.result(.peakMemoryResident, Array(repeating: 50_000_000, count: 4)),
                        F.result(.mallocCountTotal, [3, 3, 4])
                    ])
                }
            )
        }
    }

    /// Baseline plus a series that is twice as fast on w1, equal on w2 and noisy on w3.
    static func replicated(k: Int = 10) -> [BenchmarkResultFile] {
        ref("1.4.3", "a", model: "class", k: k) { _, i in 1000 + 4 * i }
            + ref("main", "b", model: "value", k: k) { workload, i in
                switch workload {
                case F.w1: (1000 + 4 * i) / 2
                case F.w2: 1000 + 4 * i + 1
                default: 1000 + 4 * i + (i % 2 == 0 ? 300 : -300) + 20 * i
                }
            }
    }

    static func single() -> [BenchmarkResultFile] {
        ref("1.4.3", "a", model: "class", k: 1) { _, _ in 1000 } + ref("main", "b", model: "value", k: 1) { _, _ in 700 }
    }

    static func render(_ files: [BenchmarkResultFile]) throws -> [RenderedFile] {
        try BenchmarkReport.render(files, options: ReportOptions(baseline: "1.4.3")).files
    }

    /// Text of the third header row of every table, i.e. the column headers.
    static func columnHeaders(_ markdown: String) -> Set<String> {
        var headers = Set<String>()
        let lines = markdown.components(separatedBy: "\n")
        for (index, line) in lines.enumerated() where line == "<thead>" {
            let row = lines[index + 3]
            for part in row.components(separatedBy: "<th>").dropFirst() {
                headers.insert(part.components(separatedBy: "</th>")[0])
            }
        }
        return headers
    }
}

@Suite
struct ReportGlossaryTests {
    @Test(arguments: [true, false])
    func everyColumnHeaderAndLegendTermHasAnEntry(replicated: Bool) throws {
        let files = replicated ? GuideFixtures.replicated() : GuideFixtures.single()
        let rendered = try GuideFixtures.render(files)
        var headers = Set<String>()
        for file in rendered where file.path.hasSuffix(".md") {
            headers.formUnion(GuideFixtures.columnHeaders(file.contents).map { $0.replacingOccurrences(of: "&amp;", with: "&") })
        }
        #expect(headers.contains("speed (×)") || files.count == 2, "tables were found")
        for header in headers {
            #expect(ReportGlossary.covers(header), Comment(rawValue: "no glossary entry for the column header '\(header)'"))
        }
        // Legend and caption terms of every plot.
        var terms = Set<String>()
        for file in rendered where file.path.hasSuffix(".svg") {
            for line in file.contents.components(separatedBy: "\n") where line.contains(#"class="note""#) {
                let text = line.components(separatedBy: ">").dropFirst().joined(separator: ">").components(separatedBy: "</text")[0]
                for match in text.matches(of: /\bp\d+\b|\b[A-Z]{2,}\b|Hodges–Lehmann/) { terms.insert(String(match.0)) }
            }
        }
        #expect(terms.isSuperset(of: ["CI", "IQR"]) || files.count == 2)
        for term in terms {
            #expect(ReportGlossary.covers(term), Comment(rawValue: "no glossary entry for the legend term '\(term)'"))
        }
    }

    @Test
    func everyVerdictAndUnavailableWordHasAnEntry() {
        let verdicts: [ReportStatistics.Verdict] = [.faster, .slower, .equivalent, .inconclusive, .notAvailable(replicates: 1), .notAvailable(replicates: 0)]
        for verdict in verdicts {
            #expect(ReportGlossary.covers(ReportWriter.verdictText(verdict)), Comment(rawValue: "\(verdict)"))
        }
        for word in ["unavailable", "n/a", "baseline", "series", "backend", "sparseSet", "archetype", "class", "value", "per-entity", "total", "wall clock", "cpu total", "throughput", "peak RSS", "malloc count", "log scale", "linear scale", "Kendall τ", "δ", "q", "BH", "p", "HL", "k", "replicates", "iterations"] {
            #expect(ReportGlossary.covers(word), Comment(rawValue: word))
        }
        #expect(!ReportGlossary.covers("zzz-not-a-term"))
    }

    @Test
    func glossaryIsLinkedFromTheTopAndFromEveryWorkloadPageAndPrecedesMethods() throws {
        let rendered = try GuideFixtures.render(GuideFixtures.replicated())
        let report = try #require(rendered.first { $0.path == "REPORT.md" }).contents
        let glossary = try #require(report.range(of: "\n## Glossary\n"))
        let methods = try #require(report.range(of: "\n## Methods\n"))
        #expect(glossary.upperBound <= methods.lowerBound)
        #expect(report.contains("[Glossary](#glossary)"))
        for page in rendered where page.path.hasPrefix("workloads/") {
            #expect(page.contents.contains("[Glossary](../REPORT.md#glossary)"), Comment(rawValue: page.path))
        }
        #expect(report.contains("- **CI, confidence interval**:") && report.contains("±5%"))
    }
}
