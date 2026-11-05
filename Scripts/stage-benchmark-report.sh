#!/usr/bin/env bash
# Stages the benchmark report of a tag for publishing. A tag publishes a report only when its committed manifest has a ref
# labelled with the tag and the code is unchanged since that measured commit (Scripts/check-release-report.sh --optional).
# On success the report page is written to <staging-dir>/<tag>.html; no label or no report stages nothing and succeeds.
# A report that names the tag but fails a check stages nothing, prints a GitHub ::error annotation and exits 1, so the
# caller can publish the documentation anyway and fail afterwards; it leaves <staging-dir>/<tag>.withheld so that publishing
# also takes down a report of that tag published earlier. STAGE_ANNOTATION=warning downgrades the annotation (backfills).
# Usage: Scripts/stage-benchmark-report.sh <tag> <staging-dir> [<candidate-ref>]   (default candidate: the tag)
set -euo pipefail

tag=${1:-}
staging=${2:-}
[[ -n $tag && -n $staging && $# -le 3 ]] || { printf 'Usage: Scripts/stage-benchmark-report.sh <tag> <staging-dir> [<candidate-ref>]\n' >&2; exit 64; }
candidate=${3:-$tag}
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

rm -f "$staging/$tag.html" "$staging/$tag.withheld"
status=0
"$here/check-release-report.sh" --optional "$tag" "$candidate" || status=$?
case $status in
    0)
        mkdir -p "$staging"
        git show "$candidate:Documentation/Benchmarks/BenchmarkReport.html" > "$staging/$tag.html"
        printf 'stage-benchmark-report: staged the report for %s\n' "$tag"
        ;;
    10) ;;
    *)
        mkdir -p "$staging"
        : > "$staging/$tag.withheld"
        printf '::%s title=Benchmark report not published::The report that names %s failed the release check; the documentation is published without it.\n' "${STAGE_ANNOTATION:-error}" "$tag" >&2
        exit 1
        ;;
esac
