# Git-ref Benchmark Suite — Methodology

Current specification of the git-ref benchmark suite: one shared ordo-one benchmark suite for committed FirebladeECS refs, one self-contained JSON result per ref and replicate, and a report command that compares saved results without rerunning benchmarks. Usage lives in [`Benchmarks/README.md`](../../Benchmarks/README.md).

**Recorded results:** none on `main`. Decision 2026-11-03: no result is recorded until the 2.0.0 tag. The first real run is `make benchmark-compare REFS=1.4.3,2.0.0`; its report is then committed as `Documentation/Benchmarks/BenchmarkReport.html`. `Scripts/sync-documentation.sh` publishes that file only if it exists.

## Scope and rules

- [`abeimler/ecs_benchmark`](https://github.com/abeimler/ecs_benchmark) (pinned at [`98678f7`](https://github.com/abeimler/ecs_benchmark/tree/98678f746e0e2f04c37a3332453c8d98daa94f92/benchmark/benchmarks)) is workload inspiration only: not a dependency, no direct Flecs comparison, no parity claim from workload names alone.
- Workloads follow the upstream logical intent, not byte-identical implementations. Differences in operation, representation or timing are documented per workload. A native operation that a revision lacks is `unsupported`; an API-based emulation is never presented as that native operation.
- Only committed refs (tag, branch, SHA) are compared. Every ref is resolved to a full SHA once, before any build. Uncommitted source and a `WORKTREE` input do not exist.
- No new package dependencies. The result tool, runner and report need only the Benchmark package already pinned in `Benchmarks/Package.resolved` (1.38.1).
- Component model follows each revision: `1.4.3` uses class components (`Component: AnyObject`), current revisions use value components (`@Component`) on the `.archetype` and `.sparseSet` backends. The model and backend are recorded per result and never presented as one representation.

## Workload inventory and parity

All workloads are defined once in the library target `ECSCompatSuite` and compiled per ref. A per-revision adapter hides the component-model difference; the runner picks it by detecting `protocol Component: AnyObject` in the snapshot (compile condition `ECS_CLASS_COMPONENTS`), never by ref name. Each workload has a stable identity, an upstream name, a parity kind with reason, and a `persistsState` flag; the manifest is part of every result file.

Scales are the 23 upstream scales (0 and every power of two up to 2,097,152; `entity.create.no-entities` is a single case). Sampling is time-based for every workload (`maxDuration` 0.5 s, no warmup). The Benchmark package counts untimed setup against that budget, so workloads with per-iteration setup (create, destroy, add) get less measured time than upstream, especially at large scales. State built once and kept across iterations: lookup, remove-add, iteration, system update, component events. Fresh untimed per-iteration state: create, destroy, add.

| Identity | Upstream name (`BM_` omitted) | 1.4.3 / current |
| --- | --- | --- |
| `entity.create.no-entities` | `CreateNoEntities` | applicable |
| `entity.create.empty`, `.warm` | `CreateEmptyEntities` | applicable (`.warm` has no upstream counterpart: types registered and storage allocated before timing) |
| `entity.create.minimal`, `.warm` | `CreateEntities` | applicable (same note) |
| `entity.destroy.minimal` | `DestroyEntities` | applicable |
| `entity.lookup.none` / `.one` / `.two` | `UnpackNoComponent`, `UnpackOneComponent`, `UnpackTwoComponents` | applicable; getters return values, upstream wrappers vary |
| `entity.lookup.mixed-three` | `UnpackThreeComponents` | applicable; population and `ceil(N/2)` lookups match, the payload layout differs |
| `component.remove-add` | `RemoveAddComponent` | applicable |
| `component.add` | `AddComponent` | applicable with a semantic difference: the batch is removed before one timed add pass |
| `system.update.basic.uniform` / `.mixed` | `SystemsUpdate`, `SystemsUpdateMixedEntities` | applicable; two explicit systems, not proven equivalent to the upstream application |
| `system.update.complex.uniform` / `.mixed` | `ComplexSystemsUpdate`, `ComplexSystemsUpdateMixedEntities` | applicable; seven systems, not proven equivalent |
| `iteration.one` / `.two` / `.mixed-three` | `IterateSingleComponent`, `IterateTwoComponents`, `IterateThreeComponentsWithMixedEntities` | applicable; upstream timing boundaries differ per wrapper; mixed membership recipe matches |
| `event.component.publish.mixed`, `.publish-update.mixed` | `PublishEventsViaComponent…`, `PublishAndUpdateEventsViaComponent…` | applicable as component churn; both refs lack a type-wide clear, so the marker is removed per entity |
| `entity.create.empty-bulk`, `entity.create.minimal-bulk`, `entity.destroy.minimal-bulk` | `CreateEmptyEntitiesInBulk`, `CreateEntitiesInBulk`, `DestroyEntitiesInBulk` | unsupported: no native bulk factory (`createEntities(count:)` loops) |
| `event.dispatch.*`, `event.observer.*`, `event.receiver.*` | dispatcher, observer and receiver event workloads | unsupported: no arbitrary-event dispatcher, observer or receiver API |

Unsupported workloads are listed with their reason in the manifest and the report; they are never approximated silently. The current revision runs both backends; `1.4.3` has no selectable backend and is not given a two-backend matrix. Correctness checks (population, operation and match counts, state mutation) live in `CompatSuiteTests`.

## Result schema

One file per ref and replicate, `<run-dir>/<sanitized-ref>-<short-sha>.json`, written by the snapshot's own `ECSBenchmarkResults write` so the workload manifest reflects that ref's adapter. Input is the plugin's native baseline (`benchmark baseline update`) decoded through an app-owned mirror of the baseline envelope; the writer refuses Benchmark or hdrhistogram-swift versions other than the pinned ones. The validator rejects a wrong schema or version, wrong pins, missing provenance and benchmark names that do not parse to a known identity.

Top-level keys: `schema` = `"fireblade-ecs-benchmark-result"` with `schemaVersion`; `run` (id, start and finish, ISO 8601 UTC); `ref` (requested name, full SHA, component model, backends); `suite` (SHA, target, filter, configuration hash over suite SHA, filter, enabled metrics and iteration constants); `packages` (every post-resolve pin); `toolchain` (`swift --version`, build mode `release`); `host` (OS, architecture, CPU model, cores, memory); `workloads`; `unsupported`; `benchmarks` (name with parsed identity, backend, scale); `baseline` (native envelope, embedded unchanged); and an optional `replicate` (index, count, round, position, seed, batch id). Files without replicate fields count as replicate 1 of 1. Statistics keep the package's precision; raw samples are not required.

## Runner

`make benchmark-compare REFS=a,b,c` runs `Scripts/benchmark-run-refs.sh`; one ref per snapshot is built by `Scripts/benchmark-snapshot.sh`.

- **Snapshot:** the ref's committed tree is extracted (`git archive` via a temporary index), its `Benchmarks/` directory replaced by the suite from one clean suite commit, the library directory kept named `ecs`, and dependencies resolved with `--force-resolved-versions` from the committed `Package.resolved`.
- **Protocol:** each ref is built once and run k times as independent processes in interleaved rounds; every round runs each ref once in an order shuffled by a recorded seed (`REPLICATES=`, `SEED=`; default k = 1). The host check runs before every replicate. Limits: one build per ref (code-layout effects are not sampled); conclusions hold for the recorded host and toolchain only.
- **Stale refs:** a local branch behind its upstream is refused before any build, with both short SHAs and counts. `ALLOW_STALE_REFS=1` turns the refusal into a warning. Tags and raw SHAs are not checked.
- **Output:** `Benchmarks/Results/<run-id>/` (gitignored). A finished measurement that fails wrapping or validation is kept in `.failed/`.

## Statistical design v3

Iterations of one run are not independent, and one process per ref cannot see run-to-run variation; a test on iterations overstates confidence, and hundreds of uncorrected tests produce false positives. The replicate is therefore the unit of analysis, and every statistic is exact, non-parametric and deterministic (no resampling; the report is byte-reproducible).

- **Per replicate:** the median of the iterations, from the stored histogram.
- **Centre and error bar** per series and scale: the median of the k replicate medians, with the distribution-free order-statistic 95% CI of that median (largest l with P(Binom(k, ½) ≤ l − 1) ≤ 0.025 gives [x₍l₎, x₍k−l+1₎]; k = 10 gives [x₍2₎, x₍9₎], coverage 97.9%). The exact coverage is printed; below 6 replicates the bar is omitted and marked.
- **Effect:** `speed (×)` = baseline ÷ series (above 1 is faster). Estimator: Hodges–Lehmann on the log replicate medians, exp of the median of all pairwise log differences. Its 95% CI comes from the Mann–Whitney order statistics of those differences; it is exact only when no replicate medians tie and approximate with ties. `change (%)` = (1 ÷ speed − 1) × 100.
- **Test:** exact two-sided Mann–Whitney U on the replicate medians (permutation distribution conditional on ties, by dynamic programming over doubled midranks). **Multiplicity:** Benjamini–Hochberg at q = 0.05 over all wall-clock comparisons of one report. Other metrics are descriptive only.
- **Verdict**, δ = 5% symmetric on the log scale (zone [1/1.05, 1.05]): `faster` q < 0.05 and CI low > 1.05; `slower` q < 0.05 and CI high < 1/1.05; `equivalent` CI inside the zone; `inconclusive` otherwise; `n/a (k replicates)` when a side has fewer than 2 replicates.
- **Drift diagnostic:** Kendall's τ between round and replicate median per series and cell (at least 3 replicates), exact p with a normal approximation under ties, BH-adjusted; flagged cells are counted and listed in the methods section.
- **Minimum k:** with k = 5 the smallest attainable p (0.0079) never passes BH over several hundred tests; k = 10 reaches 1.1×10⁻⁵, so 10 is the minimum for meaningful verdicts. One replicate renders medians and the within-run IQR with `n/a (1 replicate)` for intervals, `q` and verdicts.
- **Tests** use brute-force enumeration as an independent oracle plus published textbook examples.

## Report output

`ECSBenchmarkResults report <result.json>... --output-dir DIR [--baseline <ref>] [--title <text>] [--overwrite]` (`make benchmark-report RESULTS="a.json b.json"`) reads and validates saved results only and writes one self-contained `DIR/BenchmarkReport.html`: inline CSS and script, data embedded as JSON, no external resources, works offline from `file://`.

- **Sections:** table of contents, static "How to read this report" with generic illustrative examples (marked as such, not taken from the report), glossary of every abbreviation, one section per workload, methods (protocol, estimators, tests, δ, q, seed, drift, limits), provenance, parity notes, unsupported list.
- **Plots:** drawn in the browser from the embedded data: per-entity cost, total time and `speed (×)` against scale, with CI error bars or ribbon, the ±δ zone and a within-run IQR band labelled as spread, not uncertainty. Every plot, including the per-entity plot, has a log/linear toggle plus one global toggle. Hovering or focusing a point shows a tooltip (ref, backend, entities, median, 95% CI, speed, verdict) with crosshair lines and axis value highlights, and highlights the matching table row. A missing scale is a gap, never a zero.
- **Tables:** per series `median`, `CI low`, `CI high`, `replicates`, `iterations`; per comparison `speed (×)`, `CI low (×)`, `CI high (×)`, `change (%)`, `q`, `verdict`. Units sit in column headers. Cells are tinted by verdict (faster green, slower red, otherwise neutral) and always carry a symbol (▲ ▼ =) so colour is never the only signal. Other metrics and percentiles sit in a collapsed block.
- **Tests:** the plot script's pure functions run under `node` in the test suite when `node` is installed (skipped otherwise; node is not a dependency).
