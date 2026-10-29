import FirebladeECS

struct ReferencePositionComponent: Component, Sendable {
    var x: Float
    var y: Float

    init(x: Float = 0, y: Float = 0) {
        self.x = x
        self.y = y
    }
}
