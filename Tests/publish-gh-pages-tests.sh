#!/usr/bin/env bash
# Tests for Scripts/publish-gh-pages.sh against a local bare repository standing in for origin.
set -euo pipefail

repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
script=$repo/Scripts/publish-gh-pages.sh
root=$(mktemp -d "${TMPDIR:-/tmp}/publish-gh-pages-tests.XXXXXXXX")
trap 'rm -rf "$root"' EXIT
fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
export GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@example.com GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@example.com

origin=$root/origin.git
git init -q --bare "$origin"

# Seed gh-pages with two released versions and main.
seed=$root/seed
git init -q "$seed"
git -C "$seed" checkout -q -b gh-pages
for v in 1.0.0 1.1.0 main; do
    mkdir -p "$seed/$v/documentation/firebladeecs"
    echo "$v seed" > "$seed/$v/documentation/firebladeecs/index.html"
    echo "<html><head></head><body>$v</body></html>" > "$seed/$v/index.html"
done
git -C "$seed" add -A
git -C "$seed" commit -qm seed
git -C "$seed" remote add origin "$origin"
git -C "$seed" push -q origin gh-pages

snapshot() { # name version
    local dir=$root/snap-$1
    mkdir -p "$dir/$2/documentation/firebladeecs"
    echo "$2 built by $1" > "$dir/$2/documentation/firebladeecs/index.html"
    echo "<html><head></head><body>$2</body></html>" > "$dir/$2/index.html"
    echo "$dir"
}
stage_report() { # staging-dir tag
    mkdir -p "$1"
    echo "report $2" > "$1/$2.html"
}
publish() { # snapshot-dir version out-dir [extra env...]
    local snap=$1 version=$2 out=$3
    shift 3
    env REMOTE_URL="$origin" SNAPSHOT_DIR="$snap" PUBLISH_DIR="$out" REPORTS_DIR="$root/no-reports" DOCS_VERSION_PATH="$version" "$@" "$script" > "$root/log" 2>&1 || { cat "$root/log" >&2; return 1; }
}
show() { git --git-dir="$origin" show "gh-pages:$1"; }
has() { git --git-dir="$origin" cat-file -e "gh-pages:$1" 2> /dev/null; }

# Both snapshots are taken before either publish: the second must not wipe the first.
snapA=$(snapshot a 1.2.0)
snapB=$(snapshot b 2.0.0)
publish "$snapA" 1.2.0 "$root/outA"
publish "$snapB" 2.0.0 "$root/outB"

for v in 1.0.0 1.1.0 1.2.0 2.0.0 main; do
    has "$v/documentation/firebladeecs/index.html" || fail "version $v is missing after both publishes"
done
[[ $(show 1.0.0/documentation/firebladeecs/index.html) == "1.0.0 seed" ]] || fail 'an unrelated version changed'
[[ $(show 2.0.0/documentation/firebladeecs/index.html) == "2.0.0 built by b" ]] || fail 'the second publish is missing'
show versions.json | jq -e '.latest == "2.0.0" and ([.versions[].name] | index("1.2.0") != null) and ([.versions[].name] | index("main") != null)' > /dev/null || fail 'versions.json must list every version and name 2.0.0 latest'
show latest/index.html | grep -q '../2.0.0/documentation/firebladeecs/' || fail 'latest must redirect to 2.0.0'
has version-picker.js || fail 'version-picker.js missing'
has latest/benchmarks/BenchmarkReport.html && fail 'there is no latest/benchmarks redirect any more'
has benchmarks/index.html && fail 'no report staged: the benchmarks section must not exist'
[[ -f $root/outB/1.2.0/index.html && -f $root/outB/2.0.0/index.html ]] || fail 'the Pages tree must be the published tree'
[[ ! -e $root/outB/.git ]] || fail 'the Pages tree must not contain .git'

