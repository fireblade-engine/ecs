#!/usr/bin/env bash
#
# Emits optimized SIL for concrete call sites (Scripts/sil/CallSites.swift) of the family iteration API and checks
# the loops of the specialized code: no heap allocation, no existential, no witness_method, no key path, and no call
# to a function that was not inlined or specialized into the module of the call site.
#
# Usage: Scripts/check-sil.sh        (builds FirebladeECS in release first; exits 1 if a loop violates a rule)
#
#   SIL_OUT=<dir>   output directory (default: $TMPDIR/ecs-sil)
#
# There is no make target for SIL, so this script calls swiftc directly with the module of the release build.
# "loop" counts the instructions in the basic blocks that lie on a cycle of any function reachable from the call
# site, plus the in-module functions those blocks call. "all:wit" counts the witness calls of everything reachable,
# including the prologue that runs once per call (witness calls there are fine: they resolve component indices once).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${SIL_OUT:-${TMPDIR:-/tmp}/ecs-sil}"
mkdir -p "$OUT"

make -C "$ROOT" build-release >"$OUT/build.log" 2>&1 || { tail -20 "$OUT/build.log"; exit 1; }
MODULES="$ROOT/.build/out/Products/Release"

swiftc -O -wmo -swift-version 6 -parse-as-library -emit-sil -module-name CallSites -I "$MODULES" \
    "$ROOT/Scripts/sil/CallSites.swift" -o "$OUT/CallSites.sil" 2>"$OUT/swiftc.log" || { cat "$OUT/swiftc.log"; exit 1; }

python3 -I - "$OUT/CallSites.sil" <<'PY'
import re
import sys

text = open(sys.argv[1]).read()
funcs = {}
for match in re.finditer(r"^sil [^\n]*?@(\S+?) :[^\n]*\{\n(.*?)^\} // end sil function", text, re.S | re.M):
    funcs[match.group(1)] = match.group(2)

COUNTERS = [
    ("alloc_ref", r"\balloc_ref\b"),
    ("alloc_box", r"\balloc_box\b"),
    ("existential", r"init_existential_(addr|ref|value)|alloc_existential_box|open_existential"),
    ("witness", r"\bwitness_method\b|\bclass_method\b|\bobjc_method\b"),
    ("keypath", r"\bkeypath\b|swift_getKeyPath|getKeyPath"),
    ("allocObject", r"swift_allocObject|allocObject"),
]
TERMINATOR = re.compile(r"^\s+(br|cond_br|switch_enum|switch_enum_addr|switch_value|try_apply|checked_cast_br|dynamic_method_br|yield)\b")


def blocks(body):
    """Splits a function body into {block name: [lines]} and the successor map."""
    parts, current = {}, None
    for line in body.split("\n"):
        start = re.match(r"^(bb\d+)\b", line)
        if start:
            current = start.group(1)
            parts[current] = []
        elif current:
            parts[current].append(line)
    successors = {}
    for name, lines in parts.items():
        successors[name] = []
        for line in lines:
            if TERMINATOR.match(line):
                successors[name] += re.findall(r"\b(bb\d+)\b", line)
    return parts, successors


def cyclic(successors):
    """The blocks that can reach themselves."""
    inside = set()
    for start in successors:
        seen, stack = set(), list(successors[start])
        while stack:
            node = stack.pop()
            if node == start:
                inside.add(start)
                break
            if node in seen:
                continue
            seen.add(node)
            stack.extend(successors.get(node, []))
    return inside


def callees(lines):
    return re.findall(r"function_ref @(\S+?) :", "\n".join(lines))


def count(lines):
    body = "\n".join(lines)
    return [len(re.findall(pattern, body)) for _, pattern in COUNTERS]


def analyze(root):
    reachable, queue = set(), [root]
    while queue:
        name = queue.pop()
        if name in reachable or name not in funcs:
            continue
        reachable.add(name)
        queue.extend(callees(funcs[name].split("\n")))
    loop_lines, all_lines, loop_blocks = [], [], 0
    for name in reachable:
        parts, successors = blocks(funcs[name])
        inside = cyclic(successors)
        loop_blocks += len(inside)
        loop_lines += [line for block in inside for line in parts[block]]
        all_lines += funcs[name].split("\n")
    # in-module functions called from the loop count as loop code; calls that leave the module are what remains
    seen, queue, external = set(), callees(loop_lines), []
    while queue:
        callee = queue.pop()
        if callee in seen:
            continue
        seen.add(callee)
        if callee in funcs:
            lines = funcs[callee].split("\n")
            loop_lines += lines
            queue.extend(callees(lines))
        else:
            external.append(callee)
    return count(loop_lines), count(all_lines), sorted(set(external)), loop_blocks


print("%-34s" % "site" + "".join("%12s" % c[0] for c in COUNTERS) + "%7s%9s%7s" % ("calls", "all:wit", "loop"))
failed = False
for name in sorted(funcs):
    found = re.search(r"(site_[A-Za-z0-9_]+?)yy\d", name)
    if not found or "Tf" in name or "Tg" in name or "TA" in name:
        continue
    loop_counts, all_counts, external, loop_size = analyze(name)
    print("%-34s" % found.group(1) + "".join("%12d" % c for c in loop_counts) + "%7d%9d%7d" % (len(external), all_counts[3], loop_size))
    for callee in external:
        print("      loop calls @" + callee)
    if loop_size == 0 or any(loop_counts) or external:
        failed = True
print("SIL: " + sys.argv[1])
sys.exit(1 if failed else 0)
PY
