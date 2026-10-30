import Foundation
import Testing
@testable import ECSBenchmarkResultSchema

/// Brute-force oracles enumerate every label permutation directly; reference numbers were computed with an independent
/// implementation (scipy 1.12: stats.mannwhitneyu(method="exact"), stats.kendalltau(method="exact"),
/// stats.binom.cdf, stats.false_discovery_control, numpy medians) or are textbook values, as noted per test.
@Suite
struct ReportStatisticsTests {
    typealias S = ReportStatistics

    static func near(_ a: Double?, _ b: Double, _ tol: Double) -> Bool { a.map { abs($0 - b) < tol } ?? false }
    func near(_ a: Double?, _ b: Double, _ tol: Double) -> Bool { Self.near(a, b, tol) }

    // MARK: Oracles

    /// All index subsets of size `m` of 0..<n.
    static func combinations(_ n: Int, _ m: Int) -> [[Int]] {
        var result: [[Int]] = []
        var current: [Int] = []
        func go(_ start: Int) {
            if current.count == m { result.append(current); return }
            guard start < n else { return }
            for i in start..<n {
                current.append(i)
                go(i + 1)
                current.removeLast()
            }
        }
        go(0)
        return result
    }

    /// Average (mid) ranks computed the plain way, in Double.
    static func midranks(_ x: [Double]) -> [Double] {
        x.map { v in Double(x.filter { $0 < v }.count) + (Double(x.filter { $0 == v }.count) + 1) / 2 }
    }

    /// Two-sided p by enumerating every assignment of the pooled midranks to the first sample.
    static func bruteForceMannWhitneyP(_ a: [Double], _ b: [Double]) -> Double {
        let pooled = a + b
        let ranks = midranks(pooled)
        let observed = ranks.prefix(a.count).reduce(0, +)
        var lower = 0
        var upper = 0
        let subsets = combinations(pooled.count, a.count)
        for subset in subsets {
            let w = subset.reduce(0.0) { $0 + ranks[$1] }
            if w <= observed + 1e-9 { lower += 1 }
            if w >= observed - 1e-9 { upper += 1 }
        }
        return min(1, 2 * min(Double(lower), Double(upper)) / Double(subsets.count))
    }

    static func permutations(_ items: [Double]) -> [[Double]] {
        if items.count <= 1 { return [items] }
        var result: [[Double]] = []
        for i in items.indices {
            var rest = items
            let head = rest.remove(at: i)
            for tail in permutations(rest) { result.append([head] + tail) }
        }
        return result
    }

    static func kendallS(_ v: [Double]) -> Int {
        var s = 0
        for i in v.indices { for j in (i + 1)..<max(v.count, i + 1) { s += v[j] > v[i] ? 1 : (v[j] < v[i] ? -1 : 0) } }
        return s
    }

    static func bruteForceKendallP(_ v: [Double]) -> Double {
        let all = permutations(v)
        let s = kendallS(v)
        let lower = all.filter { kendallS($0) <= s }.count
        let upper = all.filter { kendallS($0) >= s }.count
        return min(1, 2 * Double(min(lower, upper)) / Double(all.count))
    }

    // MARK: Median CI

    @Test
    func medianCIForTenReplicates() throws {
        let values = [9.0, 1, 4, 7, 3, 10, 2, 8, 6, 5]
        let ci = try #require(try S.medianConfidenceInterval(values))
        #expect(ci.rank == 2)
        #expect(ci.low == 2 && ci.high == 9)
        #expect(ci.median == 5.5)
        // 1 - 2 * 11/1024 (binom.cdf(1, 10, .5) = 0.0107421875), the plan's 97.9%.
        #expect(ci.coverage == 0.978515625)
    }

    @Test
    func medianCIOtherSizesMatchBinomialReference() throws {
        // (k, l, coverage) from scipy.stats.binom.cdf.
        let table: [(Int, Int, Double)] = [(6, 1, 0.96875), (7, 1, 0.984375), (8, 1, 0.9921875), (12, 3, 0.96142578125), (20, 6, 0.9586105346679688)]
        for (k, l, coverage) in table {
            let ci = try #require(try S.medianConfidenceInterval((1...k).map(Double.init)))
            #expect(ci.rank == l)
            #expect(abs(ci.coverage - coverage) < 1e-14)
            #expect(ci.low == Double(l) && ci.high == Double(k - l + 1))
        }
    }

