import Testing
@testable import ECSBenchmarkResultSchema

@Suite
struct FilterCheckTests {
    private let listing = """

    Target 'ECSCompatBenchmark' available benchmarks:
    alpha / 16
    foo / 1

    """

    @Test func wholeMatchSelectsNames() throws {
        let result = try ResultsCLI.checkFilter(listing: listing, filter: "foo.*")
        #expect(result.matched == ["foo / 1"])
        #expect(result.names == ["alpha / 16", "foo / 1"])
    }

    @Test func partialMatchDoesNotCount() {
        #expect(throws: ResultError.self) { try ResultsCLI.checkFilter(listing: listing, filter: "foo") }
        #expect(throws: ResultError.self) { try ResultsCLI.checkFilter(listing: listing, filter: "alpha") }
    }

    @Test func noMatchNamesFilterAndCount() {
        do {
            _ = try ResultsCLI.checkFilter(listing: listing, filter: "zzz.*")
            Issue.record("expected a rejection")
        } catch {
            let text = "\(error)"
            #expect(text.contains("matches none of the 2 listed benchmarks"), "got: \(text)")
            #expect(text.contains("zzz.*"))
        }
    }

    @Test func emptyListingIsRejected() {
        for empty in ["", "\n", "Target 'ECSCompatBenchmark' available benchmarks:\n\n"] {
            do {
                _ = try ResultsCLI.checkFilter(listing: empty, filter: ".*")
                Issue.record("expected a rejection")
            } catch {
                #expect("\(error)".contains("the benchmark list is empty"))
            }
        }
    }

    @Test func invalidRegexIsReported() {
        do {
            _ = try ResultsCLI.checkFilter(listing: listing, filter: "(unclosed")
            Issue.record("expected a rejection")
        } catch {
            #expect("\(error)".contains("is not a valid regular expression"), "got: \(error)")
        }
    }

    @Test func junkLinesAreNotBenchmarkNames() throws {
        let noisy = """
        Building for production...
        [1/1] Planning build

        Target 'ECSCompatBenchmark' available benchmarks:
        alpha / 16
        foo / 1

        Done in 1.2s
        """
        #expect(ResultsCLI.benchmarkNames(inListing: noisy) == ["alpha / 16", "foo / 1"])
        #expect(throws: ResultError.self) { try ResultsCLI.checkFilter(listing: noisy, filter: "Done.*") }
        #expect(throws: ResultError.self) { try ResultsCLI.checkFilter(listing: noisy, filter: "Building.*") }
    }
}
