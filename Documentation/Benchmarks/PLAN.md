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

## Ordered micro-commit roadmap

The titles below are proposed imperative commit messages, not authorization to implement. Each implementation commit must be independently reviewable, bisectable, and revertable; keep the benchmark package buildable and do not break existing entry points between commits. The current comparison path is already nonworking because its expected `Benchmarks/ComparisonHarness/Package.swift` is absent; treat that as a known baseline defect, not a passing check or a regression caused by this work.

### Phase A — settle scope and measurement feasibility

1. **Inventory reference workloads and compatibility**
   - **Scope:** Reconcile every concrete registration at the pinned reference revision—including the entity-suite source discrepancy, conditional event/publish/update registrations, and extended cases—with the partial package workloads. Record stable identities, setup population, operation and match counts, timed boundaries, reset/warmup behavior, normalization, component model, backend availability, and per-ref parity (`equivalent`, `semantic difference`, or `unsupported`) in the existing benchmark documentation and focused expectations. Preserve unrelated iteration/storage cases. Do not call an event or extended case unsupported until the registrations and Fireblade API have been checked.
   - **Depends on:** Nothing.
   - **Focused evidence:** A registration-to-identity reconciliation with no unexplained registered cases; focused tests/expectations for identity uniqueness and the documented `1.4.3` reference-component versus current value-component/backend matrix. In particular, resolve the existing three-component lookup, add-component timing, iteration membership/normalization, and two-/seven-system parity questions rather than inheriting names as proof.
   - **Review gate:** User reviews the inventory and parity classifications before suite changes begin.

2. **Verify lossless benchmark statistics export**
   - **Scope:** Inspect the actually pinned ordo-one 1.38.1 result/statistics APIs and formats. Establish, with package-produced data, whether a supported export and decode round trip retains every available metric, statistic, value, and unit. Record the evidence and limitations in the existing benchmark documentation. A one-case spike or synthetic JMH fixture is exploratory evidence only, not proof of complete export.
   - **Depends on:** Step 1's workload/metric inventory.
   - **Focused evidence:** A representative package-produced result with multiple metrics/statistics; compare all exposed values and units before/after the proposed serialization. Do not finalize a result schema or claim raw-sample retention unless the package output demonstrates it.
   - **Stop condition:** If no supported lossless path is established, stop and bring the limitation/options back for user approval; do not silently fall back to p50-only JMH parsing.
   - **Review gate:** User approves the evidence and export direction before committing to a schema or implementing the result pipeline.

### Phase B — build and verify the shared workload suite

3. **Build a shared one-workload compatibility slice**
   - **Scope:** Choose the smallest existing package/harness arrangement that can run one inventoried workload against committed `1.4.3` and current sources. Add only the required reference/value component and backend adapters, plus correctness checks for population, operation count, and final state. Keep existing comparison callers untouched. Decide whether the preliminary harness is reusable or redundant from this working slice; do not add or maintain its missing manifest merely to make the old path progress.
   - **Depends on:** Approved steps 1–2.
   - **Focused evidence:** Compile and run the same small workload/configuration against both committed revisions; assert matching workload identity and intended work/state, while explicitly reporting representation/backend differences. Use the existing benchmark-package tests for fixture assertions; use `make build-release` for the engine build where applicable. No full benchmark run.
   - **Review gate:** User reviews the adapter surface, actual cross-revision evidence, and chosen shared-suite location before additional workloads are ported.

4. **Port entity creation and lookup workloads**
   - **Scope:** Add only applicable empty/minimal creation, destruction, and zero/one/two/optional-three-component lookup cases from the inventory. Make setup/timed work, lookup count, and batch normalization explicit. Do not emulate native bulk operations with loops or rename semantic mismatches as equivalent.
   - **Depends on:** Step 3's working shared slice.
   - **Focused evidence:** Small-count tests assert created/destroyed entities, matched lookup counts, component values, and normalized operation counts; compile/run the selected cases on `1.4.3` and current. Preserve existing package benchmarks outside the comparison suite.

5. **Port component mutation workloads**
   - **Scope:** Add applicable add, remove/add, and other registered mutation cases with reference-matching occupancy and timed boundaries. Reset or reconstruct state when needed so warmup/scaled iterations do not silently change the amount of work. Keep an explicit semantic-difference classification where exact matching is impossible.
   - **Depends on:** Step 3 and the mutation entries in step 1.
   - **Focused evidence:** Small-count tests assert component/entity counts and pre/post state across repeated operations; selected workload smoke checks exercise both component models without asserting timing thresholds.

6. **Port reference iteration workloads**
   - **Scope:** Add applicable one-, two-, and mixed-three-component populations and reference membership distribution. Keep created entities, family matches, and visits distinct. Resolve the existing half-population behavior and normalization difference before labeling any case equivalent; retain unrelated iteration/storage benchmarks.
   - **Depends on:** Step 3 and the iteration entries in step 1.
   - **Focused evidence:** Extend focused population/iteration tests to assert per-family membership and visited counts at empty, small, odd, and representative mixed populations, for each available backend; verify value reads and stable identities.

