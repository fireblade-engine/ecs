// Exact, non-parametric, deterministic statistics for the report (PLAN "Statistical design v3"). Pure functions on
// Double inputs: no resampling, no randomness. The replicate (one independent process) is the unit of analysis, so the
// inputs are replicate medians. Invalid input (NaN, infinite, non-positive where a log is taken, empty) throws.
import Foundation

enum StatisticsError: Error, Equatable {
    case invalidInput(String)
}

enum ReportStatistics {
    /// Two-sided significance level split evenly over the two tails.
    static let alpha = 0.05

    // MARK: Binomial helpers

    /// Cumulative P(Binom(k, 1/2) <= j) for j in 0...k, built by dyadic Pascal addition (exact in Double for k <= 52,
    /// rounding error below 1e-15 relative beyond).
    static func binomialHalfCDF(k: Int) -> [Double] {
        var pmf = [Double](repeating: 0, count: k + 1)
        pmf[0] = 1
        for step in 1...max(k, 1) where k > 0 {
            for i in stride(from: step, through: 1, by: -1) {
                pmf[i] = (pmf[i] + pmf[i - 1]) / 2
            }
            pmf[0] /= 2
        }
        var cdf = pmf
        for i in 1..<cdf.count {
            cdf[i] += cdf[i - 1]
        }
        return cdf
    }

    private static func requireFinite(_ values: [Double], _ what: String) throws {
        guard values.allSatisfy(\.isFinite) else { throw StatisticsError.invalidInput("\(what) contains NaN or infinite values") }
    }

    private static func requirePositive(_ values: [Double], _ what: String) throws {
        guard values.allSatisfy({ $0.isFinite && $0 > 0 }) else {
            throw StatisticsError.invalidInput("\(what) must be finite and positive")
        }
    }

    // MARK: 1. Median CI

    struct MedianCI: Equatable {
        let median: Double
        let low: Double
        let high: Double
        /// Exact coverage 1 - 2 * P(Binom(k, 1/2) <= l - 1).
        let coverage: Double
        /// 1-based order-statistic index l: the interval is [x(l), x(k - l + 1)].
        let rank: Int
    }

    /// Median of `values` (mean of the two middle values for even counts). Throws for empty or non-finite input.
    static func median(_ values: [Double]) throws -> Double {
        guard !values.isEmpty else { throw StatisticsError.invalidInput("median of an empty sample") }
        try requireFinite(values, "sample")
        let sorted = values.sorted()
        return medianOfSorted(sorted)
    }

    private static func medianOfSorted(_ sorted: [Double]) -> Double {
        let k = sorted.count
        return k % 2 == 1 ? sorted[k / 2] : (sorted[k / 2 - 1] + sorted[k / 2]) / 2
    }

    /// Distribution-free confidence interval of the median by order statistics: the largest l with
    /// P(Binom(k, 1/2) <= l - 1) <= alpha/2 gives [x(l), x(k - l + 1)] with exact coverage 1 - 2 P(Binom <= l - 1).
    /// Returns nil when no such l >= 1 exists (k < 6 for 95%). The input need not be sorted.
    static func medianConfidenceInterval(_ values: [Double]) throws -> MedianCI? {
        guard !values.isEmpty else { throw StatisticsError.invalidInput("median CI of an empty sample") }
        try requireFinite(values, "sample")
        let sorted = values.sorted()
        let k = sorted.count
        let cdf = binomialHalfCDF(k: k)
        var rank = 0
        for l in 1...k where cdf[l - 1] <= alpha / 2 {
            rank = l
        }
        guard rank >= 1 else { return nil }
        return MedianCI(median: medianOfSorted(sorted), low: sorted[rank - 1], high: sorted[k - rank], coverage: 1 - 2 * cdf[rank - 1], rank: rank)
    }

    // MARK: 2. Mann-Whitney U

    struct MannWhitneyResult: Equatable {
        /// U statistic of the first sample: the number of pairs (a, b) with a > b, ties counting 1/2.
        let u: Double
        /// Exact two-sided p-value: min(1, 2 * min(P(W <= w), P(W >= w))).
        let p: Double
    }

