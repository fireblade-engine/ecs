#!/usr/bin/env bash
#
# Generates the per-arity read/write overloads of the family and entity API:
#   Sources/FirebladeECS/Generated/Family+ReadWrite.generated.swift   Family.forEach(reading:writing:)
#   Sources/FirebladeECS/Generated/Entity+Components.generated.swift  Entity.components(_:writing:)
#
# Usage: Scripts/generate-read-write-api.sh [family|entity]   (from anywhere; no argument writes both files, review with `git diff`)
#
# Why bash: the repository has no Swift scripting target and the scripts of the other Fireblade repositories are bash.
# The output is committed, so building needs no generator run.
# Why generated overloads at all: a parameter pack loop stays unspecialized per member (about 9x slower, see the
# S1 spike), while every arity below specializes into a plain loop over the typed storages.
set -euo pipefail

MAX=4
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$ROOT/Sources/FirebladeECS/Generated"
mkdir -p "$OUT"

# join SEP items...
join() {
    local sep="$1" out="" first=1 item
    shift
    for item in "$@"; do
        if ((first)); then out="$item"; first=0; else out="$out$sep$item"; fi
    done
    printf '%s' "$out"
}

# plural NUMBER -> "1 component type" / "2 component types"
plural() { if (($1 == 1)); then printf '1 component type'; else printf '%d component types' "$1"; fi; }

HEADER="// swiftlint:disable all
// swiftformat:disable all
//
// GENERATED FILE, DO NOT EDIT.
// Regenerate with Scripts/generate-read-write-api.sh and commit the result.
//"

# Sets generics and closureParams for arity (r, w).
shape() {
    local r=$1 w=$2 i
    generics=()
    closureParams=()
    for ((i = 1; i <= r; i++)); do
        generics+=("R$i: Component")
        closureParams+=("R$i")
    done
    for ((i = 1; i <= w; i++)); do
        generics+=("W$i: Component")
        closureParams+=("inout W$i")
    done
}

