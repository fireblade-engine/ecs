import FirebladeECS

struct ReferenceSpriteComponent: Component, Sendable {
    var character: UInt8

    init(character: UInt8 = 32) {
        self.character = character
    }
}