    /// Number of ways to pick `m` of the items so that the chosen doubled ranks sum to w, as `counts[w]` (Double,
    /// relative error ~1e-16). Index range 0...sum of the m largest ranks.
    static func rankSumCounts(doubledRanks: [Int], m: Int) -> [Double] {
        let maxSum = doubledRanks.sorted(by: >).prefix(m).reduce(0, +)
        let width = maxSum + 1
        var dp = [Double](repeating: 0, count: (m + 1) * width)
        dp[0] = 1
        var seen = 0
        for rank in doubledRanks {
            seen += 1
            for j in stride(from: min(m, seen), through: 1, by: -1) {
                let source = (j - 1) * width
                let target = j * width
                guard rank < width else { continue }
                for w in stride(from: width - 1, through: rank, by: -1) {
                    dp[target + w] += dp[source + w - rank]
                }
            }
        }
        return Array(dp[(m * width)...])
    }

    /// Doubled midranks (integers) of the pooled sample, in the order of `pooled`. Ties get the average rank, doubled
    /// so that it stays an integer: a tie group at 1-based positions s...e has doubled midrank s + e.
    static func doubledMidranks(_ pooled: [Double]) -> [Int] {
        let order = pooled.indices.sorted { pooled[$0] < pooled[$1] }
        var ranks = [Int](repeating: 0, count: pooled.count)
        var start = 0
        while start < order.count {
            var end = start
            while end + 1 < order.count, pooled[order[end + 1]] == pooled[order[start]] {
                end += 1
            }
            for position in start...end {
                ranks[order[position]] = (start + 1) + (end + 1)
            }
            start = end + 1
        }
        return ranks
    }

    /// Exact two-sided Mann-Whitney U test of `a` against `b`.
    ///
    /// The null distribution of the rank sum W of `a` is the exact permutation distribution over all C(m+n, m)
    /// assignments of the pooled midranks, conditional on the observed tie structure (dynamic programming over doubled
    /// midranks, O(m * n * (m + n)) time). Two-sided p = min(1, 2 * min(P(W <= w), P(W >= w))). Without ties this equals
    /// R's `wilcox.test(a, b, exact = TRUE)` p-value (R doubles the smaller tail and caps at 1); with ties R falls back to
    /// a normal approximation, whereas this is the exact conditional p. If every pooled value is equal, p = 1.
    static func mannWhitney(_ a: [Double], _ b: [Double]) throws -> MannWhitneyResult {
        guard !a.isEmpty, !b.isEmpty else { throw StatisticsError.invalidInput("Mann-Whitney needs two non-empty samples") }
        try requireFinite(a, "first sample")
        try requireFinite(b, "second sample")
        let m = a.count
        let pooled = a + b
        let ranks = doubledMidranks(pooled)
        let observed = ranks.prefix(m).reduce(0, +)
        let counts = rankSumCounts(doubledRanks: ranks, m: m)
        let total = counts.reduce(0, +)
        var lower = 0.0
        var upper = 0.0
        for (w, count) in counts.enumerated() {
            if w <= observed { lower += count }
            if w >= observed { upper += count }
        }
        let p = min(1, 2 * min(lower / total, upper / total))
        let u = Double(observed) / 2 - Double(m * (m + 1)) / 2
        return MannWhitneyResult(u: u, p: p)
    }

    /// Exact null distribution of U (no ties) for sample sizes m, n: `cdf[u] = P(U <= u)` for u in 0...m*n.
    static func mannWhitneyNullCDF(m: Int, n: Int) -> [Double] {
        let counts = rankSumCounts(doubledRanks: (1...(m + n)).map { 2 * $0 }, m: m)
        let total = counts.reduce(0, +)
        let offset = m * (m + 1) // doubled minimum rank sum
        var cdf = [Double](repeating: 0, count: m * n + 1)
        var running = 0.0
        for u in 0...(m * n) {
            running += counts[offset + 2 * u]
            cdf[u] = running / total
        }
        return cdf
    }

    // MARK: 3. Hodges-Lehmann shift on log values

    struct SpeedEstimate: Equatable {
        /// exp(HL estimate of log(a) - log(b)): baseline ÷ series, so > 1 means the series is faster.
        let speed: Double
        let ciLow: Double?
        let ciHigh: Double?
        /// Exact coverage of [ciLow, ciHigh], nil when no 95% interval is attainable.
        let coverage: Double?
        /// (1 / speed - 1) * 100.
        let changePercent: Double
    }