family() {
    echo "$HEADER"
    echo
    echo "extension Family {"
    local r w i first=1
    for ((r = 0; r <= MAX; r++)); do
        for ((w = 0; w <= MAX; w++)); do
            ((r + w == 0)) && continue
            shape $r $w
            local params=()
            for ((i = 1; i <= r; i++)); do
                if ((i == 1)); then params+=("reading rType$i: R$i.Type"); else params+=("_ rType$i: R$i.Type"); fi
            done
            for ((i = 1; i <= w; i++)); do
                if ((i == 1)); then params+=("writing wType$i: W$i.Type"); else params+=("_ wType$i: W$i.Type"); fi
            done
            ((first)) || echo
            if ((r == 1 && w == 1)); then
                cat <<'DOC'
    /// Iterates the members of this family, reading some of their components and changing others in place.
    ///
    /// `body` receives the read components first (as copies), then the written ones as `inout`. The writes land
    /// in the component storage directly. Overloads exist for 0 to 4 read and 0 to 4 written component types, and a
    /// parameter pack overload covers more. Every fixed arity overload resolves the typed storages once and then runs
    /// a plain loop over the members: no allocation and no dynamic dispatch per member.
    ///
    /// ```swift
    /// let movers = nexus.family(requiresAll: Position.self, Velocity.self)
    /// movers.forEach(reading: Velocity.self, writing: Position.self) { velocity, position in
    ///     position.x += velocity.dx
    /// }
    /// ```
    ///
    /// Access is declared like the `in` and `inout` term modifiers of flecs queries
    /// ("Access modifiers" in <https://github.com/SanderMertens/flecs/blob/master/docs/Queries.md>), whose `each` callbacks take `const T&`
    /// for reads and `T&` for writes: here the labels `reading:` and `writing:` state it.
    ///
    /// - Every read and written type must be a required component of this family, not an excluded one.
    /// - The written types must be pairwise different and different from the read types, and a pass must not nest
    ///   a write access to a type that an enclosing pass or `modify` writes. Violations trap.
    /// - While `body` runs, structural changes trap: creating or destroying entities, adding or removing
    ///   components, and replacing a component with `set`. Collect them and apply them after the pass, and write
    ///   changed values through the `inout` parameters. Reading a written type through the nexus
    ///   (for example `entity.get(_:)`) traps, too.
    /// - Members are visited once each. The sparse-set storage visits them in the order of the family's member list, the
    ///   archetype storage table by table and row by row; neither order is a contract, and structural changes reorder them.
    /// - If the delegate subscribed to ``NexusEventMask/valueChanges``, one ``ComponentsModified`` event per written type
    ///   is delivered after the pass, not one per member. If `body` throws, the pass ends there, members already visited,
    ///   including the one that threw, stay changed and the events cover them.
    ///
    /// - Parameters:
    ///   - rType1: The component type to read.
    ///   - wType1: The component type to change in place.
    ///   - body: Called once per member.
    /// - Complexity: O(N) where N is the number of members, plus one hash lookup per component type.
DOC
            else
                echo "    /// Iterates the members of this family, reading $(plural $r) and changing $(plural $w) in place."
                echo "    ///"
                echo "    /// Same contract as the overload that reads 1 and writes 1 component type, see there."
            fi
            echo "    @inlinable"
            echo "    public func forEach<$(join ', ' "${generics[@]}")>("
            for p in "${params[@]}"; do echo "        $p,"; done
            echo "        _ body: ($(join ', ' "${closureParams[@]}")) throws -> Void"
            echo "    ) rethrows {"
            for ((i = 1; i <= r; i++)); do echo "        requireRequired(R$i.self)"; done
            for ((i = 1; i <= w; i++)); do echo "        requireRequired(W$i.self)"; done
            echo "        switch nexus.backend {"
            echo "        case let .sparseSet(sparse):"
            echo "            let members = memberIds"
            local conds=("!members.isEmpty")
            for ((i = 1; i <= r; i++)); do conds+=("let rs$i = sparse.existing(R$i.self, at: R$i.componentIndex)"); done
            for ((i = 1; i <= w; i++)); do conds+=("let ws$i = sparse.existing(W$i.self, at: W$i.componentIndex)"); done
            echo "            guard $(join ', ' "${conds[@]}") else { return }"
            echo "            sparse.lockDepth += 1"
            for ((i = 1; i <= w; i++)); do echo "            sparse.beginWrite(W$i.componentIndex)"; done
            for ((i = 1; i <= r; i++)); do echo "            sparse.requireReadable(R$i.componentIndex)"; done
            echo "            var visited = 0"
            echo "            defer {"
            for ((i = 1; i <= w; i++)); do echo "                sparse.endWrite(W$i.componentIndex)"; done
            echo "                sparse.lockDepth -= 1"
            if ((w > 0)); then
                echo "                if visited > 0 {"
                for ((i = 1; i <= w; i++)); do echo "                    nexus.emitModified(W$i.self, count: visited)"; done
                echo "                }"
            fi
            echo "            }"
            for ((i = 1; i <= r; i++)); do echo "            let rBase$i = rs$i.base"; done
            for ((i = 1; i <= w; i++)); do echo "            let wBase$i = ws$i.base"; done
            echo "            let entries = members.storage.dense"
            echo "            try entries.withUnsafeBufferPointer { entries in"
            echo "                for entry in entries {"
            echo "                    let key = entry.key"
            for ((i = 1; i <= r; i++)); do
                echo "                    let rSlot$i = rs$i.slot(of: key)"
                echo "                    precondition(rSlot$i >= 0, \"member without a required component\")"
            done
            for ((i = 1; i <= w; i++)); do
                echo "                    let wSlot$i = ws$i.slot(of: key)"
                echo "                    precondition(wSlot$i >= 0, \"member without a required component\")"
            done
            local callArgs=() rowArgs=()
            for ((i = 1; i <= r; i++)); do callArgs+=("rBase$i[rSlot$i]"); rowArgs+=("rBase$i[row]"); done
            for ((i = 1; i <= w; i++)); do callArgs+=("&wBase$i[wSlot$i]"); rowArgs+=("&wBase$i[row]"); done
            echo "                    visited += 1"
            echo "                    try body($(join ', ' "${callArgs[@]}"))"
            echo "                }"
            echo "            }"
            echo "        case let .archetype(archetype):"
            echo "            guard !memberIds.isEmpty, let filter = nexus.familyFiltersByTraits[traits] else { return }"
            echo "            let query = archetype.matchingTables(filter)"
            # the component indices are resolved once per call, not per table
            for ((i = 1; i <= r; i++)); do echo "            let rIndex$i = R$i.componentIndex"; done
            for ((i = 1; i <= w; i++)); do echo "            let wIndex$i = W$i.componentIndex"; done
            echo "            archetype.lockDepth += 1"
            for ((i = 1; i <= w; i++)); do echo "            archetype.beginWrite(wIndex$i)"; done
            for ((i = 1; i <= r; i++)); do echo "            archetype.requireReadable(rIndex$i)"; done
            if ((w > 0)); then echo "            var visited = 0"; fi
            echo "            defer {"
            for ((i = 1; i <= w; i++)); do echo "                archetype.endWrite(wIndex$i)"; done
            echo "                archetype.lockDepth -= 1"
            if ((w > 0)); then
                echo "                if visited > 0 {"
                for ((i = 1; i <= w; i++)); do echo "                    nexus.emitModified(W$i.self, count: visited)"; done
                echo "                }"
            fi
            echo "            }"
            echo "            for entry in query.tables {"
            echo "                try entry._withUnsafeGuaranteedRef { table in"
            echo "                    let count = table.entities.count"
            echo "                    guard count > 0 else { return }"
            for ((i = 1; i <= r; i++)); do echo "                    let rBase$i = table.base(R$i.self, at: rIndex$i)"; done
            for ((i = 1; i <= w; i++)); do echo "                    let wBase$i = table.base(W$i.self, at: wIndex$i)"; done
            echo "                    for row in 0 ..< count {"
            if ((w > 0)); then echo "                        visited += 1"; fi
            echo "                        try body($(join ', ' "${rowArgs[@]}"))"
            echo "                    }"
            echo "                }"
            echo "            }"
            echo "        }"
            echo "    }"
            first=0
        done
    done
    echo "}"
}

