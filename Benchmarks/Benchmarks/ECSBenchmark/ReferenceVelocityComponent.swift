import FirebladeECS

struct ReferenceVelocityComponent: Component, Sendable {
    var x: Float
    var y: Float

    init(x: Float = 1, y: Float = 1) {
        self.x = x
        self.y = y
    }
}
