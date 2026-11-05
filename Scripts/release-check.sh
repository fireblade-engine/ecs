#!/usr/bin/env bash
# Verifies that the code shipped by a release candidate is the code that was benchmarked: Sources, Package.swift and
# Package.resolved must be identical between the measured ref and the release-candidate ref. DocC catalogs
# (Sources/**/*.docc) are excluded: documentation edits do not change performance.
# Usage: Scripts/release-check.sh <measured-ref> [<release-candidate-ref>]   (default candidate: HEAD)
set -euo pipefail

from=${1:-}
to=${2:-HEAD}
[[ -n $from && $# -le 2 ]] || { printf 'Usage: Scripts/release-check.sh <measured-ref> [<release-candidate-ref>]\n' >&2; exit 64; }

for rev in "$from" "$to"; do
    git rev-parse --verify --quiet "$rev^{commit}" > /dev/null || { printf 'release-check: invalid ref: %s\n' "$rev" >&2; exit 2; }
done

paths=(Sources Package.swift Package.resolved)
# Pathspec magic keeps the DocC catalogs out of the comparison.
excludes=(':(exclude,glob)Sources/**/*.docc/**')
if git diff --quiet "$from" "$to" -- "${paths[@]}" "${excludes[@]}"; then
    printf 'release-check: OK, %s and %s have identical %s\n' "$from" "$to" "${paths[*]}"
else
    printf 'release-check: FAILED, %s differs from the measured %s in:\n' "$to" "$from" >&2
    git diff --name-status "$from" "$to" -- "${paths[@]}" "${excludes[@]}" >&2
    exit 1
fi
