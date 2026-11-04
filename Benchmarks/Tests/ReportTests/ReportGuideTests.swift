import Foundation
import Testing
@testable import ECSBenchmarkReport
@testable import ECSBenchmarkResultSchema

@Suite
struct ReportGuideTests {
    @Test
    func guideRendersWithSixPartsAndIsLinkedFromTheTop() throws {
        let html = try GuideFixtures.render(GuideFixtures.replicated())
        let summary = try #require(html.range(of: "<h2 id=\"summary\">"))
        let guide = try #require(html.range(of: "<h2 id=\"how-to-read-this-report\">"))
        let workloads = try #require(html.range(of: "<h2 id=\"workloads\">"))
        #expect(summary.upperBound <= guide.lowerBound && guide.upperBound <= workloads.lowerBound)
        #expect(html.contains(##"<a href="#how-to-read-this-report">How to read this report</a>"##))
        for heading in ["1. What a confidence interval is", "2. How the verdict is decided", "3. Error bars are not the light band", "4. Reading the plots", "5. What <code>q</code> is", "6. Replicates (k) and interleaving"] {
            #expect(html.contains("<h3>\(heading)</h3>"), Comment(rawValue: heading))
        }
    }

    @Test
    func guideLinksTheVerdictRuleInsteadOfRestatingIt() throws {
        let guide = try #require(ReportHTMLFragments.chapter(try GuideFixtures.render(GuideFixtures.replicated()), ReportGlossary.guideAnchor))
        #expect(guide.contains(##"<a href="#glossary">glossary</a>"##))
        #expect(!guide.contains("<code>faster</code> / <code>slower</code>: the test is significant"))
    }

    @Test
    func guideIsStaticAndMarksItsExamplesAsIllustrative() throws {
        let replicated = try guideText(GuideFixtures.replicated())
        let single = try guideText(GuideFixtures.single())
        #expect(replicated == single, "the guide does not depend on the report data")
        #expect(replicated.contains("Illustrative example (not from this report)"))
        #expect(!replicated.contains("Example from this report"))
    }

    private func guideText(_ files: [BenchmarkResultFile]) throws -> String {
        try #require(ReportHTMLFragments.chapter(try GuideFixtures.render(files), ReportGlossary.guideAnchor))
    }
}
