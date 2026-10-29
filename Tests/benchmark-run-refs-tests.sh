#!/usr/bin/env bash
# Tests for Scripts/benchmark-run-refs.sh with a stubbed snapshot script (no Swift, no builds).
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
script="$repo_root/Scripts/benchmark-run-refs.sh"
test_root=$(mktemp -d "${TMPDIR:-/tmp}/benchmark-run-refs-tests.XXXXXXXX")
test_root=$(cd "$test_root" && pwd)
trap 'rm -rf "$test_root"' EXIT

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

assert_eq() {
    [[ $1 == "$2" ]] || fail "$3 (expected '$2', got '$1')"
}

fixture="$test_root/fixture"
mkdir -p "$fixture"
git -C "$fixture" init -q
git -C "$fixture" config user.email test@example.com
git -C "$fixture" config user.name test
git -C "$fixture" config commit.gpgsign false
for n in one two three; do
    echo "$n" > "$fixture/file"
    git -C "$fixture" add file
    git -C "$fixture" commit -qm "$n"
    git -C "$fixture" tag "t-$n"
done
sha_of() { git -C "$fixture" rev-parse "$1^{commit}"; }

# Stub snapshot: logs every invocation, writes a minimal result, can fail for one ref, can skew the config hash or the
# toolchain, and can move a branch while the first ref is being "measured".
stub="$test_root/snapshot-stub.sh"
cat > "$stub" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
ref=$1; shift
echo "$ref $*" >> "$STUB_LOG"
repo="" suite="" out="" result="" requested="" batch=""
while (($#)); do
    case $1 in
        --repo) repo=$2 ;;
        --suite-ref) suite=$2 ;;
        --out) out=$2 ;;
        --result) result=$2 ;;
        --requested) requested=$2 ;;
        --batch-id) batch=$2 ;;
    esac
    shift
done
[[ -z ${STUB_MOVE_ONCE:-} || -e $STUB_MOVE_ONCE ]] || { touch "$STUB_MOVE_ONCE"; git -C "$repo" branch -f movable t-three; }
[[ ${STUB_FAIL_REF:-} != "$requested" ]] || exit 7
mkdir "$out"
hash=HASH
[[ ${STUB_SKEW_REF:-} != "$requested" ]] || hash=OTHER
swift_version="swift 6"
[[ ${STUB_TOOLCHAIN_REF:-} != "$requested" ]] || swift_version="swift 7"
sha=$(git -C "$repo" rev-parse "$ref^{commit}")
[[ ${STUB_WRONG_SHA_REF:-} != "$requested" ]] || sha=$(printf 'e%.0s' {1..40})
jq -n --arg r "$sha" --arg s "$suite" --arg h "$hash" --arg b "$batch" --arg v "$swift_version" --arg q "$requested" \
    '{run: {batchId: $b}, ref: {requested: $q, sha: $r}, suite: {sha: $s, configurationHash: $h}, toolchain: {swiftVersion: $v},
      host: {cpuModel: "cpu", physicalMemoryBytes: 1}, benchmarks: [{identity: "w", scale: 16}]}' > "$result"
STUB
chmod +x "$stub"
export BENCHMARK_SNAPSHOT_SCRIPT="$stub" STUB_LOG="$test_root/calls.log"

run() { "$script" --repo "$fixture" "$@"; }
calls() { if [[ -f $STUB_LOG ]]; then wc -l < "$STUB_LOG" | tr -d ' '; else echo 0; fi; }
reset() { rm -f "$STUB_LOG"; unset STUB_FAIL_REF STUB_SKEW_REF STUB_TOOLCHAIN_REF STUB_WRONG_SHA_REF STUB_MOVE_ONCE; }

# Validation precedes any execution: one bad ref anywhere means no snapshot call at all.
bad_cases=(
    "t-one,no-such-ref"
    "t-one,,t-two"
    ",t-one"
    "t-one,"
    "t-one,WORKTREE"
    "WORKTREE"
    "t-one,t-two,t-one"
)
for refs in "${bad_cases[@]}"; do
    reset
    if run --refs "$refs" --out "$test_root/bad-run" > /dev/null 2> "$test_root/bad.err"; then
        fail "refs '$refs' must be rejected"
    fi
    assert_eq "$(calls)" 0 "no snapshot may start when refs '$refs' are invalid"
    [[ ! -e $test_root/bad-run ]] || fail "refs '$refs' must not create the run directory"
