#!/usr/bin/env bash
# Tests for Scripts/check-release-report.sh.
set -euo pipefail

script=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/Scripts/check-release-report.sh
root=$(mktemp -d "${TMPDIR:-/tmp}/check-release-report-tests.XXXXXXXX")
trap 'rm -rf "$root"' EXIT
fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }

cd "$root"
git init -q
git config user.email test@example.com
git config user.name test
git config commit.gpgsign false
mkdir Sources
echo a > Sources/a.swift
echo p > Package.swift
git add .
git commit -qm base
git tag base
git tag no-report-docs

reports=Documentation/Benchmarks
mkdir -p "$reports"
measured=$(git rev-parse HEAD)
echo '<html></html>' > "$reports/BenchmarkReport.html"
git add "$reports/BenchmarkReport.html"
git commit -qm 'report without manifest'
git tag no-manifest

printf '{"schemaVersion":1,"baseline":"1.4.3","refs":[{"label":"1.4.3","sha":"%s"},{"label":"2.0.0","sha":"%s"}]}\n' "$measured" "$measured" > "$reports/BenchmarkReport.manifest.json"
git add "$reports/BenchmarkReport.manifest.json"
git commit -qm 'manifest'
git tag good

echo b > Sources/b.swift
git add Sources/b.swift
git commit -qm 'code after measurement'
git tag drifted

printf '{"schemaVersion":1,"baseline":null,"refs":[{"label":"2.0.0","sha":"%s"}]}\n' "0000000000000000000000000000000000000000" > "$reports/BenchmarkReport.manifest.json"
git add "$reports/BenchmarkReport.manifest.json"
git commit -qm 'manifest with unknown sha'
git tag unknown-sha

out=$("$script" 2.0.0 base 2>&1) || fail "no report must pass (got: $out)"
[[ $out == *skipping* ]] || fail "no report must print a notice (got: $out)"
if out=$("$script" 2.0.0 no-manifest 2>&1); then fail 'a report without manifest must fail'; fi
[[ $out == *manifest* ]] || fail "the missing manifest must be named (got: $out)"
"$script" 2.0.0 good > /dev/null || fail 'a matching report must pass'
"$script" v2.0.0 good > /dev/null || fail 'a leading v must be ignored'
if out=$("$script" 2.0.1 good 2>&1); then fail 'a version missing from the manifest must fail'; fi
[[ $out == *"2.0.1"* ]] || fail "the version must be named (got: $out)"
if out=$("$script" 2.0.0 drifted 2>&1); then fail 'changed sources after the measurement must fail'; fi
[[ $out == *Sources/b.swift* ]] || fail "the differing path must be listed (got: $out)"
if out=$("$script" 2.0.0 unknown-sha 2>&1); then fail 'an unknown measured sha must fail'; fi
[[ $out == *does\ not\ exist* ]] || fail "the missing commit must be named (got: $out)"
if "$script" 2.0.0 no-such-ref > /dev/null 2>&1; then fail 'an invalid ref must fail'; fi
if "$script" > /dev/null 2>&1; then fail 'a missing argument must fail'; fi
printf 'check-release-report tests passed\n'
