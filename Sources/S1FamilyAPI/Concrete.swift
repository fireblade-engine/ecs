// swiftlint:disable all
// Spike S1 gap attribution: per-arity overload without packs on the same World, storage and membership path.

extension World {
    @inlinable
    public func forEach<R: S1Component, W: S1Component>(
        reading _: R.Type, writing _: W.Type, _ body: (R, inout W) -> Void
    ) {
        let rs = storage(R.self)
        let ws = storage(W.self)
        let driver: AnyComponentStorage = rs.count <= ws.count ? rs : ws
        let rb = rs.mutableBase()
        let wb = ws.mutableBase()
        for index in 0 ..< driver.count {
            let id = driver.ids[index]
            let ri = rs.denseIndex(of: id)
            let wi = ws.denseIndex(of: id)
            guard ri >= 0, wi >= 0 else { continue }
            body(rb[ri], &wb[wi])
        }
    }
}
