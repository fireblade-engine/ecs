#!/bin/bash
# Emits -O SIL for the S1FamilyAPI sources plus concrete call sites (Spikes/S1/CallSites.swift) and counts
# allocations, witness calls and key-path usage inside every call site and the functions it reaches.
# Spike script: direct swiftc is allowed here, there is no make target for SIL.
#
#   S1_SIL_OUT=<dir>        output directory (default: $TMPDIR/s1-sil)
#   S1_SWIFTC_FLAGS=<flags> extra swiftc flags, e.g. -enforce-exclusivity=unchecked
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT="${S1_SIL_OUT:-${TMPDIR:-/tmp}/s1-sil}"
mkdir -p "$OUT"

# shellcheck disable=SC2086
swiftc -O -wmo -swift-version 6 -parse-as-library -emit-sil ${S1_SWIFTC_FLAGS:-} -module-name S1FamilyAPI \
    "$ROOT"/Sources/S1FamilyAPI/*.swift "$ROOT/Spikes/S1/CallSites.swift" -o "$OUT/S1.sil" 2>"$OUT/swiftc.log"

analyze() {
python3 -I - "$1" <<'PY'
import re
import sys

text = open(sys.argv[1]).read()
funcs = {}
for match in re.finditer(r"^sil [^\n]*?@(\S+?) :[^\n]*\{\n(.*?)^\} // end sil function", text, re.S | re.M):
    funcs[match.group(1)] = match.group(2)

COUNTERS = [
    ("alloc_ref", r"\balloc_ref\b"),
    ("alloc_box", r"\balloc_box\b"),
    ("exist", r"alloc_stack \$any |alloc_stack \$.*Existential|init_existential"),
    ("witness", r"\bwitness_method\b"),
    ("keypath", r"\bkeypath\b|swift_getKeyPath|getKeyPath"),
    ("allocObj", r"swift_allocObject|allocObject"),
    ("dynAccess", r"begin_access \[(modify|read)\] \[dynamic\]"),
    ("retain", r"\b(strong_retain|retain_value|copy_value)\b"),
    ("packLoop", r"\bdynamic_pack_index\b"),
]


def reachable(root):
    seen, queue = set(), [root]
    while queue:
        name = queue.pop()
        # Stay inside the S1 module: stdlib bodies (array growth, existentials in cold paths) are not ours.
        if name in seen or name not in funcs or "createStorage" in name or not name.startswith("$s11S1FamilyAPI"):
            continue
        seen.add(name)
        queue.extend(re.findall(r"function_ref @(\S+?) :", funcs[name]))
    return seen


print("%-20s" % "site" + "".join("%10s" % c[0] for c in COUNTERS) + "%6s" % "fns")
rows = []
for name in funcs:
    found = re.search(r"\d+(site_[A-Za-z]+_\d[A-Z]\d[A-Z])", name)
    if not found or not name.startswith("$s11S1FamilyAPI") or "Tg5" in name or "Tf" in name:
        continue
    label = found.group(1)
    body = "\n".join(funcs[n] for n in reachable(name))
    rows.append((label, [len(re.findall(p, body)) for _, p in COUNTERS], len(reachable(name))))
for label, counts, fns in sorted(rows):
    print("%-20s" % label + "".join("%10d" % c for c in counts) + "%6d" % fns)
PY
}

analyze "$OUT/S1.sil"
echo "SIL: $OUT/S1.sil"

# Deep dive: the ~Escapable Entity view. S1EntityView is its own module, so compile its source as part of the same module.
mkdir -p "$OUT/entity"
sed '/^import S1FamilyAPI$/d' "$ROOT/Sources/S1EntityView/Entity.swift" >"$OUT/entity/Entity.swift"
cat >"$OUT/entity/EntitySite.swift" <<'SWIFT'
@inline(never) public func site_Entity_1R1W(_ f: F1R1W, _ sum: inout Int) {
    var total = 0
    f.forEachEntity { entity in total &+= entity.id }
    sum = total
}
SWIFT
# shellcheck disable=SC2086
swiftc -O -wmo -swift-version 6 -parse-as-library -emit-sil -enable-experimental-feature Lifetimes ${S1_SWIFTC_FLAGS:-} -module-name S1FamilyAPI \
    "$ROOT"/Sources/S1FamilyAPI/*.swift "$ROOT/Spikes/S1/CallSites.swift" "$OUT/entity/Entity.swift" "$OUT/entity/EntitySite.swift" \
    -o "$OUT/S1Entity.sil" 2>"$OUT/swiftc-entity.log"
analyze "$OUT/S1Entity.sil" | grep -E "^site |site_Entity"