    @Test
    func medianCIIsNilWhenTooFewReplicates() throws {
        for k in 1...5 {
            #expect(try S.medianConfidenceInterval((1...k).map(Double.init)) == nil)
        }
        #expect(throws: StatisticsError.self) { try S.medianConfidenceInterval([]) }
        #expect(throws: StatisticsError.self) { try S.medianConfidenceInterval([1, .nan, 3]) }
    }

    @Test
    func medianCIWithTiesAndConstants() throws {
        let ci = try #require(try S.medianConfidenceInterval([5, 5, 5, 5, 5, 5]))
        #expect(ci.low == 5 && ci.high == 5 && ci.median == 5)
        #expect(try S.median([3, 1, 2]) == 2)
        #expect(try S.median([4, 1, 2, 3]) == 2.5)
    }

    // MARK: Mann-Whitney

    @Test
    func mannWhitneyMatchesBruteForceWithoutTies() throws {
        let samples: [([Double], [Double])] = [
            ([1, 4, 6], [2, 3]), ([5], [1, 2, 3, 4]), ([1, 2, 3, 4], [5, 6, 7, 8]), ([8, 1, 6, 3, 9], [2, 7, 4, 10, 5]),
            ([1.5, 2.5], [0.5]), ([3, 9, 12, 4, 1, 7], [8, 2, 11, 5])
        ]
        for (a, b) in samples {
            let result = try S.mannWhitney(a, b)
            #expect(abs(result.p - Self.bruteForceMannWhitneyP(a, b)) < 1e-12)
        }
    }

    @Test
    func mannWhitneyMatchesBruteForceWithTies() throws {
        let samples: [([Double], [Double])] = [
            ([1, 2, 2, 3], [2, 3, 3, 4, 5]), ([1, 1, 1], [1, 1, 2]), ([1, 2, 3, 3, 3], [3, 3, 4, 4]), ([2, 2], [2, 2, 2]),
            ([1, 1, 2, 2], [2, 2, 3, 3]), ([5, 5, 5, 6], [5, 7, 7, 7, 7]), ([1, 2, 3, 4, 5, 6, 6], [6, 6, 7, 8])
        ]
        for (a, b) in samples {
            let result = try S.mannWhitney(a, b)
            #expect(abs(result.p - Self.bruteForceMannWhitneyP(a, b)) < 1e-12)
        }
    }

    @Test
    func mannWhitneyMatchesPublishedReferences() throws {
        // R's ?wilcox.test example (Hollander & Wolfe style data): W = 35, one-sided p = 0.1272; scipy exact two-sided 0.2544122544122544.
        let x = [0.80, 0.83, 1.89, 1.04, 1.45, 1.38, 1.91, 1.64, 0.73, 1.46]
        let y = [1.15, 0.88, 0.90, 0.74, 1.21]
        let r = try S.mannWhitney(x, y)
        #expect(r.u == 35)
        #expect(abs(r.p - 0.2544122544122544) < 1e-12)
        let r2 = try S.mannWhitney([3.1, 4.7, 5.2, 6.9, 8.0, 9.4, 10.1, 12.5], [2.0, 2.9, 3.5, 4.1, 4.4, 5.0, 6.2])
        #expect(r2.u == 48)
        #expect(abs(r2.p - 0.020512820512820513) < 1e-12)
    }

    @Test
    func mannWhitneyTextbookCriticalValues() {
        // Classic table: n1 = n2 = 5, P(U <= 2) = 4/252 = 0.0159 and P(U <= 3) = 7/252 = 0.0278, so the two-sided 5% critical value is 2.
        let cdf = S.mannWhitneyNullCDF(m: 5, n: 5)
        #expect(abs(cdf[2] - 4.0 / 252) < 1e-15)
        #expect(abs(cdf[3] - 7.0 / 252) < 1e-15)
        #expect(abs(cdf[25] - 1) < 1e-15)
        // Smallest attainable two-sided p: 2 / C(m+n, m); k = 5 gives 0.0079, k = 10 gives 1.1e-5 (PLAN).
        #expect(abs(2 * S.mannWhitneyNullCDF(m: 5, n: 5)[0] - 2.0 / 252) < 1e-15)
        #expect(abs(2 * S.mannWhitneyNullCDF(m: 10, n: 10)[0] - 2.0 / 184_756) < 1e-18)
    }

