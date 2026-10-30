// The benchmark configuration shared by every registration, declared once. The result writer records these values and
// hashes them into the configuration hash, so changing a metric or a sampling parameter changes the hash.
import Benchmark

extension CompatSuite {
    /// Metrics enabled for every compat benchmark, in registration order.
    ///
    /// Decision (measured on macOS with this package setup, Benchmark 1.38.1):
    /// - wallClock, cpuTotal, throughput and peakMemoryResident work and are enabled.
    /// - mallocCountTotal is enabled: the plugin links the malloc interposer on macOS and reports plausible counts.
    /// - Everything else of `BenchmarkMetric.default` is left out on purpose: `instructions` needs Linux perf, the
    ///   interposer-only free/bytes/leak counters add overhead and noise without a workload question they answer, and
    ///   `memoryLeaked` is not stable across a persistent state.
    static let metrics: [BenchmarkMetric] = [
        .wallClock,
        .cpuTotal,
        .throughput,
        .peakMemoryResident,
        .mallocCountTotal
    ]

    /// Sampling shared by every workload, as upstream's Google Benchmark defaults: time-based (about 0.5 s), no warmup, and an
    /// iteration cap high enough never to bind first. The package budget is wall time since the benchmark started, including setup.
    static let maxDuration: Duration = .milliseconds(500)
    static let warmupIterations = 0
    static let maxIterations = 1_000_000_000

    static func configuration() -> Benchmark.Configuration {
        .init(
            metrics: metrics,
            warmupIterations: warmupIterations,
            scalingFactor: .one,
            maxDuration: maxDuration,
            maxIterations: maxIterations
        )
    }
}