done
err=$(run --refs "t-one,no-such-ref" --out "$test_root/x" 2>&1 > /dev/null || true)
[[ $err == *'invalid ref: no-such-ref'* ]] || fail 'invalid ref must be named'
err=$(run --refs "t-one,WORKTREE" --out "$test_root/x" 2>&1 > /dev/null || true)
[[ $err == *'WORKTREE is not supported'* ]] || fail 'WORKTREE must be explained'
if run --out "$test_root/x" > /dev/null 2>&1; then fail '--refs is required'; fi
if run --refs t-one --suite-ref no-such --out "$test_root/x" > /dev/null 2>&1; then fail 'invalid suite ref must be rejected'; fi
assert_eq "$(calls)" 0 'invalid options must not start snapshots'

# Duplicates are detected by SHA (tag and SHA of the same commit) and both names are listed.
git -C "$fixture" tag alias t-two
dup_err=$(run --refs "t-two,t-one,alias" --out "$test_root/dup" 2>&1 > /dev/null) && fail 'duplicate commits must be rejected'
:
[[ $dup_err == *"'t-two' and 'alias'"* ]] || fail "duplicate error must list both names (got: $dup_err)"
dup_err=$(run --refs "t-two,$(sha_of t-two)" --out "$test_root/dup" 2>&1 > /dev/null) && fail 'tag and SHA of one commit must be rejected'
assert_eq "$(calls)" 0 'duplicates must not start snapshots'

# Success: one result per ref in one run directory, distinct snapshot dirs, the same suite SHA for every ref.
reset
out_ok="$test_root/ok"
stdout=$(run --refs "t-one,t-two,t-three" --filter 'f.*' --suite-ref t-three --out "$out_ok")
assert_eq "$(calls)" 3 'one snapshot per accepted ref'
assert_eq "$(ls "$out_ok" | wc -l | tr -d ' ')" 3 'exactly one result file per ref and nothing else'
for n in one two three; do
    f="$out_ok/t-$n-$(sha_of "t-$n" | cut -c1-12).json"
    [[ -f $f ]] || fail "missing result for t-$n"
    grep -qF "result: $f" <<< "$stdout" || fail "result list must include t-$n"
done
assert_eq "$(grep -c '^result: ' <<< "$stdout")" 3 'stdout lists exactly one result line per accepted ref'
[[ $stdout != *.partial* && $stdout != *"snapshot output"* ]] || fail 'stdout must list only final result files'
assert_eq "$(grep -vc '^result: ' <<< "$stdout" || true)" 0 'stdout must contain nothing but result lines'
assert_eq "$(sed -E 's/.*--out ([^ ]+) .*/\1/' "$STUB_LOG" | sort -u | wc -l | tr -d ' ')" 3 'each ref needs its own snapshot directory'
assert_eq "$(grep -c -- "--suite-ref $(sha_of t-three) " "$STUB_LOG")" 3 'every ref uses the same resolved suite SHA'
for n in one two three; do
    grep -q "^$(sha_of "t-$n") --requested t-$n " "$STUB_LOG" || fail "t-$n must be passed to the snapshot as its resolved SHA plus the requested name"
