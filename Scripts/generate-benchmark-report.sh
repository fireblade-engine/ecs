#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd -- "$script_dir/.." && pwd)

usage() {
    printf 'Usage: %s <baseline-ref> <candidate-ref> [repetitions] [filter-regex] [--overwrite]\n' "${0##*/}"
    printf '       --overwrite may appear anywhere among the arguments.\n'
}

positional_args=()
positional_count=0
case ${BENCHMARK_REPORT_OVERWRITE:-0} in
    0) overwrite=0 ;;
    1) overwrite=1 ;;
    *) printf 'Error: BENCHMARK_REPORT_OVERWRITE must be 0 or 1.\n' >&2; exit 2 ;;
esac
for argument in "$@"; do
    if [[ $argument == --overwrite ]]; then
        overwrite=1
    else
        positional_args+=("$argument")
        positional_count=$((positional_count + 1))
    fi
done
if (( positional_count > 4 )); then
    usage >&2
    exit 2
fi
baseline_ref=${BASELINE_REF:-}
candidate_ref=${CANDIDATE_REF:-}
repetitions=${BENCHMARK_REPETITIONS:-3}
filter=${BENCHMARK_FILTER:-}
if (( positional_count > 0 )); then baseline_ref=${positional_args[0]:-$baseline_ref}; fi
if (( positional_count > 1 )); then candidate_ref=${positional_args[1]:-$candidate_ref}; fi
if (( positional_count > 2 )); then repetitions=${positional_args[2]:-$repetitions}; fi
if (( positional_count > 3 )); then filter=${positional_args[3]:-$filter}; fi

if [[ -z $baseline_ref || -z $candidate_ref ]]; then
    printf 'Error: explicit baseline and candidate Git refs are required.\n' >&2
    usage >&2
    exit 2
fi
if [[ ! $repetitions =~ ^[1-9][0-9]*$ ]] || (( repetitions < 3 )); then
    printf 'Error: repetitions must be an integer of at least 3.\n' >&2
    exit 2
fi
if ! resolved_baseline_sha=$(git -C "$repo_root" rev-parse --verify --end-of-options "${baseline_ref}^{commit}"); then
    printf 'Error: baseline ref does not resolve to a commit: %s\n' "$baseline_ref" >&2
    exit 2
fi
if [[ $candidate_ref == WORKTREE ]]; then
    if ! resolved_candidate_sha=$(git -C "$repo_root" rev-parse --verify --end-of-options 'HEAD^{commit}'); then
        printf 'Error: candidate WORKTREE has no resolvable HEAD commit.\n' >&2
        exit 2
    fi
elif ! resolved_candidate_sha=$(git -C "$repo_root" rev-parse --verify --end-of-options "${candidate_ref}^{commit}"); then
    printf 'Error: candidate ref does not resolve to a commit: %s\n' "$candidate_ref" >&2
    exit 2
fi

report_dir="$repo_root/Documentation/Benchmarks"
report_path="$report_dir/REPORT.md"
if [[ ! -d $report_dir ]]; then
    printf 'Error: benchmark report directory does not exist: %s\n' "$report_dir" >&2
    exit 1
fi
if [[ -L $report_path || ( -e $report_path && ! -f $report_path ) ]]; then
    printf 'Error: report destination must be a regular file, not a directory or symlink: %s\n' "$report_path" >&2
    exit 1
fi
if (( ! overwrite )) && [[ -e $report_path ]]; then
    printf 'Error: refusing to replace existing report without explicit opt-in: %s (pass --overwrite or set BENCHMARK_REPORT_OVERWRITE=1)\n' "$report_path" >&2
    exit 1
fi
report_initially_exists=0
report_initial_identity=
if [[ -e $report_path ]]; then
    report_initially_exists=1
    report_initial_identity=$(stat -f '%d:%i' "$report_path") || {
        printf 'Error: could not record the existing report identity: %s\n' "$report_path" >&2
        exit 1
    }
fi

if ! runner_output=$("$script_dir/benchmark-compare.sh" "$baseline_ref" "$candidate_ref" "$repetitions" "$filter"); then
    [[ -z $runner_output ]] || printf '%s\n' "$runner_output" >&2
    exit 1
fi
printf '%s\n' "$runner_output"

comparison_report=$(sed -n 's/^===> Comparison report: //p' <<<"$runner_output" | tail -n 1)
if [[ -z $comparison_report || ! -s $comparison_report ]]; then
    printf 'Error: comparison runner did not produce a complete report.\n' >&2
    exit 1
fi
case $comparison_report in
    */REPORT.md) ;;
    *) printf 'Error: comparison runner returned an invalid report path.\n' >&2; exit 1 ;;
