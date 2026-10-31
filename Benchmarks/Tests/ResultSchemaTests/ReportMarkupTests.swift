import Testing
@testable import ECSBenchmarkResultSchema

@Suite
struct ReportMarkupTests {
    @Test
    func escapesEverythingIncludingCodeSpans() {
        #expect(ReportMarkup.inline("a <script>x</script> & \"q\"") == "a &lt;script&gt;x&lt;/script&gt; &amp; &quot;q&quot;")
        #expect(ReportMarkup.inline("`a<b>`") == "<code>a&lt;b&gt;</code>")
        // Entities written by the report's `text()` helper are escaped exactly once.
        #expect(ReportMarkup.inline("x &lt; y &amp; z") == "x &lt; y &amp; z")
        #expect(ReportMarkup.inline("&amp;lt;") == "&amp;lt;")
    }

    @Test
    func inlineStylesAndLinks() {
        #expect(ReportMarkup.inline("**bold** and *italic* and `code`") == "<strong>bold</strong> and <em>italic</em> and <code>code</code>")
        #expect(ReportMarkup.inline("[glossary](#glossary)") == ##"<a href="#glossary">glossary</a>"##)
        #expect(ReportMarkup.inline("[x](https://example.com/a)") == "x", "external targets never become links")
        #expect(ReportMarkup.inline("[x](//host/x)") == "x" && ReportMarkup.inline("[x](docs/a.md)") == "x" && ReportMarkup.inline("[x](javascript:1)") == "x", "only # targets are links")
        #expect(ReportMarkup.inline("(1 ÷ speed − 1) × 100") == "(1 ÷ speed − 1) × 100")
        #expect(ReportMarkup.inline("odd ` backtick") == "odd ` backtick")
    }

    @Test
    func blocks() {
        let html = ReportMarkup.html(["## How to read this report", "", "Intro line", "- one", "- two `x`", "", "> **Note** here", "", "### 1. A part"], headingOffset: 1)
        #expect(html == """
        <h3 id="how-to-read-this-report">How to read this report</h3>
        <p>Intro line</p>
        <ul>
        <li>one</li>
        <li>two <code>x</code></li>
        </ul>
        <blockquote><p><strong>Note</strong> here</p></blockquote>
        <h4 id="1-a-part">1. A part</h4>
        """)
    }

    @Test
    func slugs() {
        #expect(ReportMarkup.slug("Glossary") == "glossary")
        #expect(ReportMarkup.slug("6. Replicates (k) and interleaving") == "6-replicates-k-and-interleaving")
        #expect(ReportMarkup.slug("What `q` is") == "what-q-is")
    }
}

@Suite
struct ReportTextEscapingTests {
    @Test
    func textEscapesMarkupSoDataDisplaysVerbatim() {
        let value = #"a*b*[c](#d) \ &lt; <x>"#
        let html = ReportMarkup.inline(ReportWriter.text(value))
        #expect(html == #"a*b*[c](#d) \ &amp;lt; &lt;x&gt;"#)
        #expect(ReportMarkup.inline("`" + ReportWriter.codeText(value) + "`") == "<code>" + #"a*b*[c](#d) \ &amp;lt; &lt;x&gt;"# + "</code>")
    }
}
