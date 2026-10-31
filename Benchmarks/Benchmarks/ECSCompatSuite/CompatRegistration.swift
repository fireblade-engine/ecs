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
                    // One state per benchmark, built in setup and shared by every iteration: no reset between passes.
                    // Teardown releases it so state does not accumulate across scales and backends.
                    nonisolated(unsafe) var state: CompatState?
                    Benchmark(
                        name,
                        configuration: CompatSuite.configuration(),
                        closure: { benchmark in
                            guard let state else {
                                benchmark.error("setup did not create the state")
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
                    // Fresh untimed state before every iteration, one pass per iteration (`.one`). Nexus teardown happens
                    // after stop.
                    Benchmark(name, configuration: CompatSuite.configuration()) { benchmark in
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
