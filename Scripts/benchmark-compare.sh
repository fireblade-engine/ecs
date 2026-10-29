#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd -- "$script_dir/.." && pwd)
source "$script_dir/benchmark-compare-lib.sh"

usage() {
    cat <<'EOF'
Usage: benchmark-compare.sh <baseline-ref> [candidate-ref] [repetitions] [filter-regex]

Compare Git refs using the same benchmark harness. Use candidate ref WORKTREE
to compare supported local tracked and untracked source edits against a commit.
Dirty or ignored source inputs and commits containing submodules are rejected.

The baseline ref is required. Defaults: candidate HEAD, 3 independent process
runs. Without a filter, every registered harness workload is measured.
EOF
}

if [[ ${1:-} == -h || ${1:-} == --help ]]; then
    usage
    exit 0
fi

baseline_ref=${1:-${BASELINE_REF:-}}
candidate_ref=${2:-${CANDIDATE_REF:-HEAD}}
repetitions=${3:-${BENCHMARK_REPETITIONS:-3}}
filter=${4:-${BENCHMARK_FILTER:-}}

if [[ -z $baseline_ref ]]; then
    printf 'Error: baseline Git ref is required.\n' >&2
    usage >&2
    exit 2
fi
if [[ ! $repetitions =~ ^[1-9][0-9]*$ ]] || (( repetitions < 3 )); then
    printf 'Error: repetitions must be an integer of at least 3.\n' >&2
    exit 2
fi
if [[ $baseline_ref == WORKTREE ]]; then
    printf 'Error: WORKTREE is supported only as the candidate ref.\n' >&2
    exit 2
fi

baseline_sha=$(git -C "$repo_root" rev-parse --verify --end-of-options "${baseline_ref}^{commit}") || {
    printf 'Error: baseline ref does not resolve to a commit: %s\n' "$baseline_ref" >&2
    exit 2
}
if [[ $candidate_ref == WORKTREE ]]; then
    candidate_sha=$(git -C "$repo_root" rev-parse --verify --end-of-options 'HEAD^{commit}') || exit 2
else
    candidate_sha=$(git -C "$repo_root" rev-parse --verify --end-of-options "${candidate_ref}^{commit}") || {
        printf 'Error: candidate ref does not resolve to a commit: %s\n' "$candidate_ref" >&2
        exit 2
    }
fi

for ref_sha in "$baseline_sha" "$candidate_sha"; do
    if benchmark_ref_has_submodules "$repo_root" "$ref_sha"; then
        printf 'Error: Git archives omit submodule contents; comparison does not support refs containing submodules (%s).\n' "$ref_sha" >&2
        exit 2
    fi
done

if [[ $candidate_ref == WORKTREE ]]; then
    while IFS= read -r -d '' path; do
        if benchmark_has_source_input_path "$path"; then
            printf 'Error: WORKTREE cannot include ignored source input %s; unignore or remove it before comparing.\n' "$path" >&2
            exit 2
        fi
    done < <(git -C "$repo_root" ls-files --others --ignored --exclude-standard -z)
fi

swift_bin=${SWIFT_BIN:-swift}
if ! command -v "$swift_bin" >/dev/null 2>&1; then
    printf 'Error: Swift executable not found: %s\n' "$swift_bin" >&2
    exit 2
fi
if ! command -v jq >/dev/null 2>&1; then
    printf 'Error: jq is required to compare benchmark results.\n' >&2
    exit 2
fi

