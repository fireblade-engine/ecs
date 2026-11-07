# Benchmarks

Benchmark documentation of FirebladeECS.

- [Methodology.md](Methodology.md): scope, workload inventory and parity, result schema, runner, statistical design and report output.
- No benchmark result is recorded on `main` yet. The first run is `REFS=1.4.3,main:2.0.0 REPLICATES=10 BENCHMARK_FILTER='.*'` (measured on `main` before the 2.0.0 tag exists); its report is committed as `Documentation/Benchmarks/BenchmarkReport.html`.
- Generate and run: `make benchmark-compare REFS=<a>,<b>` and `make benchmark-report RESULTS="..."`; the exact commands for the first report, and how to run unattended under `caffeinate -s`, are in [Benchmarks/README.md](../../Benchmarks/README.md) ("Publishing the first report").

## Release benchmarks

Reports are sporadic: only dedicated benchmark releases get one, most tags (hotfixes) do not. A report belongs to the version it measures, named by the label in its manifest, and is published only by the run of that version's tag.

Release results are measured before the tag exists, so the version label is given up front with `<ref>:<label>` (split at the first `:`). The ref is measured as usual; the label becomes the requested name in result files and the report.

1. Freeze `main`: no source changes until the release is tagged.
2. Measure the previous tag against `main` labeled with the upcoming version: `make benchmark-compare REFS=<prev-tag>,main:<version> REPLICATES=3`.
3. Render the report: `make benchmark-report RESULTS="<result files>"`. Next to `BenchmarkReport.html` it writes `BenchmarkReport.manifest.json`, which lists the requested label and full SHA of every measured ref. The page embeds the same manifest, so the two files are tied to one render. Commit both.
4. Open a PR with the results. Squash merges create a new commit, so the measured commit must already be on `main` (measure `main` or `origin/main`, never the PR branch).
5. After the merge, run the strict local check before tagging: `make check-release-report RELEASE_VERSION=<version> RELEASE_TO=<merge-commit>` (`RELEASE_TO` defaults to `HEAD`). It fails when the report or manifest is missing, when the page and manifest come from different renders, when no ref carries the label (stale or forgotten report), when the measured commit is missing from the clone, or when the code drifted. Drift means any difference in `Package.swift`, `Package.resolved` or `Sources`, except DocC catalogs (`Sources/**/*.docc`); the differing paths are listed. `make release-check RELEASE_FROM=<measured-sha> RELEASE_TO=<merge-commit>` is the underlying drift primitive.
6. Tag the merge commit.
7. CI on the tag push publishes the documentation as for any tag. It publishes the report only if the committed manifest names the tag and the same drift check passes: the report then appears at `benchmarks/<version>/` on the documentation site, and `benchmarks/` (the landing page) shows the report of the highest version published so far, so backfills and out-of-order tags never replace a newer one. Reports of other versions stay. A tag whose manifest does not name it (a hotfix) publishes no report and runs no benchmark check. If the check fails for a tag that names itself, the documentation is still published, the report is withheld and the run fails with an error annotation after the deploy. Main runs and pull requests never publish reports. After tagging, confirm the tag's Documentation run finished (build, deploy, smoke test of `benchmarks/<version>/` and `benchmarks/`).

The report's Ref SHA is the measured commit, which is one commit before the tag (the results PR itself); the release check is what proves the two carry the same code.

GitHub Pages keys a deployment by commit SHA. When the tag points at the `main` commit that was already deployed (the usual case: the results PR is tagged right after merging), the tag's deploy reuses that earlier deployment, reports success and keeps serving the content without the new version and report; the smoke test then fails with 404. `gh-pages` itself is correct, so any later deploy from a new commit publishes it: merge the next change to `main` and confirm `benchmarks/<version>/` is live.
