#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
source "$repo_root/Scripts/benchmark-compare-lib.sh"
test_root=$(mktemp -d "${TMPDIR:-/private/var/folders/mw/80xhvtrx6g7dwgn3qhr45f8c0000gn/T/opencode}/benchmark-compare-tests.XXXXXXXX")
trap 'rm -rf "$test_root"' EXIT

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

assert_eq() {
    [[ $1 == "$2" ]] || fail "$3 (expected '$2', got '$1')"
}

for path in Scripts/benchmark-compare.sh Scripts/benchmark-compare-lib.sh Scripts/generate-benchmark-report.sh Tests/benchmark-compare-tests.sh; do
    if git -C "$repo_root" check-ignore -q "$path"; then
        fail "$path must not be ignored"
    fi
done
grep -Fq 'path: "Benchmarks/ECSComparisonHarness"' "$repo_root/Benchmarks/ComparisonHarness/Package.swift" \
    || fail 'benchmark target source directory must have the required Benchmarks parent'
[[ ! -e $repo_root/Benchmarks/ComparisonHarness/Sources/ECSComparisonHarness/StorageCapabilityProbe.swift ]] \
    || fail 'compile-probe source must be removed'
! grep -q 'FIREBLADE_ECS_PROBE_STORAGE_API\|FIREBLADE_PROBE_STORAGE_API' \
    "$repo_root/Benchmarks/ComparisonHarness/Package.swift" "$repo_root/Scripts/benchmark-compare.sh" \
    || fail 'compile-probe package settings must be removed'
grep -Fq 'return Nexus(storage: .archetype)' \
    "$repo_root/Benchmarks/ComparisonHarness/Sources/ECSComparisonHarness/CommonBenchmarks.swift" \
    || fail 'modern common workloads must pin the archetype backend'
grep -Fq 'revisions without `Nexus.StorageKind` use their single built-in backend' \
    "$repo_root/Scripts/benchmark-compare-lib.sh" \
    || fail 'reports must disclose that legacy workloads are not guaranteed backend-equivalent'

selection_root="$test_root/capability-selection"
mkdir -p "$selection_root/reference/Sources/FirebladeECS" \
    "$selection_root/value/Sources/FirebladeECS" "$selection_root/modern/Sources/FirebladeECS" \
    "$selection_root/unknown/Sources/FirebladeECS"
printf 'public protocol Component: AnyObject, Sendable {}\n' > "$selection_root/reference/Sources/FirebladeECS/Component.swift"
printf 'public protocol Component: Sendable {}\n' > "$selection_root/value/Sources/FirebladeECS/Component.swift"
printf 'public protocol Component: Codable {}\n' > "$selection_root/unknown/Sources/FirebladeECS/Component.swift"
cat > "$selection_root/unknown/Sources/FirebladeECS/Storage.swift" <<'SWIFT'
public enum StorageKind {
    case archetype
}
SWIFT
printf 'public protocol Component: Sendable {}\n' > "$selection_root/modern/Sources/FirebladeECS/Component.swift"
cat > "$selection_root/modern/Sources/FirebladeECS/Storage.swift" <<'SWIFT'
extension Nexus {
    public enum StorageKind: CaseIterable, Sendable {
        case archetype
        case sparseSet
    }
}
SWIFT
assert_eq "$(benchmark_component_model "$selection_root/reference")" reference 'AnyObject Component protocol selects reference components'
assert_eq "$(benchmark_component_model "$selection_root/value")" value 'Sendable-only Component protocol selects value components'
assert_eq "$(benchmark_storage_capabilities "$selection_root/modern")" modern 'StorageKind declarations select modern workloads without benchmark sources'
[[ ! -e $selection_root/modern/Benchmarks ]] || fail 'modern capability fixture must not contain benchmark files'
if benchmark_component_model "$selection_root/unknown" > "$test_root/unknown-component.out" 2>&1; then
    fail 'unknown Component protocol models must fail instead of defaulting to value'
fi
grep -q 'unrecognized Component protocol model' "$test_root/unknown-component.out" \
    || fail 'unknown Component protocol failure should identify the unsupported model'
if benchmark_storage_capabilities "$selection_root/unknown" > "$test_root/unknown-storage.out" 2>&1; then
    fail 'an unrecognized StorageKind declaration must fail instead of assuming a capability'
fi
mkdir -p "$selection_root/incompatible/Sources/FirebladeECS"
printf 'public protocol Component: AnyObject, Sendable {}\n' > "$selection_root/incompatible/Sources/FirebladeECS/Component.swift"
if benchmark_check_harness_compatibility "$selection_root/incompatible" > "$test_root/incompatible.out" 2>&1; then
    fail 'an incompatible old ECS API must be rejected before harness execution'
fi
grep -q 'Nexus.createEntity().*Nexus.makeEntitiesIterator()' "$test_root/incompatible.out" \
    || fail 'incompatible API failure should name the missing harness requirements'
mkdir -p "$selection_root/compatible/Sources/FirebladeECS"
cat > "$selection_root/compatible/Sources/FirebladeECS/Nexus+Entity.swift" <<'SWIFT'
extension Nexus {
    public func createEntity() -> Entity
    public func makeEntitiesIterator() -> EntitiesIterator
}
SWIFT
benchmark_check_harness_compatibility "$selection_root/compatible" \
    || fail 'the current shared harness API should pass the compatibility check'

