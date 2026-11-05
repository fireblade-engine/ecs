#!/usr/bin/env bash
# Tests for Scripts/check-release-report.sh and Scripts/stage-benchmark-report.sh.
set -euo pipefail

scripts=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/Scripts
script=$scripts/check-release-report.sh
stage=$scripts/stage-benchmark-report.sh
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
measured=$(git rev-parse HEAD)

reports=Documentation/Benchmarks
mkdir -p "$reports"
write_report() { # manifest-json: page embedding the compact manifest, pretty manifest file
    printf '<html>\n<body>\n<script type="application/json" id="benchmark-manifest">%s</script>\n</body>\n</html>\n' "$(printf '%s' "$1" | jq -cS .)" > "$reports/BenchmarkReport.html"
    printf '%s' "$1" | jq -S . > "$reports/BenchmarkReport.manifest.json"
}
commit() { git add -A "$reports" Sources; git commit -qm "$1"; git tag "$1"; }
manifest_for() { printf '{"schemaVersion":1,"baseline":"1.4.3","refs":[{"label":"1.4.3","sha":"%s"},{"label":"%s","sha":"%s"}]}' "$measured" "$1" "$2"; }

# A report without manifest.
echo '<html></html>' > "$reports/BenchmarkReport.html"
commit no-manifest

# A report whose page embeds a different manifest than the committed file.
write_report "$(manifest_for 2.0.0 "$measured")"
printf '%s' "$(manifest_for 2.0.0 "$measured")" | jq -S '.baseline = "other"' > "$reports/BenchmarkReport.manifest.json"
commit mismatch

write_report "$(manifest_for 2.0.0 "$measured")"
commit good

# Hotfix 2.0.1 after the report: the code is unchanged, the manifest names no 2.0.1.
echo notes > README.md
git add README.md
commit hotfix-docs

echo b > Sources/b.swift
commit drifted

write_report "$(manifest_for 2.0.0 0000000000000000000000000000000000000000)"
commit unknown-sha

# A ref that names the version but has no usable SHA.
write_report '{"schemaVersion":1,"baseline":null,"refs":[{"label":"2.0.0"}]}'
commit no-sha
write_report '{"schemaVersion":1,"baseline":null,"refs":[{"label":"2.0.0","sha":"not-a-sha"}]}'
commit bad-sha

# --- strict mode ---
if out=$("$script" 2.0.0 base 2>&1); then fail 'strict: no report must fail'; fi
if out=$("$script" 2.0.0 no-manifest 2>&1); then fail 'strict: a report without manifest must fail'; fi
[[ $out == *manifest* ]] || fail "the missing manifest must be named (got: $out)"
if out=$("$script" 2.0.0 mismatch 2>&1); then fail 'a page and manifest from different renders must fail'; fi
[[ $out == *differ* ]] || fail "the mismatch must be named (got: $out)"
"$script" 2.0.0 good > /dev/null || fail 'a matching report must pass'
"$script" v2.0.0 good > /dev/null || fail 'a leading v must be ignored'
if out=$("$script" 2.0.1 good 2>&1); then fail 'strict: a version missing from the manifest must fail'; fi
[[ $out == *"2.0.1"* ]] || fail "the version must be named (got: $out)"
"$script" 2.0.0 hotfix-docs > /dev/null || fail 'doc-only changes after the measurement must pass'
if out=$("$script" 2.0.0 drifted 2>&1); then fail 'changed sources after the measurement must fail'; fi
[[ $out == *Sources/b.swift* ]] || fail "the differing path must be listed (got: $out)"
if out=$("$script" 2.0.0 unknown-sha 2>&1); then fail 'an unknown measured sha must fail'; fi
[[ $out == *does\ not\ exist* ]] || fail "the missing commit must be named (got: $out)"
if "$script" 2.0.0 no-such-ref > /dev/null 2>&1; then fail 'an invalid ref must fail'; fi
if "$script" > /dev/null 2>&1; then fail 'a missing argument must fail'; fi