    @Test
    func mannWhitneyEdgeCases() throws {
        let identical = try S.mannWhitney([1, 2, 3, 4], [1, 2, 3, 4])
        #expect(identical.p == 1 && identical.u == 8)
        let allTied = try S.mannWhitney([7, 7, 7], [7, 7, 7, 7])
        #expect(allTied.p == 1)
        let single = try S.mannWhitney([1], [2])
        #expect(single.p == 1) // 2 * (1/2) capped
        let separated = try S.mannWhitney([1, 2, 3], [4, 5, 6, 7, 8])
        #expect(abs(separated.p - 2.0 / 56) < 1e-15)
        let swapped = try S.mannWhitney([4, 5, 6, 7, 8], [1, 2, 3])
        #expect(abs(swapped.p - separated.p) < 1e-15)
        #expect(throws: StatisticsError.self) { try S.mannWhitney([], [1]) }
        #expect(throws: StatisticsError.self) { try S.mannWhitney([1, .nan], [1]) }
    }

    @Test
    func mannWhitneyIsExactForThirtyByThirty() throws {
        let a = (0..<30).map { Double(($0 * 7919) % 101) }
        let b = (0..<30).map { Double(($0 * 104_729) % 103) + 3 }
        let result = try S.mannWhitney(a, b)
        #expect(result.p > 0 && result.p <= 1)
        let distinct = try S.mannWhitney((0..<30).map(Double.init), (30..<60).map(Double.init))
        #expect(abs(distinct.p - 2 / 118_264_581_564_861_424.0) / distinct.p < 1e-12) // 2 / C(60, 30)
    }

    // MARK: Hodges-Lehmann

    @Test
    func hodgesLehmannMatchesIndependentReference() throws {
        // Reference: numpy median of exp-differences and brute-force enumeration of all C(15, 8) label assignments for the critical value.
        let a = [3.1, 4.7, 5.2, 6.9, 8.0, 9.4, 10.1, 12.5]
        let b = [2.0, 2.9, 3.5, 4.1, 4.4, 5.0, 6.2]
        let hl = try S.hodgesLehmannSpeed(baseline: a, series: b)
        #expect(abs(hl.speed - 1.8488325554743508) < 1e-12)
        #expect(near(hl.ciLow, 1.0689655172413794, 1e-12))
        #expect(near(hl.ciHigh, 2.8857142857142857, 1e-12))
        #expect(near(hl.coverage, 0.9599067599067599, 1e-12))
        #expect(abs(hl.changePercent - (1 / hl.speed - 1) * 100) < 1e-12)
    }

    @Test
    func hodgesLehmannCoverageMatchesBruteForce() throws {
        for (m, n) in [(4, 4), (3, 6), (5, 5), (6, 4)] {
            let subsets = Self.combinations(m + n, m)
            func u(_ s: [Int]) -> Int { s.reduce(0) { acc, i in acc + (0..<(m + n)).filter { !s.contains($0) && $0 < i }.count } }
            let us = subsets.map(u)
            let cdf = S.mannWhitneyNullCDF(m: m, n: n)
            for k in 0...(m * n) {
                let brute = Double(us.filter { $0 <= k }.count) / Double(subsets.count)
                #expect(abs(cdf[k] - brute) < 1e-12)
            }
            let a = (0..<m).map { exp(Double($0) * 0.37 + 0.1) }
            let b = (0..<n).map { exp(Double($0) * 0.41) }
            let hl = try S.hodgesLehmannSpeed(baseline: a, series: b)
            let criticalCandidates = (1...(m * n)).filter { cdf[$0 - 1] <= 0.025 }
            if let c = criticalCandidates.max() {
                let brute = 1 - 2 * Double(us.filter { $0 <= c - 1 }.count) / Double(subsets.count)
                #expect(near(hl.coverage, brute, 1e-12))
            } else {
                #expect(hl.coverage == nil && hl.ciLow == nil && hl.ciHigh == nil)
            }
        }
    }

