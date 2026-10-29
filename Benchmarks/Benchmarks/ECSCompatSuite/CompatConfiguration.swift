// The benchmark configuration shared by every registration, declared once. The result writer records these values and
// hashes them into the configuration hash, so changing a metric or a pass count changes the hash.
import Benchmark

extension CompatSuite {
    /// Metrics enabled for every compat benchmark, in registration order.
    ///
    /// Decision (measured on macOS with this package setup, Benchmark 1.38.1):
    /// - wallClock, cpuTotal, throughput and peakMemoryResident work and are enabled.
    /// - mallocCountTotal is enabled: the plugin links the malloc interposer on macOS and reports plausible counts.
    /// - Everything else of `BenchmarkMetric.default` is left out on purpose: `instructions` needs Linux perf, the
    ///   interposer-only free/bytes/leak counters add overhead and noise without a workload question they answer, and
    ///   `memoryLeaked` is not stable across a persistent world.
    static let metrics: [BenchmarkMetric] = [
        .wallClock,
        .cpuTotal,
        .throughput,
        .peakMemoryResident,
        .mallocCountTotal
    ]

    /// Configuration of workloads that prepare fresh state per invocation and run exactly one pass.
    static func freshStateConfiguration() -> Benchmark.Configuration {
        .init(metrics: metrics, scalingFactor: .one)
    }

    /// Configuration of workloads that keep one world across passes. Pass counts are pinned, not time-bounded.
    static func persistentConfiguration() -> Benchmark.Configuration {
        .init(
            metrics: metrics,
            warmupIterations: CompatWorkload.persistentWarmupIterations,
            scalingFactor: .one,
            maxDuration: CompatWorkload.persistentMaxDuration,
            maxIterations: CompatWorkload.persistentIterations
        )
    }
}
