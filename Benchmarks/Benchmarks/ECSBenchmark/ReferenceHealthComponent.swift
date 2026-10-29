import FirebladeECS

struct ReferenceHealthComponent: Component, Sendable {
    var hp: Int32
    var maxhp: Int32
    var status: ReferenceStatusEffect

    init(hp: Int32 = 0, maxhp: Int32 = 0, status: ReferenceStatusEffect = .spawn) {
        self.hp = hp
        self.maxhp = maxhp
        self.status = status
    }
}
