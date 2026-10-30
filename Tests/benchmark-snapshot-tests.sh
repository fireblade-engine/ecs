#!/usr/bin/env bash
# Tests for Scripts/benchmark-snapshot.sh using a throwaway git repository (--prepare-only: no Swift build; result mode
# runs against a stub `swift` and a stub ECSBenchmarkResults that record their arguments).
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
script="$repo_root/Scripts/benchmark-snapshot.sh"
test_root=$(mktemp -d "${TMPDIR:-/tmp}/benchmark-snapshot-tests.XXXXXXXX")
trap 'rm -rf "$test_root"' EXIT
# Private TMPDIR: temporary snapshots made by the script under test are counted here, unaffected by other processes.
export TMPDIR="$test_root/tmp"
mkdir -p "$TMPDIR"

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
count_tmp_snapshots() { find "$TMPDIR" -maxdepth 1 -name 'benchmark-snapshot.*' | wc -l | tr -d ' '; }
tmp_before=$(count_tmp_snapshots)
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
assert_eq "$(count_tmp_snapshots)" "$tmp_before" 'a failed temporary snapshot must be removed'
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
echo "tool $1" >> "$STUB_LOG"
case $1 in
    host-check) [[ -z ${STUB_HOST_FAIL:-} ]] || { echo 'cannot determine host facts' >&2; exit 1; }; exit 0 ;;
    validate) [[ -z ${STUB_VALIDATE_FAIL:-} ]] || exit 1; exit 0 ;;
    write) ;;
    *) exit 2 ;;
esac
printf '%s\n' "$@" > "$STUB_LOG.results"
[[ -z ${STUB_WRITE_FAIL:-} ]] || exit 1
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

# --requested names the ref in provenance; a full SHA is used as given and never looked up again, so a branch that moved
# after the caller resolved it cannot change what is measured. --batch-id is passed to the writer.
git -C "$fixture" branch moving "$class_sha"
moving_sha=$class_sha
git -C "$fixture" branch -f moving "$value_sha"
run "$moving_sha" --requested moving --out "$test_root/pinned" > /dev/null
assert_eq "$(sed -n 's/^ref_sha: //p' "$test_root/pinned/provenance.txt")" "$class_sha" 'a SHA must not be re-resolved through a moved branch'
assert_eq "$(sed -n 's/^ref: //p' "$test_root/pinned/provenance.txt")" moving 'the requested name must be recorded'
assert_eq "$(sed -n 's/^component_model: //p' "$test_root/pinned/provenance.txt")" class 'the snapshot must come from the pinned SHA'
if run "$(printf 'f%.0s' {1..40})" --requested x --out "$test_root/nosuchsha" > /dev/null 2>&1; then fail 'an unknown full SHA must be rejected'; fi
: > "$STUB_LOG"
PATH="$stubs:$PATH" "$script" --repo "$fixture" "$moving_sha" --requested moving --batch-id batch-7 --out "$test_root/pinned-full" --result "$test_root/pinned-result.json" > /dev/null \
    || fail 'result mode with a SHA must succeed'
assert_eq "$(arg_after --ref)" moving 'the requested name must reach the writer'
assert_eq "$(arg_after --ref-sha)" "$class_sha" 'the pinned SHA must reach the writer'
assert_eq "$(arg_after --batch-id)" batch-7 'the batch id must reach the writer'
git -C "$fixture" branch -D moving > /dev/null

# Host facts are checked before any measurement; a failure measures nothing.
: > "$STUB_LOG"
if STUB_HOST_FAIL=1 PATH="$stubs:$PATH" "$script" --repo "$fixture" class-rev --out "$test_root/hostfail" --result "$test_root/hostfail.json" > /dev/null 2> "$test_root/hostfail.err"; then
    fail 'unreadable host facts must fail'
fi
grep -q 'nothing was measured' "$test_root/hostfail.err" || fail 'a host failure must be explained'
grep -q 'baseline update' "$STUB_LOG" && fail 'no benchmark may run when the host facts are unavailable'
[[ ! -e $test_root/hostfail.json ]] || fail 'no result for a failed preflight'

