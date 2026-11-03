import Foundation
import Testing
@testable import ECSBenchmarkReport
@testable import ECSBenchmarkResultSchema

@Suite
struct ReportContentTests {
    typealias F = ReportFixtures

    private func html(_ files: [BenchmarkResultFile]) throws -> String {
        try BenchmarkReport.render(files, options: ReportOptions(baseline: "1.4.3")).html
    }

    private func twoRefs(configurationHash: String? = nil) -> [BenchmarkResultFile] {
        F.replicates(requested: "1.4.3", shaByte: "a", model: "class", medians: [1000, 1010, 1020])
            + F.replicates(requested: "main", shaByte: "b", medians: [500, 505, 510], configurationHash: configurationHash ?? String(repeating: "1", count: 64))
    }

    @Test
    func methodsClaimIdenticalSuiteSettingsOnlyWhenTheConfigurationHashesMatch() throws {
        let same = try html(twoRefs())
        #expect(same.contains("The suite settings are identical for all refs."))
        #expect(!same.contains("The suite settings differ between refs"))

        let different = try html(twoRefs(configurationHash: String(repeating: "2", count: 64)))
        #expect(!different.contains("identical for all refs"))
        let methods = try #require(ReportHTMLFragments.chapter(different, "methods"))
        #expect(methods.contains(##"The suite settings differ between refs (configuration hashes); see <a href="#warnings">Warnings</a>."##))
        #expect(different.contains("Configuration hashes differ across refs"))
    }

    @Test
    func benchmarkSetWarningShowsPlainNamesWithoutMarkdownBackticks() throws {
        let baseline = F.replicates(requested: "1.4.3", shaByte: "a", model: "class", scales: [16], medians: [1000, 1010, 1020])
        let series = F.replicates(requested: "main", shaByte: "b", scales: [16, 64], medians: [500, 505, 510])
        let rendered = try BenchmarkReport.render(baseline + series, options: ReportOptions(baseline: "1.4.3"))
        let warning = try #require(rendered.warnings.first { $0.contains("benchmark sets differ") })
        #expect(warning.contains("'\(F.w1) / 64'") && !warning.contains("`"))
        #expect(!rendered.html.contains("`"), "no Markdown leftovers anywhere in the page")
    }

    @Test
    func aWorkloadMeasuredOnlyAtZeroEntitiesHasTablesButNoPlotBoxes() throws {
        func ref(_ requested: String, _ shaByte: String, model: String, _ factor: Int) -> [BenchmarkResultFile] {
            (1 ... 3).map { index in
                F.file(
                    requested: requested, shaByte: shaByte, model: model, backends: ["default"],
                    replicate: ResultReplicate(index: index, count: 3, round: index, position: 1, seed: 7),
                    entries: [
                        F.Entry(identity: F.w1, backend: "default", scale: 16, results: [F.result(.wallClock, F.distribution(median: factor * (1000 + index)))]),
                        F.Entry(identity: F.w2, backend: "default", scale: 0, results: [F.result(.wallClock, F.distribution(median: factor * (100 + index)))])
                    ]
                )
            }
        }
        let page = try html(ref("1.4.3", "a", model: "class", 2) + ref("main", "b", model: "value", 1))
        let plotted = try #require(ReportHTMLFragments.section(page, F.w1))
        let zeroOnly = try #require(ReportHTMLFragments.section(page, F.w2))
        #expect(plotted.contains("class=\"plot\"") && !zeroOnly.contains("class=\"plot\""))
        #expect(zeroOnly.contains("<h4>Time (wall clock): Entity counts up to 1,024") && zeroOnly.contains("<td>0</td>"))
    }

    @Test
    func readingNotesLinkTheVerdictRuleAndDoNotRepeatTheFactsCards() throws {
        let page = try html(twoRefs())
        let notes = try #require(ReportHTMLFragments.chapter(page, "reading-notes"))
        for repeated in ["Baseline:", "Replicates per ref:", "Selection filter:", "Inputs:"] {
            #expect(!notes.contains(repeated), Comment(rawValue: repeated))
        }
        #expect(notes.contains(##"<a href="#glossary">glossary</a>"##) && !notes.contains("need q &lt;"))
        #expect(page.contains("<dt>Baseline</dt>") && page.contains("<dt>Selection filter</dt>"))
    }
}
