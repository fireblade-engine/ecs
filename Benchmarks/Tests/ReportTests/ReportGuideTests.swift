import Foundation
import Testing
@testable import ECSBenchmarkReport
@testable import ECSBenchmarkResultSchema

@Suite
struct ReportGuideTests {
    @Test
    func guideRendersWithSixPartsAndIsLinkedFromTheTop() throws {
        let html = try GuideFixtures.render(GuideFixtures.replicated())
        let text = ReportHTMLSupport.text(html)
        let summary = try #require(text.range(of: "\n## Summary\n"))
        let guide = try #require(text.range(of: "\n## How to read this report\n"))
        let workloads = try #require(text.range(of: "\n## Workloads\n"))
        #expect(summary.upperBound <= guide.lowerBound && guide.upperBound <= workloads.lowerBound)
        #expect(html.contains(##"<a href="#how-to-read-this-report">How to read this report</a>"##))
        for heading in ["### 1. What a confidence interval is", "### 2. How the verdict is decided", "### 3. Error bars are not the light band", "### 4. Reading the plots", "### 5. What `q` is", "### 6. Replicates (k) and interleaving"] {
            #expect(text.contains(heading), Comment(rawValue: heading))
        }
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
        let text = ReportHTMLSupport.text(try GuideFixtures.render(files))
        let start = try #require(text.range(of: "## How to read this report"))
        let end = try #require(text.range(of: "\n## Workloads\n"))
        return String(text[start.lowerBound ..< end.lowerBound])
    }
}
