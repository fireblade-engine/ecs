# Benchmarks

Benchmark documentation of FirebladeECS.

- [Methodology.md](Methodology.md): scope, workload inventory and parity, result schema, runner, statistical design and report output.
- No benchmark result is recorded on `main` yet. The first run is `REFS=1.4.3,main:2.0.0 REPLICATES=10 BENCHMARK_FILTER='.*'` (measured on `main` before the 2.0.0 tag exists); its report is committed as `Documentation/Benchmarks/BenchmarkReport.html`.
- Generate and run: `make benchmark-compare REFS=<a>,<b>` and `make benchmark-report RESULTS="..."`; the exact commands for the first report, and how to run unattended under `caffeinate -s`, are in [Benchmarks/README.md](../../Benchmarks/README.md) ("Publishing the first report").

## Release benchmarks

Release results are measured before the tag exists, so the version label is given up front with `<ref>:<label>` (split at the first `:`). The ref is measured as usual; the label becomes the requested name in result files and the report.

1. Freeze `main`: no source changes until the release is tagged.
2. Measure the previous tag against `main` labeled with the upcoming version: `make benchmark-compare REFS=<prev-tag>,main:<version> REPLICATES=3`.
3. Render the report: `make benchmark-report RESULTS="<result files>"`.
4. Open a PR with the results. Squash merges create a new commit, so the measured commit must already be on `main` (measure `main` or `origin/main`, never the PR branch).
5. After the merge, verify nothing shipped changed: `make release-check FROM=<measured-sha> TO=<merge-commit>`. It fails and lists the differing paths unless `Sources`, `Package.swift` and `Package.resolved` are identical.
6. Tag the merge commit.

The report's Ref SHA is the measured commit, which is one commit before the tag (the results PR itself); `release-check` is what proves the two carry the same code.
