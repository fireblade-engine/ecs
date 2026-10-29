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

# Stub snapshot: logs every invocation, writes a minimal result, can fail for one ref, can skew the config hash.
stub="$test_root/snapshot-stub.sh"
cat > "$stub" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
ref=$1; shift
echo "$ref $*" >> "$STUB_LOG"
[[ ${STUB_FAIL_REF:-} != "$ref" ]] || exit 7
repo="" suite="" out="" result=""
while (($#)); do
    case $1 in
        --repo) repo=$2 ;;
        --suite-ref) suite=$2 ;;
        --out) out=$2 ;;
        --result) result=$2 ;;
    esac
    shift
done
mkdir "$out"
hash=HASH
[[ ${STUB_SKEW_REF:-} != "$ref" ]] || hash=OTHER
jq -n --arg r "$(git -C "$repo" rev-parse "$ref^{commit}")" --arg s "$suite" --arg h "$hash" \
    '{ref: {sha: $r}, suite: {sha: $s, configurationHash: $h}}' > "$result"
STUB
chmod +x "$stub"
export BENCHMARK_SNAPSHOT_SCRIPT="$stub" STUB_LOG="$test_root/calls.log"

run() { "$script" --repo "$fixture" "$@"; }
calls() { if [[ -f $STUB_LOG ]]; then wc -l < "$STUB_LOG" | tr -d ' '; else echo 0; fi; }
reset() { rm -f "$STUB_LOG"; unset STUB_FAIL_REF STUB_SKEW_REF; }

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
assert_eq "$(sed -E 's/.*--out ([^ ]+) .*/\1/' "$STUB_LOG" | sort -u | wc -l | tr -d ' ')" 3 'each ref needs its own snapshot directory'
assert_eq "$(grep -c -- "--suite-ref $(sha_of t-three) " "$STUB_LOG")" 3 'every ref uses the same resolved suite SHA'
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
assert_eq "$(calls)" 2 'ref 3 must not start after a hash mismatch'

# Existing non-empty run directories are refused; a run that produces nothing leaves no directory behind.
reset
mkdir "$test_root/busy"; touch "$test_root/busy/file"
if run --refs t-one --out "$test_root/busy" > /dev/null 2>&1; then fail 'non-empty run directory must be refused'; fi
assert_eq "$(calls)" 0 'a refused run directory must not start snapshots'
export STUB_FAIL_REF=t-one
if run --refs t-one --out "$test_root/empty-fail" > /dev/null 2>&1; then fail 'failing sole ref must fail'; fi
[[ ! -e $test_root/empty-fail ]] || fail 'a run without results must not leave a run directory'

printf 'benchmark-run-refs tests passed\n'