entity() {
    echo "$HEADER"
    echo
    echo "extension Entity {"
    local r w i first=1
    for ((r = 0; r <= MAX; r++)); do
        for ((w = 0; w <= MAX; w++)); do
            ((r + w == 0)) && continue
            shape $r $w
            local params=()
            for ((i = 1; i <= r; i++)); do params+=("_ rType$i: R$i.Type"); done
            for ((i = 1; i <= w; i++)); do
                if ((i == 1)); then params+=("writing wType$i: W$i.Type"); else params+=("_ wType$i: W$i.Type"); fi
            done
            ((first)) || echo
            if ((r == 1 && w == 1)); then
                cat <<'DOC'
    /// Changes components of this entity in place, reading others.
    ///
    /// The read components are passed as copies, the written ones are changed in place in the nexus (see
    /// ``modify(_:_:)``): `body` receives the read components first, then the written ones as `inout`.
    /// Nothing runs if the entity lacks one of the components. A ``ComponentModified`` event is delivered for each
    /// written component. The written types must differ from each other, else the access traps. Overloads exist for
    /// 0 to 4 read and 0 to 4 written types, and a parameter pack overload covers more.
    ///
    /// ```swift
    /// entity.components(Velocity.self, writing: Position.self) { velocity, position in
    ///     position.x += velocity.dx
    /// }
    /// ```
    /// - Returns: `false` if this entity is destroyed or lacks one of the components; `body` is not called then.
DOC
            else
                echo "    /// Changes $(plural $w) of this entity in place, reading $(plural $r)."
                echo "    ///"
                echo "    /// Same contract as the overload that reads 1 and writes 1 component type, see there."
                echo "    /// - Returns: \`false\` if this entity is destroyed or lacks one of the components; \`body\` is not called then."
            fi
            echo "    @discardableResult"
            echo "    public func components<$(join ', ' "${generics[@]}")>("
            for p in "${params[@]}"; do echo "        $p,"; done
            echo "        _ body: ($(join ', ' "${closureParams[@]}")) throws -> Void"
            echo "    ) rethrows -> Bool {"
            local hs=()
            for ((i = 1; i <= r; i++)); do hs+=("has(R$i.self)"); done
            for ((i = 1; i <= w; i++)); do hs+=("has(W$i.self)"); done
            echo "        guard $(join ', ' "${hs[@]}") else {"
            echo "            return reportMissingForAccess()"
            echo "        }"
            for ((i = 1; i <= r; i++)); do echo "        let read$i = get(R$i.self).unsafelyUnwrapped"; done
            local args=() indent="        "
            for ((i = 1; i <= r; i++)); do args+=("read$i"); done
            for ((i = 1; i <= w; i++)); do args+=("&write$i"); done
            for ((i = 1; i <= w; i++)); do
                echo "${indent}try modify(W$i.self) { (write$i: inout W$i) in"
                indent="$indent    "
            done
            echo "${indent}try body($(join ', ' "${args[@]}"))"
            for ((i = w; i >= 1; i--)); do
                indent="${indent:4}"
                echo "${indent}}"
            done
            echo "        return true"
            echo "    }"
            first=0
        done
    done
    echo "}"
}

case "${1:-all}" in
    family) family >"$OUT/Family+ReadWrite.generated.swift" ;;
    entity) entity >"$OUT/Entity+Components.generated.swift" ;;
    all)
        family >"$OUT/Family+ReadWrite.generated.swift"
        entity >"$OUT/Entity+Components.generated.swift"
        ;;
    *) echo "usage: $0 [family|entity]" >&2; exit 2 ;;
esac
echo "generated into $OUT"
