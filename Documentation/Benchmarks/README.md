# Benchmarks

Benchmark documentation of FirebladeECS.

- [Methodology.md](Methodology.md): scope, workload inventory and parity, result schema, runner, statistical design and report output.
- No benchmark result is recorded on `main` yet. The first run is `REFS=1.4.3,2.0.0` at the 2.0.0 tag; its report is committed as `Documentation/Benchmarks/BenchmarkReport.html`.
- Generate and run: `make benchmark-compare REFS=<a>,<b>` and `make benchmark-report RESULTS="..."`; the exact commands for the first report, and how to run unattended under `caffeinate -i`, are in [Benchmarks/README.md](../../Benchmarks/README.md) ("Publishing the first report").