cat > "$test_root/mixed-units.jmh.json" <<'JSON'
[
  {"benchmark":"package.benchmark.ECSComparisonHarness.EntityIteration_/_1","secondaryMetrics":{"Time (wall clock)":{"scoreUnit":"ns","scorePercentiles":{"50.0":2500}}}},
  {"benchmark":"package.benchmark.ECSComparisonHarness.EntityIteration_/_2","secondaryMetrics":{"Time (wall clock)":{"scoreUnit":"μs","scorePercentiles":{"50.0":2.5}}}},
  {"benchmark":"package.benchmark.ECSComparisonHarness.EntityIteration_/_3","secondaryMetrics":{"Time (wall clock)":{"scoreUnit":"µs","scorePercentiles":{"50.0":2.5}}}},
  {"benchmark":"package.benchmark.ECSComparisonHarness.EntityIteration_/_4","secondaryMetrics":{"Time (wall clock)":{"scoreUnit":"ms","scorePercentiles":{"50.0":0.0025}}}},
  {"benchmark":"package.benchmark.ECSComparisonHarness.EntityIteration_/_5","secondaryMetrics":{"Time (wall clock)":{"scoreUnit":"s","scorePercentiles":{"50.0":0.0000025}}}}
]
JSON
parsed=$(benchmark_parse_jmh "$test_root/mixed-units.jmh.json")
assert_eq "$(jq '[.[].p50Nanoseconds] | unique | length' <<<"$parsed")" 1 'mixed units normalize to one nanosecond value'
assert_eq "$(jq -r '.[0].key' <<<"$parsed")" 'EntityIteration / 1' 'serialized JMH separator decodes to a stable workload name'
assert_eq "$(jq -r '.[0].p50Nanoseconds' <<<"$parsed")" 2500 'the actual JMH p50 is retained'

cat > "$test_root/malformed-identity.jmh.json" <<'JSON'
[
  {"benchmark":"package.benchmark.ECSComparisonHarness.Valid_/_64","secondaryMetrics":{"Time (wall clock)":{"scoreUnit":"ns","scorePercentiles":{"50.0":2500}}}},
  {"benchmark":"not-a-jmh-benchmark-name","secondaryMetrics":{"Time (wall clock)":{"scoreUnit":"ns","scorePercentiles":{"50.0":3000}}}}
]
JSON
if benchmark_parse_jmh "$test_root/malformed-identity.jmh.json" >/dev/null 2>&1; then
    fail 'a malformed identity beside a valid row must reject the complete JMH report'
fi
cat > "$test_root/missing-identity.jmh.json" <<'JSON'
[{"secondaryMetrics":{"Time (wall clock)":{"scoreUnit":"ns","scorePercentiles":{"50.0":2500}}}}]
JSON
if benchmark_parse_jmh "$test_root/missing-identity.jmh.json" >/dev/null 2>&1; then
    fail 'a missing benchmark identity must be rejected'
fi

cat > "$test_root/missing.jmh.json" <<'JSON'
[{"benchmark":"package.benchmark.ECSComparisonHarness.Missing_/_1","secondaryMetrics":{"Time (wall clock)":{"scoreUnit":"ns","scorePercentiles":{}}}}]
JSON
if benchmark_parse_jmh "$test_root/missing.jmh.json" >/dev/null 2>&1; then
    fail 'missing p50 should be rejected'
fi
cat > "$test_root/duplicate.jmh.json" <<'JSON'
[
  {"benchmark":"package.benchmark.ECSComparisonHarness.Duplicate_/_1","secondaryMetrics":{"Time (wall clock)":{"scoreUnit":"ns","scorePercentiles":{"50.0":1}}}},
  {"benchmark":"package.benchmark.ECSComparisonHarness.Duplicate_/_1","secondaryMetrics":{"Time (wall clock)":{"scoreUnit":"ns","scorePercentiles":{"50.0":2}}}}
]
JSON
if benchmark_parse_jmh "$test_root/duplicate.jmh.json" >/dev/null 2>&1; then
    fail 'duplicate workload identities should be rejected'
fi
printf '[]\n' > "$test_root/empty.jmh.json"
assert_eq "$(benchmark_parse_jmh "$test_root/empty.jmh.json")" '[]' 'an empty filter result is represented as no measurements'

for root in "$test_root/hash-a" "$test_root/hash-b"; do
    mkdir -p "$root/Sources/FirebladeECS" "$root/Benchmarks/Benchmarks/ECSBenchmark" \
        "$root/Benchmarks/ComparisonHarness/Sources/ECSComparisonHarness"
    printf 'manifest\n' > "$root/Package.swift"
    printf 'source input\n' > "$root/Sources/FirebladeECS/input.h"
    printf 'benchmark input\n' > "$root/Benchmarks/Benchmarks/ECSBenchmark/input.c"
    printf 'harness manifest\n' > "$root/Benchmarks/ComparisonHarness/Package.swift"
    printf 'harness source\n' > "$root/Benchmarks/ComparisonHarness/Sources/ECSComparisonHarness/input.swift"
    printf 'resolved pins\n' > "$root/Benchmarks/Package.resolved"