# A finished measurement survives a failing writer or validator: the native baseline is kept under <result dir>/.failed.
for failure in STUB_WRITE_FAIL STUB_VALIDATE_FAIL; do
    keep="$test_root/keep-$failure"
    mkdir "$keep"
    if env "$failure=1" PATH="$stubs:$PATH" "$script" --repo "$fixture" class-rev --out "$test_root/keep-out-$failure" --result "$keep/r.json" > /dev/null 2> "$keep.err"; then
        fail "$failure must fail the run"
    fi
    [[ ! -e $keep/r.json ]] || fail "$failure must not leave a result file"
    kept="$keep/.failed/class-rev-${class_sha:0:12}/results.json"
    [[ -f $kept ]] || fail "$failure must keep the native baseline at $kept"
    grep -q '"stub":true' "$kept" || fail "$failure must keep the measured baseline unchanged"
    grep -qF "$(sed 's|//|/|g' <<< "$kept")" "$keep.err" || fail "$failure must report the kept path"
done

# Prerequisites of result mode are checked before the snapshot is written.
if PATH="$stubs:$PATH" "$script" --repo "$fixture" class-rev --out "$test_root/nofilter" --filter ' ' > /dev/null 2> "$test_root/nofilter.err"; then fail 'an empty filter must be refused'; fi
grep -q 'filter is empty' "$test_root/nofilter.err" || fail 'an empty filter must be reported'
nouuid="$test_root/nouuid"
mkdir -p "$nouuid"
for tool in git bash env dirname basename mktemp rm mkdir cat awk grep sed mv cp ls cmp tar uname jq; do
    src=$(command -v "$tool" || true)
    [[ -z $src ]] || ln -s "$src" "$nouuid/$tool"
done
ln -s "$stubs/swift" "$nouuid/swift"
if PATH="$nouuid" "$script" --repo "$fixture" class-rev --out "$test_root/nouuid-out" --result "$test_root/nouuid.json" > /dev/null 2> "$test_root/nouuid.err"; then fail 'missing uuidgen must fail'; fi
grep -q 'uuidgen is required' "$test_root/nouuid.err" || fail 'missing uuidgen must be reported'
[[ ! -e $test_root/nouuid-out ]] || fail 'missing uuidgen must not create the snapshot'

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

# The plugin whole-matches names, so a partial-only filter ('/ 1' matches "alpha / 16" only as a substring) is refused.
: > "$STUB_LOG"
if PATH="$stubs:$PATH" "$script" --repo "$fixture" class-rev --out "$test_root/partial" --filter '/ 1' > /dev/null 2> "$test_root/partial.err"; then
    fail 'a partial-only filter must fail like the plugin whole-match'
fi
grep -q 'filter matches no benchmarks: / 1' "$test_root/partial.err" || fail 'a partial-only filter must be reported with its text'
grep -q 'baseline update\|benchmark --target' "$STUB_LOG" && fail 'nothing may run for a partial-only filter'

# Without --result the previous behavior stands: a plain benchmark run, no baseline, no result tool.
: > "$STUB_LOG"
PATH="$stubs:$PATH" "$script" --repo "$fixture" class-rev --out "$test_root/plain" > /dev/null || fail 'plain run must succeed with stubs'
grep -q 'baseline update' "$STUB_LOG" && fail 'a plain run must not store a baseline'
grep -q 'ECSBenchmarkResults' "$STUB_LOG" && fail 'a plain run must not build the result tool'

# --reuse runs an already built snapshot again: no extraction, resolve or compat build, but the replicate fields reach the tool.
: > "$STUB_LOG"
PATH="$stubs:$PATH" "$script" --repo "$fixture" class-rev --out "$test_root/full" --filter 'f.*' --reuse --result "$test_root/reuse-result.json" \
    --replicate 2 --replicates 3 --round 2 --position 1 --seed 77 > /dev/null || fail '--reuse must succeed on a prepared snapshot'
