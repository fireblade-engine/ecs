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

The Git-ref comparison below uses the separate preliminary `ComparisonHarness`, not these reference-derived cases. It does not compare them and is not a completed Flecs comparison.

## Comparing Git refs

Use the root comparison harness to measure the shared workloads against two Git refs. The baseline is required; the candidate defaults to `HEAD`:

```sh
make benchmark-compare BASELINE_REF=1.4.3 CANDIDATE_REF=HEAD
```

Use `CANDIDATE_REF=WORKTREE` to include supported local tracked and untracked engine sources without changing the original worktree. Ignored source inputs and refs containing Git submodules are rejected rather than silently omitted. The command runs at least three independent processes per ref and writes a provenance-rich report and raw JMH outputs under `Benchmarks/results/`. `make benchmark-report BASELINE_REF=<ref> CANDIDATE_REF=<ref>` runs the same validated comparison and atomically updates `Documentation/Benchmarks/REPORT.md` only after success; it refuses to replace an existing report unless the caller explicitly sets `BENCHMARK_REPORT_OVERWRITE=1`. The report comes from the separate preliminary `ComparisonHarness`, not the package benchmarks or reference-derived cases; its raw outputs and provenance remain in the run artifacts.

A filtered smoke comparison can be run with the script directly:

```sh
./Scripts/benchmark-compare.sh 1.4.3 HEAD 3 'EntityIteration / 64'
```

Exact workload names are required for arithmetic. Workloads missing on either side are reported as unsupported, never as zero. The comparison records source snapshot and harness hashes, host/toolchain details, and whether the revisions use reference-type or value-type components; differing component models are not a like-for-like storage comparison. `Update7SystemsOnly` excludes world and system construction from timing on both suites.
