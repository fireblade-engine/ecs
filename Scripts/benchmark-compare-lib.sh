#!/usr/bin/env bash

benchmark_parse_jmh() {
    local input=$1
    jq -ce '
        def nanoseconds($unit):
            if ($unit == "ns" or $unit == "nsec" or $unit == "nanoseconds") then 1
            elif ($unit == "us" or $unit == "μs" or $unit == "µs" or $unit == "microseconds") then 1000
            elif ($unit == "ms" or $unit == "milliseconds") then 1000000
            elif ($unit == "s" or $unit == "sec" or $unit == "seconds") then 1000000000
            else error("unsupported wall-clock unit: \($unit)") end;
        def stable_key($name):
            if ($name | type) != "string" then error("missing benchmark identity")
            elif ($name | test("^package\\.benchmark\\.[^.]+\\..+$")) then
                ($name | capture("^package\\.benchmark\\.[^.]+\\.(?<key>.+)$").key | gsub("_/_"; " / "))
            else error("malformed benchmark identity: \($name)") end;
        if type != "array" then error("JMH output must be an array") else . end
        | map(
            .benchmark as $name
            | stable_key($name) as $key
            | .secondaryMetrics["Time (wall clock)"] as $metric
            | $metric.scorePercentiles["50.0"] as $p50
            | $metric.scoreUnit as $unit
            | if (($p50 | type) != "number" or $p50 <= 0) then error("missing or invalid wall-clock p50 for \($name)") else . end
            | {
                key: $key,
                p50Nanoseconds: ($p50 * nanoseconds($unit)),
                sourceUnit: $unit
              }
          ) as $rows
        | if ([$rows[].key] | unique | length) != ($rows | length) then error("duplicate benchmark key in JMH output") else ($rows | sort_by(.key)) end
    ' "$input"
}

benchmark_compare_samples() {
    local samples=$1
    jq -ce '
        def median($values):
            ($values | sort) as $sorted
            | ($sorted | length) as $length
            | if $length % 2 == 1 then $sorted[($length / 2 | floor)]
              else (($sorted[($length / 2 | floor) - 1] + $sorted[($length / 2 | floor)]) / 2)
              end;
        def valid_run($run):
            ($run | type) == "array"
            and ([$run[].key] | unique | length) == ($run | length)
            and all($run[]; (.key | type) == "string" and (.p50Nanoseconds | type) == "number" and .p50Nanoseconds > 0 and (.sourceUnit | type) == "string");
        def stable_keys($runs):
            ($runs[0] | map(.key) | sort) as $expected
            | all($runs[1:][]; (map(.key) | sort) == $expected);
        def stats($runs; $key):
            [$runs[][] | select(.key == $key)] as $rows
            | [$rows[].p50Nanoseconds] as $values
            | {
                median: median($values),
                min: ($values | min),
                max: ($values | max),
                samples: $values,
                sourceUnits: ([$rows[].sourceUnit] | unique | sort)
              };
        if ((.baseline | type) != "array") or ((.candidate | type) != "array") then error("both revisions need measurement runs") else . end
        | if ((.baseline | length) < 3) or ((.candidate | length) < 3) then error("at least three independent runs per revision are required") else . end
        | . as $all
        | if (all($all.baseline[]; valid_run(.)) and all($all.candidate[]; valid_run(.))) then . else error("invalid parsed JMH run") end
        | if (stable_keys($all.baseline) and stable_keys($all.candidate)) then . else error("benchmark discovery changed between repetitions") end
        | if (([$all.baseline[] | .[]] | length) + ([$all.candidate[] | .[]] | length)) == 0 then error("both revisions produced no matching benchmark measurements") else . end
        | ($all.baseline[0] | map(.key)) as $baselineKeys
        | ($all.candidate[0] | map(.key)) as $candidateKeys
        | [($baselineKeys[] | select(. as $key | $candidateKeys | index($key) != null))] as $commonKeys
        | [($baselineKeys[] | select(. as $key | $candidateKeys | index($key) == null))] as $baselineOnly
        | [($candidateKeys[] | select(. as $key | $baselineKeys | index($key) == null))] as $candidateOnly
        | {
            comparable: [
                $commonKeys[] as $key
                | stats($all.baseline; $key) as $baseline
                | stats($all.candidate; $key) as $candidate
                | ($key | capture("^(?<series>.*?)(?: / (?<scale>[0-9]+))?$")) as $identity
                | {
                    key: $key,
                    series: $identity.series,
                    scale: (if $identity.scale == null then null else ($identity.scale | tonumber) end),
                    baseline: $baseline,
                    candidate: $candidate,
                    changePercent: ((($candidate.median - $baseline.median) / $baseline.median) * 100),
                    outcome: (
                        if $candidate.median < $baseline.median and $candidate.max < $baseline.min then "observed improvement; ranges separated"
                        elif $candidate.median < $baseline.median then "inconclusive; observed median lower"
                        elif $candidate.median > $baseline.median and $candidate.min > $baseline.max then "observed regression; ranges separated"
                        elif $candidate.median > $baseline.median then "inconclusive; observed median higher"
                        else "inconclusive; equal observed medians"
                        end
                    )
                  }
            ],
            baselineOnly: $baselineOnly,
            candidateOnly: $candidateOnly
          }
    ' <<<"$samples"
}