done
assert_eq "$(benchmark_source_snapshot_hash "$test_root/hash-a")" \
    "$(benchmark_source_snapshot_hash "$test_root/hash-b")" \
    'source snapshots hash the same relative names and contents across directories, including non-Swift inputs'
assert_eq "$(benchmark_harness_snapshot_hash "$test_root/hash-a")" \
    "$(benchmark_harness_snapshot_hash "$test_root/hash-b")" \
    'harness hashes do not depend on the checkout absolute path'
printf 'different support input\n' > "$test_root/hash-b/Sources/FirebladeECS/input.h"
if [[ $(benchmark_source_snapshot_hash "$test_root/hash-a") == $(benchmark_source_snapshot_hash "$test_root/hash-b") ]]; then
    fail 'source snapshot hashes must include non-Swift package inputs'
fi
cp -R "$test_root/hash-a" "$test_root/hash-renamed"
mv "$test_root/hash-renamed/Sources/FirebladeECS/input.h" \
    "$test_root/hash-renamed/Sources/FirebladeECS/renamed.h"
if [[ $(benchmark_source_snapshot_hash "$test_root/hash-a") == $(benchmark_source_snapshot_hash "$test_root/hash-renamed") ]]; then
    fail 'source snapshot hashes must include relative file names'
fi
printf 'outside snapshot\n' > "$test_root/outside-snapshot"
ln -s "$test_root/outside-snapshot" "$test_root/hash-a/Sources/FirebladeECS/linked.h"
if benchmark_source_snapshot_hash "$test_root/hash-a" > "$test_root/source-symlink.out" 2>&1; then
    fail 'source snapshot hashes must reject symlink inputs'
fi
rm "$test_root/hash-a/Sources/FirebladeECS/linked.h"
ln -s "$test_root/outside-snapshot" \
    "$test_root/hash-a/Benchmarks/ComparisonHarness/Sources/ECSComparisonHarness/linked.swift"
if benchmark_harness_snapshot_hash "$test_root/hash-a" > "$test_root/harness-symlink.out" 2>&1; then
    fail 'harness snapshot hashes must reject symlink inputs'
fi
rm "$test_root/hash-a/Benchmarks/ComparisonHarness/Sources/ECSComparisonHarness/linked.swift"

make_run() {
    local multiplier=$1 include_update=$2
    jq -cn --argjson multiplier "$multiplier" --argjson includeUpdate "$include_update" '
        ([1, 64, 256, 1024] | map({key:("EntityIteration / " + tostring), p50Nanoseconds:(. * 1000 * $multiplier), sourceUnit:"ns"}))
        + ([1, 64, 256, 1024] | map({key:("FamilyComponentIteration / " + tostring), p50Nanoseconds:(. * 2000 * $multiplier), sourceUnit:"ns"}))
        + (if $includeUpdate then [{key:"Update7SystemsOnly [archetype] / 64", p50Nanoseconds:50000, sourceUnit:"ns"}] else [] end)
    '
}
baseline_runs=$(jq -cn \
    --argjson first "$(make_run 1 false)" \
    --argjson second "$(make_run 1.1 false)" \
    --argjson third "$(make_run 0.9 false)" \
    '{baseline:[$first,$second,$third]}')
candidate_runs=$(jq -cn \
    --argjson first "$(make_run 0.5 true)" \
    --argjson second "$(make_run 0.55 true)" \
    --argjson third "$(make_run 0.45 true)" \
    '{candidate:[$first,$second,$third]}')
samples=$(jq -cn --argjson baseline "$baseline_runs" --argjson candidate "$candidate_runs" '{baseline:$baseline.baseline,candidate:$candidate.candidate}')
comparison=$(benchmark_compare_samples "$samples")
assert_eq "$(jq -r '.comparable[] | select(.key == "EntityIteration / 64") | .baseline.median' <<<"$comparison")" 64000 'median is computed from three independent runs of the same stable keys'
assert_eq "$(jq -r '.comparable[] | select(.key == "EntityIteration / 64") | .changePercent' <<<"$comparison")" -50 'change is normalized against baseline'
assert_eq "$(jq -r '.candidateOnly[0]' <<<"$comparison")" 'Update7SystemsOnly [archetype] / 64' 'unsupported workloads remain candidate-only'

metadata=$(jq -cn '{
    runID:"test-run", startedUTC:"2026-10-28T00:00:00Z", baseline:{ref:"old",sha:"1111111111111111111111111111111111111111",componentModel:"reference",sourceSnapshotSHA256:"basehash"},
    candidate:{ref:"new",sha:"2222222222222222222222222222222222222222",componentModel:"value",sourceSnapshotSHA256:"candidatehash"}, repetitions:3, filter:"",
    host:"Darwin arm64; macOS test; model test-model; processor test-cpu", swiftVersion:"Swift test", harnessSHA256:"deadbeef", artifactPath:"results/test-run",
    workingTreeChangesExcluded:true, workingTreeChangesIncluded:false
}')
benchmark_render_report "$metadata" "$comparison" "$test_root/report.md.tmp"
report=$(cat "$test_root/report.md.tmp")
[[ $report == *'x-axis [1, 64, 256, 1024]'* ]] || fail 'chart scales must be sorted numerically'
[[ $report == *'line "baseline (11111111)" [1, 64, 256, 1024]'* ]] || fail 'baseline chart values must follow their own numeric scale order'
[[ $report == *'line "candidate (22222222)" [0.5, 32, 128, 512]'* ]] || fail 'candidate chart values must match exact names and numeric scales'
[[ $report == *'| EntityIteration / 64 | 64 μs (57.6–70.4) | 32 μs (28.8–35.2) | -50% |'* ]] || fail 'table p50 values and ranges must match the plotted measurements'
[[ $report == *'### FamilyComponentIteration'* ]] || fail 'each exact workload series must get its own chart'
[[ $report == *'Candidate only: `Update7SystemsOnly [archetype] / 64`'* ]] || fail 'unsupported workload should be listed without an estimate'
[[ $report == *'Uncommitted local changes were excluded'* ]] || fail 'dirty committed-ref behavior must be explicit'
[[ $report == *'component models differ'* ]] || fail 'reference/value representation difference must be disclosed'
[[ $report == *'not guaranteed to compare equivalent storage backends'* ]] \
    || fail 'cross-generation backend uncertainty must be disclosed'
