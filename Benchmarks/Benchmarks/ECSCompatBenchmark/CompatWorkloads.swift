// Workloads shared verbatim by every FirebladeECS revision. Stable identities are the contract with the plan's matrix.
import FirebladeECS

enum CompatWorkload {
    /// Matrix identity of the empty-entity creation workload.
    static let createEmptyIdentity = "entity.create.empty"

    /// Creates exactly `count` entities without components in `nexus`.
    static func createEmptyEntities(in nexus: Nexus, count: Int) {
        for _ in 0 ..< count {
            _ = nexus.createEntity()
        }
    }
}
