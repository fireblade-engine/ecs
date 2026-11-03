import Foundation
import Testing
@testable import ECSBenchmarkResultSchema

/// The single-file HTML report: self-contained, escaped, data embedded, verdicts shown by tint and symbol.
@Suite
struct ReportHTMLTests {
    private func render(_ files: [BenchmarkResultFile]? = nil) throws -> RenderedReport {
        try BenchmarkReport.render(files ?? GuideFixtures.replicated(), options: ReportOptions(baseline: "1.4.3"))
    }

    @Test
    func outputIsOneFileNamedBenchmarkReportHTML() throws {
        let rendered = try render()
        #expect(BenchmarkReport.fileName == "BenchmarkReport.html")
        #expect(rendered.html.hasPrefix("<!doctype html>\n<html lang=\"en\">"))
        #expect(rendered.html.contains("<meta charset=\"utf-8\">") && rendered.html.contains("name=\"viewport\""))
    }

    @Test
    func pageHasNoExternalResourcesAndNoURLs() throws {
        let html = try render().html
        #expect(!html.contains("http://") && !html.contains("https://") && !html.contains("//cdn"))
        #expect(!html.contains("<script src") && !html.contains("<link ") && !html.contains("<img") && !html.contains("@import"))
        #expect(html.matches(of: /url\((?!#)/).isEmpty, "only in-document url(#id) references")
        // Every link is an in-page anchor.
        for match in html.matches(of: #/(?:href|src)="([^"]*)"/#) {
            #expect(match.output.1.hasPrefix("#"), Comment(rawValue: String(match.output.1)))
        }
        // The only scripts are the data block and the inline script.
        #expect(html.components(separatedBy: "<script").count == 3)
    }

