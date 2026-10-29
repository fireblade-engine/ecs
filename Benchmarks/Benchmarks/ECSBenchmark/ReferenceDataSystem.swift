import FirebladeECS

struct ReferenceDataSystem {
    private let family: Family<ReferenceDataComponent>

    init(nexus: Nexus) {
        family = nexus.family(requires: ReferenceDataComponent.self)
    }

    func update(deltaTime: Float) {
        family.forEach(writing: ReferenceDataComponent.self) { data in
            Self.update(data: &data, deltaTime: deltaTime)
        }
    }

    static func update(data: inout ReferenceDataComponent, deltaTime: Float) {
        data.thingy = (data.thingy + 1) % 1_000_000
        data.dingy += 0.0001 * Double(deltaTime)
        data.mingy.toggle()
        data.numgy = data.rng.next()
    }
}