    @Test
    func hodgesLehmannEdgeCases() throws {
        // Identical samples: no shift, CI around 1.
        let same = try S.hodgesLehmannSpeed(baseline: [1, 2, 3, 4, 5, 6], series: [1, 2, 3, 4, 5, 6])
        #expect(abs(same.speed - 1) < 1e-12 && abs(same.changePercent) < 1e-9)
        let low = try #require(same.ciLow)
        let high = try #require(same.ciHigh)
        #expect(low <= 1 && high >= 1)
        // Constant ratio: speed 2 exactly, degenerate CI.
        let doubled = try S.hodgesLehmannSpeed(baseline: [2, 4, 8, 16, 32, 64], series: [1, 2, 4, 8, 16, 32])
        #expect(abs(doubled.speed - 2) < 1e-9)
        // Series twice as slow: speed 0.5, change +100 %.
        let slow = try S.hodgesLehmannSpeed(baseline: [1, 1, 1, 1, 1, 1], series: [2, 2, 2, 2, 2, 2])
        #expect(abs(slow.speed - 0.5) < 1e-12)
        #expect(abs(slow.changePercent - 100) < 1e-9)
        #expect(slow.ciLow.map { abs($0 - 0.5) < 1e-12 } == true)
        // Too few for 95 %: C(7, 3) = 35 < 40.
        let small = try S.hodgesLehmannSpeed(baseline: [1, 2, 3], series: [4, 5, 6, 7])
        #expect(small.ciLow == nil && small.coverage == nil)
        // m != n and k = 1.
        let single = try S.hodgesLehmannSpeed(baseline: [4], series: [2])
        #expect(single.speed == 2 && single.ciLow == nil)
        #expect(throws: StatisticsError.self) { try S.hodgesLehmannSpeed(baseline: [1, 0], series: [1]) }
        #expect(throws: StatisticsError.self) { try S.hodgesLehmannSpeed(baseline: [1], series: [-1]) }
        #expect(throws: StatisticsError.self) { try S.hodgesLehmannSpeed(baseline: [1], series: [.nan]) }
    }

    // MARK: Benjamini-Hochberg