7. **Port update and applicable extended workloads**
   - **Scope:** Add the inventoried uniform/mixed two-system and applicable seven-system scenarios, then only event/extended operations verified as registered and expressible. Preserve operation order, setup/timed boundaries, accumulator/observable work, and state reset semantics. Record unsupported operations with concrete reasons; do not relabel `Update7SystemsOnly` as equivalent without evidence.
   - **Depends on:** Step 3 and the system/event/extended entries in step 1.
   - **Focused evidence:** Small-count tests assert setup population, each system's state transition/count, reset/warmup behavior, and final state; selected smoke cases cover every supported scenario and classify unavailable combinations explicitly.
   - **Review gate:** User reviews the complete suite, per-ref parity matrix, and focused correctness evidence before result production is added.

### Phase C — connect results, runner, and report

8. **Write validated full-statistics results**
   - **Scope:** Implement the self-contained per-ref JSON writer using only the export path approved in step 2. Include requested ref and full SHA, run/suite/configuration identity, component model/backend/capabilities, toolchain/build/host provenance, metric names/units, all verified statistics, and parity/availability notes. Keep each result independently interpretable; do not reduce or round values.
   - **Depends on:** Steps 2–7.
   - **Focused evidence:** Encode/decode round-trip tests compare every supported metric/statistic/value/unit against package-produced results; schema validation rejects missing required provenance, malformed values, and unsupported unit claims. If the gate in step 2 was not passed, this commit does not proceed.

9. **Run a list of committed refs in isolation**
   - **Scope:** Extend the committed-ref runner to accept a list, resolve and validate every input to a full SHA before any build/run, reject invalid or duplicate refs, and run the same committed suite/configuration against isolated source snapshots. Emit one result per ref, preserve requested-name and resolved-SHA provenance, isolate state/artifacts, and make missing capability/unsupported workloads explicit. Exclude `WORKTREE` and uncommitted source. Retain existing caller behavior until the final cutover.
   - **Depends on:** Steps 3–8.
   - **Focused evidence:** Runner tests with controlled/fake executions prove all-ref validation precedes execution, snapshots do not share mutable source/state, each accepted ref produces exactly one independently valid result, and failure/missing-capability paths do not leave partial published results. Run the updated `make test-benchmark-compare` only after its tests target this implementation; its present missing-manifest failure is known baseline behavior, not evidence of a pass.

10. **Render N-way reports from saved results**
    - **Scope:** Make report generation consume three or more saved JSON inputs only. Match by stable identity, metric, statistic, and compatible units; display all comparable statistics with units/provenance; mark missing, unsupported, or incompatible values unavailable; guard zero baselines; render the required Markdown tables and Mermaid charts without changing inputs. Retain guarded publication behavior and do not invoke the runner from this path.
    - **Depends on:** Step 8's validated schema; step 9's result contract.
    - **Focused evidence:** Fixture tests with at least three refs cover multiple statistics beyond p50, missing metrics/workloads, dimension-compatible and incompatible units, zero baselines, unsupported availability, and deterministic output. A stub/call counter proves report generation does not invoke a benchmark command or alter source JSON.

11. **Switch comparison callers to the validated pipeline**
    - **Scope:** Atomically update the existing Makefile targets, scripts, their tests, and `Benchmarks/README.md` to the new producer/report flow. Preserve existing target names and two-ref use where compatible, and document any unavoidable CLI change in the same commit. Remove the preliminary comparison harness only if the replacement suite and all callers are already covered; otherwise repair it only if it is the selected minimal shared suite. Do not overwrite `Documentation/Benchmarks/REPORT.md` or commit run artifacts without explicit approval.
    - **Depends on:** Steps 8–10 and successful focused tests for the replacement paths.
    - **Focused evidence:** `make test-benchmark-compare` exercises the final command contracts, validation/failure behavior, no-rerun report path, and publication guard; documentation examples match the actual Makefile interface. `make test` remains the official ECS package test command. Do not claim the old comparison command passed before cutover; distinguish its known missing-manifest failure from new regressions.
    - **Review gate:** User reviews the full caller/docs diff and focused verification before any cross-version smoke or publication.

### Phase D — approved validation only

12. **Validate approved reference and current runs** — **validation gate, not an automatic commit**
    - **Scope:** After step 11 review, run an agreed low-count smoke selection against committed `1.4.3` and current refs, inspect result parity/provenance, resource use, and report output. Present full-run workload count, expected duration/resource cost, and any remaining unsupported cases for review. Run the full workload set only after the user explicitly approves that cost and scope.
    - **Depends on:** Step 11 and explicit user approval for the smoke. Full execution additionally depends on smoke review and separate explicit full-run approval.
    - **Focused evidence:** The smoke must build each requested committed snapshot, produce one valid JSON per ref, round-trip the full available statistics, and render a report without rerunning measurements. Use the checked-in Makefile commands (`make build-release`, `make test`, and the final comparison targets) where applicable; `make benchmark` runs the package's broad workload set and is not a default smoke. No test/build/full benchmark is authorized by this plan itself.
    - **Commit rule:** A validation-only pass has no commit. Commit a generated report or benchmark artifacts only if the user separately approves those exact deliverables; never manufacture a commit for a run with no accepted repository delta.

Review checkpoints are mandatory between phases: after steps 1–2; after steps 3–7; after steps 8–10; after step 11; and after the smoke before any full run. A review checkpoint is not permission to start the next phase until the user approves it.