esac
artifact_dir=${comparison_report%/REPORT.md}
metadata_path="$artifact_dir/metadata.json"
source "$script_dir/benchmark-compare-lib.sh"
if ! artifact_report_identity=$(benchmark_artifact_identity "$artifact_dir" REPORT.md) \
    || ! artifact_metadata_identity=$(benchmark_artifact_identity "$artifact_dir" metadata.json); then
    printf 'Error: comparison report or metadata failed artifact containment validation.\n' >&2
    exit 1
fi
if [[ $artifact_report_identity == "$artifact_metadata_identity" ]]; then
    printf 'Error: comparison report and metadata resolve to the same file.\n' >&2
    exit 1
fi
if ! metadata=$(jq -ce -s 'if length == 1 then .[0] else error("expected one metadata object") end' "$metadata_path"); then
    printf 'Error: comparison metadata is missing or invalid.\n' >&2
    exit 1
fi
if [[ ! -s $metadata_path ]] || ! jq -e \
    --arg baseline "$baseline_ref" \
    --arg candidate "$candidate_ref" \
    --arg baselineSHA "$resolved_baseline_sha" \
    --arg candidateSHA "$resolved_candidate_sha" \
    --arg filter "$filter" \
    --argjson repetitions "$repetitions" \
    '
        .runs as $runs
        | (.baseline.ref == $baseline)
        and (.candidate.ref == $candidate)
        and (.baseline.sha == $baselineSHA)
        and (.candidate.sha == $candidateSHA)
        and (.filter == $filter)
        and (.baseline.sha | (type == "string" and test("^([0-9a-f]{40}|[0-9a-f]{64})$")))
        and (.candidate.sha | (type == "string" and test("^([0-9a-f]{40}|[0-9a-f]{64})$")))
        and (.baseline.sourceSnapshotSHA256 | (type == "string" and test("^[0-9a-f]{64}$")))
        and (.candidate.sourceSnapshotSHA256 | (type == "string" and test("^[0-9a-f]{64}$")))
        and (.harnessSHA256 | (type == "string" and test("^[0-9a-f]{64}$")))
        and (.baseline.componentModel | (. == "reference" or . == "value"))
        and (.candidate.componentModel | (. == "reference" or . == "value"))
        and (.baseline.hasModernSuite | (type == "number" and (. == 0 or . == 1)))
        and (.candidate.hasModernSuite | (type == "number" and (. == 0 or . == 1)))
        and (.baseline.storageCapabilities | (type == "array" and all(.[]; . == "archetype" or . == "sparseSet")))
        and (.candidate.storageCapabilities | (type == "array" and all(.[]; . == "archetype" or . == "sparseSet")))
        and (.baseline.storageCapabilityStatus | (type == "string" and length > 0))
        and (.candidate.storageCapabilityStatus | (type == "string" and length > 0))
        and (.workingTreeChangesExcluded | type == "boolean")
        and (.workingTreeChangesIncluded | type == "boolean")
        and (.runID | (type == "string" and length > 0))
        and (.repetitions == $repetitions)
        and (.runs | type == "array")
        and (.runs | length == $repetitions * 2)
        and (.runs | all(.[]; ((.revision == "baseline") or (.revision == "candidate"))
            and (.repetition | (type == "number" and . >= 1 and . <= $repetitions and floor == .))
            and (.raw | (type == "string" and length > 0))
            and (.parsed | (type == "string" and length > 0))
            and (.stdout | (type == "string" and length > 0))
            and (.stderr | (type == "string" and length > 0))
            and ((.revision == "baseline" and .sha == $baselineSHA) or (.revision == "candidate" and .sha == $candidateSHA))))
        and ([.runs[] | "\(.revision):\(.repetition)"] | unique | length == $repetitions * 2)
        and ([.runs[] | [.raw, .parsed, .stdout, .stderr][]] | unique | length == $repetitions * 8)
        and all(range(1; $repetitions + 1);
            . as $repetition
            | ([$runs[] | select(.revision == "baseline" and .repetition == $repetition)] | length == 1)
            and ([$runs[] | select(.revision == "candidate" and .repetition == $repetition)] | length == 1))
        and (.startedUTC | (type == "string" and length > 0))
        and (.host | (type == "string" and length > 0))
        and (.swiftVersion | (type == "string" and length > 0))
        and (.artifactPath | (type == "string" and length > 0))
    ' <<<"$metadata" >/dev/null; then
    printf 'Error: comparison artifacts failed provenance validation.\n' >&2
    exit 1
