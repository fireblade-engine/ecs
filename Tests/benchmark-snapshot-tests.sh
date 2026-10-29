#!/usr/bin/env bash
# Tests for Scripts/benchmark-snapshot.sh using a throwaway git repository (--prepare-only: no Swift build; result mode
# runs against a stub `swift` and a stub ECSBenchmarkResults that record their arguments).
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
assert_eq "$(sed -n 's/^pin.benchmark: //p' "$prov")" '1.38.1 aaaa' 'benchmark pin must be recorded'
assert_eq "$(sed -n 's/^pin.hdrhistogram-swift: //p' "$prov")" '0.2.0 bbbb' 'every pin must be recorded'
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

# export-ignore / export-subst in the ref must not alter the snapshot (git archive would honor them).
attr=$(mktemp -d "$test_root/attr.XXXXXXXX")
git clone -q "$fixture" "$attr/repo"
git -C "$attr/repo" config user.email test@example.com
git -C "$attr/repo" config user.name test
printf 'ignored.txt export-ignore\nsubst.txt export-subst\n' > "$attr/repo/.gitattributes"
echo 'kept' > "$attr/repo/ignored.txt"
echo '$Format:%H$' > "$attr/repo/subst.txt"
git -C "$attr/repo" add .gitattributes ignored.txt subst.txt
git -C "$attr/repo" commit -qm attributes
"$script" --repo "$attr/repo" --prepare-only HEAD --out "$test_root/attr-out" > /dev/null
[[ -f $test_root/attr-out/ecs/ignored.txt ]] || fail 'export-ignore must not drop files from the snapshot'
assert_eq "$(cat "$test_root/attr-out/ecs/subst.txt")" '$Format:%H$' 'export-subst must not rewrite files'

# Class detection is anchored: a comment mentioning the class model must not select it.
git -C "$attr/repo" checkout -q -b prose
printf '// protocol Component: AnyObject\n/* protocol Component: AnyObject */\npublic protocol Component: Sendable {}\n' > "$attr/repo/Sources/FirebladeECS/Component.swift"
git -C "$attr/repo" add Sources/FirebladeECS/Component.swift
git -C "$attr/repo" commit -qm prose
"$script" --repo "$attr/repo" --prepare-only prose --out "$test_root/prose" > /dev/null
assert_eq "$(sed -n 's/^component_model: //p' "$test_root/prose/provenance.txt")" value 'comments must not select the class model'

# jq is required.
nojq="$test_root/nojq"
mkdir -p "$nojq"
for tool in git bash env dirname basename mktemp rm mkdir cat awk grep sed mv cp ls cmp tar uname; do
    src=$(command -v "$tool" || true)
    [[ -z $src ]] || ln -s "$src" "$nojq/$tool"
done
if PATH="$nojq" "$script" --repo "$fixture" --prepare-only class-rev --out "$test_root/nojq-out" > /dev/null 2> "$test_root/nojq.err"; then
    fail 'missing jq must fail'
fi
grep -q 'jq is required' "$test_root/nojq.err" || fail 'missing jq must be reported'
[[ ! -e $test_root/nojq-out ]] || fail 'missing jq must not create the snapshot'

# A temporary snapshot is removed when the run fails; an explicit --out is kept.
tmp_before=$(ls -d "${TMPDIR:-/tmp}"/benchmark-snapshot.* 2> /dev/null | wc -l)
printf 'fake\n' > "$fixture/Benchmarks/Benchmarks/ECSCompatBenchmark/Suite.swift"
git -C "$fixture" checkout -q -- Benchmarks
cat > "$test_root/failing-swift" <<'STUB'
#!/usr/bin/env bash
exit 3
STUB
mkdir -p "$test_root/failbin"
cp "$test_root/failing-swift" "$test_root/failbin/swift"
chmod +x "$test_root/failbin/swift"
if PATH="$test_root/failbin:$PATH" "$script" --repo "$fixture" class-rev > /dev/null 2>&1; then fail 'failing swift must fail the run'; fi
assert_eq "$(ls -d "${TMPDIR:-/tmp}"/benchmark-snapshot.* 2> /dev/null | wc -l)" "$tmp_before" 'a failed temporary snapshot must be removed'
if PATH="$test_root/failbin:$PATH" "$script" --repo "$fixture" class-rev --out "$test_root/kept" > /dev/null 2>&1; then fail 'failing swift must fail the run'; fi
[[ -d $test_root/kept/ecs ]] || fail 'an explicit --out must be kept after a failure'

