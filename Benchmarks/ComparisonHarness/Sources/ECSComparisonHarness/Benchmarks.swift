import Benchmark

let benchmarks: @Sendable () -> Void = {
    commonBenchmarks()
#if FIREBLADE_HAS_MODERN_SUITE
    comparisonBenchmarks()
#endif
}
