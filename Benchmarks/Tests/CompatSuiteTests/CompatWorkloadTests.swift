import FirebladeECS
import Testing
@testable import ECSCompatBenchmark

@Suite
struct CompatWorkloadTests {
    @Test
    func createEmptyCreatesExactlyCountEntitiesOnFreshNexus() {
        for backend in CompatSuite.backends {
            for count in [0, 1, 16, 1024] {
                let nexus = CompatSuite.makeNexus(backend: backend)
                #expect(nexus.numEntities == 0)

                CompatWorkload.createEmptyEntities(in: nexus, count: count)

                #expect(nexus.numEntities == count)
                #expect(nexus.numComponents == 0)
            }
        }
    }

    @Test
    func repeatedInvocationsOnFreshNexusDoNotAccumulate() {
        for backend in CompatSuite.backends {
            for _ in 0 ..< 3 {
                let nexus = CompatSuite.makeNexus(backend: backend)
                CompatWorkload.createEmptyEntities(in: nexus, count: 16)
                #expect(nexus.numEntities == 16)
            }
        }
    }

    @Test
    func adapterReflectsComponentModelOfRevision() {
        #expect((CompatProbeComponent.self is AnyObject.Type) == CompatSuite.usesClassComponents)
        #expect(CompatWorkload.createEmptyIdentity == "entity.create.empty")
        #expect(!CompatSuite.backends.isEmpty)
    }
}
