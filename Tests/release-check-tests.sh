#!/usr/bin/env bash
# Tests for Scripts/release-check.sh.
set -euo pipefail

script=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/Scripts/release-check.sh
root=$(mktemp -d "${TMPDIR:-/tmp}/release-check-tests.XXXXXXXX")
trap 'rm -rf "$root"' EXIT
fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }

cd "$root"
git init -q
git config user.email test@example.com
git config user.name test
git config commit.gpgsign false
mkdir -p Sources/Lib.docc
echo a > Sources/a.swift
echo p > Package.swift
git add .
git commit -qm base
git tag measured
echo doc > README.md
git add README.md
git commit -qm docs
git tag docs-only
echo b > Sources/b.swift
git add Sources/b.swift
git commit -qm code
git tag code
echo doc > Sources/Lib.docc/Page.md
git add Sources/Lib.docc/Page.md
git commit -qm docc
git tag docc

"$script" measured docs-only > /dev/null || fail 'a docs-only change must pass'
"$script" measured > /dev/null && fail 'HEAD with source changes must fail'
out=$("$script" measured code 2>&1) && fail 'a source change must fail'
[[ $out == *Sources/b.swift* ]] || fail "the differing path must be listed (got: $out)"
"$script" code docc > /dev/null || fail 'a DocC-only change must pass'
if "$script" measured docc > /dev/null 2>&1; then fail 'source changes must still fail when DocC files changed too'; fi
if "$script" measured no-such-ref > /dev/null 2>&1; then fail 'an invalid ref must fail'; fi
if "$script" > /dev/null 2>&1; then fail 'a missing argument must fail'; fi
printf 'release-check tests passed\n'
