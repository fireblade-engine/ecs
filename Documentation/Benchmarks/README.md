# Benchmarks

Benchmark documentation of FirebladeECS.

- [Methodology.md](Methodology.md): plan, workload inventory, parity labels and the statistical design.
- No benchmark result is recorded on `main` yet. The first run is `REFS=1.4.3,2.0.0` at the 2.0.0 tag; its report is committed as `Documentation/Benchmarks/BenchmarkReport.html`.
- Generate and run: `make benchmark-compare REFS=<a>,<b>` and `make benchmark-report RESULTS="..."`, see [Benchmarks/README.md](../../Benchmarks/README.md).
