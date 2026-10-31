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
repo="" suite="" out="" result="" requested="" batch="" build=0 reuse=0 rep="" reps="" round="" position="" seed=""
while (($#)); do
    case $1 in
        --build-only) build=1 ;;
        --reuse) reuse=1 ;;
        --replicate) rep=$2 ;;
        --replicates) reps=$2 ;;
        --round) round=$2 ;;
        --position) position=$2 ;;
        --seed) seed=$2 ;;
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
if ((build)); then
    [[ ${STUB_FAIL_BUILD_REF:-} != "$requested" ]] || exit 9
    mkdir "$out"
    exit 0
fi
if ((reuse)); then
    [[ -d $out ]] || { echo "stub: --reuse of an unprepared snapshot" >&2; exit 8; }
    [[ -z ${STUB_FAIL_AT:-} || ${STUB_FAIL_AT} != "$requested:$round" ]] || exit 7
else
    mkdir "$out"
fi
[[ ${STUB_FAIL_REF:-} != "$requested" ]] || exit 7
hash=HASH
[[ ${STUB_SKEW_REF:-} != "$requested" ]] || hash=OTHER
swift_version="swift 6"
[[ ${STUB_TOOLCHAIN_REF:-} != "$requested" ]] || swift_version="swift 7"
sha=$(git -C "$repo" rev-parse "$ref^{commit}")
[[ ${STUB_WRONG_SHA_REF:-} != "$requested" ]] || sha=$(printf 'e%.0s' {1..40})
replicate=null
[[ -z $rep ]] || replicate=$(jq -n --argjson i "$rep" --argjson c "$reps" --argjson r "$round" --argjson p "$position" --argjson s "$seed" \
    '{index: $i, count: $c, round: $r, position: $p, seed: $s}')
[[ ${STUB_BAD_REPLICATE_REF:-} != "$requested" ]] || replicate=$(jq -n '{index: 1, count: 1, round: 1, position: 1, seed: 0}')
jq -n --argjson rp "$replicate" --arg r "$sha" --arg s "$suite" --arg h "$hash" --arg b "$batch" --arg v "$swift_version" --arg q "$requested" \
    '{run: ({batchId: $b} + (if $rp == null then {} else {replicate: $rp} end)), ref: {requested: $q, sha: $r}, suite: {sha: $s, configurationHash: $h}, toolchain: {swiftVersion: $v},
      host: {cpuModel: "cpu", physicalMemoryBytes: 1}, benchmarks: [{identity: "w", scale: 16}]}' > "$result"
STUB
chmod +x "$stub"
export BENCHMARK_SNAPSHOT_SCRIPT="$stub" STUB_LOG="$test_root/calls.log"

run() { "$script" --repo "$fixture" "$@"; }
calls() { if [[ -f $STUB_LOG ]]; then wc -l < "$STUB_LOG" | tr -d ' '; else echo 0; fi; }
reset() { rm -f "$STUB_LOG"; unset STUB_FAIL_BUILD_REF STUB_FAIL_AT STUB_BAD_REPLICATE_REF STUB_FAIL_REF STUB_SKEW_REF STUB_TOOLCHAIN_REF STUB_WRONG_SHA_REF STUB_MOVE_ONCE; }

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

GOLDEN_ORDERS=' t-two t-three t-one| t-three t-two t-one| t-three t-two t-one|'
# --- Replicates ---------------------------------------------------------------------------------------------------------
run_lines() { grep -- '--reuse' "$STUB_LOG" || true; }
build_lines() { grep -- '--build-only' "$STUB_LOG" || true; }
orders() { # prints one line per round: refs in execution order (by requested name)
    run_lines | sed -E 's/.*--requested ([^ ]+) .*--round ([0-9]+) .*/\2 \1/' | sort -n -s -k1,1 | awk '{a[$1]=a[$1] " " $2} END {for (r = 1; r in a; r++) print a[r]}'
}

for bad in '--replicates 0' '--replicates x' '--replicates 10000' '--seed -1' '--seed x' '--seed 4294967296'; do
    reset
    # shellcheck disable=SC2086
    if run --refs t-one,t-two $bad --out "$test_root/badrep" > /dev/null 2>&1; then fail "'$bad' must be rejected"; fi
    assert_eq "$(calls)" 0 "'$bad' must not start snapshots"
done

