#!/usr/bin/env bash
set -euo pipefail

REPO_NAME="${REPO_NAME:-ecs}"
OUTPUT_DIR="${OUTPUT_DIR:-.build/documentation}"
DOCS_VERSION_PATH="${DOCS_VERSION_PATH:-main}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ "$OUTPUT_DIR" != /* ]]; then
    OUTPUT_DIR="$ROOT/$OUTPUT_DIR"
fi

mkdir -p "${OUTPUT_DIR}"
if git fetch origin gh-pages:refs/remotes/origin/gh-pages 2>/dev/null; then
    echo "==> Restoring existing documentation from gh-pages..."
    git --work-tree="${OUTPUT_DIR}" checkout origin/gh-pages -- . || true
    rm -rf "${OUTPUT_DIR}/.git"
fi

echo "==> Building documentation for version: ${DOCS_VERSION_PATH}..."
mkdir -p "${OUTPUT_DIR}/${DOCS_VERSION_PATH}"
swift package --disable-sandbox \
    --allow-writing-to-directory "${OUTPUT_DIR}" \
    generate-documentation --target FirebladeECS \
    --disable-indexing \
    --transform-for-static-hosting \
    --hosting-base-path "${REPO_NAME}/${DOCS_VERSION_PATH}" \
    --output-path "${OUTPUT_DIR}/${DOCS_VERSION_PATH}"

# Copy version-picker.js
cp "${ROOT}/Scripts/version-picker.js" "${OUTPUT_DIR}/version-picker.js"

# Discover all version directories present in OUTPUT_DIR
TAGS=$(find "${OUTPUT_DIR}" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | grep -E '^[v]?[0-9]+\.[0-9]+\.[0-9]+' | sort -V -r || true)
HAS_MAIN="false"
if [ -d "${OUTPUT_DIR}/main" ]; then
    HAS_MAIN="true"
fi

LATEST_TAG=$(echo "$TAGS" | head -n 1)
LATEST_TARGET="${LATEST_TAG:-${DOCS_VERSION_PATH}}"

create_redirect() {
  local FILE_PATH=$1
  local TARGET_URL=$2
  local TITLE=$3
  
  mkdir -p "$(dirname "$FILE_PATH")"
  
  cat <<EOF > "$FILE_PATH"
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>$TITLE</title>
    <link rel="canonical" href="$TARGET_URL">
    <script>
        window.location.href = "$TARGET_URL" + window.location.hash;
    </script>
    <meta http-equiv="refresh" content="0;url=$TARGET_URL">
</head>
<body>
    <p>Redirecting to <a href="$TARGET_URL">$TITLE</a>...</p>
</body>
</html>
EOF
}

echo "Generating redirect files..."
create_redirect "${OUTPUT_DIR}/index.html" "latest/documentation/firebladeecs/" "Redirecting to Latest Docs"
create_redirect "${OUTPUT_DIR}/latest/index.html" "../${LATEST_TARGET}/documentation/firebladeecs/" "Redirecting to Latest Docs"
create_redirect "${OUTPUT_DIR}/latest/documentation/firebladeecs/index.html" "../../../${LATEST_TARGET}/documentation/firebladeecs/" "Redirecting to Latest Docs"
create_redirect "${OUTPUT_DIR}/documentation/firebladeecs/index.html" "../../${LATEST_TARGET}/documentation/firebladeecs/" "Redirecting to Latest Docs"
create_redirect "${OUTPUT_DIR}/versions.html" "versions/" "Redirecting to Versions"

echo "Generating version manifest and catalog landing page..."
export TAGS_LIST="$TAGS"
export HAS_MAIN_FLAG="$HAS_MAIN"
export LATEST_TARGET="$LATEST_TARGET"

python3 - << 'PYTHON_EOF'
import os
import json

output_dir = os.environ.get('OUTPUT_DIR', '.build/documentation')
docs_version_path = os.environ.get('DOCS_VERSION_PATH', 'main')
repo_name = os.environ.get('REPO_NAME', 'ecs')
tags_raw = os.environ.get('TAGS_LIST', '')
has_main = os.environ.get('HAS_MAIN_FLAG', 'false') == 'true'
latest_target = os.environ.get('LATEST_TARGET', docs_version_path)

tags = [t.strip() for t in tags_raw.split('\n') if t.strip()]
latest_tag = tags[0] if tags else latest_target

versions_list = []
if tags:
    versions_list.append({
        "name": latest_tag,
        "label": f"Latest Release ({latest_tag})",
        "path": f"{latest_tag}/documentation/firebladeecs/"
    })

if has_main:
    versions_list.append({
        "name": "main",
        "label": "Development (main)",
        "path": "main/documentation/firebladeecs/"
    })