fi
artifact_path="$artifact_dir"
case $artifact_dir in
    "$repo_root"/*) artifact_path=${artifact_dir#"$repo_root/"} ;;
esac
if ! jq -e --arg artifactPath "$artifact_path" '.artifactPath == $artifactPath' <<<"$metadata" >/dev/null; then
    printf 'Error: comparison artifact path does not match its metadata.\n' >&2
    exit 1
fi
run_records=$(jq -c '.runs | sort_by(.revision, .repetition)[]' <<<"$metadata") || {
    printf 'Error: comparison run metadata is invalid.\n' >&2
    exit 1
}

for retained_side in baseline candidate; do
    retained_relative="source-$retained_side"
    retained_path="$artifact_dir/$retained_relative"
    retained_required=0
    if [[ $retained_side == candidate ]] \
        && [[ $(jq -r '.workingTreeChangesIncluded' <<<"$metadata") == true ]]; then
        retained_required=1
    fi
    if [[ -e $retained_path || -L $retained_path ]]; then
        if ! retained_source=$(benchmark_artifact_directory "$artifact_dir" "$retained_relative"); then
            printf 'Error: retained %s source snapshot is unsafe.\n' "$retained_side" >&2
            exit 1
        fi
        if ! retained_hash=$(benchmark_source_snapshot_hash "$retained_source"); then
            printf 'Error: retained %s source snapshot failed hashing.\n' "$retained_side" >&2
            exit 1
        fi
        expected_hash=$(jq -r --arg side "$retained_side" '.[$side].sourceSnapshotSHA256' <<<"$metadata")
        if [[ $retained_hash != "$expected_hash" ]]; then
            printf 'Error: retained %s source snapshot does not match its provenance hash.\n' "$retained_side" >&2
            exit 1
        fi
    elif (( retained_required )); then
        printf 'Error: candidate WORKTREE source snapshot is missing from the artifacts.\n' >&2
        exit 1
    fi
done

if ! retained_harness=$(benchmark_artifact_directory "$artifact_dir" harness/snapshot); then
    printf 'Error: retained shared harness snapshot is missing or unsafe.\n' >&2
    exit 1
fi
if ! retained_harness_hash=$(benchmark_harness_snapshot_hash "$retained_harness"); then
    printf 'Error: retained shared harness snapshot failed hashing.\n' >&2
    exit 1
fi
if [[ $retained_harness_hash != "$(jq -r '.harnessSHA256' <<<"$metadata")" ]]; then
    printf 'Error: retained shared harness snapshot does not match its provenance hash.\n' >&2
    exit 1
fi

baseline_runs='[]'
seen_artifact_identities="|$artifact_report_identity|$artifact_metadata_identity|"
candidate_runs='[]'
while IFS= read -r run_record; do
    for artifact_kind in raw parsed stdout stderr; do
        artifact_path=$(jq -r --arg kind "$artifact_kind" '.[$kind]' <<<"$run_record")
        case $artifact_path in
            ''|/*|.|./*|../*|*/./*|*/../*|*/.|*/..|*//*|*/|*\\*|*$'\n'*)
                printf 'Error: invalid artifact path in comparison metadata: %s\n' "$artifact_path" >&2
                exit 1
                ;;
        esac
        if ! artifact_identity=$(benchmark_artifact_identity "$artifact_dir" "$artifact_path"); then
            printf 'Error: comparison artifact failed containment validation: %s\n' "$artifact_path" >&2
            exit 1
        fi
        case $seen_artifact_identities in
            *"|$artifact_identity|"*)
                printf 'Error: comparison artifact aliases a different recorded path: %s\n' "$artifact_path" >&2
                exit 1
                ;;
        esac
        seen_artifact_identities+="$artifact_identity|"
        if [[ $artifact_kind == raw || $artifact_kind == parsed ]] && [[ ! -s "$artifact_dir/$artifact_path" ]]; then
            printf 'Error: comparison measurement artifact is empty: %s\n' "$artifact_path" >&2
            exit 1
        fi
    done
    raw_path=$(jq -r '.raw' <<<"$run_record")
    parsed_path=$(jq -r '.parsed' <<<"$run_record")
    if ! parsed_raw=$(benchmark_parse_jmh "$artifact_dir/$raw_path") \
        || ! parsed_saved=$(jq -ce -s 'if length == 1 then .[0] else error("expected one parsed result") end' "$artifact_dir/$parsed_path"); then
        printf 'Error: comparison JMH output failed validation: %s\n' "$raw_path" >&2
        exit 1
    fi
    if [[ $parsed_raw != "$parsed_saved" ]]; then
        printf 'Error: parsed samples do not match raw JMH output: %s\n' "$raw_path" >&2
        exit 1
    fi
    if [[ $(jq -r '.revision' <<<"$run_record") == baseline ]]; then
        baseline_runs=$(jq -cn --argjson runs "$baseline_runs" --argjson run "$parsed_saved" '$runs + [$run]')
    else
        candidate_runs=$(jq -cn --argjson runs "$candidate_runs" --argjson run "$parsed_saved" '$runs + [$run]')
    fi
