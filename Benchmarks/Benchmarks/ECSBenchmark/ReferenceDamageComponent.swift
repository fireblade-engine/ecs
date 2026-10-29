import FirebladeECS

struct ReferenceDamageComponent: Component, Sendable {
    var atk: Int32
    var def: Int32

    init(atk: Int32 = 0, def: Int32 = 0) {
        self.atk = atk
        self.def = def
    }
}