    /// Hodges-Lehmann estimate of the multiplicative shift `a` ÷ `b` (a = baseline, b = series) with the exact
    /// distribution-free CI: with the m*n sorted pairwise log differences d, take the largest c with
    /// P(U <= c - 1) <= alpha/2 under the exact no-ties Mann-Whitney null and report [d(c), d(m*n - c + 1)], coverage
    /// 1 - 2 P(U <= c - 1). The CI is nil when even c = 1 exceeds alpha/2 (C(m+n, m) < 40).
    static func hodgesLehmannSpeed(baseline a: [Double], series b: [Double]) throws -> SpeedEstimate {
        guard !a.isEmpty, !b.isEmpty else { throw StatisticsError.invalidInput("Hodges-Lehmann needs two non-empty samples") }
        try requirePositive(a, "baseline sample")
        try requirePositive(b, "series sample")
        let logA = a.map { log($0) }
        let logB = b.map { log($0) }
        var differences: [Double] = []
        differences.reserveCapacity(a.count * b.count)
        for x in logA {
            for y in logB {
                differences.append(x - y)
            }
        }
        differences.sort()
        let count = differences.count
        let speed = exp(medianOfSorted(differences))
        let change = (1 / speed - 1) * 100
        let cdf = mannWhitneyNullCDF(m: a.count, n: b.count)
        var c = 0
        for candidate in 1...count where cdf[candidate - 1] <= alpha / 2 {
            c = candidate
        }
        guard c >= 1 else {
            return SpeedEstimate(speed: speed, ciLow: nil, ciHigh: nil, coverage: nil, changePercent: change)
        }
        return SpeedEstimate(
            speed: speed,
            ciLow: exp(differences[c - 1]),
            ciHigh: exp(differences[count - c]),
            coverage: 1 - 2 * cdf[c - 1],
            changePercent: change
        )
    }

    // MARK: 4. Benjamini-Hochberg

    /// Benjamini-Hochberg adjusted q-values (monotone step-up, capped at 1) in the original order. Entries that are nil
    /// or NaN are excluded from the number of tests m and come back as nil.
    static func benjaminiHochberg(_ pValues: [Double?]) -> [Double?] {
        let valid = pValues.indices.filter { index in pValues[index].map { !$0.isNaN } ?? false }
        let m = valid.count
        let order = valid.sorted { pValues[$0]! < pValues[$1]! }
        var result = [Double?](repeating: nil, count: pValues.count)
        var running = 1.0
        for (offset, index) in order.enumerated().reversed() {
            let adjusted = pValues[index]! * Double(m) / Double(offset + 1)
            running = min(running, adjusted)
            result[index] = min(1, running)
        }
        return result
    }

    // MARK: 5. Kendall's tau

    struct KendallResult: Equatable {
        /// tau-b of (index, value); nil when all values are equal (undefined).
        let tau: Double?
        /// Two-sided p = min(1, 2 * min(P(S <= s), P(S >= s))) under the permutation null; 1 when tau is undefined.
        let p: Double
        /// True when the p-value comes from the normal approximation (ties with n > 10) instead of the exact distribution.
        let isApproximate: Bool
    }

    /// Kendall's tau-b between the position 0..<n (the round index) and `values`, with the p-value of the test for a trend.
    ///
    /// S = concordant - discordant pairs. Under the null all n! orderings of the values are equally likely.
    /// - No ties: exact, from the distribution of the inversion count (S = n(n-1)/2 - 2 * inversions) by dynamic programming.
    /// - Ties, n <= 10: exact, by enumerating the distinct orderings of the observed multiset (conditional on the ties).
    /// - Ties, n > 10: normal approximation of S with the tie-corrected variance
    ///   (n(n-1)(2n+5) - sum t(t-1)(2t+5)) / 18 and a continuity correction of 1; `isApproximate` is set.
    static func kendallTrend(_ values: [Double]) throws -> KendallResult {
        try requireFinite(values, "sample")
        let n = values.count
        guard n >= 2 else { throw StatisticsError.invalidInput("Kendall's tau needs at least 2 values") }
        var s = 0
        for i in 0..<n {
            for j in (i + 1)..<n {
                if values[j] > values[i] { s += 1 } else if values[j] < values[i] { s -= 1 }
            }
        }
        let n0 = Double(n * (n - 1) / 2)
        let groups = Dictionary(grouping: values, by: { $0 }).values.map(\.count).sorted()
        let tiedPairs = Double(groups.reduce(0) { $0 + $1 * ($1 - 1) / 2 })
        guard n0 - tiedPairs > 0 else { return KendallResult(tau: nil, p: 1, isApproximate: false) }
        let tau = Double(s) / (n0 * (n0 - tiedPairs)).squareRoot()

        if groups.allSatisfy({ $0 == 1 }) {
            let distribution = kendallNoTiesDistribution(n: n)
            return KendallResult(tau: tau, p: twoSided(distribution: distribution, observed: s), isApproximate: false)
        }
        if n <= 10 {
            let distribution = kendallTiedDistribution(groupSizes: groups)
            return KendallResult(tau: tau, p: twoSided(distribution: distribution, observed: s), isApproximate: false)
        }
        let nD = Double(n)
        let tieTerm = groups.reduce(0.0) { $0 + Double($1) * Double($1 - 1) * Double(2 * $1 + 5) }
        let variance = (nD * (nD - 1) * (2 * nD + 5) - tieTerm) / 18
        let z = max(0, Double(abs(s)) - 1) / variance.squareRoot()
        return KendallResult(tau: tau, p: min(1, erfc(z / 2.0.squareRoot())), isApproximate: true)
    }