[[ $report != *'Update7SystemsOnly [archetype] / 64 | 0'* ]] || fail 'unsupported workload must not appear as zero'

empty_side=$(jq -cn --argjson candidate "$(make_run 1 true)" '{baseline:[[],[],[]],candidate:[$candidate,$candidate,$candidate]}')
empty_side_comparison=$(benchmark_compare_samples "$empty_side")
assert_eq "$(jq -r '.comparable | length' <<<"$empty_side_comparison")" 0 'one empty side produces no comparable measurements'
assert_eq "$(jq -r '.candidateOnly | length' <<<"$empty_side_comparison")" 9 'one valid side is listed as unsupported rather than treated as zero'
empty_both=$(jq -cn '{baseline:[[],[],[]],candidate:[[],[],[]]}')
if benchmark_compare_samples "$empty_both" >/dev/null 2>&1; then
    fail 'both empty sides must not produce a successful comparison'
fi
inconsistent=$(jq -cn --argjson first "$(make_run 1 false)" --argjson second '[]' --argjson third "$(make_run 1 false)" '{baseline:[$first,$second,$third],candidate:[$first,$first,$first]}')
if benchmark_compare_samples "$inconsistent" >/dev/null 2>&1; then
    fail 'benchmark keys changing across repetitions must be rejected'
fi

status_repo="$test_root/status-repo"
mkdir -p "$status_repo/Sources/FirebladeECS"
git -C "$status_repo" init -q
git -C "$status_repo" config user.name Test
git -C "$status_repo" config user.email test@example.invalid
printf 'committed\n' > "$status_repo/tracked.txt"
printf 'public protocol Component: AnyObject {}\n' > "$status_repo/Sources/FirebladeECS/Component.swift"
printf 'Sources/ignored.swift\n' > "$status_repo/.gitignore"
git -C "$status_repo" add tracked.txt Sources/FirebladeECS/Component.swift .gitignore
git -C "$status_repo" commit -qm initial
printf 'modified\n' > "$status_repo/tracked.txt"
printf 'untracked\n' > "$status_repo/new.txt"
[[ -n $(benchmark_git_status "$status_repo") ]] || fail 'dirty tracked and untracked files must be detected'
[[ $(benchmark_has_source_input_path Sources/FirebladeECS/Component.swift && printf yes || printf no) == yes ]] || fail 'nested Swift source must be classified as a snapshot input'
printf 'ignored source\n' > "$status_repo/Sources/ignored.swift"
ignored_inputs=$(git -C "$status_repo" ls-files --others --ignored --exclude-standard -z | tr '\0' '\n')
[[ $ignored_inputs == *'Sources/ignored.swift'* ]] || fail 'ignored source fixtures must be discoverable for explicit rejection'
git() {
    if [[ ${1:-} == -C && ${3:-} == ls-tree ]]; then
        printf '160000 commit %040d\tmodule\n' 1
        for ((index = 0; index < 6000; index++)); do
            printf '100644 blob %040d\tfile-%05d\n' "$index" "$index"
        done
    else
        command git "$@"
    fi
}
if ! benchmark_ref_has_submodules "$status_repo" fixture-sha; then
    fail 'submodule detection must drain large git tree output despite pipefail'
fi
unset -f git

fake_bin="$test_root/fake-bin"
mkdir -p "$fake_bin"
cat > "$fake_bin/swift" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
if [[ ${1:-} == --version ]]; then
    printf 'Apple Swift version mock\n'
    exit 0
fi
if [[ " $* " != *' benchmark '* ]]; then
    exit 0
fi
if [[ -n ${FAKE_SWIFT_RUN_LOG:-} ]]; then
    printf 'benchmark run\n' >> "$FAKE_SWIFT_RUN_LOG"
fi
source_root=${FIREBLADE_ECS_SOURCE:-}
component_source="$source_root/Sources/FirebladeECS"
if [[ ! -f $component_source/Component.swift ]]; then
    printf 'benchmark did not receive the runner source tree: %s\n' "$source_root" >&2
    exit 10
fi
component_declaration=$(grep -R -h -E '^[[:space:]]*public protocol Component[[:space:]]*:' \
    "$component_source" --include='*.swift' || true)