# Suite ref other than HEAD: the worktree is irrelevant, so a dirty worktree does not block it; HEAD still does.
echo 'dirty' >> "$fixture/Benchmarks/Benchmarks/ECSCompatBenchmark/Suite.swift"
run class-rev --suite-ref class-rev --out "$test_root/suite-nonhead" > /dev/null || fail 'a committed non-HEAD suite ref must ignore worktree changes'
assert_eq "$(sed -n 's/^suite_sha: //p' "$test_root/suite-nonhead/provenance.txt")" "$class_sha" 'non-HEAD suite ref must be used as committed'

assert_eq "$(cat "$test_root/suite-nonhead/ecs/Benchmarks/Benchmarks/ECSCompatBenchmark/Suite.swift")" suite 'non-HEAD suite must come from the committed tree'
git -C "$fixture" checkout -q -- Benchmarks

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

# --result needs a full run, a fresh file and an existing directory; nothing is created when it is refused.
for mode in --prepare-only --build-only; do
    if run class-rev --out "$test_root/res-mode" --result "$test_root/r.json" $mode > /dev/null 2> "$test_root/res-mode.err"; then
        fail "--result must be refused with $mode"
    fi
    grep -q 'full run' "$test_root/res-mode.err" || fail '--result with a partial mode must be explained'
done
[[ ! -e $test_root/res-mode ]] || fail 'a refused --result must not create the snapshot'
touch "$test_root/existing.json"
if "$script" --repo "$fixture" class-rev --out "$test_root/res-exists" --result "$test_root/existing.json" > /dev/null 2> "$test_root/res-exists.err"; then
    fail 'an existing result file must be refused'
fi
grep -q 'already exists' "$test_root/res-exists.err" || fail 'an existing result file must be reported'
if "$script" --repo "$fixture" class-rev --out "$test_root/res-dir" --result "$test_root/no-such-dir/r.json" > /dev/null 2>&1; then
    fail 'a missing result directory must be refused'
fi

# Result mode end to end with stubs: one baseline-update run, then ECSBenchmarkResults write with full provenance.
stubs="$test_root/stubs"
mkdir -p "$stubs/bin"
cat > "$stubs/swift" <<'STUB'
#!/usr/bin/env bash
echo "$*" >> "$STUB_LOG"
case "$*" in
    *"baseline update"*)
        name=$(sed -E 's/.*baseline update ([^ ]+).*/\1/' <<< "$*")
        mkdir -p ".benchmarkBaselines/ECSCompatBenchmark/$name"
        echo '{"stub":true}' > ".benchmarkBaselines/ECSCompatBenchmark/$name/results.json" ;;
    *"benchmark list"*) printf 'alpha / 16\nfoo / 1\n' ;;
    *"package resolve"*) [[ -z ${STUB_RESOLVE_TOUCH:-} ]] || echo changed >> Package.resolved ;;
    *"--show-bin-path"*) echo "$STUB_BIN" ;;
    --version) echo "stub swift 1.0" ;;