# Republishing replaces only that directory's content (--delete inside it).
mkdir -p "$snapA/1.2.0/extra"
echo x > "$snapA/1.2.0/extra/file"
publish "$snapA" 1.2.0 "$root/outA2"
has 1.2.0/extra/file || fail 'a republish must add new files'
rm -rf "$snapA/1.2.0/extra"
publish "$snapA" 1.2.0 "$root/outA3"
has 1.2.0/extra/file && fail 'files removed from a rebuilt version must be deleted'

# --- Benchmark reports: only staged ones publish, per version; benchmarks/index.html is the highest version ---
reports=$root/reports
publish_with_report() { # tag
    local snap
    snap=$(snapshot "r$1" "$1")
    rm -rf "$reports"
    stage_report "$reports" "$1"
    publish "$snap" "$1" "$root/outR-$1" REPORTS_DIR="$reports"
}
publish_with_report 2.0.0
[[ $(show benchmarks/2.0.0/index.html) == "report 2.0.0" ]] || fail 'the report must be published under benchmarks/<version>/'
[[ $(show benchmarks/index.html) == "report 2.0.0" ]] || fail 'benchmarks/index.html must be the only report'
[[ -f $root/outR-2.0.0/benchmarks/2.0.0/index.html ]] || fail 'the Pages tree must contain the report'

publish_with_report 1.9.0   # a backfill of an older tag must not regress the landing page
[[ $(show benchmarks/index.html) == "report 2.0.0" ]] || fail 'an older version must not replace the newest report'
[[ $(show benchmarks/1.9.0/index.html) == "report 1.9.0" && $(show benchmarks/2.0.0/index.html) == "report 2.0.0" ]] || fail 'reports of other versions must stay'

publish_with_report 2.10.0
[[ $(show benchmarks/index.html) == "report 2.10.0" ]] || fail '2.10.0 is newer than 2.0.0 (version order, not text order)'
publish_with_report 2.9.0
[[ $(show benchmarks/index.html) == "report 2.10.0" ]] || fail '2.9.0 is older than 2.10.0'
publish_with_report v2.11.0
[[ $(show benchmarks/index.html) == "report v2.11.0" ]] || fail 'a v-prefixed tag counts by its number'
has benchmarks/v2.11.0/index.html || fail 'the v-prefixed directory keeps the tag spelling'

# A hotfix or main run with nothing staged leaves every report alone.
snapH=$(snapshot h 2.11.1)
publish "$snapH" 2.11.1 "$root/outH"
[[ $(show benchmarks/index.html) == "report v2.11.0" ]] || fail 'a hotfix without a report must not change the landing page'
has benchmarks/2.0.0/index.html || fail 'a hotfix without a report must keep older reports'
snapM=$(snapshot m main)
publish "$snapM" main "$root/outM"
[[ $(show benchmarks/index.html) == "report v2.11.0" ]] || fail 'main must not change reports'

# A final release outranks its prereleases, whatever the publish order.
publish_with_report 3.0.0-rc1
[[ $(show benchmarks/index.html) == "report 3.0.0-rc1" ]] || fail 'a prerelease of a newer version becomes the landing page'
publish_with_report 3.0.0
[[ $(show benchmarks/index.html) == "report 3.0.0" ]] || fail '3.0.0 must outrank 3.0.0-rc1'
publish_with_report 3.0.0-rc2
[[ $(show benchmarks/index.html) == "report 3.0.0" ]] || fail 'a later prerelease must not replace the final release'

# A withheld report (drift) takes down what the same tag published earlier and recomputes the landing page.
withheld=$root/withheld
rm -rf "$withheld"; mkdir -p "$withheld"; : > "$withheld/3.0.0.withheld"
publish "$(snapshot w 3.0.0)" 3.0.0 "$root/outW" REPORTS_DIR="$withheld"
has benchmarks/3.0.0/index.html && fail 'a withheld report must be removed'
[[ $(show benchmarks/index.html) == "report 3.0.0-rc2" ]] || fail 'the landing page must fall back to the next newest report'
has 3.0.0/documentation/firebladeecs/index.html || fail 'the documentation is published although the report is withheld'
has benchmarks/2.10.0/index.html || fail 'other reports must stay'
for gone in 3.0.0-rc1 3.0.0-rc2 v2.11.0 2.10.0 2.9.0 2.0.0 1.9.0; do
    rm -rf "$withheld"; mkdir -p "$withheld"; : > "$withheld/$gone.withheld"
    publish "$(snapshot w "$gone")" "$gone" "$root/outW" REPORTS_DIR="$withheld"