case $component_declaration in
    *AnyObject*) expected_component_model=reference ;;
    *Sendable*) expected_component_model=value ;;
    *) printf 'runner source has no recognizable Component model: %s\n' "$source_root" >&2; exit 10 ;;
esac
if grep -R -q -E '^[[:space:]]*public enum StorageKind([[:space:]:{])' "$component_source" --include='*.swift'; then
    expected_modern_suite=1
else
    expected_modern_suite=0
fi
if [[ ${FIREBLADE_ECS_COMPONENT_MODEL:-} != "$expected_component_model" ]]; then
    printf 'benchmark received component model %s for a %s runner source\n' \
        "${FIREBLADE_ECS_COMPONENT_MODEL:-}" "$expected_component_model" >&2
    exit 10
fi
if [[ ${FIREBLADE_ECS_HAS_MODERN_SUITE:-} != "$expected_modern_suite" ]]; then
    printf 'benchmark received storage capability %s for a %s runner source\n' \
        "${FIREBLADE_ECS_HAS_MODERN_SUITE:-}" "$expected_modern_suite" >&2
    exit 10
fi
if [[ ! -d Benchmarks/ECSComparisonHarness ]]; then
    printf 'benchmark target sources must be copied beneath Benchmarks\n' >&2
    exit 10
fi
if [[ ${FAKE_EXPECT_WORKTREE_SOURCE:-0} == 1 && ${FIREBLADE_ECS_SOURCE:-} == */source-candidate ]]; then
    grep -q 'worktree tracked marker' "$FIREBLADE_ECS_SOURCE/Sources/FirebladeECS/Component.swift" \
        || { printf 'tracked worktree source was not patched into the candidate snapshot\n' >&2; exit 10; }
    grep -q 'worktree support marker' "$FIREBLADE_ECS_SOURCE/Sources/FirebladeECS/BenchmarkSupport.h" \
        || { printf 'non-Swift worktree input was not copied into the candidate snapshot\n' >&2; exit 10; }
fi
if [[ " $* " != *' --metric throughput '* || " $* " != *' --metric wallClock '* ]]; then
    printf 'benchmark runs must request throughput and wallClock\n' >&2
    exit 10
fi
if [[ ${FAKE_SWIFT_FAIL:-0} == 1 ]]; then
    printf 'simulated benchmark failure\n' >&2
    exit 9