esac
STUB
cat > "$stubs/bin/ECSBenchmarkResults" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$STUB_LOG.results"
out=""
while (($#)); do [[ $1 == --out ]] && out=$2; shift; done
echo '{"stub":"result"}' > "$out"
STUB
chmod +x "$stubs/swift" "$stubs/bin/ECSBenchmarkResults"
export STUB_LOG="$test_root/stub.log" STUB_BIN="$stubs/bin"
PATH="$stubs:$PATH" "$script" --repo "$fixture" class-rev --out "$test_root/full" --filter 'f.*' --result "$test_root/full-result.json" > /dev/null \
    || fail 'result mode must succeed with stubs'
[[ -f $test_root/full-result.json ]] || fail 'result file must be written'
grep -Eq 'benchmark baseline update snapshot-[0-9a-f]{12}-[0-9]+-[0-9]+ --target ECSCompatBenchmark --filter f\.\*' "$STUB_LOG" || fail 'result mode must store a uniquely named baseline'
[[ $(grep -c 'benchmark baseline update' "$STUB_LOG") == 1 ]] || fail 'result mode must run the benchmarks exactly once'
grep -q 'build -c release --product ECSBenchmarkResults' "$STUB_LOG" || fail 'the snapshot must build its own result tool'
args="$test_root/stub.log.results"
arg_after() { grep -A1 -x -- "$1" "$args" | tail -1; }
assert_eq "$(arg_after --ref)" class-rev 'requested ref must be passed'
assert_eq "$(arg_after --ref-sha)" "$class_sha" 'full ref SHA must be passed'
assert_eq "$(arg_after --suite-sha)" "$value_sha" 'suite SHA must be passed'
assert_eq "$(arg_after --filter)" 'f.*' 'filter must be passed'
assert_eq "$(arg_after --package-resolved)" Package.resolved 'post-resolve Package.resolved must be passed'
assert_eq "$(arg_after --swift-version)" 'stub swift 1.0' 'swift version text must be passed'
assert_eq "$(arg_after --baseline | sed -E 's/snapshot-[0-9a-f]{12}-[0-9]+-[0-9]+/NAME/')" '.benchmarkBaselines/ECSCompatBenchmark/NAME/results.json' 'baseline path must be passed'
[[ $(arg_after --started) =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:]{8}Z$ ]] || fail 'start must be an ISO 8601 UTC timestamp'
[[ $(arg_after --finished) =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:]{8}Z$ ]] || fail 'finish must be an ISO 8601 UTC timestamp'
[[ -n $(arg_after --run-id) ]] || fail 'a run id must be passed'

# Resolving must not change the committed Package.resolved.
if STUB_RESOLVE_TOUCH=1 PATH="$stubs:$PATH" "$script" --repo "$fixture" class-rev --out "$test_root/resolve-changed" > /dev/null 2> "$test_root/resolve-changed.err"; then
    fail 'a resolve that changes Package.resolved must fail'
fi
grep -q 'changed Package.resolved' "$test_root/resolve-changed.err" || fail 'changed Package.resolved must be reported'

# A filter that matches no benchmark fails before anything runs.
: > "$STUB_LOG"
if PATH="$stubs:$PATH" "$script" --repo "$fixture" class-rev --out "$test_root/nomatch" --filter 'zzz-nothing' > /dev/null 2> "$test_root/nomatch.err"; then
    fail 'a filter matching nothing must fail'
fi
grep -q 'matches no benchmarks' "$test_root/nomatch.err" || fail 'an empty filter selection must be reported'
grep -q 'baseline update\|benchmark --target' "$STUB_LOG" && fail 'nothing may run when the filter matches nothing'

# Without --result the previous behavior stands: a plain benchmark run, no baseline, no result tool.
: > "$STUB_LOG"
PATH="$stubs:$PATH" "$script" --repo "$fixture" class-rev --out "$test_root/plain" > /dev/null || fail 'plain run must succeed with stubs'
grep -q 'baseline update' "$STUB_LOG" && fail 'a plain run must not store a baseline'
grep -q 'ECSBenchmarkResults' "$STUB_LOG" && fail 'a plain run must not build the result tool'

printf 'benchmark-snapshot tests passed\n'
