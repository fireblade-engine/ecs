import Foundation
import Testing
@testable import ECSBenchmarkReport
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

    static func render(_ files: [BenchmarkResultFile]) throws -> String {
        try BenchmarkReport.render(files, options: ReportOptions(baseline: "1.4.3")).html
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
        let headers = GuideFixtures.columnHeaders(rendered).map { ReportHTMLFragments.decode($0) }
        #expect(headers.contains("speed (×)") || files.count == 2, "tables were found")
        for header in headers {
            #expect(ReportGlossary.covers(header), Comment(rawValue: "no glossary entry for the column header '\(header)'"))
        }
        // Legend and caption terms of every plot: the notes the script writes under each plot.
        var terms = Set<String>()
        for note in ReportScript.source.matches(of: #/notes\.push\("([^"]*)"/#) {
            let text = String(note.output.1).replacingOccurrences(of: "\\u2013", with: "–")
            for match in text.matches(of: /\bp\d+\b|\b[A-Z]{2,}\b|Hodges–Lehmann/) { terms.insert(String(match.0)) }
        }
        #expect(terms.isSuperset(of: ["CI", "IQR"]) || files.count == 2)
        for term in terms {
            #expect(ReportGlossary.covers(term), Comment(rawValue: "no glossary entry for the legend term '\(term)'"))
        }
    }

    @Test
    func theTestOnlyNamesDescribeExactlyTheGlossaryEntries() {
        #expect(Set(ReportGlossary.names.keys) == Set(ReportGlossary.entries.map(\.term)))
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
    func glossaryIsLinkedFromTheTopAndFromEveryWorkloadSectionAndPrecedesMethods() throws {
        let html = try GuideFixtures.render(GuideFixtures.replicated())
        let glossary = try #require(html.range(of: "<h2 id=\"glossary\">"))
        let methods = try #require(html.range(of: "<h2 id=\"methods\">"))
        #expect(glossary.upperBound <= methods.lowerBound)
        #expect(html.contains(##"<a href="#glossary">Glossary</a>"##))
        for workload in [GuideFixtures.F.w1, GuideFixtures.F.w2, GuideFixtures.F.w3] {
            let section = try #require(ReportHTMLFragments.section(html, workload))
            #expect(section.contains(##"<a href="#glossary">glossary</a>"##), Comment(rawValue: workload))
        }
        let chapter = try #require(ReportHTMLFragments.chapter(html, "glossary"))
        #expect(chapter.contains("<strong>CI, confidence interval</strong>:") && chapter.contains("±5%"))
    }
}

extension ReportGlossary {
    // Test-only: the production report prints the entries and never looks terms up.
    /// True when `label` (a table column header, legend term or verdict cell) is defined by an entry. Unit suffixes in parentheses
    /// ("median (ms)") are ignored; the whole label and the label without the suffix are both tried.
    static func covers(_ label: String) -> Bool {
        let all = Set(names.values.flatMap { $0 }.map { $0.lowercased() })
        let lowered = label.lowercased()
        if all.contains(lowered) { return true }
        if let open = lowered.range(of: " (", options: .backwards), lowered.hasSuffix(")"), all.contains(String(lowered[..<open.lowerBound])) { return true }
        if lowered.range(of: #"^p\d+$"#, options: .regularExpression) != nil { return all.contains("p0") }
        if lowered.hasPrefix("n/a (") { return all.contains("n/a") }
        return false
    }
}
