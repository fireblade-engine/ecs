#!/usr/bin/env bash
# Builds (and optionally runs) the shared benchmark compatibility suite against one committed git ref.
#
# Snapshot contract: extract the ref's committed tree (via a temporary index, so export-ignore/export-subst never apply), replace its Benchmarks/ directory with the suite from one clean suite
# commit, keep the library directory named `ecs` (the suite's path dependency is resolved by directory name), and
# resolve with the committed Benchmarks/Package.resolved using --force-resolved-versions.
#
# One ref per invocation. This is not the multi-ref runner. With --result it runs the suite once through
# `benchmark baseline update` and turns the native baseline into one self-contained result file via the snapshot's own
# ECSBenchmarkResults tool, so the file's workload manifest reflects that ref's adapter. It writes no report.
set -euo pipefail

usage() {
    cat >&2 <<'USAGE'
Usage: Scripts/benchmark-snapshot.sh <ref> [options]

  --suite-ref <rev>   commit providing the suite (default: HEAD); suite paths in the worktree must be clean
  --out <dir>         snapshot directory (must not exist or be empty; default: new temporary directory)
  --filter <regex>    benchmark filter passed to the Benchmark plugin (default: smallest scale of every compat workload)
  --result <path>     write a self-contained result file for the run (must not exist; needs a full run)
  --prepare-only      stop after writing the snapshot and provenance; do not resolve, build or run
  --build-only        resolve and build, but do not run
  --repo <dir>        repository to read refs from (default: the repository containing this script)
USAGE
    exit 64
}

die() {
    printf 'benchmark-snapshot: %s\n' "$1" >&2
    exit 1
}

repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
ref=""
suite_ref=HEAD
out=""
filter='^(entity\.create\.no-entities .* / 0|.* / 16)$'
mode=run
result=""