done <<<"$run_records"
samples=$(jq -cn --argjson baseline "$baseline_runs" --argjson candidate "$candidate_runs" '{baseline: $baseline, candidate: $candidate}')
if ! comparison=$(benchmark_compare_samples "$samples"); then
    printf 'Error: validated run samples could not be compared.\n' >&2
    exit 1
fi

temporary_report=$(mktemp "$report_dir/.REPORT.md.XXXXXXXX")
trap 'rm -f "$temporary_report"' EXIT
if ! benchmark_render_report "$metadata" "$comparison" "$temporary_report"; then
    printf 'Error: could not render report from validated benchmark samples.\n' >&2
    exit 1
fi
if ! cmp -s "$temporary_report" "$comparison_report"; then
    printf 'Error: comparison report does not match its validated raw measurements and metadata.\n' >&2
    exit 1
fi
cat >> "$temporary_report" <<'EOF'

## Relation to package benchmarks and reference workloads

This report contains only measurements from the separate preliminary `ComparisonHarness`, identified by the workload names above. It does not measure or represent the package benchmarks in `Benchmarks/Benchmarks/ECSBenchmark` or claim to reproduce reference workloads.
EOF

if [[ -L $report_path || ( -e $report_path && ! -f $report_path ) ]]; then
    printf 'Error: report destination changed to a directory or non-regular file during generation: %s\n' "$report_path" >&2
    exit 1
fi
if (( report_initially_exists )); then
    if [[ ! -e $report_path ]] \
        || ! report_current_identity=$(stat -f '%d:%i' "$report_path") \
        || [[ $report_current_identity != "$report_initial_identity" ]]; then
        printf 'Error: report destination changed during generation; left it untouched: %s\n' "$report_path" >&2
        exit 1
    fi
    mode_source=$report_path
else
    if [[ -e $report_path || -L $report_path ]]; then
        printf 'Error: report destination appeared during generation; left it untouched: %s\n' "$report_path" >&2
        exit 1
    fi
    mode_source=$comparison_report
fi
if ! report_mode=$(stat -f '%Lp' "$mode_source"); then
    printf 'Error: could not read report permissions from %s\n' "$mode_source" >&2
    exit 1
fi
if ! chmod "$report_mode" "$temporary_report"; then
    printf 'Error: could not preserve report permissions (%s).\n' "$report_mode" >&2
    exit 1
fi

remove_misplaced_report() {
    local expected_identity=$1
    local misplaced_report="$report_path/${temporary_report##*/}"
    local misplaced_identity

    [[ -f $misplaced_report && ! -L $misplaced_report ]] || return 0
    misplaced_identity=$(stat -f '%d:%i' "$misplaced_report") || return 1
    [[ $misplaced_identity == "$expected_identity" ]] || return 0
    rm -f "$misplaced_report"
}

publication_identity=$(stat -f '%d:%i' "$temporary_report") || {
    printf 'Error: could not record the staged report identity.\n' >&2
    exit 1
}
if (( overwrite )); then
    if ! mv -f "$temporary_report" "$report_path"; then
        printf 'Error: could not publish the report at %s.\n' "$report_path" >&2
        exit 1
    fi
else
    if ! ln "$temporary_report" "$report_path"; then
        printf 'Error: report destination appeared during publication; left it untouched: %s\n' "$report_path" >&2
        exit 1
    fi
fi
if [[ -d $report_path ]]; then
    if ! remove_misplaced_report "$publication_identity"; then
        printf 'Error: could not remove the unpublished staged file from the raced directory: %s\n' "$report_path" >&2
        exit 1
    fi
    printf 'Error: report destination became a directory during publication; no report was published: %s\n' "$report_path" >&2
    exit 1
fi
if [[ -L $report_path || ! -f $report_path ]] \
    || ! published_identity=$(stat -f '%d:%i' "$report_path") \
    || [[ $published_identity != "$publication_identity" ]]; then
    printf 'Error: report destination changed during publication; no report was confirmed: %s\n' "$report_path" >&2
    exit 1
fi
if (( ! overwrite )); then
    rm -f "$temporary_report"
fi
temporary_report=
printf '===> Benchmark report atomically updated at %s\n' "$report_path"
printf 'Note: publication preserves POSIX mode bits only; ownership, ACLs, file flags, and extended attributes are not preserved.\n' >&2
