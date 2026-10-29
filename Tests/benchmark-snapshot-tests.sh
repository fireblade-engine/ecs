#!/usr/bin/env bash
# Tests for Scripts/benchmark-snapshot.sh using a throwaway git repository (--prepare-only: no Swift build).
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
script="$repo_root/Scripts/benchmark-snapshot.sh"
test_root=$(mktemp -d "${TMPDIR:-/tmp}/benchmark-snapshot-tests.XXXXXXXX")
trap 'rm -rf "$test_root"' EXIT

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

assert_eq() {
    [[ $1 == "$2" ]] || fail "$3 (expected '$2', got '$1')"
}

fixture="$test_root/fixture"
mkdir -p "$fixture/Sources/FirebladeECS" "$fixture/Benchmarks/Benchmarks/ECSCompatBenchmark" "$fixture/Benchmarks/ComparisonHarness"
git -C "$fixture" init -q
git -C "$fixture" config user.email test@example.com
git -C "$fixture" config user.name test
git -C "$fixture" config commit.gpgsign false

cat > "$fixture/Benchmarks/Package.resolved" <<'JSON'
{
  "pins" : [
    { "identity" : "benchmark", "state" : { "revision" : "aaaa", "version" : "1.38.1" } },
    { "identity" : "hdrhistogram-swift", "state" : { "revision" : "bbbb", "version" : "0.2.0" } }
  ],
  "version" : 3
}
JSON
echo 'suite' > "$fixture/Benchmarks/Benchmarks/ECSCompatBenchmark/Suite.swift"
echo 'harness' > "$fixture/Benchmarks/ComparisonHarness/Old.swift"
echo 'public protocol Component: AnyObject, Sendable {}' > "$fixture/Sources/FirebladeECS/Component.swift"
mkdir -p "$fixture/Benchmarks/Old"
echo 'old' > "$fixture/Benchmarks/Old/Old.swift"
git -C "$fixture" add -A
git -C "$fixture" commit -qm 'class revision'
git -C "$fixture" tag class-rev
class_sha=$(git -C "$fixture" rev-parse HEAD)

echo 'public protocol Component: Sendable {}' > "$fixture/Sources/FirebladeECS/Component.swift"
git -C "$fixture" rm -rq Benchmarks/Old
git -C "$fixture" add -A
git -C "$fixture" commit -qm 'value revision'
value_sha=$(git -C "$fixture" rev-parse HEAD)

run() { "$script" --repo "$fixture" --prepare-only "$@"; }

# Invalid refs are rejected before anything is written.
if run no-such-ref --out "$test_root/invalid" > /dev/null 2> "$test_root/invalid.err"; then
    fail 'invalid ref must be rejected'
fi
grep -q 'invalid ref' "$test_root/invalid.err" || fail 'invalid ref must be reported'
[[ ! -e $test_root/invalid ]] || fail 'invalid ref must not create the output directory'

# Class revision: resolved to a full SHA, old Benchmarks/ replaced, library directory named ecs, class model detected.
run class-rev --out "$test_root/class" > /dev/null
prov="$test_root/class/provenance.txt"
assert_eq "$(sed -n 's/^ref_sha: //p' "$prov")" "$class_sha" 'class ref must resolve to its full SHA'
assert_eq "$(sed -n 's/^suite_sha: //p' "$prov")" "$value_sha" 'suite SHA defaults to HEAD'
assert_eq "$(sed -n 's/^component_model: //p' "$prov")" class 'class components must be detected from Component.swift'
assert_eq "$(sed -n 's/^swift_flags: //p' "$prov")" '-Xswiftc -DECS_CLASS_COMPONENTS' 'class snapshot must define ECS_CLASS_COMPONENTS'
assert_eq "$(sed -n 's/^benchmark: //p' "$prov")" '1.38.1 aaaa' 'benchmark version must be recorded'
assert_eq "$(sed -n 's/^hdrhistogram-swift: //p' "$prov")" '0.2.0 bbbb' 'hdrhistogram version must be recorded'
[[ -f $test_root/class/ecs/Sources/FirebladeECS/Component.swift ]] || fail 'library must live in a directory named ecs'
[[ ! -e $test_root/class/ecs/Benchmarks/Old ]] || fail 'ref-owned Benchmarks/ content must be replaced'
[[ -f $test_root/class/ecs/Benchmarks/Benchmarks/ECSCompatBenchmark/Suite.swift ]] || fail 'suite must be copied'
[[ ! -e $test_root/class/ecs/Benchmarks/ComparisonHarness ]] || fail 'retired harness must not be copied'

# Value revision, selected by ref name only as input: model comes from the file.
run "$value_sha" --out "$test_root/value" > /dev/null
assert_eq "$(sed -n 's/^component_model: //p' "$test_root/value/provenance.txt")" value 'value components must be detected'
assert_eq "$(sed -n 's/^swift_flags: //p' "$test_root/value/provenance.txt")" none 'value snapshot must not define ECS_CLASS_COMPONENTS'

# An explicit suite commit is honored.
run class-rev --suite-ref class-rev --out "$test_root/suite" > /dev/null
assert_eq "$(sed -n 's/^suite_sha: //p' "$test_root/suite/provenance.txt")" "$class_sha" 'explicit suite ref must be used'

# Non-empty output directory is refused.
mkdir "$test_root/busy"
touch "$test_root/busy/file"
if run class-rev --out "$test_root/busy" > /dev/null 2>&1; then
    fail 'non-empty output directory must be refused'
fi

# Dirty suite paths are refused (modified tracked file, then untracked file).
echo 'dirty' >> "$fixture/Benchmarks/Benchmarks/ECSCompatBenchmark/Suite.swift"
if run class-rev --out "$test_root/dirty1" > /dev/null 2> "$test_root/dirty1.err"; then
    fail 'modified suite file must be refused'
fi
grep -q 'dirty' "$test_root/dirty1.err" || fail 'dirty suite must be reported'
git -C "$fixture" checkout -q -- Benchmarks
echo 'new' > "$fixture/Benchmarks/Benchmarks/ECSCompatBenchmark/New.swift"
if run class-rev --out "$test_root/dirty2" > /dev/null 2>&1; then
    fail 'untracked suite file must be refused'
fi
rm "$fixture/Benchmarks/Benchmarks/ECSCompatBenchmark/New.swift"
run class-rev --out "$test_root/clean" > /dev/null || fail 'clean suite must be accepted'

printf 'benchmark-snapshot tests passed\n'
