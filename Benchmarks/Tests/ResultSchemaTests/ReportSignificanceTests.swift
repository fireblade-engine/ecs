import Foundation
import Testing
@testable import ECSBenchmarkResultSchema

@Suite
struct ReportSignificanceTests {
    /// Reference values computed with scipy.stats.t.sf (two-sided).
    @Test
    func twoSidedPMatchesReferenceValues() {
        #expect(abs(Welch.twoSidedP(t: 2.0, degreesOfFreedom: 10) - 0.07338803477074039) < 1e-9)
        #expect(abs(Welch.twoSidedP(t: 0.5, degreesOfFreedom: 3.7) - 0.645335633319932) < 1e-9)
        // Closed forms: df 1 (Cauchy) and df 2.
        #expect(abs(Welch.twoSidedP(t: 2, degreesOfFreedom: 1) - (1 - 2 / Double.pi * atan(2))) < 1e-12)
        #expect(abs(Welch.twoSidedP(t: 2, degreesOfFreedom: 2) - (1 - 2 / 6.0.squareRoot())) < 1e-12)
        // Critical value of the t table: t(0.975, 10) = 2.228138852.
        #expect(abs(Welch.twoSidedP(t: 2.228138852, degreesOfFreedom: 10) - 0.05) < 1e-8)
        #expect(Welch.twoSidedP(t: 0, degreesOfFreedom: 5) == 1)
        #expect(Welch.twoSidedP(t: 40, degreesOfFreedom: 5000) < 1e-100)
        #expect(Welch.twoSidedP(t: -2.0, degreesOfFreedom: 10) == Welch.twoSidedP(t: 2.0, degreesOfFreedom: 10))
    }

    @Test
    func welchStatisticMatchesReferenceValues() throws {
        // Population deviations are converted to sample deviations inside, so feed population values (s * sqrt((n - 1) / n)).
        func population(_ sample: Double, _ n: Int) -> Double { sample * (Double(n - 1) / Double(n)).squareRoot() }
        let a = try #require(Welch.test(mean1: 10, standardDeviation1: population(2, 10), count1: 10, mean2: 7, standardDeviation2: population(4, 20), count2: 20))
        #expect(abs(a.t - 2.73861278752583) < 1e-9)
        #expect(abs(a.degreesOfFreedom - 27.981818181818184) < 1e-9)
        #expect(abs(a.p - 0.01061052868362615) < 1e-9)
        #expect(a.isSignificant)
        let b = try #require(Welch.test(mean1: 100, standardDeviation1: population(15, 50), count1: 50, mean2: 95, standardDeviation2: population(10, 40), count2: 40))
        #expect(abs(b.p - 0.06217280937787479) < 1e-9)
        #expect(!b.isSignificant)
        let c = try #require(Welch.test(mean1: 5, standardDeviation1: population(1, 3), count1: 3, mean2: 3, standardDeviation2: population(0.5, 4), count2: 4))
        #expect(abs(c.degreesOfFreedom - 2.7557251908396942) < 1e-9)
        #expect(abs(c.p - 0.05634116258351984) < 1e-9)
    }

    @Test
    func undefinedForFewerThanTwoSamplesAndHandlesZeroVariance() throws {
        #expect(Welch.test(mean1: 1, standardDeviation1: 0, count1: 1, mean2: 2, standardDeviation2: 1, count2: 5) == nil)
        #expect(Welch.test(mean1: 1, standardDeviation1: 1, count1: 5, mean2: 2, standardDeviation2: 1, count2: 0) == nil)
        let same = try #require(Welch.test(mean1: 3, standardDeviation1: 0, count1: 4, mean2: 3, standardDeviation2: 0, count2: 4))
        #expect(same.p == 1 && !same.isSignificant)
        let different = try #require(Welch.test(mean1: 3, standardDeviation1: 0, count1: 4, mean2: 4, standardDeviation2: 0, count2: 4))
        #expect(different.p == 0 && different.isSignificant)
    }
}
