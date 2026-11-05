# Benchmarks

See how FirebladeECS revisions compare on a shared workload suite, and run the comparison yourself.

## Overview

The benchmark suite measures the same workloads at several committed FirebladeECS revisions, such as a release tag against `main`. The workloads cover entity creation, destruction and lookup, adding and removing components, iterating families, system updates and component events. Revisions with value-type components run each workload on both the `archetype` and the `sparseSet` storage (see <doc:ChoosingAStorage>), so a report also shows what the storage choice costs.

### How results are made trustworthy

Each revision is built once and measured in `k` independent process replicates, interleaved in a seeded random order. The replicate is the unit of analysis: the centre value is the median of the replicate medians, with a distribution-free order-statistic 95% confidence interval. A speed-up against the baseline is the Hodges–Lehmann estimate with its exact confidence interval, tested with an exact Mann–Whitney test and adjusted across all comparisons of a report with Benjamini–Hochberg. A change counts as `faster` or `slower` only when it is significant and clears the ±5% equivalence zone; an interval inside that zone is reported as `equivalent`, anything else as `inconclusive`.

### Read and reproduce

- The latest published report: [BenchmarkReport.html](https://fireblade-engine.github.io/ecs/latest/benchmarks/BenchmarkReport.html). Reports are published from 2.0.0 on.
- The statistical design and workload parity notes: [Methodology.md](https://github.com/fireblade-engine/ecs/blob/main/Documentation/Benchmarks/Methodology.md).

To measure revisions locally, pass comma-separated tags, branches or commit IDs. Results are saved under `Benchmarks/Results/<UTC timestamp>/`:

```sh
make benchmark-compare REFS=1.4.3,main:2.0.0 REPLICATES=10 BENCHMARK_FILTER='.*'
make benchmark-report RESULTS="Benchmarks/Results/<run>/*.json" REPORT_BASELINE=1.4.3
```

Without `BENCHMARK_FILTER` only 16 entities of every workload plus `entity.create.no-entities` (which only has 0 entities) run. `make benchmark-report` renders the single file `BenchmarkReport.html` from saved results and never runs benchmarks. See `Benchmarks/README.md` for all options.
