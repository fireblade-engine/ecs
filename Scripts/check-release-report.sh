#!/usr/bin/env bash
# Verifies that a release candidate carries a benchmark report measured for its version: the committed report manifest must
# list a ref labelled with the version, the manifest must belong to the committed report page, and the code at the measured
# SHA must equal the candidate's (Scripts/release-check.sh). Reads everything from the candidate's committed tree.
#
# Usage: Scripts/check-release-report.sh [--optional] <version> [<candidate-ref>]   (default candidate: HEAD; a leading "v" is ignored)
#
# Strict (default, the local pre-tag check of a dedicated benchmark release): a missing report, manifest or label fails.
# --optional (CI on tag pushes, where most tags are hotfixes without a report of their own): a missing report, manifest or
# label means "nothing to publish" and exits 10; a report that names the version must still pass every check.
# Exit codes: 0 verified, 1 failed, 2 invalid ref, 10 nothing to check (--optional only), 64 usage.
set -euo pipefail

optional="false"
if [[ ${1:-} == --optional ]]; then
    optional="true"
    shift
fi
version=${1:-}
candidate=${2:-HEAD}
[[ -n $version && $# -le 2 ]] || { printf 'Usage: Scripts/check-release-report.sh [--optional] <version> [<candidate-ref>]\n' >&2; exit 64; }
version=${version#v}

here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
report=Documentation/Benchmarks/BenchmarkReport.html
manifest=Documentation/Benchmarks/BenchmarkReport.manifest.json

fail() { printf 'check-release-report: FAILED, %s\n' "$1" >&2; exit 1; }
nothing() {
    if [[ $optional == true ]]; then
        printf 'check-release-report: %s, no benchmark report to publish for %s\n' "$1" "$version"
        exit 10
    fi
    fail "$1 (a dedicated benchmark release needs a report labelled $version; measure with REFS=<previous>,main:$version)"
}

command -v jq > /dev/null || fail 'jq is required'
git rev-parse --verify --quiet "$candidate^{commit}" > /dev/null || { printf 'check-release-report: invalid ref: %s\n' "$candidate" >&2; exit 2; }

git cat-file -e "$candidate:$report" 2> /dev/null || nothing "no $report in $candidate"
git cat-file -e "$candidate:$manifest" 2> /dev/null || nothing "$candidate has $report but no $manifest"

matches=$(git show "$candidate:$manifest" | jq -r --arg v "$version" '[.refs[]? | select(.label == $v)] | length') \
    || fail "$manifest in $candidate is not valid JSON"
[[ $matches -gt 0 ]] || nothing "$manifest in $candidate lists no ref labelled $version"
# A ref that names the version must carry a usable SHA, in --optional mode too.
sha=$(git show "$candidate:$manifest" | jq -r --arg v "$version" '[.refs[] | select(.label == $v) | .sha | strings][0] // empty')

# The page embeds the manifest it was rendered with; both files must come from the same render.
embedded=$(git show "$candidate:$report" | grep -m1 '^<script type="application/json" id="benchmark-manifest">' \
    | sed -e 's/^<script type="application\/json" id="benchmark-manifest">//' -e 's/<\/script>$//') || true
[[ -n $embedded ]] || fail "$report in $candidate embeds no manifest; re-render the report with the current tool"
[[ $(printf '%s' "$embedded" | jq -cS . 2> /dev/null) == "$(git show "$candidate:$manifest" | jq -cS .)" ]] \
    || fail "$manifest and the manifest embedded in $report differ in $candidate; they must come from one render"

[[ $sha =~ ^[0-9a-f]{40}$ ]] || fail "$manifest lists an invalid SHA for $version: $sha"
git rev-parse --verify --quiet "$sha^{commit}" > /dev/null || fail "measured commit $sha for $version does not exist in this clone (fetch full history)"

"$here/release-check.sh" "$sha" "$candidate" || fail "$candidate differs from $sha, the commit $version was measured at"
