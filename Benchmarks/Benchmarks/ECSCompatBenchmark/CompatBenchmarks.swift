import Benchmark
import FirebladeECS

let benchmarks: @Sendable () -> Void = {
    let scales = [0, 1, 16, 1024]

    for scale in scales {
        for backend in CompatSuite.backends {
            // Nexus construction is before timing and teardown after stop; each invocation creates exactly `scale` entities.
            Benchmark("\(CompatWorkload.createEmptyIdentity) [\(backend)] / \(scale)", configuration: .init(scalingFactor: .one)) { benchmark in
                let nexus = CompatSuite.makeNexus(backend: backend)
                benchmark.startMeasurement()
                for _ in benchmark.scaledIterations {
                    CompatWorkload.createEmptyEntities(in: nexus, count: scale)
                }
                benchmark.stopMeasurement()
                blackHole(nexus.numEntities)
            }
        }
    }
}
