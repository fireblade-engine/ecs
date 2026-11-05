#!/usr/bin/env bash
# Tests for the gh-pages restore of Scripts/sync-documentation.sh (--restore-only) with a local bare repository as origin.
set -euo pipefail

script=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/Scripts/sync-documentation.sh
root=$(mktemp -d "${TMPDIR:-/tmp}/sync-documentation-tests.XXXXXXXX")
trap 'rm -rf "$root"' EXIT
fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
export GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@example.com GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@example.com

origin=$root/origin.git
git init -q --bare "$origin"

# The working repository stands in for a CI checkout: it has a main branch with a tracked file and a staged change.
work=$root/work
git init -q -b main "$work"
echo code > "$work/code.txt"
git -C "$work" add code.txt
git -C "$work" commit -qm code
git -C "$work" remote add origin "$origin"
git -C "$work" push -q origin main
echo staged > "$work/staged.txt"
git -C "$work" add staged.txt
snapshot_state() { { git -C "$work" status --porcelain; git -C "$work" ls-files -s; cksum < "$work/.git/index"; } | cksum; }
before=$(snapshot_state)

# No gh-pages branch yet: nothing to restore, not an error.
out=$root/out-none
(cd "$work" && OUTPUT_DIR="$out" "$script" --restore-only) > "$root/log" 2>&1 || { cat "$root/log" >&2; fail 'a missing gh-pages branch must not fail'; }
grep -q 'No gh-pages branch' "$root/log" || fail 'the missing branch must be reported'

# With a gh-pages branch the tree is restored into OUTPUT_DIR and the repository's own index stays untouched.
seed=$root/seed
git init -q -b gh-pages "$seed"
mkdir -p "$seed/1.0.0/documentation" "$seed/benchmarks/2.0.0"
echo v1 > "$seed/1.0.0/documentation/index.html"
echo report > "$seed/benchmarks/2.0.0/index.html"
git -C "$seed" add -A
git -C "$seed" commit -qm pages
git -C "$seed" remote add origin "$origin"
git -C "$seed" push -q origin gh-pages

out=$root/out
(cd "$work" && OUTPUT_DIR="$out" "$script" --restore-only) > "$root/log" 2>&1 || { cat "$root/log" >&2; fail 'the restore must succeed'; }
[[ $(cat "$out/1.0.0/documentation/index.html") == v1 && $(cat "$out/benchmarks/2.0.0/index.html") == report ]] || fail 'gh-pages must be restored into OUTPUT_DIR'
[[ ! -e $out/.git ]] || fail 'OUTPUT_DIR must not contain .git'
[[ $(snapshot_state) == "$before" ]] || fail "the repository's index and working tree must stay untouched"
[[ $(git -C "$work" diff --cached --name-only) == staged.txt ]] || fail 'only the pre-staged file may be staged'
[[ ! -e $work/1.0.0 ]] || fail 'nothing may be checked out into the repository'

# An unreachable origin is an error, not "no gh-pages branch".
git -C "$work" remote set-url origin "$root/does-not-exist.git"
if (cd "$work" && OUTPUT_DIR="$root/out-bad" "$script" --restore-only) > "$root/log" 2>&1; then fail 'an unreachable origin must fail'; fi
printf 'sync-documentation tests passed\n'