for t in tags:
    versions_list.append({
        "name": t,
        "label": t if t != latest_tag else f"Latest Release ({t})",
        "path": f"{t}/documentation/firebladeecs/"
    })

seen = set()
unique_versions = []
for v in versions_list:
    if v["name"] not in seen:
        seen.add(v["name"])
        unique_versions.append(v)

manifest = {
    "latest": latest_target,
    "versions": unique_versions
}

with open(os.path.join(output_dir, 'versions.json'), 'w') as f:
    json.dump(manifest, f, indent=2)

versions_html_dir = os.path.join(output_dir, 'versions')
os.makedirs(versions_html_dir, exist_ok=True)

latest_link = f"../{latest_target}/documentation/firebladeecs/"
dev_link = "../main/documentation/firebladeecs/"

previous_releases_html = ""
for v in unique_versions:
    if v["name"] != latest_tag and v["name"] != "main":
        previous_releases_html += f'<li><a href="../{v["path"]}">{v["label"]}</a></li>\n'

dev_section_html = f"""<section>
            <h2>Development</h2>
            <ul>
                <li><a href="{dev_link}">Development (main)</a></li>
            </ul>
        </section>""" if has_main else ""

html_content = f"""<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>FirebladeECS Documentation Versions</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        :root {{
            --color-background: #ffffff;
            --color-text: #1d1d1f;
            --color-secondary: #86868b;
            --color-border: #d2d2d7;
            --color-card-bg: #f5f5f7;
            --color-link: #0066cc;
            --color-link-hover: #004499;
        }}
        @media (prefers-color-scheme: dark) {{
            :root {{
                --color-background: #000000;
                --color-text: #f5f5f7;
                --color-secondary: #a1a1a6;
                --color-border: #38383a;
                --color-card-bg: #1c1c1e;
                --color-link: #2997ff;
                --color-link-hover: #70b5ff;
            }}
        }}
        body {{
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            background-color: var(--color-background);
            color: var(--color-text);
            margin: 0;
            padding: 40px 20px;
            line-height: 1.5;
        }}
        .container {{
            max-width: 800px;
            margin: 0 auto;
        }}
        header {{
            margin-bottom: 40px;
            border-bottom: 1px solid var(--color-border);
            padding-bottom: 20px;
        }}
        h1 {{
            font-size: 32px;
            font-weight: 600;
            margin: 0 0 10px 0;
        }}
        .back-link {{
            color: var(--color-link);
            text-decoration: none;
            font-size: 15px;
        }}
        .back-link:hover {{
            text-decoration: underline;
        }}
        section {{
            background-color: var(--color-card-bg);
            border: 1px solid var(--color-border);
            border-radius: 12px;
            padding: 24px;
            margin-bottom: 24px;
        }}
        h2 {{
            font-size: 20px;
            font-weight: 600;
            margin-top: 0;
            margin-bottom: 12px;
        }}
        ul {{
            list-style: none;
            padding: 0;
            margin: 0;
        }}
        li {{
            margin-bottom: 10px;
        }}
        a {{
            color: var(--color-link);
            text-decoration: none;
        }}
        a:hover {{
            color: var(--color-link-hover);
            text-decoration: underline;
        }}
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>FirebladeECS Documentation Versions</h1>
            <a class="back-link" href="{latest_link}">Back to Latest Documentation</a>
        </header>

        <section>
            <h2>Latest Release</h2>
            <ul>
                <li><a href="{latest_link}">Latest Release ({latest_tag})</a></li>
            </ul>
        </section>

        {dev_section_html}

        <section>
            <h2>Previous Releases</h2>
            <ul>
                {previous_releases_html if previous_releases_html else "<li>No previous releases available.</li>"}
            </ul>
        </section>
    </div>
</body>
</html>
"""

with open(os.path.join(versions_html_dir, 'index.html'), 'w') as f:
    f.write(html_content)

script_tag = f'<script src="/{repo_name}/version-picker.js" defer></script>'
entries = os.listdir(output_dir)
for entry in entries:
    version_path = os.path.join(output_dir, entry)
    if os.path.isdir(version_path):
        index_file = os.path.join(version_path, 'index.html')
        if os.path.isfile(index_file):
            with open(index_file, 'r') as f:
                content = f.read()
            if script_tag not in content:
                if '</head>' in content:
                    content = content.replace('</head>', f'    {script_tag}\n</head>')
                else:
                    content += f'\n{script_tag}'
                with open(index_file, 'w') as f:
                    f.write(content)
PYTHON_EOF

echo "Documentation sync, manifest, catalog landing page, and version picker generation complete."