started_utc=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
stamp=$(date -u '+%Y%m%dT%H%M%SZ')
run_id="compare-$stamp-$$"
results_dir=${BENCHMARK_RESULTS_DIR:-"$repo_root/Benchmarks/results"}
case $results_dir in
    /*) ;;
    *) results_dir="$repo_root/$results_dir" ;;
esac
mkdir -p "$results_dir"
run_dir=$(mktemp -d "$results_dir/$run_id.XXXXXX")
run_id=${run_dir##*/}
report_relpath=$run_dir
case $run_dir in
    "$repo_root"/*) report_relpath=${run_dir#"$repo_root/"} ;;
esac

working_tree_status=$(benchmark_git_status "$repo_root")
printf '%s\n' "$working_tree_status" > "$run_dir/working-tree-status.txt"
if [[ -n $working_tree_status ]]; then
    printf 'Note: local changes are present; committed refs exclude them. Use candidate WORKTREE to include an isolated snapshot.\n' >&2
fi

temp_root=$(mktemp -d "${TMPDIR:-/private/var/folders/mw/80xhvtrx6g7dwgn3qhr45f8c0000gn/T/opencode}/fireblade-ecs-compare.XXXXXXXX")
if git -C "$temp_root" rev-parse --show-toplevel >/dev/null 2>&1; then
    printf 'Error: temporary source snapshots must be outside every Git repository.\n' >&2
    rm -rf "$temp_root"
    exit 2
fi
cleanup() {
    local status=$?
    if [[ -n ${run_dir:-} && $status -ne 0 ]]; then
        rm -f "$run_dir/REPORT.md.tmp"
    fi
    if [[ -n ${temp_root:-} ]]; then
        rm -rf "$temp_root"
    fi
    return "$status"
}
trap cleanup EXIT

benchmark_extract_ref() {
    local sha=$1
    local destination=$2
    mkdir -p "$destination"
    git -C "$repo_root" archive "$sha" | tar -x -C "$destination"
}

benchmark_extract_worktree() {
    local destination=$1
    local staging="$temp_root/candidate-source"
    local path patch_file parent
    mkdir -p "$staging"
    git -C "$repo_root" archive "$candidate_sha" | tar -x -C "$staging"
    patch_file="$run_dir/working-tree.patch"
    git -C "$repo_root" diff --binary HEAD > "$patch_file"
    if [[ -s $patch_file ]]; then
        git -C "$staging" apply --binary "$patch_file"
    fi
    while IFS= read -r -d '' path; do
        if benchmark_has_source_input_path "$path"; then
            parent=${path%/*}
            [[ $parent == "$path" ]] && parent=.
            mkdir -p "$staging/$parent"
            cp -p "$repo_root/$path" "$staging/$path"
        fi
    done < <(git -C "$repo_root" ls-files --others --exclude-standard -z)
    mv "$staging" "$destination"
}

baseline_source="$temp_root/baseline-source"
benchmark_extract_ref "$baseline_sha" "$baseline_source"
if [[ $candidate_ref == WORKTREE ]]; then
    candidate_source="$run_dir/source-candidate"
    benchmark_extract_worktree "$candidate_source"
else
    candidate_source="$temp_root/candidate-source"
    benchmark_extract_ref "$candidate_sha" "$candidate_source"
fi

benchmark_validate_harness() {
    local sha=$1
    local source=$2
    local component_model storage_api

    component_model=$(benchmark_component_model "$source") || return 1
    if ! benchmark_check_harness_compatibility "$source"; then
        printf 'Error: revision %s is incompatible with the comparison harness.\n' "$sha" >&2
        return 1
    fi
    storage_api=$(benchmark_storage_capabilities "$source") || return 1

    benchmark_component_model=$component_model
    case $storage_api in
        modern)
            benchmark_has_modern=1
            benchmark_storage_capabilities='["archetype","sparseSet"]'
            benchmark_storage_status='engine declarations provide Nexus.StorageKind.archetype and sparseSet'
            ;;
        legacy)
            benchmark_has_modern=0
            benchmark_storage_capabilities='[]'
            benchmark_storage_status='Nexus.StorageKind is not declared by this revision'
            ;;
    esac
}

benchmark_snapshot_harness() {
    local destination=$1
    benchmark_reject_symlinks "$repo_root" Benchmarks/ComparisonHarness Benchmarks/Package.resolved || return 1
    mkdir -p "$destination/Benchmarks"
    cp -R "$repo_root/Benchmarks/ComparisonHarness" "$destination/Benchmarks/"
    cp "$repo_root/Benchmarks/Package.resolved" "$destination/Benchmarks/Package.resolved"
    benchmark_reject_symlinks "$destination" Benchmarks/ComparisonHarness Benchmarks/Package.resolved
}

benchmark_prepare_harness() {
    local source=$1
    local destination=$2
    mkdir -p "$destination/Benchmarks"
    cp "$source/Benchmarks/ComparisonHarness/Package.swift" "$destination/Package.swift"
    cp -R "$source/Benchmarks/ComparisonHarness/Sources/ECSComparisonHarness" "$destination/Benchmarks/"
    cp "$source/Benchmarks/Package.resolved" "$destination/Package.resolved"
    benchmark_reject_symlinks "$destination" Package.swift Benchmarks/ECSComparisonHarness Package.resolved || return 1
    cmp -s "$source/Benchmarks/ComparisonHarness/Package.swift" "$destination/Package.swift" \
        && cmp -s "$source/Benchmarks/Package.resolved" "$destination/Package.resolved" \
        && diff -qr "$source/Benchmarks/ComparisonHarness/Sources/ECSComparisonHarness" \
            "$destination/Benchmarks/ECSComparisonHarness" >/dev/null
}

baseline_harness="$run_dir/harness/baseline"
candidate_harness="$run_dir/harness/candidate"
harness_snapshot="$run_dir/harness/snapshot"
benchmark_snapshot_harness "$harness_snapshot"
harness_sha256=$(benchmark_harness_snapshot_hash "$harness_snapshot")
benchmark_prepare_harness "$harness_snapshot" "$baseline_harness"
benchmark_prepare_harness "$harness_snapshot" "$candidate_harness"

if ! benchmark_validate_harness "$baseline_sha" "$baseline_source"; then
    exit 1
fi
baseline_component_model=$benchmark_component_model
baseline_has_modern=$benchmark_has_modern
baseline_storage_capabilities=$benchmark_storage_capabilities
baseline_storage_status=$benchmark_storage_status
if ! benchmark_validate_harness "$candidate_sha" "$candidate_source"; then
    exit 1
fi
candidate_component_model=$benchmark_component_model
candidate_has_modern=$benchmark_has_modern
candidate_storage_capabilities=$benchmark_storage_capabilities
candidate_storage_status=$benchmark_storage_status

swift_version=$("$swift_bin" --version | tr '\n' ' ')
host=$(benchmark_host_description)
baseline_snapshot_sha256=$(benchmark_source_snapshot_hash "$baseline_source")
candidate_snapshot_sha256=$(benchmark_source_snapshot_hash "$candidate_source")

baseline_runs='[]'
candidate_runs='[]'
runs_metadata='[]'

benchmark_run_one() {
    local side=$1
    local repetition=$2
    local source=$3
    local harness=$4
    local sha=$5
    local component_model=$6
    local modern=$7
    local output_dir run_path raw_file parsed_file log_file err_file
    output_dir="$run_dir/runs/$side-$repetition/output"
    run_path="$run_dir/runs/$side-$repetition"
    raw_file="$output_dir/Current_run.jmh.json"
    parsed_file="$run_path/parsed.json"
    log_file="$run_path/stdout.log"
    err_file="$run_path/stderr.log"
    mkdir -p "$output_dir"

    local -a command_args
    command_args=(package --allow-writing-to-package-directory benchmark --format jmh --metric throughput --metric wallClock --benchmark-build-configuration release --no-progress --path "$output_dir")
    if [[ -n $filter ]]; then
        command_args+=(--filter "$filter")
    fi
    {
        printf 'FIREBLADE_ECS_SOURCE=%q FIREBLADE_ECS_COMPONENT_MODEL=%q FIREBLADE_ECS_HAS_MODERN_SUITE=%q ' \
            "$source" "$component_model" "$modern"
        printf '%q ' "$swift_bin" "${command_args[@]}"
        printf '\n'
    } > "$run_path/command.txt"

    printf '===> %s run %s/%s: %s at %s\n' "$side" "$repetition" "$repetitions" "$([[ -n $filter ]] && printf '%s' "$filter" || printf 'all workloads')" "$sha"
    if ! (
        cd "$harness"
        FIREBLADE_ECS_SOURCE="$source" \
        FIREBLADE_ECS_COMPONENT_MODEL="$component_model" \
        FIREBLADE_ECS_HAS_MODERN_SUITE="$modern" \
            "$swift_bin" "${command_args[@]}"
    ) > "$log_file" 2> "$err_file"; then
        printf 'Error: %s benchmark run %s failed; raw output follows (%s, %s):\n' "$side" "$repetition" "$log_file" "$err_file" >&2
        cat "$log_file" "$err_file" >&2
        return 1
    fi
    if [[ ! -s $raw_file ]]; then
        printf 'Error: expected non-empty JMH output at %s\n' "$raw_file" >&2
        return 1
    fi
    if ! benchmark_parse_jmh "$raw_file" > "$parsed_file"; then
        printf 'Error: invalid JMH output for %s run %s; see %s\n' "$side" "$repetition" "$raw_file" >&2
        return 1
    fi
    if [[ $side == baseline ]]; then
        baseline_runs=$(jq -cn --argjson runs "$baseline_runs" --slurpfile run "$parsed_file" '$runs + [$run[0]]')
    else
        candidate_runs=$(jq -cn --argjson runs "$candidate_runs" --slurpfile run "$parsed_file" '$runs + [$run[0]]')
    fi
    runs_metadata=$(jq -cn \
        --argjson runs "$runs_metadata" \
        --arg side "$side" \
        --argjson repetition "$repetition" \
        --arg sha "$sha" \
        --arg raw "${raw_file#"$run_dir/"}" \
        --arg parsed "${parsed_file#"$run_dir/"}" \
        --arg stdout "${log_file#"$run_dir/"}" \
        --arg stderr "${err_file#"$run_dir/"}" \
        '$runs + [{revision: $side, repetition: $repetition, sha: $sha, raw: $raw, parsed: $parsed, stdout: $stdout, stderr: $stderr}]')
}

for ((repetition = 1; repetition <= repetitions; repetition++)); do
    if (( repetition % 2 == 1 )); then
        order=(baseline candidate)
    else
        order=(candidate baseline)
    fi
    for side in "${order[@]}"; do
        if [[ $side == baseline ]]; then
            benchmark_run_one baseline "$repetition" "$baseline_source" "$baseline_harness" "$baseline_sha" \
                "$baseline_component_model" "$baseline_has_modern"
        else
            benchmark_run_one candidate "$repetition" "$candidate_source" "$candidate_harness" "$candidate_sha" \
                "$candidate_component_model" "$candidate_has_modern"
        fi
    done
done

current_baseline_snapshot_sha256=$(benchmark_source_snapshot_hash "$baseline_source")
current_candidate_snapshot_sha256=$(benchmark_source_snapshot_hash "$candidate_source")
current_harness_sha256=$(benchmark_harness_snapshot_hash "$harness_snapshot")
if [[ $current_baseline_snapshot_sha256 != "$baseline_snapshot_sha256" \
    || $current_candidate_snapshot_sha256 != "$candidate_snapshot_sha256" \
    || $current_harness_sha256 != "$harness_sha256" ]]; then
    printf 'Error: a source or harness snapshot changed during benchmark execution.\n' >&2
    exit 1
fi

samples=$(jq -cn --argjson baseline "$baseline_runs" --argjson candidate "$candidate_runs" '{baseline: $baseline, candidate: $candidate}')
comparison=$(benchmark_compare_samples "$samples")
printf '%s\n' "$samples" > "$run_dir/parsed-samples.json"
printf '%s\n' "$comparison" > "$run_dir/comparison.json"

working_tree_changes_excluded=false
working_tree_changes_included=false
if [[ $candidate_ref == WORKTREE ]]; then
    working_tree_changes_included=true
elif [[ -n $working_tree_status ]]; then
    working_tree_changes_excluded=true
fi
metadata=$(jq -n \
    --arg runID "$run_id" \
    --arg startedUTC "$started_utc" \
    --arg baselineRef "$baseline_ref" \
    --arg baselineSHA "$baseline_sha" \
    --arg candidateRef "$candidate_ref" \
    --arg candidateSHA "$candidate_sha" \
    --arg filter "$filter" \
    --arg host "$host" \
    --arg swiftVersion "$swift_version" \
    --arg harnessSHA256 "$harness_sha256" \
    --arg artifactPath "$report_relpath" \
    --argjson repetitions "$repetitions" \
    --argjson workingTreeChangesExcluded "$working_tree_changes_excluded" \
    --argjson workingTreeChangesIncluded "$working_tree_changes_included" \
    --argjson baselineModern "$baseline_has_modern" \
    --argjson candidateModern "$candidate_has_modern" \
    --arg baselineComponentModel "$baseline_component_model" \
    --arg candidateComponentModel "$candidate_component_model" \
    --argjson baselineStorageCapabilities "$baseline_storage_capabilities" \
    --argjson candidateStorageCapabilities "$candidate_storage_capabilities" \
    --arg baselineStorageStatus "$baseline_storage_status" \
    --arg candidateStorageStatus "$candidate_storage_status" \
    --arg baselineSnapshotSHA256 "$baseline_snapshot_sha256" \
    --arg candidateSnapshotSHA256 "$candidate_snapshot_sha256" \
    --argjson runs "$runs_metadata" \
    '{
        runID: $runID,
        startedUTC: $startedUTC,
        baseline: {ref: $baselineRef, sha: $baselineSHA, hasModernSuite: $baselineModern, storageCapabilities: $baselineStorageCapabilities, storageCapabilityStatus: $baselineStorageStatus, componentModel: $baselineComponentModel, sourceSnapshotSHA256: $baselineSnapshotSHA256},
        candidate: {ref: $candidateRef, sha: $candidateSHA, hasModernSuite: $candidateModern, storageCapabilities: $candidateStorageCapabilities, storageCapabilityStatus: $candidateStorageStatus, componentModel: $candidateComponentModel, sourceSnapshotSHA256: $candidateSnapshotSHA256},
        repetitions: $repetitions,
        filter: $filter,
        host: $host,
        swiftVersion: $swiftVersion,
        harnessSHA256: $harnessSHA256,
        artifactPath: $artifactPath,
        workingTreeChangesExcluded: $workingTreeChangesExcluded,
        workingTreeChangesIncluded: $workingTreeChangesIncluded,
        runs: $runs
    }')
printf '%s\n' "$metadata" > "$run_dir/metadata.json"

benchmark_render_report "$metadata" "$comparison" "$run_dir/REPORT.md.tmp"
mv -f "$run_dir/REPORT.md.tmp" "$run_dir/REPORT.md"
printf '===> Comparison report: %s/REPORT.md\n' "$run_dir"
