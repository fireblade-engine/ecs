#!/usr/bin/env bash
# Runs the shared benchmark compatibility suite against a list of committed git refs and stores one self-contained
# result file per ref in a single run directory. Every ref is built and measured in its own isolated snapshot by
# Scripts/benchmark-snapshot.sh --result; all refs use the same suite commit, filter and suite configuration.
#
# All refs are resolved once and validated before the first build, and the resolved full SHA (plus the requested name for
# provenance) is what the snapshot script receives, so a branch that moves mid-run cannot change what is measured.
# Prerequisites (jq, uuidgen, swift, a non-empty filter) are checked before the first build; the snapshot script also
# checks the host facts before it measures. A ref's result is staged under a hidden name inside the run directory and
# renamed into place only after the snapshot run succeeded and its provenance checks passed. If a ref fails, later refs
# are not started, results of already completed refs are kept, and the exit status is non-zero. A completed measurement
# whose result is rejected is never discarded: it is kept under <run dir>/.failed/ and its path is reported. All results
# of one invocation share a batch id. Differences in toolchain, host or benchmark set between results produce warnings.
#
# Replicates: with --replicates K > 1 every ref is prepared and built ONCE (snapshot --build-only), then K interleaved
# rounds run; each round runs every ref once, in an order shuffled deterministically from (seed, round). Each run is a fresh
# process of the prepared snapshot (snapshot --reuse), which re-checks provenance and pins and the host before measuring,
# and writes its own self-contained result <ref>-<sha12>.r<NN>.json carrying the replicate, round, position and seed. The seed
# is random unless --seed is given and is always printed. With K = 1 (the default) nothing changes: the refs run once each in
# the given order (no shuffle), the snapshot is built and run in one call, files are <ref>-<sha12>.json without replicate
# fields (a file without them counts as replicate 1 of 1). The first failure ends the run; finished results are kept.
# Report generation reads these files elsewhere.
set -euo pipefail