# Build once per ref, K interleaved rounds, every round runs every ref once, sorted file naming.
reset
out_rep="$test_root/rep"
stdout=$(run --refs "t-one,t-two,t-three" --replicates 4 --seed 42 --out "$out_rep" 2> "$test_root/rep.err")
assert_eq "$(build_lines | wc -l | tr -d ' ')" 3 'each ref is built exactly once'
assert_eq "$(run_lines | wc -l | tr -d ' ')" 12 'K runs per ref'
assert_eq "$(calls)" 15 'only builds and runs reach the snapshot script'
assert_eq "$(build_lines | grep -c -- '--result' || true)" 0 'builds never measure'
assert_eq "$(run_lines | grep -c -- '--build-only' || true)" 0 'runs never rebuild'
assert_eq "$(ls "$out_rep" | wc -l | tr -d ' ')" 12 'one result file per replicate and nothing else'
assert_eq "$(ls -A "$out_rep" | wc -l | tr -d ' ')" 12 'no staged or failed leftovers'
for n in one two three; do
    for r in 01 02 03 04; do
        [[ -f $out_rep/t-$n-$(sha_of "t-$n" | cut -c1-12).r$r.json ]] || fail "missing replicate $r of t-$n"
    done
done
assert_eq "$(grep -c '^result: ' <<< "$stdout")" 12 'stdout lists every replicate'
assert_eq "$(grep '^result: ' <<< "$stdout")" "$(grep '^result: ' <<< "$stdout" | LC_ALL=C sort)" 'result lines are sorted by ref, then replicate'
for n in one two three; do
    f="$out_rep/t-$n-$(sha_of "t-$n" | cut -c1-12).r03.json"
    assert_eq "$(jq -c '.run.replicate | [.index, .count, .round, .seed]' "$f")" '[3,4,3,42]' "replicate fields of t-$n r03"
done
assert_eq "$(jq -r '.run.batchId' "$out_rep"/*.json | sort -u | wc -l | tr -d ' ')" 1 'all replicates share one batch id'
assert_eq "$(jq -r '"\(.run.replicate.round) \(.run.replicate.position)"' "$out_rep"/*.json | sort | uniq | wc -l | tr -d ' ')" 12 'every (round, position) slot is used once for 3 refs and 4 rounds'
grep -q 'seed 42' "$test_root/rep.err" || fail 'the seed must be reported'
# Interleaved: no ref runs a second time before every ref ran in the round, and builds precede all runs.
first_run=$(grep -n -- '--reuse' "$STUB_LOG" | head -1 | cut -d: -f1)
assert_eq "$(head -n $((first_run - 1)) "$STUB_LOG" | grep -c -- '--build-only')" 3 'all builds precede the first run'
per_round=$(orders)
assert_eq "$(wc -l <<< "$per_round" | tr -d ' ')" 4 'four rounds'
while read -r line; do
    assert_eq "$(tr ' ' '\n' <<< "$line" | sort | tr '\n' ' ')" 't-one t-three t-two ' "round '$line' must run every ref exactly once"
done <<< "$per_round"
# Round order in the log is contiguous: rounds are not mixed.
assert_eq "$(run_lines | sed -E 's/.*--round ([0-9]+) .*/\1/' | tr '\n' ' ')" '1 1 1 2 2 2 3 3 3 4 4 4 ' 'rounds run one after another'
# The recorded position matches the execution order within the round.
assert_eq "$(run_lines | sed -E 's/.*--position ([0-9]+) .*/\1/' | tr '\n' ' ')" '1 2 3 1 2 3 1 2 3 1 2 3 ' 'positions count within each round'

# Same seed gives the same order; different seeds give different orders somewhere.
reset
run --refs "t-one,t-two,t-three" --replicates 12 --seed 42 --out "$test_root/rep-a" > /dev/null 2>&1
orders_a=$(orders)
reset
run --refs "t-one,t-two,t-three" --replicates 12 --seed 42 --out "$test_root/rep-b" > /dev/null 2>&1
assert_eq "$(orders)" "$orders_a" 'the same seed must give the same order'
reset
run --refs "t-one,t-two,t-three" --replicates 12 --seed 43 --out "$test_root/rep-c" > /dev/null 2>&1
[[ $(orders) != "$orders_a" ]] || fail 'a different seed must change the order somewhere'
[[ $(sort -u <<< "$orders_a" | wc -l | tr -d ' ') -gt 1 ]] || fail 'rounds must not all use the same order'
# Golden orders pin the shuffle across bash versions (macOS ships bash 3.2).
assert_eq "$(head -3 <<< "$orders_a" | tr '\n' '|')" "$GOLDEN_ORDERS" 'shuffle must be identical on every bash'
if [[ -x /bin/bash ]]; then
    reset
    /bin/bash "$script" --repo "$fixture" --refs "t-one,t-two,t-three" --replicates 12 --seed 42 --out "$test_root/rep-d" > /dev/null 2>&1
    assert_eq "$(orders)" "$orders_a" '/bin/bash must give the same order'