done
has benchmarks/index.html && fail 'without any report the landing page must go away'

# --- A real race: another publish lands between this publish's clone and its push ---
hook=$origin/hooks/pre-receive
snapRaceMine=$(snapshot racemine 3.0.0)
snapRaceOther=$(snapshot raceother 3.1.0)
cat > "$hook" <<HOOK
#!/usr/bin/env bash
# The first push (this publish) triggers a competing publish before it lands.
if [ ! -e "$root/raced" ]; then
    touch "$root/raced"
    env -u GIT_DIR -u GIT_QUARANTINE_PATH -u GIT_OBJECT_DIRECTORY -u GIT_ALTERNATE_OBJECT_DIRECTORIES \\
        REMOTE_URL="$origin" SNAPSHOT_DIR="$snapRaceOther" PUBLISH_DIR="$root/outRaceOther" REPORTS_DIR="$root/no-reports" \\
        DOCS_VERSION_PATH=3.1.0 "$script" > "$root/log-competitor" 2>&1
fi
HOOK
chmod +x "$hook"
publish "$snapRaceMine" 3.0.0 "$root/outRace"
rm "$hook"
[[ -e $root/raced ]] || fail 'the competing publish never ran'
grep -q 'retrying' "$root/log" || fail 'the lost race must be retried'
[[ $(show 3.0.0/documentation/firebladeecs/index.html) == "3.0.0 built by racemine" ]] || fail 'the retried publish must land'
[[ $(show 3.1.0/documentation/firebladeecs/index.html) == "3.1.0 built by raceother" ]] || fail 'the competing publish must survive the retry'
show versions.json | jq -e '[.versions[].name] | index("3.0.0") != null and index("3.1.0") != null' > /dev/null || fail 'versions.json must list both racing versions'
[[ -f $root/outRace/3.1.0/index.html ]] || fail 'the Pages tree must include the competing publish'

# --- Retry and give-up on rejection ---
cat > "$hook" <<HOOK
#!/usr/bin/env bash
count=\$(cat "$root/rejections" 2> /dev/null || echo 0)
if [ "\$count" -lt 1 ]; then echo \$((count + 1)) > "$root/rejections"; echo rejected >&2; exit 1; fi
HOOK
chmod +x "$hook"
snapE=$(snapshot e 4.0.0)
publish "$snapE" 4.0.0 "$root/outE"
has 4.0.0/index.html || fail 'the publish must succeed after one rejected push'
cat > "$hook" <<HOOK
#!/usr/bin/env bash
exit 1
HOOK
snapF=$(snapshot f 4.1.0)
if publish "$snapF" 4.1.0 "$root/outF" MAX_ATTEMPTS=2 2> /dev/null; then fail 'a permanently rejected push must fail'; fi
rm "$hook"

# --- Errors ---
if publish "$snapF" 9.9.9 "$root/outG" 2> /dev/null; then fail 'a missing version directory must fail'; fi
# An unreachable remote is not "no gh-pages branch yet": nothing may be initialised and pushed.
if publish "$snapF" 4.1.0 "$root/outU" REMOTE_URL="$root/does-not-exist.git" 2> /dev/null; then fail 'an unreachable remote must fail'; fi
# A reachable remote without gh-pages starts the branch.
fresh=$root/fresh.git
git init -q --bare "$fresh"
publish "$snapF" 4.1.0 "$root/outN" REMOTE_URL="$fresh"
git --git-dir="$fresh" cat-file -e gh-pages:4.1.0/index.html || fail 'the first publish must create gh-pages'
printf 'publish-gh-pages tests passed\n'
