import FirebladeECS

#if FIREBLADE_REFERENCE_COMPONENTS
final class HarnessPosition: Component, @unchecked Sendable {
    var value: Int

    init(value: Int) {
        self.value = value
    }
}
#else
struct HarnessPosition: Component, Sendable {
    var value: Int

    init(value: Int) {
        self.value = value
    }
}
#endif
