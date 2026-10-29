# Git-ref Benchmark Suite — Living Plan

**Status:** design only. No implementation or benchmark run is authorized by this plan.

**Goal:** one repeatable ordo-one benchmark suite for committed FirebladeECS refs, one self-contained JSON result per ref, and a separate N-way Markdown/Mermaid report generator that consumes saved results without rerunning benchmarks.

## Scope and rules

- Use [`abeimler/ecs_benchmark`](https://github.com/abeimler/ecs_benchmark) only as workload inspiration. Do not add it as a dependency, run a direct Flecs comparison, or claim framework parity from workload names alone.
- Port every workload that Fireblade can express with equivalent semantics. Skip unsupported native operations instead of approximating them under the same name. Record the reason and affected ref/backend.
- Keep existing unrelated iteration and storage benchmarks. This work replaces the incomplete Git-ref comparison path, not the whole benchmark package.
- Compare only committed tags, branches, or commit IDs. Resolve every requested ref to a full SHA before starting. Never include uncommitted source or a special `WORKTREE` input.

## Verified starting point

- `Benchmarks/Package.swift` is already a separate Swift Benchmark package and resolves `https://github.com/ordo-one/benchmark` to **1.38.1** in `Benchmarks/Package.resolved`.
- The local `1.4.3` tag declares `Component: AnyObject, Sendable`; the checked-out current revision declares `Component: Sendable` and exposes `Nexus.StorageKind.archetype` and `.sparseSet`. Results must identify component model and backend; those differences are not evidence of equivalent storage behavior.
- Existing reference-derived cases are in `Benchmarks/Benchmarks/ECSBenchmark/ComparisonBenchmarks.swift`, `ReferenceIterationBenchmarks.swift`, and `ReferenceUpdateBenchmarks.swift`. The latter two provide useful starting fixtures for two-system uniform/mixed updates and one-, two-, and mixed-three-component iteration. `OneDimensionBenchmarks.swift` and `StorageBenchmarks.swift` also contain existing, non-reference workloads to preserve.
- The preliminary runner is incomplete: `Scripts/benchmark-compare.sh` copies `Benchmarks/ComparisonHarness/Package.swift`, but that file is absent. The script accepts a baseline/candidate pair and a special `WORKTREE` candidate; it runs repeated benchmark processes per side (three by default), while its JMH parser in `Scripts/benchmark-compare-lib.sh` retains only wall-clock p50. `Scripts/generate-benchmark-report.sh` invokes that runner, rather than consuming N saved result files. `Tests/benchmark-compare-tests.sh` also assumes the missing package manifest exists.
- `Benchmarks/README.md` documents existing semantic differences: `AddComponent` moves removal outside the timed loop, and the current three-component lookup population/count differs from the upstream helper. The existing `Update7SystemsOnly` case is not by itself proof of parity with the reference update cases. Preserve these as known mismatches until a workload-level comparison resolves them.
- Large existing scales reach millions of entities. Use a targeted low-count smoke selection before any full run.
- `Documentation/Benchmarks/REPORT.md` already exists and remains untouched during this planning task.

## Workload inventory and parity

Before implementation, inventory concrete benchmark registrations at the pinned reference revision [`98678f7`](https://github.com/abeimler/ecs_benchmark/tree/98678f746e0e2f04c37a3332453c8d98daa94f92/benchmark/benchmarks), especially [`EntityBenchmark.h`](https://github.com/abeimler/ecs_benchmark/blob/98678f746e0e2f04c37a3332453c8d98daa94f92/benchmark/benchmarks/EntityBenchmark.h), [`ECSBenchmark.h`](https://github.com/abeimler/ecs_benchmark/blob/98678f746e0e2f04c37a3332453c8d98daa94f92/benchmark/benchmarks/ECSBenchmark.h), and [`ExtendedECSBenchmark.h`](https://github.com/abeimler/ecs_benchmark/blob/98678f746e0e2f04c37a3332453c8d98daa94f92/benchmark/benchmarks/ExtendedECSBenchmark.h). Reconcile that inventory with current registrations and this repo's `Benchmarks/README.md`, which names an additional entity-suite source and notes differences in the no-component case.

| Family to inventory | Required treatment |
| --- | --- |
| Entity creation/destruction and entity/component lookup | Cover applicable empty/minimal creation, destruction, and zero/one/two/optional-three-component lookup cases. Make setup, timed region, lookup count, and batch normalization explicit. |
| Component changes | Cover add, remove/add, and other registered applicable mutations. Match whether removal/setup is timed and the storage occupancy during the timed operation; otherwise label the case as semantically different, not equivalent. |
| Iteration | Port applicable one-, two-, and mixed-three-component populations, including the reference's membership distribution. Keep entity count distinct from matched/visited count. |
| System updates | Inventory uniform and mixed update workloads, then any registered two- or seven-system variants. Compare only when work, state transitions, and setup/timing boundaries match; do not relabel the existing seven-system case as reference-equivalent without that check. |
| Events and extended cases | Verify whether the reference's conditional event/publish/update operations are actually registered and whether Fireblade has equivalent semantics. Include only validated matches; otherwise record unsupported or omit as framework-specific. |
| Bulk and dispatcher operations | Skip native bulk create/destroy when Fireblade has no matching bulk API; do not emulate it with a loop and call it bulk. Skip absent dispatcher/framework-specific operations. |

Assign each case a stable workload identity and document its setup population, operation count, state reset/warmup behavior, timed boundary, output normalization, component model, and parity classification (`equivalent`, `semantic difference`, or `unsupported`). Existing `Reference*` fixtures/tests may be reused after their semantics are checked; they do not establish parity merely by sharing a name.

## Proposed workflow

1. **One shared suite, thin adapters.** Keep benchmark definitions and configuration shared across refs. Add only the small adapter surface needed for the 1.x reference-component API versus current value-component API, and for available storage backends. Run the same workload definitions and configuration for each ref. Do not encode unsupported operations as no-op substitutes.
2. **Committed-ref runner.** Accept an arbitrary list, for example `--refs 1a1,2b2,3c3`. Resolve all names to full SHAs once; reject invalid or duplicate inputs before running. Build each ref from an isolated snapshot of its committed tree and use the same committed suite/configuration for every snapshot. Do not copy or overlay uncommitted source. Record the requested ref and resolved SHA separately. No default/current ref should be silently added.
3. **Consistent measurements.** Use the same release configuration, enabled metric set, iteration/scaling policy, setup and timing boundaries, and smoke/full selection for every ref. Preserve meaningful work with the package's black-hole mechanism and correctness assertions. Record whether setup/teardown is measured; do not change it to fit one version. A smoke run selects a small workload/count subset without changing workload semantics. Full-scale execution follows a successful smoke and explicit approval.
4. **One self-contained JSON result per ref.** Store all available statistics for every enabled metric without rounding or reducing the result to p50. Include requested ref, full SHA, run identity/time, suite/workload identity and configuration/hash, Fireblade component model and backend/capabilities, benchmark package version, Swift toolchain, build mode, host/OS/hardware, metric names, units, and parity/availability notes. Keep each file independently interpretable; do not require a sidecar or a later benchmark run to understand it.
5. **Statistics-export gate before schema choice.** First inspect the actual pinned ordo-one 1.38.1 output and result/statistics APIs using a representative smoke case. Verify which export formats retain every statistic the package makes available and whether encoding/decoding preserves those values and units. The current JMH parser proves only p50 retention; do not assume JMH is complete. Select the JSON representation only after this check. Preserve raw samples only if the actual supported output provides them; do not claim them otherwise. If no supported export is lossless, stop at that decision gate and bring the limitation/options back for approval rather than silently dropping statistics.
6. **Independent N-way report generator.** Read N existing result JSON files only; never launch the runner. Match results by stable workload identity, statistic, metric, and compatible unit. Compare and display every available comparable statistic, with explicit units and provenance. Convert units only where their dimensions are known compatible. Missing workloads/fields, unsupported backends, and incompatible units are `unavailable`, never zero or fabricated parity. Guard zero baselines: show absolute values/deltas where valid and mark ratios/percent changes unavailable. Render a Markdown table and Mermaid chart for each comparable numeric statistic/series; keep source JSON unchanged. The existing `Documentation/Benchmarks/REPORT.md` can remain the publication target only with validated output and an explicit overwrite guard.

## Phases and review gates

Each phase is a separate check-in; pause for user review before beginning the next.

- [ ] **Inventory and semantics:** map every upstream registration to a workload identity and classify applicability/parity for `1.4.3` and the current revision. Resolve the source discrepancy documented in `Benchmarks/README.md`.
- [ ] **Export feasibility:** prove the pinned package's lossless statistics path and record exactly which metric/statistic fields it emits. No JSON schema is final before this gate.
- [ ] **Shared suite and adapters:** consolidate/reuse applicable cases, preserve unrelated package benchmarks, and add correctness checks for population counts, operation counts, and state mutation.
- [ ] **Ref runner and results:** support more than two committed refs, isolated SHA snapshots, consistent config, complete per-ref JSON, and clear failure for unsupported refs or missing capabilities.
- [ ] **Report-only path:** validate N-way matching, all-statistic output, unit handling, missing values, zero baselines, Mermaid rendering, and that report generation does not invoke benchmarks.
- [ ] **Compatibility and performance validation:** after approval, build/smoke against `1.4.3` and current, then run the full agreed workload set only after smoke results and resource cost are reviewed.

### Acceptance checks

- Every applicable reference workload is either ported with recorded semantics or listed with a concrete unsupported reason; no unsupported operation is silently approximated.
- The same committed suite, configuration, and enabled metrics run against each requested ref; no `WORKTREE` or uncommitted source path is involved.
- Each ref produces one self-contained JSON file with full provenance and every statistic verified available from the pinned package export.
- The report generator consumes three or more independent fixture JSON inputs and compares all their available statistics without rerunning benchmarks. Fixtures cover a missing metric, a nonmatching workload, compatible units, a zero baseline, and multiple statistics beyond p50.
- `1.4.3` and current pass the approved build and targeted smoke checks. Full runs are repeatable, resource-bounded, and disclose semantic differences; no direct Flecs comparison is produced.

## Likely implementation touch points (not changed by this plan)

- `Benchmarks/Benchmarks/ECSBenchmark/ComparisonBenchmarks.swift`, `ReferenceIterationBenchmarks.swift`, `ReferenceUpdateBenchmarks.swift`, and only the necessary shared fixtures/tests; preserve unrelated `OneDimensionBenchmarks.swift` and `StorageBenchmarks.swift` cases.
- `Benchmarks/ComparisonHarness/**` and its missing package manifest: either complete and consolidate this shared suite or remove the redundant preliminary harness after its applicable work is migrated. Do not maintain two competing suites.
- `Scripts/benchmark-compare.sh`, `Scripts/benchmark-compare-lib.sh`, `Scripts/generate-benchmark-report.sh`, the benchmark targets in `Makefile`, and `Tests/benchmark-compare-tests.sh` for the committed-ref runner, result validation, and report-only fixtures.
- `Benchmarks/README.md` and, after approval, generated `Documentation/Benchmarks/REPORT.md` for the final workflow and report. No CI/pipeline files, permanent version metadata files, or unrelated architecture files are part of this plan.
