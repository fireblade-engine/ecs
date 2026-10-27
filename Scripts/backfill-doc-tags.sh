#!/usr/bin/env bash
set -euo pipefail

REPO_NAME="${REPO_NAME:-ecs}"
OUTPUT_DIR="${OUTPUT_DIR:-.build/documentation}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ "$OUTPUT_DIR" != /* ]]; then
    OUTPUT_DIR="$ROOT/$OUTPUT_DIR"
fi

TAGS=$(git tag -l --sort=v:refname | grep -E '^[v]?[0-9]+\.[0-9]+\.[0-9]+' || true)

for TAG in $TAGS; do
    if [ -d "${OUTPUT_DIR}/${TAG}" ]; then
        echo "Docs for tag ${TAG} already exist, skipping."
    else
        echo "==> Generating documentation for tag ${TAG}..."
        TMP_WT=$(mktemp -d /tmp/ecs-doc-tag-XXXXXX)
        if git worktree add --detach "${TMP_WT}" "${TAG}" >/dev/null 2>&1; then
            mkdir -p "${OUTPUT_DIR}/${TAG}"
            if (cd "${TMP_WT}" && swift package --disable-sandbox --allow-writing-to-directory "${OUTPUT_DIR}" generate-documentation --target FirebladeECS --disable-indexing --transform-for-static-hosting --hosting-base-path "${REPO_NAME}/${TAG}" --output-path "${OUTPUT_DIR}/${TAG}"); then
                echo "==> Successfully built docs for ${TAG}"
            else
                echo "::warning::Failed to build docs for ${TAG}, skipping"
                rm -rf "${OUTPUT_DIR}/${TAG}"
            fi
            git worktree remove --force "${TMP_WT}" >/dev/null 2>&1 || rm -rf "${TMP_WT}"
        else
            echo "::warning::Failed to create worktree for tag ${TAG}, skipping"
            rm -rf "${TMP_WT}"
        fi
    fi
done

echo "Tag documentation backfill complete."