usage() {
    cat >&2 <<'USAGE'
Usage: Scripts/benchmark-run-refs.sh --refs <a,b,c> [options]

  --refs <list>       comma-separated committed refs (tags, branches or SHAs); at least one, no duplicates by SHA
  --filter <regex>    benchmark filter (default: the snapshot script's smallest-scale smoke selection)
  --suite-ref <rev>   commit providing the suite for every ref (default: HEAD)
  --out <dir>         run directory (must not exist or be empty; default: Benchmarks/.results/<UTC timestamp>)
  --repo <dir>        repository to read refs from (default: the repository containing this script)
  --replicates <k>    runs per ref (default: 1); with k > 1 refs are built once and run in k interleaved, shuffled rounds
  --seed <n>          shuffle seed, an integer 0..4294967295 (default: random; always printed and recorded for k > 1)

Environment: BENCHMARK_SNAPSHOT_SCRIPT overrides the snapshot script (used by tests).
USAGE
    exit 64
}

die() {
    printf 'benchmark-run-refs: %s\n' "$1" >&2
    exit 1
}

here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo=$(cd -- "$here/.." && pwd)
snapshot=${BENCHMARK_SNAPSHOT_SCRIPT:-$here/benchmark-snapshot.sh}
refs_arg=""
have_refs=0
suite_ref=HEAD
out=""
filter_args=()
filter_given=0
filter_text=""
replicates=1
seed=""

while (($#)); do
    case $1 in
        --refs) (($# >= 2)) || usage; refs_arg=$2; have_refs=1; shift 2 ;;
        --filter) (($# >= 2)) || usage; filter_args=(--filter "$2"); filter_given=1; filter_text=$2; shift 2 ;;
        --suite-ref) (($# >= 2)) || usage; suite_ref=$2; shift 2 ;;
        --out) (($# >= 2)) || usage; out=$2; shift 2 ;;
        --repo) (($# >= 2)) || usage; repo=$2; shift 2 ;;
        --replicates) (($# >= 2)) || usage; replicates=$2; shift 2 ;;
        --seed) (($# >= 2)) || usage; seed=$2; shift 2 ;;
        *) usage ;;
    esac
done
((have_refs)) || usage
for tool in jq uuidgen swift; do
    command -v "$tool" > /dev/null || die "$tool is required"
done
[[ $replicates =~ ^[1-9][0-9]{0,3}$ ]] || die "--replicates must be an integer from 1 to 9999, got '$replicates'"
if [[ -n $seed ]]; then
    [[ $seed =~ ^[0-9]{1,10}$ ]] && ((10#$seed <= 4294967295)) || die "--seed must be an integer from 0 to 4294967295, got '$seed'"
    seed=$((10#$seed))
else
    seed=$(((RANDOM << 15 | RANDOM) << 2 | RANDOM % 4))
fi
((!filter_given)) || [[ -n ${filter_text//[[:space:]]/} ]] || die "--filter is empty"

# --- Validate everything before any build ---------------------------------------------------------------------------
[[ -n $refs_arg ]] || die "--refs is empty"
[[ $refs_arg != ,* && $refs_arg != *, && $refs_arg != *,,* ]] || die "--refs contains an empty item: '$refs_arg'"
IFS=, read -r -a refs <<< "$refs_arg"

suite_sha=$(git -C "$repo" rev-parse --verify --quiet "$suite_ref^{commit}") || die "invalid suite ref: $suite_ref"

shas=()
errors=()
for ref in "${refs[@]}"; do
    if [[ -z ${ref//[[:space:]]/} ]]; then
        errors+=("empty ref item")
        shas+=("")
        continue
    fi
    if [[ $ref == WORKTREE ]]; then
        errors+=("WORKTREE is not supported; benchmark committed refs only")
        shas+=("")
        continue
    fi
    if ! sha=$(git -C "$repo" rev-parse --verify --quiet "$ref^{commit}"); then
        errors+=("invalid ref: $ref")
        shas+=("")
        continue
    fi
    for ((i = 0; i < ${#shas[@]}; i++)); do
        if [[ ${shas[i]} == "$sha" ]]; then
            errors+=("duplicate refs resolve to the same commit $sha: '${refs[i]}' and '$ref'")
        fi
    done
    shas+=("$sha")
done
if ((${#errors[@]})); then
    printf 'benchmark-run-refs: %s\n' "${errors[@]}" >&2
    exit 1
fi

if [[ -z $out ]]; then
    out="$repo/Benchmarks/.results/$(date -u +%Y%m%dT%H%M%SZ)"
elif [[ -e $out ]]; then
    [[ -d $out && -z $(ls -A "$out") ]] || die "run directory is not empty: $out"
fi
mkdir -p "$out"
out=$(cd "$out" && pwd)

scratch=$(mktemp -d "${TMPDIR:-/tmp}/benchmark-run-refs.XXXXXXXX")
cleanup() {
    rm -rf "$scratch"
    rm -f "$out"/.*.partial
    rmdir "$out" 2> /dev/null || true # an empty run directory is not a result
}
trap cleanup EXIT

batch_id=$(uuidgen)
failed_dir="$out/.failed"
# Keeps a rejected result: <staged file> <result name> -> prints the kept path on stderr.
keep_failed() {
    mkdir -p "$failed_dir"
    mv "$1" "$failed_dir/$2"
    printf 'benchmark-run-refs: the completed measurement was kept at %s\n' "$failed_dir/$2" >&2
}
# Differences between a result and the first one that make a comparison less trustworthy (warnings only).
fingerprint() { # <file> <part>
    case $2 in
        toolchain) jq -c '.toolchain' "$1" ;;
        host) jq -c '.host | del(.physicalMemoryBytes)' "$1" ;;
        set) jq -c '[(.benchmarks // [])[] | "\(.identity) / \(.scale)"] | unique' "$1" ;;
    esac
}

# Deterministic shuffle of 0..n-1 from (seed, round): a 31-bit LCG with a Fisher-Yates pass, plain bash integer arithmetic only
# (no $RANDOM, arrays are indexed, so bash 3.2 on macOS gives the same order as any other bash).
shuffle_order() { # <seed> <round> <n> -> indices, space separated
    local n=$3 m=2147483648 state i j t k
    local idx=()
    state=$(((($1 % m) * 7919 + $2 * 104729 + 12345) % m))
    for ((i = 0; i < n; i++)); do idx[i]=$i; done
    for ((k = 0; k < 4; k++)); do state=$(((state * 1103515245 + 12345) % m)); done
    for ((i = n - 1; i > 0; i--)); do
        state=$(((state * 1103515245 + 12345) % m))
        j=$(((state >> 8) % (i + 1)))
        t=${idx[i]}
        idx[i]=${idx[j]}
        idx[j]=$t
    done
    printf '%s\n' "${idx[*]}"
}

names=()
for ((i = 0; i < ${#refs[@]}; i++)); do
    names+=("$(printf '%s' "${refs[i]}" | tr -c 'A-Za-z0-9._\n-' '-')-${shas[i]:0:12}")
done
width=${#replicates}
((width >= 2)) || width=2

# --- Prepare and build every ref once (replicated runs only) ----------------------------------------------------------
if ((replicates > 1)); then
    printf 'benchmark-run-refs: %d replicates per ref, seed %s\n' "$replicates" "$seed" >&2
    for ((i = 0; i < ${#refs[@]}; i++)); do
        printf 'benchmark-run-refs: building [%d/%d] %s (%s)\n' "$((i + 1))" "${#refs[@]}" "${refs[i]}" "${shas[i]:0:12}" >&2
        "$snapshot" "${shas[i]}" --requested "${refs[i]}" --batch-id "$batch_id" --repo "$repo" --suite-ref "$suite_sha" --out "$scratch/snapshot-$i" --build-only ${filter_args[@]+"${filter_args[@]}"} >&2 \
            || die "building ref ${refs[i]} failed; nothing was measured"
    done
fi

# --- Run the rounds: every ref once per round --------------------------------------------------------------------------
results=()
config_hash=""
failed=0
for ((round = 1; round <= replicates && !failed; round++)); do
    if ((replicates > 1)); then
        order=$(shuffle_order "$seed" "$round" "${#refs[@]}")
    else
        order=$(seq -s ' ' 0 $((${#refs[@]} - 1)))
    fi
    position=0
    for i in $order; do
        position=$((position + 1))
        ref=${refs[i]}
        sha=${shas[i]}
        if ((replicates > 1)); then
            name="${names[i]}.r$(printf '%0*d' "$width" "$round").json"
            extra=(--reuse --replicate "$round" --replicates "$replicates" --round "$round" --position "$position" --seed "$seed")
            printf 'benchmark-run-refs: round %d/%d position %d/%d: %s (%s)\n' "$round" "$replicates" "$position" "${#refs[@]}" "$ref" "${sha:0:12}" >&2
        else
            name="${names[i]}.json"
            extra=()
            printf 'benchmark-run-refs: [%d/%d] %s (%s)\n' "$position" "${#refs[@]}" "$ref" "${sha:0:12}" >&2
        fi
        final="$out/$name"
        [[ ! -e $final ]] || die "result file already exists: $final"
        staged="$out/.$name.partial"

        if ! "$snapshot" "$sha" --requested "$ref" --batch-id "$batch_id" --repo "$repo" --suite-ref "$suite_sha" --out "$scratch/snapshot-$i" --result "$staged" ${extra[@]+"${extra[@]}"} ${filter_args[@]+"${filter_args[@]}"} >&2; then
            if ((replicates == 1)); then rm -rf "$scratch/snapshot-$i"; fi
            if [[ -f $staged ]]; then keep_failed "$staged" "$name"; fi
            printf 'benchmark-run-refs: ref %s failed%s; later runs were not started\n' "$ref" "$( ((replicates > 1)) && printf ' in round %d' "$round")" >&2
            failed=1
            break
        fi
        if ((replicates == 1)); then rm -rf "$scratch/snapshot-$i"; fi

        problem=""
        if [[ ! -f $staged ]]; then
            problem="the snapshot run wrote no result file"
        elif [[ $(jq -r '.ref.sha' "$staged") != "$sha" ]]; then
            problem="result records ref sha $(jq -r '.ref.sha' "$staged"), expected $sha"
        elif [[ $(jq -r '.suite.sha' "$staged") != "$suite_sha" ]]; then
            problem="result records suite sha $(jq -r '.suite.sha' "$staged"), expected $suite_sha"
        elif ((replicates > 1)) && [[ $(jq -c '.run.replicate // null | [.index, .count, .round, .position, .seed]' "$staged") != "[$round,$replicates,$round,$position,$seed]" ]]; then
            problem="result records replicate fields $(jq -c '.run.replicate' "$staged"), expected index $round of $replicates, round $round, position $position, seed $seed"
        else
            hash=$(jq -r '.suite.configurationHash' "$staged")
            if [[ -z $config_hash ]]; then
                config_hash=$hash
            elif [[ $hash != "$config_hash" ]]; then
                problem="configuration hash $hash differs from $config_hash of the first result"
            fi
        fi
        if [[ -n $problem ]]; then
            if [[ -f $staged ]]; then keep_failed "$staged" "$name"; fi
            printf 'benchmark-run-refs: ref %s failed: %s; later runs were not started\n' "$ref" "$problem" >&2
            failed=1
            break
        fi

        mv "$staged" "$final"
        if ((${#results[@]})); then
            for part in toolchain host set; do
                if [[ $(fingerprint "$final" "$part") != "$(fingerprint "${results[0]}" "$part")" ]]; then
                    printf 'benchmark-run-refs: warning: %s differs between %s and %s; their results may not be comparable\n' "$part" "$ref" "$(jq -r '.ref.requested' "${results[0]}")" >&2
                fi
            done
        fi
        results+=("$final")
    done
done

if ((${#results[@]})); then
    # Replicated runs execute in shuffled order; list them sorted by ref, then replicate (the file names sort that way).
    if ((replicates > 1)); then
        printf '%s\n' "${results[@]}" | LC_ALL=C sort | sed 's/^/result: /'
    else
        printf 'result: %s\n' "${results[@]}"
    fi
fi
((${#results[@]} == ${#refs[@]} * replicates)) || exit 1
