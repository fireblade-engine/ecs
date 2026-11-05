#!/usr/bin/env bash
# Verifies that a release candidate carries a benchmark report measured for its version: the committed report manifest must
# list a ref labelled with the version, and the code at that measured SHA must equal the candidate's (Scripts/release-check.sh).
# Reads everything from the candidate's committed tree, so it also works on a tag build with a detached checkout.
# Usage: Scripts/check-release-report.sh <version> [<candidate-ref>]   (default candidate: HEAD; a leading "v" is ignored)
# No committed report at all (releases before 2.0.0, backfills) is a notice, not a failure.
set -euo pipefail

version=${1:-}
candidate=${2:-HEAD}
[[ -n $version && $# -le 2 ]] || { printf 'Usage: Scripts/check-release-report.sh <version> [<candidate-ref>]\n' >&2; exit 64; }
version=${version#v}

here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
report=Documentation/Benchmarks/BenchmarkReport.html
manifest=Documentation/Benchmarks/BenchmarkReport.manifest.json

fail() { printf 'check-release-report: FAILED, %s\n' "$1" >&2; exit 1; }

git rev-parse --verify --quiet "$candidate^{commit}" > /dev/null || { printf 'check-release-report: invalid ref: %s\n' "$candidate" >&2; exit 2; }

if ! git cat-file -e "$candidate:$report" 2> /dev/null; then
    printf 'check-release-report: no %s in %s, skipping (releases before 2.0.0 carry no report)\n' "$report" "$candidate"
    exit 0
fi
git cat-file -e "$candidate:$manifest" 2> /dev/null || fail "$candidate has $report but no $manifest; re-render the report with the current tool"

sha=$(git show "$candidate:$manifest" | jq -er --arg v "$version" '[.refs[]? | select(.label == $v) | .sha][0] // empty') \
    || fail "$manifest in $candidate lists no ref labelled $version (stale or forgotten report; measure with REFS=<previous>,main:$version)"
[[ $sha =~ ^[0-9a-f]{40}$ ]] || fail "$manifest lists an invalid SHA for $version: $sha"
git rev-parse --verify --quiet "$sha^{commit}" > /dev/null || fail "measured commit $sha for $version does not exist in this clone (fetch full history)"

"$here/release-check.sh" "$sha" "$candidate"
