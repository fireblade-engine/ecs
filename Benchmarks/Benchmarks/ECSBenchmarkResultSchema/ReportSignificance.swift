// Welch's two-sample t-test for the report's `sig.` column (PLAN "Report v2 design"). Pure arithmetic on summary statistics:
// no sampling, no randomness, deterministic.
import Foundation

struct WelchResult: Equatable {
    let t: Double
    /// Welch-Satterthwaite degrees of freedom.
    let degreesOfFreedom: Double
    /// Two-sided p-value.
    let p: Double

    static let alpha = 0.05

    var isSignificant: Bool {
        p < Self.alpha
    }
}

enum Welch {
    /// Two-sided Welch t-test on mean, standard deviation and sample count of two groups.
    ///
    /// `standardDeviation` is the *population* deviation as the HdrHistogram reports it; the test needs the sample variance,
    /// so it is scaled by n / (n - 1). Returns nil when either group has fewer than two samples (the test is undefined).
    /// With zero variance on both sides the means decide: equal means give p = 1, different means p = 0.
    static func test(mean1: Double, standardDeviation1: Double, count1: Int, mean2: Double, standardDeviation2: Double, count2: Int) -> WelchResult? {
        guard count1 >= 2, count2 >= 2 else { return nil }
        let n1 = Double(count1)
        let n2 = Double(count2)
        let v1 = standardDeviation1 * standardDeviation1 * n1 / (n1 - 1) / n1
        let v2 = standardDeviation2 * standardDeviation2 * n2 / (n2 - 1) / n2
        let squaredError = v1 + v2
        let difference = mean1 - mean2
        guard squaredError > 0 else {
            return WelchResult(t: difference == 0 ? 0 : (difference > 0 ? .infinity : -.infinity), degreesOfFreedom: n1 + n2 - 2, p: difference == 0 ? 1 : 0)
        }
        let t = difference / squaredError.squareRoot()
        let degrees = squaredError * squaredError / (v1 * v1 / (n1 - 1) + v2 * v2 / (n2 - 1))
        return WelchResult(t: t, degreesOfFreedom: degrees, p: twoSidedP(t: t, degreesOfFreedom: degrees))
    }

    /// P(|T| >= |t|) for Student's t with `degreesOfFreedom`: the regularized incomplete beta I_x(df / 2, 1 / 2), x = df / (df + t^2).
    static func twoSidedP(t: Double, degreesOfFreedom: Double) -> Double {
        guard t.isFinite else { return 0 }
        let x = degreesOfFreedom / (degreesOfFreedom + t * t)
        return min(1, max(0, regularizedIncompleteBeta(x, a: degreesOfFreedom / 2, b: 0.5)))
    }

    /// I_x(a, b) by the continued fraction of Numerical Recipes (modified Lentz), using the symmetry relation for fast convergence.
    static func regularizedIncompleteBeta(_ x: Double, a: Double, b: Double) -> Double {
        guard x > 0 else { return 0 }
        guard x < 1 else { return 1 }
        let logFront = lgamma(a + b) - lgamma(a) - lgamma(b) + a * log(x) + b * log(1 - x)
        let front = exp(logFront)
        if x < (a + 1) / (a + b + 2) {
            return front * continuedFraction(x, a: a, b: b) / a
        }
        return 1 - front * continuedFraction(1 - x, a: b, b: a) / b
    }

    private static func continuedFraction(_ x: Double, a: Double, b: Double) -> Double {
        let tiny = 1e-300
        let qab = a + b
        let qap = a + 1
        let qam = a - 1
        var c = 1.0
        var d = 1 - qab * x / qap
        if abs(d) < tiny { d = tiny }
        d = 1 / d
        var h = d
        for m in 1 ... 500 {
            let m = Double(m)
            let m2 = 2 * m
            var aa = m * (b - m) * x / ((qam + m2) * (a + m2))
            d = 1 + aa * d
            if abs(d) < tiny { d = tiny }
            c = 1 + aa / c
            if abs(c) < tiny { c = tiny }
            d = 1 / d
            h *= d * c
            aa = -(a + m) * (qab + m) * x / ((a + m2) * (qap + m2))
            d = 1 + aa * d
            if abs(d) < tiny { d = tiny }
            c = 1 + aa / c
            if abs(c) < tiny { c = tiny }
            d = 1 / d
            let delta = d * c
            h *= delta
            if abs(delta - 1) < 1e-15 { break }
        }
        return h
    }
}