    @Test
    func themeTokensDarkModeAndExplicitBackground() throws {
        let html = try render().html
        #expect(html.contains(":root {") && html.contains("--bg:") && html.contains("--faster-bg:") && html.contains("--slower-bg:"))
        #expect(html.contains("@media (prefers-color-scheme: dark)"))
        #expect(html.contains("background: var(--bg)"))
        #expect(html.contains("overflow-x: auto"), "tables scroll inside their own container")
        for index in 0 ..< 7 { #expect(html.contains("--c\(index):") && html.contains("--e\(index):")) }
        #expect(html.contains("@media (max-width: 600px)"))
    }

    @Test
    func verdictCellsAreTintedAndCarryASymbol() throws {
        let html = try render().html
        for (verdict, symbol) in [("faster", "\u{25B2}"), ("equivalent", "="), ("inconclusive", "?")] {
            #expect(html.contains("class=\"verdict v-\(verdict)\""), Comment(rawValue: verdict))
            #expect(html.contains("<span class=\"sym\" aria-hidden=\"true\">\(symbol)</span> \(verdict)</td>"), Comment(rawValue: verdict))
        }
        // Every cell of a compared block in the row carries the class, not only the verdict cell.
        #expect(html.contains("<td class=\"v-faster\" data-s=\"1\">"))
        #expect(html.contains("td.v-faster {") && html.contains("td.v-slower {"))
        // Single-replicate input: no verdicts, so no faster/slower tint or symbol.
        let single = try render(GuideFixtures.single()).html
        #expect(!single.contains("class=\"verdict v-faster\"") && !single.contains("class=\"verdict v-slower\""))
        #expect(single.contains("v-unavailable"))
    }

    @Test
    func slowerGetsItsOwnTintAndSymbol() throws {
        // The series needs twice as long as the baseline on every workload.
        let files = GuideFixtures.ref("1.4.3", "a", model: "class", k: 10) { _, i in 1000 + 4 * i }
            + GuideFixtures.ref("main", "b", model: "value", k: 10) { _, i in 2000 + 4 * i }
        let html = try render(files).html
        #expect(html.contains("<span class=\"sym\" aria-hidden=\"true\">\u{25BC}</span> slower</td>"))
        #expect(html.contains("class=\"verdict v-slower\""))
    }

    @Test
    func tablesLinkRowsToPlotPoints() throws {
        let html = try render().html
        #expect(html.contains("<table data-w=\"w-\(ReportFixtures.w1)\">"))
        #expect(html.contains("<tr data-w=\"w-\(ReportFixtures.w1)\" data-n=\"16\">"))
        #expect(html.contains("class=\"table-wrap\""))
    }

    @Test
    func embeddedJSONParsesAndHoldsTheTableValues() throws {
        let html = try render().html
        let json = try #require(ReportHTMLSupport.embeddedJSON(html))
        let object = try #require(try JSONSerialization.jsonObject(with: json) as? [String: Any])
        let workloads = try #require(object["workloads"] as? [[String: Any]])
        #expect(workloads.map { $0["identity"] as? String } == [ReportFixtures.w1, ReportFixtures.w2, ReportFixtures.w3].sorted())
        let w1 = try #require(workloads.first { $0["identity"] as? String == ReportFixtures.w1 })
        let series = try #require(w1["series"] as? [[String: Any]])
        #expect(series.count == 2)
        let point = try #require((series[1]["points"] as? [[String: Any]])?.first)
        #expect(point["n"] as? Int == 16 && point["k"] as? Int == 10)
        // The tooltip text is the table text: the median of main on w1 is about 500 ns.
        let tMedian = try #require(point["tMedian"] as? String)
        #expect(tMedian.hasSuffix(" ns") || tMedian.hasSuffix(" μs"))
        #expect(point["verdict"] as? String == "faster" && (point["tSpeed"] as? String)?.contains("CI") == true)
        let relative = try #require(w1["rel"] as? [[String: Any]])
        #expect(relative.count == 1 && relative[0]["backend"] as? String == "default")
    }

    @Test
    func jsonCannotCloseTheScriptElement() throws {
        var files = GuideFixtures.replicated()
        for index in files.indices where files[index].ref.requested == "main" { files[index].ref.requested = "</script><!--&" }
        let html = try render(files).html
        let json = try #require(ReportHTMLSupport.embeddedJSON(html))
        let text = String(decoding: json, as: UTF8.self)
        #expect(!text.contains("<") && !text.contains(">") && !text.contains("&"))
        let object = try #require(try JSONSerialization.jsonObject(with: json) as? [String: Any])
        let workload = try #require((object["workloads"] as? [[String: Any]])?.first)
        #expect((workload["series"] as? [[String: Any]])?.contains { $0["ref"] as? String == "</script><!--&" } == true)
        #expect(html.components(separatedBy: "</script>").count == 3, "only the two real script elements close")
        #expect(!html.contains("</script><!--"))
    }

    @Test
    func refLabelsInProseDisplayVerbatim() throws {
        var files = GuideFixtures.replicated()
        for index in files.indices where files[index].ref.requested == "main" { files[index].ref.requested = "a&lt;*b*[c](#d)" }
        let html = try render(files).html
        // Entities, emphasis and link syntax of a label are shown as typed, in the reading notes and the protocol.
        #expect(html.components(separatedBy: "<code>a&amp;lt;*b*[c](#d)</code>: 10 of 10").count >= 3, "reading notes, protocol and guide")
        #expect(!html.contains("<em>b</em>") && !html.contains(##"<a href="#d">c</a>"##))
    }

    @Test
    func everyWorkloadHasASectionAndATableOfContentsEntry() throws {
        let html = try render().html
        for workload in [ReportFixtures.w1, ReportFixtures.w2, ReportFixtures.w3] {
            #expect(ReportHTMLSupport.section(html, workload) != nil, Comment(rawValue: workload))
            #expect(html.contains("<a href=\"#w-\(workload)\">"))
        }
        // Header facts and the fixed sections.
        let text = ReportHTMLSupport.text(html)
        for heading in ["## Reading notes", "## Summary", "## How to read this report", "## Workloads", "## Glossary", "## Methods", "## Provenance", "## Series and pairing", "## Parity notes", "## Unsupported workloads"] {
            #expect(text.contains("\n\(heading)\n"), Comment(rawValue: heading))
        }
        for fact in ["Baseline", "Refs", "Replicates (k) per ref", "Runs", "Batch (run id)", "Seed", "Host", "Toolchain"] {
            #expect(html.contains("<dt>\(fact)</dt>"), Comment(rawValue: fact))
        }
    }

    @Test
    func scriptHasNoNetworkAndNoUnsafeSinks() {
        let script = ReportScript.source
        #expect(!script.contains("http://") && !script.contains("https://"))
        #expect(!script.contains("fetch(") && !script.contains("XMLHttpRequest") && !script.contains("innerHTML") && !script.contains("eval("))
    }
}