    /// Probability of each S value: keys are S, values are probabilities.
    private static func twoSided(distribution: [Int: Double], observed s: Int) -> Double {
        var lower = 0.0
        var upper = 0.0
        for (value, probability) in distribution {
            if value <= s { lower += probability }
            if value >= s { upper += probability }
        }
        return min(1, 2 * min(lower, upper))
    }

    /// Exact null distribution of S for n distinct values: S = n(n-1)/2 - 2 * inversions; the inversion count is the
    /// sum of independent uniform {0..i-1} contributions.
    static func kendallNoTiesDistribution(n: Int) -> [Int: Double] {
        var inversions: [Double] = [1]
        for i in 2...max(n, 2) where i <= n {
            var next = [Double](repeating: 0, count: inversions.count + i - 1)
            for (count, probability) in inversions.enumerated() {
                for extra in 0..<i {
                    next[count + extra] += probability / Double(i)
                }
            }
            inversions = next
        }
        let n0 = n * (n - 1) / 2
        var result: [Int: Double] = [:]
        for (count, probability) in inversions.enumerated() {
            result[n0 - 2 * count] = probability
        }
        return result
    }

    /// Exact null distribution of S for a multiset with the given tie group sizes (all distinct orderings equally likely),
    /// by enumerating distinct orderings; feasible for n <= 10.
    static func kendallTiedDistribution(groupSizes: [Int]) -> [Int: Double] {
        var remaining = groupSizes
        let n = groupSizes.reduce(0, +)
        var counts: [Int: Double] = [:]
        var total = 0.0
        // Placed per group (group index = value order); S grows by (#earlier smaller) - (#earlier larger) for each placement.
        func place(_ depth: Int, _ s: Int) {
            if depth == n {
                counts[s, default: 0] += 1
                total += 1
                return
            }
            for g in remaining.indices where remaining[g] > 0 {
                let placed = (0..<groupSizes.count).map { groupSizes[$0] - remaining[$0] }
                let smaller = placed[..<g].reduce(0, +)
                let larger = placed[(g + 1)...].reduce(0, +)
                remaining[g] -= 1
                place(depth + 1, s + smaller - larger)
                remaining[g] += 1
            }
        }
        place(0, 0)
        return counts.mapValues { $0 / total }
    }

    // MARK: 6. Verdict

    enum Verdict: Equatable {
        case faster
        case slower
        case equivalent
        case inconclusive
        /// Either side has fewer than 2 replicates; the payload is the smaller replicate count.
        case notAvailable(replicates: Int)
    }

    static let defaultDelta = 0.05
    static let significanceLevel = 0.05

    /// Classifies a comparison. Evaluation order: n/a, then equivalent, faster, slower, inconclusive. The classes are
    /// mutually exclusive by construction (faster needs low > 1 + delta, equivalent needs high <= 1 + delta; slower needs
    /// high < 1 / (1 + delta), equivalent needs low >= 1 / (1 + delta)), so the order never changes a result.
    /// `ciLow` / `ciHigh` are the speed CI (baseline ÷ series); nil CI or nil / NaN q gives `inconclusive`.
    static func classify(ciLow: Double?, ciHigh: Double?, q: Double?, baselineReplicates: Int, seriesReplicates: Int, delta: Double = defaultDelta) -> Verdict {
        let fewest = min(baselineReplicates, seriesReplicates)
        guard fewest >= 2 else { return .notAvailable(replicates: fewest) }
        guard let low = ciLow, let high = ciHigh, low.isFinite, high.isFinite else { return .inconclusive }
        let upperEdge = 1 + delta
        let lowerEdge = 1 / (1 + delta)
        if lowerEdge <= low, high <= upperEdge { return .equivalent }
        if let q, !q.isNaN, q < significanceLevel {
            if low > upperEdge { return .faster }
            if high < lowerEdge { return .slower }
        }
        return .inconclusive
    }
}