benchmark_git_status() {
    git -C "$1" status --porcelain --untracked-files=all
}

benchmark_has_source_input_path() {
    case $1 in
        Sources/*|Benchmarks/Benchmarks/*|Package.swift|Package.resolved|Benchmarks/Package.swift|Benchmarks/Package.resolved) return 0 ;;
        *) return 1 ;;
    esac
}

benchmark_ref_has_submodules() {
    git -C "$1" ls-tree -r "$2" | grep '^160000 commit ' >/dev/null
}

benchmark_component_model() {
    local source=$1
    local declaration

    declaration=$(grep -R -h -E '^[[:space:]]*public protocol Component[[:space:]]*:' \
        "$source/Sources/FirebladeECS" --include='*.swift' || true)
    if [[ $(wc -l <<<"$declaration" | tr -d ' ') != 1 ]]; then
        printf 'Error: expected exactly one public Component protocol declaration in %s/Sources/FirebladeECS.\n' "$source" >&2
        return 1
    fi
    case $declaration in
        *AnyObject*) printf 'reference\n' ;;
        *Sendable*) printf 'value\n' ;;
        *)
            printf 'Error: unrecognized Component protocol model in %s: %s\n' "$source" "$declaration" >&2
            return 1
            ;;
    esac
}

benchmark_storage_capabilities() {
    local source=$1
    local file block declarations=0 has_archetype=0 has_sparse_set=0

    while IFS= read -r -d '' file; do
        block=$(awk '
            !inside && /^[[:space:]]*public enum StorageKind([[:space:]:{])/ { inside = 1 }
            inside {
                print
                if ($0 ~ /^[[:space:]]*}/) exit
            }
        ' "$file")
        [[ -n $block ]] || continue
        ((declarations += 1))
        grep -Eq '^[[:space:]]*case[[:space:]]+archetype([[:space:],]|$)' <<<"$block" && has_archetype=1
        grep -Eq '^[[:space:]]*case[[:space:]]+sparseSet([[:space:],]|$)' <<<"$block" && has_sparse_set=1
    done < <(find "$source/Sources/FirebladeECS" -type f -name '*.swift' -print0)

    if (( declarations == 0 )); then
        printf 'legacy\n'
    elif (( declarations == 1 && has_archetype && has_sparse_set )); then
        printf 'modern\n'
    else
        printf 'Error: unrecognized Nexus.StorageKind declaration in %s/Sources/FirebladeECS.\n' "$source" >&2
        return 1
    fi
}

benchmark_check_harness_compatibility() {
    local source=$1 file has_create=0 has_iterator=0

    while IFS= read -r -d '' file; do
        grep -Eq '^[[:space:]]*(public[[:space:]]+)?extension Nexus([[:space:]]|$)' "$file" || continue
        grep -Eq '^[[:space:]]*public func createEntity[(][)][[:space:]]*-> Entity' "$file" && has_create=1
        grep -Eq '^[[:space:]]*public func makeEntitiesIterator[(][)]' "$file" && has_iterator=1
    done < <(find "$source/Sources/FirebladeECS" -type f -name '*.swift' -print0)

    if (( ! has_create || ! has_iterator )); then
        printf 'Error: incompatible ECS API for the comparison harness; requires Nexus.createEntity() and Nexus.makeEntitiesIterator().\n' >&2
        return 1
    fi
}

benchmark_reject_symlinks() (
    local root=$1
    shift
    local path symlink

    for path in "$@"; do
        if [[ -L "$root/$path" ]]; then
            printf 'Error: snapshot input is a symlink: %s\n' "$root/$path" >&2
            return 1
        fi
        if [[ -d "$root/$path" ]]; then
            symlink=$(find "$root/$path" -type l -print -quit) || return 1
            if [[ -n $symlink ]]; then
                printf 'Error: snapshot input contains a symlink: %s\n' "$symlink" >&2
                return 1
            fi
        fi
    done
)

benchmark_hash_inputs() (
    local root=$1
    shift
    local path

    [[ ! -L $root && -d $root ]] || {
        printf 'Error: snapshot root must be a non-symlink directory: %s\n' "$root" >&2
        return 1
    }
    cd -- "$root"
    root=$(pwd -P)
    benchmark_reject_symlinks "$root" "$@" || return 1
    {
        for path in "$@"; do
            if [[ -d $path ]]; then
                find "$path" -type f -print0
            elif [[ -f $path ]]; then
                printf '%s\0' "$path"
            fi
        done
    } | xargs -0 shasum -a 256 | LC_ALL=C sort | shasum -a 256 | awk '{print $1}'
)

benchmark_source_snapshot_hash() {
    benchmark_hash_inputs "$1" Sources Benchmarks/Benchmarks Package.swift Package.resolved \
        Benchmarks/Package.swift Benchmarks/Package.resolved
}

benchmark_harness_snapshot_hash() {
    benchmark_hash_inputs "$1" Benchmarks/ComparisonHarness Benchmarks/Package.resolved
}

benchmark_artifact_identity() {
    local root=$1
    local relative_path=$2
    local root_real current parent_real parent stats device inode links segment
    local -a segments

    [[ ! -L $root && -d $root ]] || {
        printf 'Error: artifact directory must not be a symlink: %s\n' "$root" >&2
        return 1
    }
    root_real=$(cd -P -- "$root" && pwd) || return 1
    current=$root
    IFS='/' read -r -a segments <<<"$relative_path"
    for segment in "${segments[@]}"; do
        current="$current/$segment"
        if [[ -L $current ]]; then
            printf 'Error: comparison artifact path contains a symlink: %s\n' "$current" >&2
            return 1
        fi
    done
    [[ -f $current ]] || {
        printf 'Error: comparison artifact is missing or not a regular file: %s\n' "$relative_path" >&2
        return 1
    }
    parent=${relative_path%/*}
    [[ $parent != "$relative_path" ]] || parent=.
    parent_real=$(cd -P -- "$root/$parent" && pwd) || return 1
    case $parent_real in
        "$root_real"|"$root_real"/*) ;;
        *) printf 'Error: comparison artifact escapes its artifact directory: %s\n' "$relative_path" >&2; return 1 ;;
    esac
    stats=$(stat -f '%d:%i:%l' "$current") || return 1
    IFS=: read -r device inode links <<<"$stats"
    if [[ ! $links =~ ^[0-9]+$ ]] || (( links != 1 )); then
        printf 'Error: comparison artifact must not have hard-link aliases: %s\n' "$relative_path" >&2
        return 1
    fi
    printf '%s:%s\n' "$device" "$inode"
}

benchmark_artifact_directory() {
    local root=$1
    local relative_path=$2
    local root_real current real_path segment
    local -a segments

    [[ ! -L $root && -d $root ]] || {
        printf 'Error: artifact directory must not be a symlink: %s\n' "$root" >&2
        return 1
    }
    root_real=$(cd -P -- "$root" && pwd) || return 1
    current=$root
    IFS='/' read -r -a segments <<<"$relative_path"
    for segment in "${segments[@]}"; do
        current="$current/$segment"
        if [[ -L $current ]]; then
            printf 'Error: retained snapshot path contains a symlink: %s\n' "$current" >&2
            return 1
        fi
    done
    [[ -d $current ]] || return 1
    real_path=$(cd -P -- "$current" && pwd) || return 1
    case $real_path in
        "$root_real"|"$root_real"/*) printf '%s\n' "$real_path" ;;
        *) printf 'Error: retained snapshot escapes its artifact directory: %s\n' "$relative_path" >&2; return 1 ;;
    esac
}

benchmark_host_description() {
    local description model processor version
    description=$(uname -srm)
    version=$(sw_vers -productVersion 2>/dev/null || true)
    if [[ -n $version ]]; then
        description+="; macOS $version"
    fi
    model=$(sysctl -n hw.model 2>/dev/null || true)
    processor=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || true)
    if [[ -n $model ]]; then
        description+="; model $model"
    fi
    if [[ -n $processor ]]; then
        description+="; processor $processor"
    fi
    printf '%s' "$description"
}

benchmark_render_report() {
    local metadata=$1
    local comparison=$2
    local output=$3
    local run_id baseline_sha candidate_sha baseline_ref candidate_ref repetitions started host swift_version filter artifact_path baseline_model candidate_model baseline_snapshot candidate_snapshot

    run_id=$(jq -r '.runID' <<<"$metadata")
    baseline_sha=$(jq -r '.baseline.sha' <<<"$metadata")
    candidate_sha=$(jq -r '.candidate.sha' <<<"$metadata")
    baseline_ref=$(jq -r '.baseline.ref | gsub("[`\\\\]"; "_")' <<<"$metadata")
    candidate_ref=$(jq -r '.candidate.ref | gsub("[`\\\\]"; "_")' <<<"$metadata")
    repetitions=$(jq -r '.repetitions' <<<"$metadata")
    started=$(jq -r '.startedUTC' <<<"$metadata")
    host=$(jq -r '.host | gsub("[`\\\\]"; "_")' <<<"$metadata")
    swift_version=$(jq -r '.swiftVersion | gsub("[`\\\\]"; "_") | gsub("\\n"; " ")' <<<"$metadata")
    filter=$(jq -r '.filter | if . == "" then "all registered harness workloads" else . end | gsub("[`\\\\]"; "_")' <<<"$metadata")
    artifact_path=$(jq -r '.artifactPath | gsub("[`\\\\]"; "_")' <<<"$metadata")
    baseline_model=$(jq -r '.baseline.componentModel' <<<"$metadata")
    candidate_model=$(jq -r '.candidate.componentModel' <<<"$metadata")
    baseline_snapshot=$(jq -r '.baseline.sourceSnapshotSHA256' <<<"$metadata")
    candidate_snapshot=$(jq -r '.candidate.sourceSnapshotSHA256' <<<"$metadata")

    {
        cat <<'EOF'
# FirebladeECS Git-ref Benchmark Comparison

The table contains only exact-name workloads measured on both revisions. JMH wall-clock p50 values are normalized to microseconds. Each displayed median is calculated from independent process-run p50s; ranges are the observed minimum–maximum of those run medians. Lower time is faster. Direction labels describe observed medians and ranges, not statistical significance.

## Comparable measurements

| Workload | Baseline p50 (range) | Candidate p50 (range) | Change | Observed direction |
|:---|---:|---:|---:|:---|
EOF
        jq -r '
            .comparable[]
            | (.key | gsub("\\|"; "\\\\|")) as $key
            | "| \($key) | \(.baseline.median / 1000) μs (\(.baseline.min / 1000)–\(.baseline.max / 1000)) | \(.candidate.median / 1000) μs (\(.candidate.min / 1000)–\(.candidate.max / 1000)) | \(((.changePercent * 100 | round) / 100))% | \(.outcome) |"
        ' <<<"$comparison"

        if [[ $(jq '.comparable | length' <<<"$comparison") -gt 0 ]]; then
            printf '\n## Charts\n'
            while IFS= read -r series; do
                local label points scales baseline_values candidate_values max_value
                label=$(jq -rn --arg series "$series" '$series | gsub("[^A-Za-z0-9 ._-]"; "_")')
                points=$(jq -c --arg series "$series" '[.comparable[] | select(.series == $series and .scale != null)] | sort_by(.scale)' <<<"$comparison")
                scales=$(jq -r 'map(.scale | tostring) | join(", ")' <<<"$points")
                baseline_values=$(jq -r 'map(.baseline.median / 1000 | tostring) | join(", ")' <<<"$points")
                candidate_values=$(jq -r 'map(.candidate.median / 1000 | tostring) | join(", ")' <<<"$points")
                max_value=$(jq -r '[.[] | .baseline.median / 1000, .candidate.median / 1000] | max' <<<"$points")
                printf '\n### %s\n\n```mermaid\nxychart-beta\n    title "%s p50 (μs)"\n    x-axis [%s]\n    y-axis "Time (μs)" 0 --> %s\n    line "baseline (%s)" [%s]\n    line "candidate (%s)" [%s]\n```\n' \
                    "$label" "$label" "$scales" "$max_value" "${baseline_sha:0:8}" "$baseline_values" "${candidate_sha:0:8}" "$candidate_values"
            done < <(jq -r '[.comparable[] | select(.scale != null) | .series] | unique[]' <<<"$comparison")
        fi

        if [[ $(jq '.baselineOnly | length' <<<"$comparison") -gt 0 || $(jq '.candidateOnly | length' <<<"$comparison") -gt 0 ]]; then
            printf '\n## Not compared: missing counterpart\n\nThese registered workload names had no exact-name result on the other revision. They are omitted from arithmetic and charts; no values or estimates are shown.\n'
            jq -r '.baselineOnly[] | "- Baseline only: `\(.)`"' <<<"$comparison"
            jq -r '.candidateOnly[] | "- Candidate only: `\(.)`"' <<<"$comparison"
        fi

        if [[ $(jq '.comparable | length' <<<"$comparison") -eq 0 ]]; then
            printf '\nNo directly comparable benchmark names were produced for this selection. No performance values or charts are shown.\n'
        fi

        cat <<EOF

## Provenance

- Run: \`$run_id\` ($started)
- Baseline: \`$baseline_ref\` at \`$baseline_sha\`
- Candidate: \`$candidate_ref\` at \`$candidate_sha\`
- Independent process runs per revision: $repetitions
- Benchmark filter: \`$filter\`
- Host: $host
- Swift toolchain: $swift_version
- Baseline component model: $baseline_model
- Candidate component model: $candidate_model
- Baseline verified storage capabilities: $(jq -r '.baseline.storageCapabilities | if length == 0 then "none" else join(", ") end' <<<"$metadata") ($(jq -r '.baseline.storageCapabilityStatus' <<<"$metadata"))
- Candidate verified storage capabilities: $(jq -r '.candidate.storageCapabilities | if length == 0 then "none" else join(", ") end' <<<"$metadata") ($(jq -r '.candidate.storageCapabilityStatus' <<<"$metadata"))
- Baseline source snapshot SHA-256: \`$baseline_snapshot\`
- Candidate source snapshot SHA-256: \`$candidate_snapshot\`
- Harness SHA-256: \`$(jq -r '.harnessSHA256' <<<"$metadata")\`
- Raw JMH output, parsed samples, logs, and run metadata: \`$artifact_path\`
EOF

        if [[ $baseline_model != "$candidate_model" ]]; then
            printf '\nThe component models differ: one revision uses reference-type components and the other uses value-type components. These timings are not a like-for-like comparison of component storage representation.\n'
        fi

        if [[ $(jq -r '.workingTreeChangesIncluded' <<<"$metadata") == true ]]; then
            printf '\nThe candidate is an isolated snapshot of the local worktree. Relevant source, manifests, and lockfiles were copied to the artifact and are identified by the snapshot hash above; the original worktree was not modified.\n'
        elif [[ $(jq -r '.workingTreeChangesExcluded' <<<"$metadata") == true ]]; then
            printf '\nUncommitted local changes were excluded: both measurements use committed Git objects only. See `working-tree-status.txt` in the run artifacts. Use candidate ref `WORKTREE` to measure supported local source changes.\n'
        else
            printf '\nThe local working tree was clean when this comparison started.\n'
        fi

        cat <<'EOF'

## Scope and support

The shared harness measures entity iteration, family-entity iteration, and family-component iteration at the same entity counts. Modern revisions use an explicitly selected archetype backend for these common workloads; revisions without `Nexus.StorageKind` use their single built-in backend, so cross-generation rows are not guaranteed to compare equivalent storage backends. `Update7SystemsOnly` starts timing after world and system setup, so it measures only the seven update calls and accumulator consumption. A workload without an exact counterpart is listed above and omitted from arithmetic; unsupported measurements are not represented as zero. Legacy revisions without the modern storage API do not run or imply either backend. The comparison harness adapts to the revision's component protocol, but a reference-type/value-type difference remains a disclosed limitation rather than storage equivalence.
EOF
    } > "$output"
}
