import Benchmark
import ECSCompatSuite

let benchmarks: @Sendable () -> Void = {
    registerCompatBenchmarks()
}
