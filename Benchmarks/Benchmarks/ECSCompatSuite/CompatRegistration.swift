import Benchmark
import FirebladeECS

/// Registers every workload of the compatibility suite with the Benchmark plugin. Called by the thin
/// `ECSCompatBenchmark` executable, which only owns the plugin's `benchmarks` entry point.
public func registerCompatBenchmarks() {
    for workload in CompatWorkload.allCases {
        for scale in workload.registeredScales {
            for backend in CompatSuite.backends {
                let name = workload.benchmarkName(backend: backend, scale: scale)
                if workload.persistsState {
                    // One world per benchmark, built in setup and shared by warmup and every sample: no reset between passes.
                    nonisolated(unsafe) var state: CompatState?
                    // Pass counts are pinned, not time-bounded: the world carries state across passes (Render's draw count
                    // drifts), so every revision must run the same passes. `maxDuration` is only a generous safety net.
                    Benchmark(
                        name,
                        configuration: .init(
                            warmupIterations: CompatWorkload.persistentWarmupIterations,
                            scalingFactor: .one,
                            maxDuration: CompatWorkload.persistentMaxDuration,
                            maxIterations: CompatWorkload.persistentIterations
                        ),
                        closure: { benchmark in
                            guard let state else {
                                benchmark.error("setup did not create the world")
                                return
                            }
                            benchmark.startMeasurement()
                            let outcome = workload.run(state, count: scale)
                            benchmark.stopMeasurement()
                            blackHole(outcome)
                            blackHole(state.nexus.numEntities)
                        },
                        setup: { state = workload.prepare(backend: backend, count: scale) },
                        teardown: { state = nil }
                    )
                } else {
                    // Every invocation prepares fresh state before timing and runs exactly one pass (`.one`), so warmup and
                    // repeated invocations do the same work. Nexus teardown happens after stop.
                    Benchmark(name, configuration: .init(scalingFactor: .one)) { benchmark in
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
}
