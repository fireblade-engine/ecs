# Benchmarks

Benchmark documentation of FirebladeECS.

- [Methodology.md](Methodology.md): scope, workload inventory and parity, result schema, runner, statistical design and report output.
- No benchmark result is recorded on `main` yet. The first run is `REFS=1.4.3,main:2.0.0 REPLICATES=10 BENCHMARK_FILTER='.*'` (measured on `main` before the 2.0.0 tag exists); its report is committed as `Documentation/Benchmarks/BenchmarkReport.html`.
- Generate and run: `make benchmark-compare REFS=<a>,<b>` and `make benchmark-report RESULTS="..."`; the exact commands for the first report, and how to run unattended under `caffeinate -s`, are in [Benchmarks/README.md](../../Benchmarks/README.md) ("Publishing the first report").

## Release benchmarks

Release results are measured before the tag exists, so the version label is given up front with `<ref>:<label>` (split at the first `:`). The ref is measured as usual; the label becomes the requested name in result files and the report.

1. Freeze `main`: no source changes until the release is tagged.
2. Measure the previous tag against `main` labeled with the upcoming version: `make benchmark-compare REFS=<prev-tag>,main:<version> REPLICATES=3`.
3. Render the report: `make benchmark-report RESULTS="<result files>"`. Next to `BenchmarkReport.html` it writes `BenchmarkReport.manifest.json`, which lists the requested label and full SHA of every measured ref; commit both.
4. Open a PR with the results. Squash merges create a new commit, so the measured commit must already be on `main` (measure `main` or `origin/main`, never the PR branch).
5. After the merge, check the release locally before tagging: `make check-release-report VERSION=<version> TO=<merge-commit>` (`TO` defaults to `HEAD`). It reads the committed manifest, finds the ref labelled `<version>` and runs `release-check` between that measured SHA and the merge commit. It fails when the report has no manifest, when no ref carries the label (stale or forgotten report), when the measured commit is missing from the clone, or when `Sources`, `Package.swift` or `Package.resolved` differ (the differing paths are listed). It passes with a notice when no report is committed at all (releases before 2.0.0). This supersedes working out `FROM` and `TO` by hand; `make release-check FROM=<measured-sha> TO=<merge-commit>` remains the underlying primitive.
6. Tag the merge commit.
7. CI runs the same check (`make check-release-report`) first on every tag push and publishes no documentation for a tag that fails it. After tagging, confirm the tag's Documentation workflow run finished: build, deploy and the smoke test, which fetches `<version>/benchmarks/BenchmarkReport.html` and the `latest/benchmarks/` redirect.

The report's Ref SHA is the measured commit, which is one commit before the tag (the results PR itself); the release check is what proves the two carry the same code.
