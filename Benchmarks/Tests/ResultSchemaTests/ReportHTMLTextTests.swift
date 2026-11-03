import Testing
@testable import ECSBenchmarkResultSchema

@Suite
struct ReportHTMLTextTests {
    @Test
    func interpolatedValuesAreEscapedAndLiteralMarkupIsKept() {
        let hostile = #"a <script>x</script> & "q" 'z' *b* [c](https://example.com) \ &lt;"#
        let text: HTMLText = "<code>\(hostile)</code> and <strong>\(hostile)</strong>"
        let escaped = #"a &lt;script&gt;x&lt;/script&gt; &amp; &quot;q&quot; &#39;z&#39; *b* [c](https://example.com) \ &amp;lt;"#
        #expect(text.html == "<code>\(escaped)</code> and <strong>\(escaped)</strong>")
        #expect(ReportHTML.code(hostile).html == "<code>\(escaped)</code>")
        #expect(("\(42) and \(1.5)" as HTMLText).html == "42 and 1.5")
    }

    @Test
    func nestedMarkupPassesOnlyAsHTMLText() {
        let inner: HTMLText = "<em>\("<b>")</em>"
        let outer: HTMLText = "x \(inner) \("<em>raw</em>")"
        #expect(outer.html == "x <em>&lt;b&gt;</em> &lt;em&gt;raw&lt;/em&gt;")
    }

    @Test
    func linksOnlyPointToInPageAnchors() {
        func link(_ anchor: String) -> String {
            let text: HTMLText = "\(anchor: anchor, "label <1>")"
            return text.html
        }
        #expect(link("glossary") == ##"<a href="#glossary">label &lt;1&gt;</a>"##)
        #expect(link("w-a_b-1") == ##"<a href="#w-a_b-1">label &lt;1&gt;</a>"##)
        for target in ["https://example.com/a", "//host/x", "docs/a.md", "javascript:1", "a\"b", "", "#x y"] {
            #expect(link(target) == "label &lt;1&gt;", Comment(rawValue: target))
        }
    }

    @Test
    func blocksRenderOneLineEach() {
        #expect(ReportBlock.heading(2, "Glossary", id: "glossary").html == #"<h2 id="glossary">Glossary</h2>"#)
        #expect(ReportBlock.heading(4, "<code>\("a<b")</code>").html == "<h4><code>a&lt;b</code></h4>")
        #expect(ReportBlock.paragraph("Intro").html == "<p>Intro</p>")
        #expect(ReportBlock.list(["one", "two <code>x</code>"]).html == "<ul>\n<li>one</li>\n<li>two <code>x</code></li>\n</ul>")
    }

    @Test
    func renderedReportHasNoUnescapedDataAndOnlyInPageLinks() throws {
        let html = try GuideFixtures.render(GuideFixtures.replicated())
        let page = String(html[..<html.range(of: "<script")!.lowerBound])
        #expect(!page.contains("`") && !page.contains("**") && !page.contains("&amp;lt;") && !page.contains("&amp;amp;"), "no Markdown leftovers or double escaping")
        #expect(!html.contains("href=\"http") && !html.contains("href=\"//") && !html.contains("javascript:"))
        for match in html.matches(of: #/href="([^"]*)"/#) {
            #expect(match.output.1.hasPrefix("#"), Comment(rawValue: String(match.output.1)))
        }
    }
}