# --- optional mode (CI on tag pushes) ---
status=0; "$script" --optional 2.0.0 base > /dev/null || status=$?
[[ $status == 10 ]] || fail "optional: no report must exit 10 (got $status)"
status=0; "$script" --optional 2.0.0 no-manifest > /dev/null || status=$?
[[ $status == 10 ]] || fail "optional: no manifest must exit 10 (got $status)"
status=0; "$script" --optional 2.0.1 good > /dev/null || status=$?
[[ $status == 10 ]] || fail "optional: a hotfix without its own label must exit 10 (got $status)"
status=0; "$script" --optional 2.0.1 drifted > /dev/null || status=$?
[[ $status == 10 ]] || fail "optional: unrelated drift of another version's report is not this tag's concern (got $status)"
"$script" --optional 2.0.0 good > /dev/null || fail 'optional: a matching report must pass'
status=0; "$script" --optional 2.0.0 drifted > /dev/null 2>&1 || status=$?
[[ $status == 1 ]] || fail "optional: drift of the named version must fail (got $status)"
status=0; "$script" --optional 2.0.0 mismatch > /dev/null 2>&1 || status=$?
[[ $status == 1 ]] || fail "optional: a mismatching page must fail (got $status)"

for broken in no-sha bad-sha; do
    status=0; "$script" --optional 2.0.0 "$broken" > /dev/null 2>&1 || status=$?
    [[ $status == 1 ]] || fail "optional: a ref labelled with the version but with $broken must fail hard (got $status)"
done
# Without jq nothing can be verified: a hard failure even in optional mode, never "nothing to publish".
nojq=$root/nojq
mkdir -p "$nojq"
for tool in git grep sed dirname cat; do ln -s "$(command -v "$tool")" "$nojq/$tool"; done
status=0; PATH=$nojq /bin/bash "$script" --optional 2.0.0 good > /dev/null 2>&1 || status=$?
[[ $status == 1 ]] || fail "optional: missing jq must fail hard (got $status)"

# --- staging ---
staging=$root/staging
"$stage" 2.0.0 "$staging" good > /dev/null || fail 'staging a verified report must succeed'
[[ -f $staging/2.0.0.html ]] && grep -q benchmark-manifest "$staging/2.0.0.html" || fail 'the verified report must be staged under the tag name'
"$stage" v2.0.0 "$staging" good > /dev/null || fail 'a v-prefixed tag must stage'
[[ -f $staging/v2.0.0.html ]] || fail 'the staged file keeps the tag spelling'
"$stage" 2.0.1 "$staging" good > /dev/null || fail 'a tag without a label must succeed'
[[ ! -e $staging/2.0.1.html ]] || fail 'a tag without a label stages nothing'
"$stage" 1.0.0 "$staging" base > /dev/null || fail 'a tag without any report must succeed'
[[ ! -e $staging/1.0.0.html ]] || fail 'a tag without a report stages nothing'
mkdir -p "$staging" && echo stale > "$staging/2.0.0.html"
if out=$("$stage" 2.0.0 "$staging" drifted 2>&1); then fail 'drift must make staging fail'; fi
[[ $out == *"::error"* ]] || fail "drift must emit an error annotation (got: $out)"
[[ ! -e $staging/2.0.0.html ]] || fail 'drift must not leave a staged report (a stale one is removed)'
[[ -e $staging/2.0.0.withheld ]] || fail 'drift must leave a withheld marker for the publisher'
if out=$(STAGE_ANNOTATION=warning "$stage" 2.0.0 "$staging" drifted 2>&1); then fail 'drift must fail with a warning annotation too'; fi
[[ $out == *"::warning"* && $out != *"::error"* ]] || fail "backfills downgrade the annotation (got: $out)"
"$stage" 2.0.0 "$staging" good > /dev/null || fail 'a later verified stage must succeed'
[[ ! -e $staging/2.0.0.withheld && -f $staging/2.0.0.html ]] || fail 'a verified stage clears the withheld marker'
printf 'check-release-report tests passed\n'