[[ -f $test_root/reuse-result.json ]] || fail '--reuse must write the result file'
grep -q 'package resolve' "$STUB_LOG" && fail '--reuse must not resolve again'
grep -q 'product ECSCompatBenchmark' "$STUB_LOG" && fail '--reuse must not rebuild the suite'
grep -q 'build -c release --product' "$STUB_LOG" && fail '--reuse must not compile anything'
grep -q 'benchmark list' "$STUB_LOG" && fail '--reuse must not list benchmarks again'
[[ $(grep -c 'benchmark baseline update' "$STUB_LOG") == 1 ]] || fail '--reuse must run the benchmarks once'
grep -q 'tool host-check' "$STUB_LOG" || fail '--reuse must check the host before measuring'
args="$test_root/stub.log.results"
for pair in "--replicate 2" "--replicates 3" "--round 2" "--position 1" "--seed 77"; do
    assert_eq "$(grep -A1 -x -- "${pair% *}" "$args" | tail -1)" "${pair#* }" "${pair% *} must be passed to the result tool"
done
# --build-only builds everything a later --reuse needs (suite, result tool, plugin listing) and measures nothing; --reuse fails
# instead of building when a required binary is missing.
: > "$STUB_LOG"
PATH="$stubs:$PATH" "$script" --repo "$fixture" class-rev --out "$test_root/built" --filter 'f.*' --build-only > /dev/null || fail '--build-only must succeed with stubs'
grep -q 'build -c release --product ECSCompatBenchmark' "$STUB_LOG" || fail '--build-only must build the suite'
grep -q 'build -c release --product ECSBenchmarkResults' "$STUB_LOG" || fail '--build-only must build the result tool'
grep -q 'benchmark list' "$STUB_LOG" || fail '--build-only must warm the benchmark plugin and check the filter'
grep -q 'baseline update' "$STUB_LOG" && fail '--build-only must not measure'
mkdir -p "$test_root/emptybin"
: > "$STUB_LOG"
if STUB_BIN="$test_root/emptybin" PATH="$stubs:$PATH" "$script" --repo "$fixture" class-rev --out "$test_root/built" --filter 'f.*' --reuse --result "$test_root/reuse-nobin.json" > /dev/null 2> "$test_root/nobin.err"; then fail '--reuse must fail when the result tool is missing'; fi
grep -q 'is missing' "$test_root/nobin.err" || fail 'a missing binary must be reported'
grep -q 'build -c release --product' "$STUB_LOG" && fail '--reuse must not build a missing binary'
# A different ref, a tampered provenance, tampered pins, an unprepared directory or a half-given replicate set is refused.
: > "$STUB_LOG"
if PATH="$stubs:$PATH" "$script" --repo "$fixture" t-other --out "$test_root/full" --reuse --result "$test_root/reuse-x.json" > /dev/null 2>&1; then fail '--reuse must refuse an unknown ref'; fi
git -C "$fixture" tag other-rev "$class_sha"
if PATH="$stubs:$PATH" "$script" --repo "$fixture" other-rev --out "$test_root/full" --reuse --result "$test_root/reuse-x.json" > /dev/null 2> "$test_root/reuse-x.err"; then fail '--reuse must refuse a snapshot prepared for another requested name'; fi
grep -q 'provenance' "$test_root/reuse-x.err" || fail 'a provenance mismatch must be reported'
cp -R "$test_root/full" "$test_root/full-pins"
echo ' ' >> "$test_root/full-pins/ecs/Benchmarks/Package.resolved"
if PATH="$stubs:$PATH" "$script" --repo "$fixture" class-rev --out "$test_root/full-pins" --reuse --result "$test_root/reuse-y.json" > /dev/null 2> "$test_root/reuse-y.err"; then fail '--reuse must refuse changed pins'; fi
grep -q 'differs from the committed pins' "$test_root/reuse-y.err" || fail 'changed pins must be reported'
mkdir "$test_root/empty-snap"
if PATH="$stubs:$PATH" "$script" --repo "$fixture" class-rev --out "$test_root/empty-snap" --reuse --result "$test_root/reuse-z.json" > /dev/null 2>&1; then fail '--reuse must refuse an unprepared directory'; fi
if PATH="$stubs:$PATH" "$script" --repo "$fixture" class-rev --out "$test_root/full" --reuse --result "$test_root/reuse-w.json" --replicate 1 > /dev/null 2>&1; then fail 'half-given replicate options must be refused'; fi
grep -q 'baseline update' "$STUB_LOG" && fail 'a refused --reuse must not measure'

printf 'benchmark-snapshot tests passed\n'