fi
output=''
while (($#)); do
    if [[ $1 == --path ]]; then
        output=$2
        shift 2
    else
        shift
    fi
done
mkdir -p "$output"
if [[ ${FAKE_SWIFT_EMPTY_SIDE:-} == baseline && ${FIREBLADE_ECS_SOURCE:-} == *baseline-source ]]; then
    printf '[]\n' > "$output/Current_run.jmh.json"
else
    cat > "$output/Current_run.jmh.json" <<'JSON'
[{"benchmark":"package.benchmark.ECSComparisonHarness.EntityIteration_/_64","secondaryMetrics":{"Time (wall clock)":{"scoreUnit":"μs","scorePercentiles":{"50.0":1.25}}}}]
JSON
fi
MOCK
chmod +x "$fake_bin/swift"

if SWIFT_BIN="$fake_bin/swift" BENCHMARK_RESULTS_DIR="$test_root/missing-baseline" "$repo_root/Scripts/benchmark-compare.sh" > "$test_root/missing-baseline.log" 2>&1; then
    fail 'baseline ref must not silently default to a version or HEAD'
fi
grep -q 'baseline Git ref is required' "$test_root/missing-baseline.log" || fail 'missing baseline error should explain the required ref'
for repetitions in 03 08; do
    rejected_results="$test_root/leading-zero-$repetitions"
    run_log="$test_root/leading-zero-$repetitions.runs"
    if FAKE_SWIFT_RUN_LOG="$run_log" SWIFT_BIN="$fake_bin/swift" \
        BENCHMARK_RESULTS_DIR="$rejected_results" \
        "$repo_root/Scripts/benchmark-compare.sh" HEAD HEAD "$repetitions" \
        > "$test_root/leading-zero-$repetitions.log" 2>&1; then
        fail "leading-zero repetition value $repetitions must be rejected"
    fi
    grep -q 'repetitions must be an integer' "$test_root/leading-zero-$repetitions.log" \
        || fail "leading-zero repetition value $repetitions should fail validation"
    [[ ! -e $run_log && ! -e $rejected_results ]] \
        || fail "leading-zero repetition value $repetitions must be rejected before any runs or artifacts"
done

success_output=$(SWIFT_BIN="$fake_bin/swift" BENCHMARK_RESULTS_DIR="$test_root/results" "$repo_root/Scripts/benchmark-compare.sh" HEAD HEAD 3 'EntityIteration / 64' 2>&1)
report_path=$(sed -n 's/^===> Comparison report: //p' <<<"$success_output")
[[ -n $report_path && -f $report_path ]] || fail 'successful ref comparison must publish one complete report'
[[ $(cat "$report_path") == *'Uncommitted local changes were excluded'* ]] || fail 'HEAD comparison must identify excluded local changes'
[[ $(cat "$report_path") == *'Host: Darwin'* ]] || fail 'report must include real host provenance'
[[ -s ${report_path%/REPORT.md}/metadata.json ]] || fail 'comparison metadata must be retained beside the report'

candidate_only_output=$(FAKE_SWIFT_EMPTY_SIDE=baseline SWIFT_BIN="$fake_bin/swift" BENCHMARK_RESULTS_DIR="$test_root/one-side" "$repo_root/Scripts/benchmark-compare.sh" HEAD HEAD 3 'EntityIteration / 64' 2>&1)
candidate_only_report=$(sed -n 's/^===> Comparison report: //p' <<<"$candidate_only_output")
[[ -n $candidate_only_report && -f $candidate_only_report ]] || fail 'an empty baseline and valid candidate must produce a report'
[[ $(cat "$candidate_only_report") == *'Candidate only: `EntityIteration / 64`'* ]] || fail 'one-sided measurements must be reported as unsupported'
[[ $(cat "$candidate_only_report") != *'0 μs'* ]] || fail 'one-sided measurements must not be rendered as zero'

success_count=$(find "$test_root/results" -name REPORT.md -type f | wc -l | tr -d ' ')
if FAKE_SWIFT_FAIL=1 SWIFT_BIN="$fake_bin/swift" BENCHMARK_RESULTS_DIR="$test_root/results" "$repo_root/Scripts/benchmark-compare.sh" HEAD HEAD 3 'EntityIteration / 64' > "$test_root/failure.log" 2>&1; then
    fail 'benchmark command failure must propagate'
fi
grep -q 'simulated benchmark failure' "$test_root/failure.log" \
    || fail 'benchmark stderr should be propagated to the comparison caller'
failure_count=$(find "$test_root/results" -name REPORT.md -type f | wc -l | tr -d ' ')
assert_eq "$failure_count" "$success_count" 'failed benchmark runs must not publish stale or partial reports'

worktree_output=$(SWIFT_BIN="$fake_bin/swift" BENCHMARK_RESULTS_DIR="$test_root/results" "$repo_root/Scripts/benchmark-compare.sh" HEAD WORKTREE 3 'EntityIteration / 64' 2>&1)
worktree_report=$(sed -n 's/^===> Comparison report: //p' <<<"$worktree_output")
[[ -n $worktree_report && -f $worktree_report ]] || fail 'WORKTREE candidate must produce a report from its isolated snapshot'
[[ $(cat "$worktree_report") == *'isolated snapshot of the local worktree'* ]] || fail 'WORKTREE report must identify the snapshot'
[[ $(jq -r '.candidate.sourceSnapshotSHA256 | length' "${worktree_report%/REPORT.md}/metadata.json") == 64 ]] || fail 'WORKTREE source snapshot must have a content hash'

fixture_repo="$test_root/report-fixture"
mkdir -p "$fixture_repo/Scripts" "$fixture_repo/Sources/FirebladeECS" \
    "$fixture_repo/Benchmarks/Benchmarks/ECSBenchmark" \
    "$fixture_repo/Documentation/Benchmarks"
fixture_repo=$(cd "$fixture_repo" && pwd)
cp "$repo_root/Scripts/benchmark-compare.sh" "$fixture_repo/Scripts/"
cp "$repo_root/Scripts/benchmark-compare-lib.sh" "$fixture_repo/Scripts/"
cp "$repo_root/Scripts/generate-benchmark-report.sh" "$fixture_repo/Scripts/"
cp -R "$repo_root/Benchmarks/ComparisonHarness" "$fixture_repo/Benchmarks/"
cp "$repo_root/Benchmarks/Package.resolved" "$fixture_repo/Benchmarks/Package.resolved"
printf 'let package = Package(name: "Fixture")\n' > "$fixture_repo/Package.swift"
printf 'let package = Package(name: "FixtureBenchmarks")\n' > "$fixture_repo/Benchmarks/Package.swift"
printf 'public protocol Component: AnyObject {}\n' > "$fixture_repo/Sources/FirebladeECS/Component.swift"
cat > "$fixture_repo/Sources/FirebladeECS/Nexus.swift" <<'SWIFT'
public struct Entity {}
public struct EntitiesIterator {}
public struct Nexus {}
extension Nexus {
    public func createEntity() -> Entity { Entity() }
    public func makeEntitiesIterator() -> EntitiesIterator { EntitiesIterator() }
}
SWIFT
cat > "$fixture_repo/Sources/FirebladeECS/Storage.swift" <<'SWIFT'
extension Nexus {
    public enum StorageKind: CaseIterable, Sendable {
        case archetype
        case sparseSet
    }
}
SWIFT
printf 'Update7Systems benchmark fixture\n' > "$fixture_repo/Benchmarks/Benchmarks/ECSBenchmark/ComparisonBenchmarks.swift"
printf 'No verified comparison report has been generated.\n' > "$fixture_repo/Documentation/Benchmarks/REPORT.md"
git -C "$fixture_repo" init -q
git -C "$fixture_repo" config user.name Test
git -C "$fixture_repo" config user.email test@example.invalid
git -C "$fixture_repo" add \
    Scripts/benchmark-compare.sh Scripts/benchmark-compare-lib.sh Scripts/generate-benchmark-report.sh \
    Package.swift Sources/FirebladeECS/Component.swift Sources/FirebladeECS/Nexus.swift \
    Sources/FirebladeECS/Storage.swift Benchmarks/Package.swift Benchmarks/Package.resolved \
    Benchmarks/Benchmarks/ECSBenchmark/ComparisonBenchmarks.swift \
    Benchmarks/ComparisonHarness/Package.swift \
    Benchmarks/ComparisonHarness/Sources/ECSComparisonHarness/Benchmarks.swift \
    Benchmarks/ComparisonHarness/Sources/ECSComparisonHarness/CommonBenchmarks.swift \
    Benchmarks/ComparisonHarness/Sources/ECSComparisonHarness/CommonComponents.swift \
    Benchmarks/ComparisonHarness/Sources/ECSComparisonHarness/ModernComponents.swift \
    Benchmarks/ComparisonHarness/Sources/ECSComparisonHarness/ModernSystems.swift \
    Benchmarks/ComparisonHarness/Sources/ECSComparisonHarness/Update7Benchmarks.swift \
    Documentation/Benchmarks/REPORT.md
git -C "$fixture_repo" commit -qm 'Create synthetic comparison fixture'
printf 'public protocol Component: AnyObject {} // worktree tracked marker\n' > "$fixture_repo/Sources/FirebladeECS/Component.swift"
printf 'worktree support marker\n' > "$fixture_repo/Sources/FirebladeECS/BenchmarkSupport.h"
fixture_report="$fixture_repo/Documentation/Benchmarks/REPORT.md"
if (
    unset BENCHMARK_RESULTS_DIR
    FAKE_EXPECT_WORKTREE_SOURCE=1 SWIFT_BIN="$fake_bin/swift" \
        "$fixture_repo/Scripts/generate-benchmark-report.sh" HEAD WORKTREE 3 'EntityIteration / 64'
) > "$test_root/report-no-opt-in.log" 2>&1; then
    fail 'an existing report must not be replaced without explicit opt-in'
fi
grep -q 'refusing to replace existing report without explicit opt-in' "$test_root/report-no-opt-in.log" \
    || fail 'refusing report replacement should explain the opt-in'
assert_eq "$(cat "$fixture_report")" 'No verified comparison report has been generated.' \
    'report refusal must preserve the existing report'
rm "$fixture_report"
fresh_report_output=$(
    unset BENCHMARK_RESULTS_DIR
    FAKE_EXPECT_WORKTREE_SOURCE=1 SWIFT_BIN="$fake_bin/swift" \
        "$fixture_repo/Scripts/generate-benchmark-report.sh" HEAD WORKTREE 3 'EntityIteration / 64'
)
[[ -f $fixture_report && $fresh_report_output == *'atomically updated'* ]] \
    || fail 'a missing report must be published without overwrite opt-in'
fresh_comparison_report=$(sed -n 's/^===> Comparison report: //p' <<<"$fresh_report_output" | tail -n 1)
assert_eq "$(stat -f '%Lp' "$fixture_report")" "$(stat -f '%Lp' "$fresh_comparison_report")" \
    'new reports must retain the comparison report permissions'
chmod 640 "$fixture_report"
worktree_report_output=$(
    unset BENCHMARK_RESULTS_DIR
    FAKE_EXPECT_WORKTREE_SOURCE=1 SWIFT_BIN="$fake_bin/swift" \
        "$fixture_repo/Scripts/generate-benchmark-report.sh" --overwrite HEAD WORKTREE 3 'EntityIteration / 64'
)
[[ -f $fixture_report ]] || fail 'successful report command must update the requested documentation location'
assert_eq "$(stat -f '%Lp' "$fixture_report")" 640 'overwritten reports must preserve the destination permissions'
[[ $(cat "$fixture_report") == *'# FirebladeECS Git-ref Benchmark Comparison'* ]] || fail 'only validated comparison output should replace the synthetic placeholder'
[[ $(cat "$fixture_report") == *'Raw JMH output, parsed samples, logs, and run metadata'* ]] || fail 'published report must retain raw-output provenance'
[[ $(cat "$fixture_report") == *'does not measure or represent the package benchmarks'* ]] \
    || fail 'published report must distinguish the comparison harness from package workloads'
fixture_comparison_report=$(sed -n 's/^===> Comparison report: //p' <<<"$worktree_report_output" | tail -n 1)
[[ $fixture_comparison_report == "$fixture_repo"/Benchmarks/results/*/REPORT.md ]] || fail 'report command must retain artifacts in the default results directory'
fixture_candidate_source="${fixture_comparison_report%/REPORT.md}/source-candidate"
grep -q 'worktree tracked marker' "$fixture_candidate_source/Sources/FirebladeECS/Component.swift" \
    || fail 'tracked source changes must survive patching with the default nested results path'
grep -q 'worktree support marker' "$fixture_candidate_source/Sources/FirebladeECS/BenchmarkSupport.h" \
    || fail 'untracked non-Swift package inputs must be copied into the source snapshot'
fixture_report_before_failure=$(cat "$fixture_report")
fixture_comparison_metadata="${fixture_comparison_report%/REPORT.md}/metadata.json"
comparison_runner="$fixture_repo/Scripts/benchmark-compare.sh"
comparison_runner_real="$fixture_repo/Scripts/benchmark-compare.real.sh"
comparison_report_backup="$test_root/comparison-report.md"
comparison_metadata_backup="$test_root/comparison-metadata.json"
cp "$fixture_comparison_report" "$comparison_report_backup"
cp "$fixture_comparison_metadata" "$comparison_metadata_backup"
mv "$comparison_runner" "$comparison_runner_real"
cat > "$comparison_runner" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
printf '===> Comparison report: %s\n' "$FIXTURE_COMPARISON_REPORT"
MOCK
chmod +x "$comparison_runner"
assert_generator_rejects_fixture() {
    local label=$1
    if (
        FIXTURE_COMPARISON_REPORT="$fixture_comparison_report" SWIFT_BIN="$fake_bin/swift" \
            "$fixture_repo/Scripts/generate-benchmark-report.sh" --overwrite HEAD WORKTREE 3 'EntityIteration / 64'
    ) > "$test_root/$label.log" 2>&1; then
        fail "$label comparison artifacts must be rejected"
    fi
    assert_eq "$(cat "$fixture_report")" "$fixture_report_before_failure" \
        "$label validation must leave the published report untouched"
}
printf '\nTampered result.\n' >> "$fixture_comparison_report"
assert_generator_rejects_fixture mismatched-render
cp "$comparison_report_backup" "$fixture_comparison_report"
jq '.filter = "wrong filter"' "$comparison_metadata_backup" > "$fixture_comparison_metadata"
assert_generator_rejects_fixture mismatched-filter
jq '.baseline.sha = "0000000000000000000000000000000000000000"' "$comparison_metadata_backup" > "$fixture_comparison_metadata"
assert_generator_rejects_fixture mismatched-ref-sha
jq '.runs[1].raw = .runs[0].raw' "$comparison_metadata_backup" > "$fixture_comparison_metadata"
assert_generator_rejects_fixture duplicate-artifact-path
cp "$comparison_metadata_backup" "$fixture_comparison_metadata"
cp "$fixture_report" "$test_root/report-before-directory-race.md"
cat > "$comparison_runner" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
rm -f "$FIXTURE_REPORT_PATH"
mkdir "$FIXTURE_REPORT_PATH"
printf '===> Comparison report: %s\n' "$FIXTURE_COMPARISON_REPORT"
MOCK
chmod +x "$comparison_runner"
if (
    FIXTURE_REPORT_PATH="$fixture_report" FIXTURE_COMPARISON_REPORT="$fixture_comparison_report" \
        SWIFT_BIN="$fake_bin/swift" \
        "$fixture_repo/Scripts/generate-benchmark-report.sh" --overwrite HEAD WORKTREE 3 'EntityIteration / 64'
) > "$test_root/report-directory-race.log" 2>&1; then
    fail 'a report destination changed to a directory during generation must be rejected'
fi
grep -q 'changed to a directory or non-regular file' "$test_root/report-directory-race.log" \
    || fail 'directory replacement failure should explain why publication stopped'
[[ -d $fixture_report ]] || fail 'directory race fixture must remain a directory'
rmdir "$fixture_report"
cp "$test_root/report-before-directory-race.md" "$fixture_report"
mv "$comparison_runner_real" "$comparison_runner"
fixture_report_before_failure=$(cat "$fixture_report")
if (
    unset BENCHMARK_RESULTS_DIR
    FAKE_SWIFT_FAIL=1 SWIFT_BIN="$fake_bin/swift" \
        "$fixture_repo/Scripts/generate-benchmark-report.sh" HEAD HEAD 3 'EntityIteration / 64' --overwrite
) > "$test_root/report-failure.log" 2>&1; then
    fail 'failed comparison must not publish a report'
fi
assert_eq "$(cat "$fixture_report")" "$fixture_report_before_failure" \
    'failed report generation must leave the existing documentation report untouched'

printf 'public protocol Component: Sendable {}\n' > "$fixture_repo/Sources/FirebladeECS/Component.swift"
rm "$fixture_repo/Sources/FirebladeECS/Storage.swift" "$fixture_repo/Sources/FirebladeECS/BenchmarkSupport.h"
git -C "$fixture_repo" add Sources/FirebladeECS/Component.swift Sources/FirebladeECS/Storage.swift
git -C "$fixture_repo" commit -qm 'Add synthetic value-component revision'
revision_output=$(SWIFT_BIN="$fake_bin/swift" BENCHMARK_RESULTS_DIR="$test_root/per-revision-results" \
    "$fixture_repo/Scripts/benchmark-compare.sh" HEAD~1 HEAD 3 'EntityIteration / 64' 2>&1)
revision_report=$(sed -n 's/^===> Comparison report: //p' <<<"$revision_output")
[[ -n $revision_report && -f $revision_report ]] || fail 'different component revisions must complete a comparison'
revision_metadata="${revision_report%/REPORT.md}/metadata.json"
assert_eq "$(jq -r '.baseline.componentModel' "$revision_metadata")" reference 'baseline component flags must match the baseline source tree'
assert_eq "$(jq -r '.baseline.hasModernSuite' "$revision_metadata")" 1 'baseline storage flags must match the baseline source tree'
assert_eq "$(jq -r '.candidate.componentModel' "$revision_metadata")" value 'candidate component flags must match the candidate source tree'
assert_eq "$(jq -r '.candidate.hasModernSuite' "$revision_metadata")" 0 'candidate storage flags must match the candidate source tree'

printf 'PASS: strict JMH parsing, exact p50 tables and charts, per-revision source flags, stable snapshots, WORKTREE inputs, provenance, and atomic report publication\n'