while (($#)); do
    case $1 in
        --suite-ref) (($# >= 2)) || usage; suite_ref=$2; shift 2 ;;
        --out) (($# >= 2)) || usage; out=$2; shift 2 ;;
        --filter) (($# >= 2)) || usage; filter=$2; shift 2 ;;
        --repo) (($# >= 2)) || usage; repo=$2; shift 2 ;;
        --result) (($# >= 2)) || usage; result=$2; shift 2 ;;
        --prepare-only) mode=prepare; shift ;;
        --build-only) mode=build; shift ;;
        -h | --help) usage ;;
        -*) usage ;;
        *) [[ -z $ref ]] || usage; ref=$1; shift ;;
    esac
done
[[ -n $ref ]] || usage
if [[ -n $result ]]; then
    [[ $mode == run ]] || die "--result needs a full run; it cannot be combined with --prepare-only or --build-only"
    [[ ! -e $result ]] || die "result file already exists: $result"
    [[ -d $(dirname -- "$result") ]] || die "result directory does not exist: $(dirname -- "$result")"
    result="$(cd "$(dirname -- "$result")" && pwd)/$(basename -- "$result")"
fi

command -v jq > /dev/null || die "jq is required (provenance and pins are read from Package.resolved)"

git_repo() { git -C "$repo" "$@"; }

ref_sha=$(git_repo rev-parse --verify --quiet "$ref^{commit}") || die "invalid ref: $ref"
suite_sha=$(git_repo rev-parse --verify --quiet "$suite_ref^{commit}") || die "invalid suite ref: $suite_ref"

# The suite is everything under Benchmarks/ except the retired preliminary harness. Only the checked-out HEAD can have
# a dirty worktree; any other suite ref is read from its committed tree, so the worktree state is irrelevant.
head_sha=$(git_repo rev-parse --verify --quiet 'HEAD^{commit}' || true)
if [[ $suite_sha == "$head_sha" ]]; then
    suite_dirty=$(git_repo status --porcelain --untracked-files=all -- Benchmarks ':(exclude)Benchmarks/ComparisonHarness' ':(exclude)Benchmarks/graft')
    [[ -z $suite_dirty ]] || die "suite paths are dirty; commit or discard first:
$suite_dirty"
fi

git_repo cat-file -e "$suite_sha:Benchmarks/Package.resolved" 2>/dev/null || die "suite commit $suite_sha has no Benchmarks/Package.resolved"

cleanup_dir=""
scratch=$(mktemp -d "${TMPDIR:-/tmp}/benchmark-snapshot-scratch.XXXXXXXX")
on_exit() {
    local status=$?
    rm -rf "$scratch"
    # A temporary snapshot is removed on failure; an explicit --out is the caller's to inspect.
    if ((status != 0)) && [[ -n $cleanup_dir ]]; then rm -rf "$cleanup_dir"; fi
    return "$status"
}
trap on_exit EXIT

if [[ -z $out ]]; then
    out=$(mktemp -d "${TMPDIR:-/tmp}/benchmark-snapshot.XXXXXXXX")
    cleanup_dir=$out
elif [[ -e $out ]]; then
    [[ -d $out && -z $(ls -A "$out") ]] || die "output directory is not empty: $out"
fi
mkdir -p "$out"
out=$(cd "$out" && pwd)
lib="$out/ecs"
mkdir "$lib"

# Extract committed trees through a throwaway index: unlike `git archive`, this ignores export-ignore/export-subst.
extract_tree() { # <sha> <dest> [pathspec]
    local index="$scratch/index.$1.$$"
    GIT_INDEX_FILE=$index git_repo read-tree "$1"
    GIT_INDEX_FILE=$index git_repo ls-files -z -- ${3:+"$3"} | GIT_INDEX_FILE=$index git_repo checkout-index -z --stdin --prefix="$2/"
    rm -f "$index"
}
extract_tree "$ref_sha" "$lib"
rm -rf "$lib/Benchmarks"
extract_tree "$suite_sha" "$lib" Benchmarks
rm -rf "$lib/Benchmarks/ComparisonHarness" "$lib/Benchmarks/graft"

component_file="$lib/Sources/FirebladeECS/Component.swift"
[[ -f $component_file ]] || die "snapshot of $ref has no Sources/FirebladeECS/Component.swift"
# Comments are stripped first so a mention of the class model in prose never selects it.
strip_comments() {
    awk '{
        line = $0; out = ""
        while (length(line) > 0) {
            if (inblock) {
                i = index(line, "*/")
                if (i == 0) { line = ""; break }
                line = substr(line, i + 2); inblock = 0
            } else {
                b = index(line, "/*"); l = index(line, "//")
                if (l > 0 && (b == 0 || l < b)) { out = out substr(line, 1, l - 1); line = ""; break }
                if (b == 0) { out = out line; line = ""; break }
                out = out substr(line, 1, b - 1); line = substr(line, b + 2); inblock = 1
            }
        }
        print out
    }' "$1"
}
if strip_comments "$component_file" | grep -Eq '(^|[[:space:]])protocol[[:space:]]+Component[[:space:]]*:[[:space:]]*([A-Za-z_]+[[:space:]]*,[[:space:]]*)*AnyObject([^A-Za-z0-9_]|$)'; then
    component_model=class
    swift_flags=(-Xswiftc -DECS_CLASS_COMPONENTS)
else
    component_model=value
    swift_flags=()
fi

write_provenance() {
    local resolved="$lib/Benchmarks/Package.resolved"
    {
        cat <<NOTE
ref: $ref
ref_sha: $ref_sha
suite_sha: $suite_sha
component_model: $component_model
swift_flags: ${swift_flags[*]:-none}
NOTE
        jq -r '.pins[] | "pin.\(.identity): \(.state.version // "none") \(.state.revision)"' "$resolved"
    } > "$out/provenance.txt.tmp"
    mv "$out/provenance.txt.tmp" "$out/provenance.txt"
}

cp "$lib/Benchmarks/Package.resolved" "$scratch/Package.resolved.committed"
write_provenance
printf 'snapshot: %s\n' "$out"

[[ $mode != prepare ]] || exit 0

cd "$lib/Benchmarks"
export ECS_BENCHMARK_SUITE=shared
swift package resolve --force-resolved-versions
cmp -s "$scratch/Package.resolved.committed" Package.resolved || die "resolving changed Package.resolved; commit the intended pins first"
write_provenance
swift build -c release --product ECSCompatBenchmark --force-resolved-versions ${swift_flags[@]+"${swift_flags[@]}"}

[[ $mode != build ]] || exit 0

# The filter must select something; an empty selection would otherwise "succeed" with no measurements.
matches=$(swift package --disable-automatic-resolution ${swift_flags[@]+"${swift_flags[@]}"} benchmark list --target ECSCompatBenchmark | grep -Ec -- "$filter" || true)
((matches > 0)) || die "filter matches no benchmarks: $filter"

# Package options must precede the plugin command; the resolved file was already enforced above.
if [[ -z $result ]]; then
    swift package --disable-automatic-resolution ${swift_flags[@]+"${swift_flags[@]}"} --allow-writing-to-package-directory \
        benchmark --target ECSCompatBenchmark --filter "$filter" --no-progress
    exit 0
fi

# Result mode: one run, stored as a uniquely named native baseline, then wrapped with this snapshot's provenance.
baseline_name="snapshot-${ref_sha:0:12}-$$-$RANDOM"
run_id=$(uuidgen)
timestamp() { date -u +%Y-%m-%dT%H:%M:%SZ; }
started=$(timestamp)
swift package --disable-automatic-resolution ${swift_flags[@]+"${swift_flags[@]}"} --allow-writing-to-package-directory \
    benchmark baseline update "$baseline_name" --target ECSCompatBenchmark --filter "$filter" --no-progress
finished=$(timestamp)
baseline_file=".benchmarkBaselines/ECSCompatBenchmark/$baseline_name/results.json"
[[ -f $baseline_file ]] || die "benchmark plugin wrote no baseline at $lib/Benchmarks/$baseline_file"

swift build -c release --product ECSBenchmarkResults --force-resolved-versions ${swift_flags[@]+"${swift_flags[@]}"}
bin_path=$(swift build -c release --show-bin-path ${swift_flags[@]+"${swift_flags[@]}"})
"$bin_path/ECSBenchmarkResults" write \
    --baseline "$baseline_file" --out "$result" --run-id "$run_id" --started "$started" --finished "$finished" \
    --ref "$ref" --ref-sha "$ref_sha" --suite-sha "$suite_sha" --filter "$filter" \
    --package-resolved Package.resolved --swift-version "$(swift --version 2>&1)"
printf 'result: %s\n' "$result"
