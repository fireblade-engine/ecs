#!/usr/bin/env bash
# Builds (and optionally runs) the shared benchmark compatibility suite against one committed git ref.
#
# Snapshot contract: `git archive` the ref, replace its Benchmarks/ directory with the suite from one clean suite
# commit, keep the library directory named `ecs` (the suite's path dependency is resolved by directory name), and
# resolve with the committed Benchmarks/Package.resolved using --force-resolved-versions.
#
# One ref per invocation. This is not the multi-ref runner: it writes no result schema and no report.
set -euo pipefail

usage() {
    cat >&2 <<'USAGE'
Usage: Scripts/benchmark-snapshot.sh <ref> [options]

  --suite-ref <rev>   commit providing the suite (default: HEAD); suite paths in the worktree must be clean
  --out <dir>         snapshot directory (must not exist or be empty; default: new temporary directory)
  --filter <regex>    benchmark filter passed to the Benchmark plugin (default: smallest scale of entity.create.empty)
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
filter='^entity\.create\.empty .* / 16$'
mode=run

while (($#)); do
    case $1 in
        --suite-ref) (($# >= 2)) || usage; suite_ref=$2; shift 2 ;;
        --out) (($# >= 2)) || usage; out=$2; shift 2 ;;
        --filter) (($# >= 2)) || usage; filter=$2; shift 2 ;;
        --repo) (($# >= 2)) || usage; repo=$2; shift 2 ;;
        --prepare-only) mode=prepare; shift ;;
        --build-only) mode=build; shift ;;
        -h | --help) usage ;;
        -*) usage ;;
        *) [[ -z $ref ]] || usage; ref=$1; shift ;;
    esac
done
[[ -n $ref ]] || usage

git_repo() { git -C "$repo" "$@"; }

ref_sha=$(git_repo rev-parse --verify --quiet "$ref^{commit}") || die "invalid ref: $ref"
suite_sha=$(git_repo rev-parse --verify --quiet "$suite_ref^{commit}") || die "invalid suite ref: $suite_ref"

# The suite is everything under Benchmarks/ except the retired preliminary harness.
suite_dirty=$(git_repo status --porcelain --untracked-files=all -- Benchmarks ':(exclude)Benchmarks/ComparisonHarness' ':(exclude)Benchmarks/graft')
[[ -z $suite_dirty ]] || die "suite paths are dirty; commit or discard first:
$suite_dirty"

git_repo cat-file -e "$suite_sha:Benchmarks/Package.resolved" 2>/dev/null || die "suite commit $suite_sha has no Benchmarks/Package.resolved"

if [[ -z $out ]]; then
    out=$(mktemp -d "${TMPDIR:-/tmp}/benchmark-snapshot.XXXXXXXX")
elif [[ -e $out ]]; then
    [[ -d $out && -z $(ls -A "$out") ]] || die "output directory is not empty: $out"
fi
mkdir -p "$out"
out=$(cd "$out" && pwd)
lib="$out/ecs"
mkdir "$lib"

git_repo archive "$ref_sha" | tar -x -C "$lib"
rm -rf "$lib/Benchmarks"
git_repo archive "$suite_sha" Benchmarks | tar -x -C "$lib"
rm -rf "$lib/Benchmarks/ComparisonHarness" "$lib/Benchmarks/graft"

component_file="$lib/Sources/FirebladeECS/Component.swift"
[[ -f $component_file ]] || die "snapshot of $ref has no Sources/FirebladeECS/Component.swift"
if grep -Eq 'protocol[[:space:]]+Component[[:space:]]*:[[:space:]]*AnyObject' "$component_file"; then
    component_model=class
    swift_flags=(-Xswiftc -DECS_CLASS_COMPONENTS)
else
    component_model=value
    swift_flags=()
fi

write_provenance() {
    local resolved="$lib/Benchmarks/Package.resolved"
    local benchmark_version="" hdr_version=""
    if [[ -f $resolved ]] && command -v jq > /dev/null; then
        benchmark_version=$(jq -r '[.pins[] | select(.identity == "benchmark")][0].state | "\(.version // "none") \(.revision)"' "$resolved")
        hdr_version=$(jq -r '[.pins[] | select(.identity == "hdrhistogram-swift")][0].state | "\(.version // "none") \(.revision)"' "$resolved")
    fi
    cat > "$out/provenance.txt" <<NOTE
ref: $ref
ref_sha: $ref_sha
suite_sha: $suite_sha
component_model: $component_model
swift_flags: ${swift_flags[*]:-none}
benchmark: ${benchmark_version:-unknown}
hdrhistogram-swift: ${hdr_version:-unknown}
NOTE
}

write_provenance
printf 'snapshot: %s\n' "$out"

[[ $mode != prepare ]] || exit 0

cd "$lib/Benchmarks"
export ECS_BENCHMARK_SUITE=shared
swift package resolve --force-resolved-versions
write_provenance
swift build -c release --product ECSCompatBenchmark --force-resolved-versions ${swift_flags[@]+"${swift_flags[@]}"}

[[ $mode != build ]] || exit 0

# Package options must precede the plugin command; the resolved file was already enforced above.
swift package --disable-automatic-resolution ${swift_flags[@]+"${swift_flags[@]}"} --allow-writing-to-package-directory \
    benchmark --target ECSCompatBenchmark --filter "$filter" --no-progress
