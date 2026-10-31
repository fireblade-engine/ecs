import FirebladeECS

struct ReferenceMovementSystem {
    private let family: Family<ReferencePositionComponent, ReferenceVelocityComponent>

    init(nexus: Nexus) {
        family = nexus.family(
            requiresAll: ReferencePositionComponent.self,
            ReferenceVelocityComponent.self
        )
    }

    func update(deltaTime: Float) {
        family.forEach(
            reading: ReferenceVelocityComponent.self,
            writing: ReferencePositionComponent.self
        ) { velocity, position in
            Self.update(position: &position, velocity: velocity, deltaTime: deltaTime)
        }
    }

    static func update(
        position: inout ReferencePositionComponent,
        velocity: ReferenceVelocityComponent,
        deltaTime: Float
    ) {
        position.x += velocity.x * deltaTime
        position.y += velocity.y * deltaTime
    }
}
