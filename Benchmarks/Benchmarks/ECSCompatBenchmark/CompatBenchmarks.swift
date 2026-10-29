import Benchmark
import FirebladeECS

let benchmarks: @Sendable () -> Void = {
    for workload in CompatWorkload.allCases {
        for scale in workload.registeredScales {
            for backend in CompatSuite.backends {
                // Every invocation prepares fresh state before timing and runs exactly one pass (`.one`), so warmup and
                // repeated invocations do the same work. Nexus teardown happens after stop.
                Benchmark(workload.benchmarkName(backend: backend, scale: scale), configuration: .init(scalingFactor: .one)) { benchmark in
                    let state = workload.prepare(backend: backend, count: scale)
                    benchmark.startMeasurement()
                    let outcome = workload.run(state, count: scale)
                    benchmark.stopMeasurement()
                    blackHole(outcome)
                    blackHole(state.nexus.numEntities)
                }
            }
        }
    }
}