fi

# Without --seed a seed is chosen, reported, recorded in every file, and reusable to reproduce the order.
reset
run --refs "t-one,t-two" --replicates 2 --out "$test_root/rep-r" > /dev/null 2> "$test_root/rep-r.err"
rseed=$(jq -r '.run.replicate.seed' "$test_root"/rep-r/*.json | sort -u)
[[ $rseed =~ ^[0-9]+$ ]] || fail "a random seed must be recorded (got '$rseed')"
grep -q "seed $rseed" "$test_root/rep-r.err" || fail 'the random seed must be reported'

# K = 1 stays backward compatible: given order, one call per ref, old file names, no replicate fields, no builds.
reset
out_k1="$test_root/k1"
run --refs "t-one,t-two,t-three" --replicates 1 --seed 5 --out "$out_k1" > /dev/null 2>&1
assert_eq "$(calls)" 3 'K=1 uses one snapshot call per ref'
assert_eq "$(build_lines | wc -l | tr -d ' ')" 0 'K=1 does not split build and run'
assert_eq "$(sed -E 's/^[0-9a-f]+ --requested ([^ ]+) .*/\1/' "$STUB_LOG" | tr '\n' ' ')" 't-one t-two t-three ' 'K=1 keeps the given order'
assert_eq "$(ls "$out_k1" | wc -l | tr -d ' ')" 3 'K=1 writes one file per ref'
[[ -f $out_k1/t-two-$(sha_of t-two | cut -c1-12).json ]] || fail 'K=1 keeps the old file names'
assert_eq "$(jq -r '.run | has("replicate")' "$out_k1"/*.json | sort -u)" false 'K=1 writes no replicate fields'

# A failure mid-round keeps the completed replicates and stops everything else.
reset
export STUB_FAIL_AT=t-two:3
out_mid="$test_root/mid"
if run --refs "t-one,t-two,t-three" --replicates 4 --seed 42 --out "$out_mid" > /dev/null 2> "$test_root/mid.err"; then fail 'a failing replicate must fail the run'; fi
grep -q 't-two failed in round 3' "$test_root/mid.err" || fail 'the failing ref and round must be reported'
# Rounds 1 and 2 completed (6 files); round 3 stopped at t-two, so the refs ordered before it in the shuffle have a round-3 file.
done_round3=$(ls "$out_mid" | grep -c '\.r03\.json' || true)
assert_eq "$(ls "$out_mid" | grep -c -e '\.r01\.json' -e '\.r02\.json')" 6 'completed rounds are kept'
assert_eq "$(ls "$out_mid" | grep -c '\.r04\.json' || true)" 0 'later rounds never start'
assert_eq "$(run_lines | grep -c -- '--round 3 ')" $((done_round3 + 1)) 'the run stops at the failing replicate'
assert_eq "$(ls -A "$out_mid" | grep -c partial || true)" 0 'no staged file may remain'
[[ ! -e $out_mid/t-two-$(sha_of t-two | cut -c1-12).r03.json ]] || fail 'the failed replicate has no result'

# A build failure stops before any measurement.
reset
export STUB_FAIL_BUILD_REF=t-two
if run --refs "t-one,t-two" --replicates 2 --seed 1 --out "$test_root/buildfail" > /dev/null 2> "$test_root/buildfail.err"; then fail 'a failing build must fail the run'; fi
assert_eq "$(run_lines | wc -l | tr -d ' ')" 0 'nothing is measured when a build fails'
[[ ! -e $test_root/buildfail ]] || fail 'a run without results must not leave a run directory'

# Replicate fields that differ from the request are rejected and kept.
reset
export STUB_BAD_REPLICATE_REF=t-one
if run --refs "t-one,t-two" --replicates 2 --seed 9 --out "$test_root/badrp" > /dev/null 2> "$test_root/badrp.err"; then fail 'wrong replicate fields must fail the run'; fi
grep -q 'replicate fields' "$test_root/badrp.err" || fail 'wrong replicate fields must be reported'
assert_eq "$(ls "$test_root/badrp/.failed" | wc -l | tr -d ' ')" 1 'the rejected replicate is kept under .failed'

printf 'benchmark-run-refs tests passed\n'

