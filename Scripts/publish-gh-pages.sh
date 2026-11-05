#!/usr/bin/env bash
# Publishes built documentation to the gh-pages branch without clobbering concurrent publishes.
#
# Only the version directories named in PUBLISH_PATHS (default: DOCS_VERSION_PATH) are taken from the snapshot, replacing
# the same directories in a fresh clone of gh-pages. Everything else in the clone is left alone, then the shared root files
# are regenerated against the clone (Scripts/sync-documentation.sh --index-only), committed and pushed. A rejected push
# (another run published meanwhile) restarts from a fresh clone, up to MAX_ATTEMPTS times. On success PUBLISH_DIR holds
# the exact published tree (without .git), which is what the Pages artifact is built from.
#
# Environment:
#   REMOTE_URL        git URL of the repository (required)
#   DOCS_VERSION_PATH version directory built by this run (default: main)
#   PUBLISH_PATHS     space separated version directories to publish (default: DOCS_VERSION_PATH; backfills list several)
#   SNAPSHOT_DIR      built documentation (default: .build/documentation)
#   REPORTS_DIR       staged benchmark reports (default: .build/benchmark-reports): every <version>.html in it is published as
#                     benchmarks/<version>/index.html next to the reports of other versions, which stay untouched
#                     (Scripts/stage-benchmark-report.sh fills it; main runs and pull requests stage nothing)
#   PUBLISH_DIR       published tree output (default: .build/gh-pages-publish)
#   REPO_NAME         site base path (default: ecs)
#   MAX_ATTEMPTS      push attempts (default: 3)
#   GIT_AUTHOR_NAME / GIT_AUTHOR_EMAIL  commit identity (default: github-actions[bot])
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REMOTE_URL="${REMOTE_URL:?REMOTE_URL is required}"
DOCS_VERSION_PATH="${DOCS_VERSION_PATH:-main}"
PUBLISH_PATHS="${PUBLISH_PATHS:-$DOCS_VERSION_PATH}"
SNAPSHOT_DIR="${SNAPSHOT_DIR:-.build/documentation}"
PUBLISH_DIR="${PUBLISH_DIR:-.build/gh-pages-publish}"
REPORTS_DIR="${REPORTS_DIR:-.build/benchmark-reports}"
REPO_NAME="${REPO_NAME:-ecs}"
MAX_ATTEMPTS="${MAX_ATTEMPTS:-3}"
NAME="${GIT_AUTHOR_NAME:-github-actions[bot]}"
EMAIL="${GIT_AUTHOR_EMAIL:-github-actions[bot]@users.noreply.github.com}"

[[ $SNAPSHOT_DIR == /* ]] || SNAPSHOT_DIR="$PWD/$SNAPSHOT_DIR"
[[ $PUBLISH_DIR == /* ]] || PUBLISH_DIR="$PWD/$PUBLISH_DIR"
[[ $REPORTS_DIR == /* ]] || REPORTS_DIR="$PWD/$REPORTS_DIR"

for path in $PUBLISH_PATHS; do
    [[ -d $SNAPSHOT_DIR/$path ]] || { printf 'publish-gh-pages: %s/%s does not exist\n' "$SNAPSHOT_DIR" "$path" >&2; exit 1; }
done

CLONE="$(mktemp -d "${TMPDIR:-/tmp}/gh-pages-XXXXXX")"
trap 'rm -rf "$CLONE"' EXIT

git_clone() {
    rm -rf "$CLONE"
    mkdir -p "$CLONE"
    # Exit status 2 means the branch does not exist (first publish); any other failure is an error, never a reason to init.
    local status=0
    git ls-remote --exit-code --heads "$REMOTE_URL" gh-pages > /dev/null 2>&1 || status=$?
    if [ "$status" -eq 0 ]; then
        git clone -q --branch gh-pages --single-branch "$REMOTE_URL" "$CLONE"
    elif [ "$status" -eq 2 ]; then
        git init -q "$CLONE"
        git -C "$CLONE" remote add origin "$REMOTE_URL"
        git -C "$CLONE" checkout -q -b gh-pages
    else
        printf 'publish-gh-pages: cannot query %s (git exit %d)\n' "$REMOTE_URL" "$status" >&2
        exit 1
    fi
    git -C "$CLONE" config user.name "$NAME"
    git -C "$CLONE" config user.email "$EMAIL"
    git -C "$CLONE" config commit.gpgsign false
}

published="false"
for ((attempt = 1; attempt <= MAX_ATTEMPTS; attempt++)); do
    printf '==> Publishing %s to gh-pages (attempt %d of %d)...\n' "$PUBLISH_PATHS" "$attempt" "$MAX_ATTEMPTS"
    git_clone
    for path in $PUBLISH_PATHS; do
        mkdir -p "$CLONE/$path"
        rsync -a --delete "$SNAPSHOT_DIR/$path/" "$CLONE/$path/"
    done
    for report in "$REPORTS_DIR"/*.html; do
        [[ -f $report ]] || continue
        version=$(basename "$report" .html)
        mkdir -p "$CLONE/benchmarks/$version"
        cp "$report" "$CLONE/benchmarks/$version/index.html"
    done
    OUTPUT_DIR="$CLONE" REPO_NAME="$REPO_NAME" DOCS_VERSION_PATH="$DOCS_VERSION_PATH" "$ROOT/Scripts/sync-documentation.sh" --index-only
    git -C "$CLONE" add -A
    if git -C "$CLONE" diff --cached --quiet; then
        echo "No changes to commit to gh-pages"
        published="true"
        break
    fi
    git -C "$CLONE" commit -q -m "Update documentation for $PUBLISH_PATHS"
    if git -C "$CLONE" push -q origin gh-pages; then
        published="true"
        break
    fi
    printf 'publish-gh-pages: push rejected, retrying from a fresh clone\n' >&2
done

[[ $published == "true" ]] || { printf 'publish-gh-pages: giving up after %d attempts\n' "$MAX_ATTEMPTS" >&2; exit 1; }

mkdir -p "$PUBLISH_DIR"
rsync -a --delete --exclude '.git' "$CLONE/" "$PUBLISH_DIR/"
printf '==> Published tree available at %s\n' "$PUBLISH_DIR"
