//
//  Family+ReadWrite.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 25.10.26.
//

// The fixed arity overloads of `forEach(reading:writing:)` (0 to 4 read, 0 to 4 written types) are generated into
// Generated/Family+ReadWrite.generated.swift by Scripts/generate-read-write-api.sh.

extension Family {
    /// Traps if `type` is not a required component of this family.
    ///
    /// The member list is the iteration domain, so only required types are guaranteed to exist for every member.
    @inlinable
    func requireRequired<T: Component>(_: T.Type) {
        precondition(traits.requiresAll.contains(T.identifier), "component type is not required by the family")
    }
}
