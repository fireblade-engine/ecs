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
mkdir -p "$seed/1.1.0/benchmarks"
echo old-report > "$seed/1.1.0/benchmarks/BenchmarkReport.html"
git -C "$seed" add -A
git -C "$seed" commit -qm seed
git -C "$seed" remote add origin "$origin"
git -C "$seed" push -q origin gh-pages

snapshot() { # name version [with-report]
    local dir=$root/snap-$1
    mkdir -p "$dir/$2/documentation/firebladeecs"
    echo "$2 built by $1" > "$dir/$2/documentation/firebladeecs/index.html"
    echo "<html><head></head><body>$2</body></html>" > "$dir/$2/index.html"
    if [[ ${3:-} == report ]]; then
        mkdir -p "$dir/$2/benchmarks"
        echo "report $2" > "$dir/$2/benchmarks/BenchmarkReport.html"
    fi
    echo "$dir"
}
publish() { # snapshot-dir version out-dir [extra env...]
    local snap=$1 version=$2 out=$3
    shift 3
    env REMOTE_URL="$origin" SNAPSHOT_DIR="$snap" PUBLISH_DIR="$out" DOCS_VERSION_PATH="$version" "$@" "$script" > "$root/log" 2>&1 || { cat "$root/log" >&2; return 1; }
}
show() { git --git-dir="$origin" show "gh-pages:$1"; }

# Both snapshots are taken before either publish: the second must not wipe the first.
snapA=$(snapshot a 1.2.0 report)
snapB=$(snapshot b 2.0.0)
publish "$snapA" 1.2.0 "$root/outA"
publish "$snapB" 2.0.0 "$root/outB"

for v in 1.0.0 1.1.0 1.2.0 2.0.0 main; do
    show "$v/documentation/firebladeecs/index.html" > /dev/null || fail "version $v is missing after both publishes"
done
[[ $(show 1.0.0/documentation/firebladeecs/index.html) == "1.0.0 seed" ]] || fail 'an unrelated version changed'
[[ $(show 1.1.0/benchmarks/BenchmarkReport.html) == old-report ]] || fail 'an unrelated version lost its report'
[[ $(show 1.2.0/benchmarks/BenchmarkReport.html) == "report 1.2.0" ]] || fail 'the first publish lost its report'
[[ $(show 2.0.0/documentation/firebladeecs/index.html) == "2.0.0 built by b" ]] || fail 'the second publish is missing'
show versions.json | jq -e '.latest == "2.0.0" and ([.versions[].name] | index("1.2.0") != null) and ([.versions[].name] | index("main") != null)' > /dev/null || fail 'versions.json must list every version and name 2.0.0 latest'
show latest/index.html | grep -q '../2.0.0/documentation/firebladeecs/' || fail 'latest must redirect to 2.0.0'
show version-picker.js > /dev/null || fail 'version-picker.js missing'
if show latest/benchmarks/BenchmarkReport.html > /dev/null 2>&1; then fail 'latest has no report: no latest/benchmarks redirect may exist'; fi
[[ -f $root/outB/1.2.0/benchmarks/BenchmarkReport.html && -f $root/outB/2.0.0/index.html ]] || fail 'the Pages artifact tree must be the published tree'
[[ ! -e $root/outB/.git ]] || fail 'the Pages artifact tree must not contain .git'

# A report in the latest version creates the redirect; a later latest without one removes it again.
snapC=$(snapshot c 2.1.0 report)
publish "$snapC" 2.1.0 "$root/outC"
show latest/benchmarks/BenchmarkReport.html | grep -q '../../2.1.0/benchmarks/BenchmarkReport.html' || fail 'latest/benchmarks must redirect to 2.1.0'
snapD=$(snapshot d 2.2.0)
publish "$snapD" 2.2.0 "$root/outD"
if show latest/benchmarks/BenchmarkReport.html > /dev/null 2>&1; then fail 'a stale latest/benchmarks redirect must be removed'; fi
show 2.1.0/benchmarks/BenchmarkReport.html > /dev/null || fail 'the report of 2.1.0 must stay'

# Republishing replaces only that directory's content (--delete inside it).
mkdir -p "$snapC/2.1.0/documentation/firebladeecs"
rm -rf "$snapC/2.1.0/benchmarks"
publish "$snapC" 2.1.0 "$root/outC2"
if show 2.1.0/benchmarks/BenchmarkReport.html > /dev/null 2>&1; then fail 'files removed from a rebuilt version must be deleted'; fi

# A rejected push is retried from a fresh clone.
hook=$origin/hooks/pre-receive
cat > "$hook" <<HOOK
#!/usr/bin/env bash
count=\$(cat "$root/rejections" 2> /dev/null || echo 0)
if [ "\$count" -lt 1 ]; then echo \$((count + 1)) > "$root/rejections"; echo rejected >&2; exit 1; fi
HOOK
chmod +x "$hook"
snapE=$(snapshot e 2.3.0)
publish "$snapE" 2.3.0 "$root/outE"
show 2.3.0/index.html > /dev/null || fail 'the publish must succeed after one rejected push'
grep -q 'retrying' "$root/log" || fail 'the retry must be logged'

# Persistent rejection gives up with a failure.
cat > "$hook" <<HOOK
#!/usr/bin/env bash
exit 1
HOOK
snapF=$(snapshot f 2.4.0)
if publish "$snapF" 2.4.0 "$root/outF" MAX_ATTEMPTS=2 2> /dev/null; then fail 'a permanently rejected push must fail'; fi
rm "$hook"

# A missing snapshot directory is an error.
if publish "$snapF" 9.9.9 "$root/outG" 2> /dev/null; then fail 'a missing version directory must fail'; fi
printf 'publish-gh-pages tests passed\n'
