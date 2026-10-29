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

while (($#)); do
    case $1 in
        --refs) (($# >= 2)) || usage; refs_arg=$2; have_refs=1; shift 2 ;;
        --filter) (($# >= 2)) || usage; filter_args=(--filter "$2"); filter_given=1; filter_text=$2; shift 2 ;;
        --suite-ref) (($# >= 2)) || usage; suite_ref=$2; shift 2 ;;
        --out) (($# >= 2)) || usage; out=$2; shift 2 ;;
        --repo) (($# >= 2)) || usage; repo=$2; shift 2 ;;
        *) usage ;;
    esac
done
((have_refs)) || usage
for tool in jq uuidgen swift; do
    command -v "$tool" > /dev/null || die "$tool is required"
done
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

# --- Run one snapshot per ref ---------------------------------------------------------------------------------------
results=()
config_hash=""
for ((i = 0; i < ${#refs[@]}; i++)); do
    ref=${refs[i]}
    sha=${shas[i]}
    name="$(printf '%s' "$ref" | tr -c 'A-Za-z0-9._\n-' '-')-${sha:0:12}.json"
    final="$out/$name"
    [[ ! -e $final ]] || die "result file already exists: $final"
    staged="$out/.$name.partial"
    printf 'benchmark-run-refs: [%d/%d] %s (%s)\n' "$((i + 1))" "${#refs[@]}" "$ref" "${sha:0:12}" >&2

    if ! "$snapshot" "$sha" --requested "$ref" --batch-id "$batch_id" --repo "$repo" --suite-ref "$suite_sha" --out "$scratch/snapshot-$i" --result "$staged" ${filter_args[@]+"${filter_args[@]}"} >&2; then
        rm -rf "$scratch/snapshot-$i"
        if [[ -f $staged ]]; then keep_failed "$staged" "$name"; fi
        printf 'benchmark-run-refs: ref %s failed; later refs were not started\n' "$ref" >&2
        break
    fi
    rm -rf "$scratch/snapshot-$i"

    problem=""
    if [[ ! -f $staged ]]; then
        problem="the snapshot run wrote no result file"
    elif [[ $(jq -r '.ref.sha' "$staged") != "$sha" ]]; then
        problem="result records ref sha $(jq -r '.ref.sha' "$staged"), expected $sha"
    elif [[ $(jq -r '.suite.sha' "$staged") != "$suite_sha" ]]; then
        problem="result records suite sha $(jq -r '.suite.sha' "$staged"), expected $suite_sha"
    else
        hash=$(jq -r '.suite.configurationHash' "$staged")
        if [[ -z $config_hash ]]; then
            config_hash=$hash
        elif [[ $hash != "$config_hash" ]]; then
            problem="configuration hash $hash differs from $config_hash of the first ref"
        fi
    fi
    if [[ -n $problem ]]; then
        if [[ -f $staged ]]; then keep_failed "$staged" "$name"; fi
        printf 'benchmark-run-refs: ref %s failed: %s; later refs were not started\n' "$ref" "$problem" >&2
        break
    fi

    mv "$staged" "$final"
    if ((${#results[@]})); then
        for part in toolchain host set; do
            if [[ $(fingerprint "$final" "$part") != "$(fingerprint "${results[0]}" "$part")" ]]; then
                printf 'benchmark-run-refs: warning: %s differs between %s and %s; their results may not be comparable\n' "$part" "$ref" "${refs[0]}" >&2
            fi
        done
    fi
    results+=("$final")
done

if ((${#results[@]})); then
    printf 'result: %s\n' "${results[@]}"
fi
((${#results[@]} == ${#refs[@]})) || exit 1
