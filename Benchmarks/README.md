# Benchmarks for FirebladeECS

Originally seeded by replicating performance tests into a new form leveraging [benchmark](https://github.com/ordo-one/benchmark) [Documentation](https://swiftpackageindex.com/ordo-one/package-benchmark/main/documentation/benchmark).

The iteration-only (`IterOnly...`) and storage (`S2...`) benchmarks run on both storages of `Nexus(storage:)`: the name carries the storage in brackets, for example `IterOnlyForEachReadWrite [archetype]`. The `S2...` benchmarks are ported from the storage spike and cover iteration at several arities, filtered and fragmented families, 100k entities in permuted storage order, random access and structural churn.

Note: These are macro-benchmarks using `package-benchmark`. For micro-benchmarks or performance unit tests, use traits-gated unit test performance benchmarks (`swift test --traits benchmarks`).

To run all the available benchmarks from the repository root:

    make benchmark

or from this directory:

    swift package benchmark --format markdown

For more help on the package-benchmark SwiftPM plugin:

    swift package benchmark help

Creating a local baseline:

    swift package --allow-writing-to-package-directory benchmark baseline update dev
    swift package benchmark baseline list

Comparing to the baseline 'dev'

    swift package benchmark baseline compare dev

For more details on creating and comparing package-benchmark named baselines, read [Creating and Comparing Benchmark Baselines](https://swiftpackageindex.com/ordo-one/package-benchmark/main/documentation/benchmark/creatingandcomparingbaselines).

## Reference workload status

[`abeimler/ecs_benchmark`](https://github.com/abeimler/ecs_benchmark) at `98678f746e0e2f04c37a3332453c8d98daa94f92` is C/C++ source used for workload design only, not a dependency. The new create, destroy, remove-add, and lookup cases are a partial Swift port, not a completed Flecs comparison. Reference registry teardown is timed; Swift create/destroy excludes teardown. Published reference results are not like-for-like because the machine, toolchain, metrics, and timing differ. Existing `Update7SystemsOnly` and other unported workloads do not match the reference.

For the entity suite, the reference is `flecs-entities/FlecsEntityBenchmarkSuite` (`EntityBenchmark.h`), not the separate `ECSBenchmark.h`, whose no-component case differs. Fireblade `Entity.get` returns optional value copies, unlike Flecs `get_mut`, which returns references. Flecs bulk-creation APIs have no matching Fireblade bulk API and are not emulated; Fireblade's `createEntities` helper creates entities one at a time. `UnpackThreeComponents` is implemented but is not exact parity: it creates N entities, while the upstream half-components-vector bug means only the ceil(N/2) even-index entities are looked up. Its `DataComponent` is a simplified pair of `Int32` values, not the reference `Data`/RNG layout.

`AddComponent` also differs: Fireblade removes `Position` from the whole batch before timing, while upstream removes each entity immediately before its timed add. This changes timed storage occupancy and timing boundaries, so the results are not exact parity.

Throughput is reported per benchmark invocation (batch). For `UnpackThreeComponents`, N is the created-entity count, not the lookup count; when N > 0, per-lookup normalization uses ceil(N/2), not N.

The Git-ref comparison described below uses the shared suite (`ECSCompatBenchmark`), not the package benchmarks above. It is not a completed Flecs comparison.

## Shared comparison suite

`ECSCompatBenchmark` (workloads in the `ECSCompatSuite` library) is the one suite that compiles against every FirebladeECS revision, so the same committed source can be measured at several Git refs.

- **Workloads:** 19 identities such as `entity.create.minimal`, `component.add`, `iteration.two`, `system.update.basic.uniform` and `event.component.publish.mixed`. A benchmark is named `<identity> [<backend>] / <scale>`. Revisions with the value-type model run the `archetype` and `sparseSet` backends; the class-component model of `1.4.3` has one `default` backend.
- **Adapter:** `CompatAdapter.swift` is the only file that knows about the component model (`#if ECS_CLASS_COMPONENTS`). Each revision uses its native path: value components go through `Family.forEach(reading:writing:)`, class components are mutated in place.
- **Parity labels:** every workload is labelled `adapted(<reason>)` or `equivalent`. All current workloads are `adapted`; the reason names the difference from the reference (timing boundary, population, native API). The label is stored in the result file and printed in the report.
- **Unsupported:** ten reference workloads are listed with a reason in `CompatUnsupported.all` and never approximated: bulk creation/destruction (`entity.create.empty-bulk`, `entity.create.minimal-bulk`, `entity.destroy.minimal-bulk`), dispatcher events (`event.dispatch.*`, four), observer events (`event.observer.*`, two) and the receiver (`event.receiver.post-update.mixed`).
- **Metrics:** wall clock, CPU total, throughput, peak resident memory and malloc count, declared once in `CompatConfiguration.swift`. 
- **Scales:** as the upstream reference (`CreateRange(0, 2'097'152, 2)`): 0 and every power of two through 2,097,152 (23 values); `entity.create.no-entities` is registered once.
- **Setup lifetime:** `entity.lookup.*`, `component.remove-add`, `iteration.*`, `system.update.*` and `event.component.*` build their state once per benchmark and keep it across iterations (released afterwards); `entity.create.*`, `entity.destroy.minimal` and `component.add` rebuild untimed state before every iteration.
- **Sampling:** every workload is time-based like Google Benchmark's defaults upstream: `maxDuration` 0.5 s, no warmup, a high iteration cap. The package budget is wall time since the benchmark started, including setup, and there is no minimum iteration count, so per-iteration-setup workloads get less measured time than upstream's 0.5 s, especially at large scales; persistent workloads' pass count and world state can differ by revision, as upstream. A full run through 2,097,152 entities is expensive; measure cost with a filter first.
- **Tests:** `make test-benchmarks` (population and operation counts, state mutation, schema round trips, report rendering). `make test-benchmark-scripts` tests the runner and snapshot shell scripts.

## Comparing Git refs

Measure the suite at one or more committed refs (tags, branches or SHAs). Each ref is resolved once to a SHA and built and measured in its own isolated snapshot; uncommitted changes are never measured.

```sh
make benchmark-compare REFS=1.4.3,main
```

The command prints one `result: <path>` line per ref. Files land in a new run directory `Benchmarks/.results/<UTC timestamp>/` (gitignored) as `<ref>-<sha12>.json`. If a ref fails, later refs are not started, finished results are kept and a rejected measurement is kept under `.failed/`. Warnings are printed when toolchain, host or benchmark set differ between refs.

Selection:

- **Smoke (default):** without a filter only the smallest scale of every workload runs.
- **Full:** `BENCHMARK_FILTER='.*' make benchmark-compare REFS=...` runs every workload and scale. `BENCHMARK_FILTER` takes a regular expression that must match the whole benchmark name (the package uses `wholeMatch`, so `/ 16$` alone selects nothing; write `.* / 16$`), for example `BENCHMARK_FILTER='iteration\..* / 16'`; in a Makefile recipe or inline `make` assignment a literal `$` must be written `$$`. A filter that matches nothing fails before measuring, naming the filter.

The runner script offers more options (`--suite-ref`, `--out`); running it without arguments prints the usage.

## Result files

Each file is self-contained JSON (`schema` `fireblade-ecs-benchmark-result`, `schemaVersion` 1) with the keys `run` (id, timestamps, batch id), `ref` (requested name, full SHA, component model, backends), `suite` (suite SHA, filter, configuration hash), `packages` (resolved pins), `toolchain`, `host`, `workloads` (identity, upstream name, parity), `unsupported`, `benchmarks` (one per benchmark name with identity, backend and scale) and `baseline`, the package-benchmark native baseline embedded unchanged with every statistic at the package's precision. A file is validated when it is written and when it is read:

```sh
cd Benchmarks && swift run -c release ECSBenchmarkResults validate <result.json>
```

## Reports

`make benchmark-report` renders a Markdown report from saved result files only (two or more); it builds the `ECSBenchmarkResults` tool in release mode and never runs benchmarks.

```sh
make benchmark-report RESULTS="Benchmarks/.results/<run>/1.4.3-<sha>.json Benchmarks/.results/<run>/main-<sha>.json" \
    REPORT_OUTPUT=report.md REPORT_BASELINE=1.4.3 REPORT_TITLE="ECS 1.4.3 vs main"
```

`REPORT_OUTPUT` defaults to `Benchmarks/.results/report.md` and an existing output file is refused unless `REPORT_OVERWRITE=1` is set; `REPORT_BASELINE` (a requested ref name) defaults to the first file; `REPORT_TITLE` is optional. The report has a provenance table per ref, warnings about differing configuration, parity notes and the unsupported list, then per workload, scale and metric a table of all statistics with deltas and a Mermaid chart of p50. Values missing or incomparable print `unavailable`, never zero.

`Documentation/Benchmarks/REPORT.md` is generated from saved result files with this command; do not edit it by hand.

## Make targets

| Target | Purpose |
| :--- | :--- |
| `make benchmark` | Run the broad package benchmarks of this package |
| `make benchmark-compare REFS=a,b,c [BENCHMARK_FILTER=...]` | Measure refs and save one validated result file each |
| `make benchmark-report RESULTS="a.json b.json" [REPORT_OUTPUT=...] [REPORT_BASELINE=...] [REPORT_TITLE=...] [REPORT_OVERWRITE=1]` | Render a report from saved results |
| `make test-benchmarks` | Swift tests of this package |
| `make test-benchmark-scripts` | Shell tests of the runner and snapshot scripts |