    @Test
    func benjaminiHochbergMatchesReference() {
        // scipy.stats.false_discovery_control([0.01, 0.04, 0.03, 0.005, 0.5, 0.2]) = [0.03, 0.06, 0.06, 0.03, 0.5, 0.24]
        let q = S.benjaminiHochberg([0.01, 0.04, 0.03, 0.005, 0.5, 0.2])
        let expected = [0.03, 0.06, 0.06, 0.03, 0.5, 0.24]
        for (got, want) in zip(q, expected) { #expect(near(got, want, 1e-12)) }
    }

    @Test
    func benjaminiHochbergTiesNaNsAndCaps() throws {
        let q = S.benjaminiHochberg([0.02, nil, 0.02, .nan, 0.9])
        #expect(q[1] == nil && q[3] == nil)
        // m = 3: sorted 0.02, 0.02, 0.9 -> raw 0.06, 0.03, 0.9 -> monotone 0.03, 0.03, 0.9.
        #expect(near(q[0], 0.03, 1e-15))
        #expect(near(q[2], 0.03, 1e-15))
        #expect(q[4] == 0.9)
        #expect(S.benjaminiHochberg([0.9, 0.95]) == [0.95, 0.95])
        #expect(S.benjaminiHochberg([]).isEmpty)
        #expect(S.benjaminiHochberg([nil, .nan]) == [nil, nil])
        #expect(S.benjaminiHochberg([0.4]) == [0.4])
    }

    // MARK: Kendall

    @Test
    func kendallNoTiesMatchesBruteForceAndReference() throws {
        for v in [[3.0, 1, 2], [1.0, 2, 3, 4], [4.0, 2, 5, 1, 3], [6.0, 1, 5, 2, 4, 3], [1.0, 3, 2, 5, 4, 7, 6]] {
            let r = try S.kendallTrend(v)
            #expect(abs(r.p - Self.bruteForceKendallP(v)) < 1e-12)
            #expect(!r.isApproximate)
        }
        // scipy.stats.kendalltau(range(10), v, method="exact")
        let r = try S.kendallTrend([5, 3, 8, 1, 9, 2, 7, 4, 6, 10])
        #expect(near(r.tau, 0.24444444444444444, 1e-12))
        #expect(abs(r.p - 0.38071979717813054) < 1e-12)
        let r12 = try S.kendallTrend([1.2, 1.9, 1.4, 2.8, 3.3, 2.2, 4.0, 4.1, 5.5, 5.0, 6.1, 7.7])
        #expect(near(r12.tau, 0.8787878787878787, 1e-12))
        #expect(abs(r12.p - 5.319397680508792e-06) < 1e-15)
    }

    @Test
    func kendallWithTiesIsExactAndMatchesBruteForce() throws {
        for v in [[1.0, 1, 2], [2.0, 1, 2, 3], [1.0, 2, 2, 3, 3], [3.0, 3, 1, 2, 1, 2], [1.0, 1, 1, 2, 2, 3, 4]] {
            let r = try S.kendallTrend(v)
            #expect(abs(r.p - Self.bruteForceKendallP(v)) < 1e-12)
            #expect(!r.isApproximate)
            let n0 = Double(v.count * (v.count - 1) / 2)
            let tied = Double(Dictionary(grouping: v, by: { $0 }).values.reduce(0) { $0 + $1.count * ($1.count - 1) / 2 })
            #expect(abs(try #require(r.tau) - Double(Self.kendallS(v)) / (n0 * (n0 - tied)).squareRoot()) < 1e-12)
        }
        // Larger tied sample falls back to the normal approximation and says so.
        let big = try S.kendallTrend([1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6])
        #expect(big.isApproximate && big.p < 0.01)
    }

    @Test
    func kendallEdgeCases() throws {
        let constant = try S.kendallTrend([4, 4, 4, 4])
        #expect(constant.tau == nil && constant.p == 1)
        let monotone = try S.kendallTrend([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
        #expect(monotone.tau == 1)
        #expect(abs(monotone.p - 2.0 / 3_628_800) < 1e-18)
        let descending = try S.kendallTrend([3, 2, 1])
        #expect(descending.tau == -1 && abs(descending.p - 1.0 / 3) < 1e-15) // 2 * P(S <= -3) = 2/6
        let pair = try S.kendallTrend([1, 2])
        #expect(pair.tau == 1 && pair.p == 1)
        #expect(throws: StatisticsError.self) { try S.kendallTrend([1]) }
        #expect(throws: StatisticsError.self) { try S.kendallTrend([1, .nan]) }
        let twenty = try S.kendallTrend((0..<20).map { Double(($0 * 7) % 20) })
        #expect(twenty.p >= 0 && twenty.p <= 1)
    }

    // MARK: Verdict

    @Test
    func verdictBoundaries() {
        let lowerEdge = 1 / 1.05
        func v(_ low: Double?, _ high: Double?, _ q: Double?, k1: Int = 10, k2: Int = 10) -> S.Verdict {
            S.classify(ciLow: low, ciHigh: high, q: q, baselineReplicates: k1, seriesReplicates: k2)
        }
        #expect(v(1.06, 1.2, 0.01) == .faster)
        #expect(v(1.05, 1.2, 0.01) == .inconclusive) // low must be strictly above 1.05
        #expect(v(1.06, 1.2, 0.05) == .inconclusive) // q must be strictly below 0.05
        #expect(v(1.06, 1.2, nil) == .inconclusive)
        #expect(v(1.06, 1.2, .nan) == .inconclusive)
        #expect(v(0.7, 0.9, 0.01) == .slower)
        #expect(v(0.7, lowerEdge, 0.01) == .inconclusive) // high must be strictly below 1/1.05
        #expect(v(0.7, lowerEdge.nextDown, 0.01) == .slower)
        #expect(v(lowerEdge, 1.05, 0.9) == .equivalent)
        #expect(v(lowerEdge, 1.05, 0.001) == .equivalent) // inside the zone beats significance
        #expect(v(lowerEdge.nextDown, 1.0, 0.9) == .inconclusive)
        #expect(v(1.0, 1.05.nextUp, 0.9) == .inconclusive)
        #expect(v(0.9, 1.2, 0.9) == .inconclusive)
        #expect(v(nil, nil, 0.001) == .inconclusive)
        #expect(v(1.06, 1.2, 0.01, k1: 1) == .notAvailable(replicates: 1))
        #expect(v(1.06, 1.2, 0.01, k1: 10, k2: 0) == .notAvailable(replicates: 0))
        #expect(v(nil, nil, nil, k1: 1, k2: 1) == .notAvailable(replicates: 1))
        #expect(S.classify(ciLow: 1.01, ciHigh: 1.2, q: 0.01, baselineReplicates: 5, seriesReplicates: 5, delta: 0) == .faster)
    }
}