done
batches=$(jq -r '.run.batchId' "$out_ok"/*.json | sort -u)
[[ -n $batches && $(wc -l <<< "$batches" | tr -d ' ') == 1 ]] || fail 'all results of one invocation share one batch id'
[[ $(grep -c -- "--batch-id $batches " "$STUB_LOG") == 3 ]] || fail 'the batch id must be passed to every snapshot'
assert_eq "$(ls -A "$out_ok" | wc -l | tr -d ' ')" 3 'no staged or failed leftovers after a successful run'
assert_eq "$(grep -c -- '--filter f\.\*' "$STUB_LOG")" 3 'every ref uses the same filter'

# Failure of ref 2 of 3: ref 1's result stays, no result for ref 2, ref 3 never starts, non-zero exit.
reset
export STUB_FAIL_REF=t-two
out_fail="$test_root/fail"
if run --refs "t-one,t-two,t-three" --out "$out_fail" > /dev/null 2> "$test_root/fail.err"; then fail 'a failing ref must fail the run'; fi
assert_eq "$(calls)" 2 'ref 3 must not start after ref 2 failed'
grep -q 't-two failed' "$test_root/fail.err" || fail 'the failing ref must be named'
assert_eq "$(ls "$out_fail")" "t-one-$(sha_of t-one | cut -c1-12).json" 'only the completed ref keeps a result'

# A configuration hash that differs from the first ref's is a failure and leaves no result for that ref.
reset
export STUB_SKEW_REF=t-two
out_skew="$test_root/skew"
if run --refs "t-one,t-two,t-three" --out "$out_skew" > /dev/null 2> "$test_root/skew.err"; then fail 'a differing configuration hash must fail the run'; fi
grep -q 'configuration hash' "$test_root/skew.err" || fail 'hash mismatch must be reported'
assert_eq "$(ls "$out_skew" | wc -l | tr -d ' ')" 1 'a hash mismatch leaves only the earlier result'
kept="$out_skew/.failed/t-two-$(sha_of t-two | cut -c1-12).json"
[[ -f $kept ]] || fail 'a rejected completed measurement must be kept under .failed'
grep -qF "$kept" "$test_root/skew.err" || fail 'the kept path must be reported'
assert_eq "$(ls -A "$out_skew" | grep -c partial || true)" 0 'no staged file may remain'
assert_eq "$(calls)" 2 'ref 3 must not start after a hash mismatch'

# A result recording another SHA than the resolved one is rejected and kept as well.
reset
export STUB_WRONG_SHA_REF=t-one
out_wrong="$test_root/wrong"
if run --refs "t-one,t-two" --out "$out_wrong" > /dev/null 2> "$test_root/wrong.err"; then fail 'a result with the wrong SHA must fail the run'; fi
[[ -f $out_wrong/.failed/t-one-$(sha_of t-one | cut -c1-12).json ]] || fail 'the rejected result must be kept'
assert_eq "$(calls)" 1 'later refs must not start after a rejected result'

# Refs are resolved once: a branch that moves while the first ref runs does not change the SHA measured for it.
reset
git -C "$fixture" branch movable t-two
export STUB_MOVE_ONCE="$test_root/moved.flag"
rm -f "$STUB_MOVE_ONCE"
out_move="$test_root/move"
run --refs "t-one,movable" --out "$out_move" > /dev/null 2>&1
assert_eq "$(sha_of movable)" "$(sha_of t-three)" 'the stub must have moved the branch'
grep -q "^$(sha_of t-two) --requested movable " "$STUB_LOG" || fail 'the SHA resolved before the run must be measured, not the moved branch'
[[ -f $out_move/movable-$(sha_of t-two | cut -c1-12).json ]] || fail 'the result file must carry the original SHA'
assert_eq "$(jq -r '.ref.requested' "$out_move"/movable-*.json)" movable 'the requested name stays provenance'

# Differences between results warn without failing the run.
reset
export STUB_TOOLCHAIN_REF=t-two
out_warn="$test_root/warn"
run --refs "t-one,t-two" --out "$out_warn" > /dev/null 2> "$test_root/warn.err" || fail 'a toolchain difference must not fail the run'
grep -q 'warning: toolchain differs between t-two and t-one' "$test_root/warn.err" || fail 'a toolchain difference must warn'
assert_eq "$(ls "$out_warn" | wc -l | tr -d ' ')" 2 'both results are kept despite the warning'
reset
run --refs "t-one,t-two" --out "$test_root/nowarn" > /dev/null 2> "$test_root/nowarn.err"
grep -q 'warning' "$test_root/nowarn.err" && fail 'identical toolchain, host and set must not warn'

# Prerequisites and the filter are checked before any snapshot starts.
reset
if run --refs t-one --filter ' ' --out "$test_root/nofilter" > /dev/null 2> "$test_root/nofilter.err"; then fail 'an empty filter must be refused'; fi
grep -q 'filter is empty' "$test_root/nofilter.err" || fail 'an empty filter must be reported'
nouuid="$test_root/nouuid"
mkdir -p "$nouuid"
for tool in git bash env dirname basename mktemp rm mkdir rmdir cat awk grep sed mv cp ls tr date jq swift sort; do
    src=$(command -v "$tool" || true)
    [[ -z $src ]] || ln -s "$src" "$nouuid/$tool"
done
if PATH="$nouuid" run --refs t-one --out "$test_root/nouuid-out" > /dev/null 2> "$test_root/nouuid.err"; then fail 'missing uuidgen must fail'; fi
grep -q 'uuidgen is required' "$test_root/nouuid.err" || fail 'missing uuidgen must be reported'
assert_eq "$(calls)" 0 'missing prerequisites must not start snapshots'
[[ ! -e $test_root/nouuid-out ]] || fail 'missing prerequisites must not create the run directory'

# Existing non-empty run directories are refused; a run that produces nothing leaves no directory behind.
reset
mkdir "$test_root/busy"; touch "$test_root/busy/file"
if run --refs t-one --out "$test_root/busy" > /dev/null 2>&1; then fail 'non-empty run directory must be refused'; fi
assert_eq "$(calls)" 0 'a refused run directory must not start snapshots'
export STUB_FAIL_REF=t-one
if run --refs t-one --out "$test_root/empty-fail" > /dev/null 2>&1; then fail 'failing sole ref must fail'; fi
[[ ! -e $test_root/empty-fail ]] || fail 'a run without results must not leave a run directory'

printf 'benchmark-run-refs tests passed\n'
