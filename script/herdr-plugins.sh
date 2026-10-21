#!/usr/bin/env bash
# Install pinned Herdr plugins from GitHub
# This script is idempotent. It skips a plugin that is already installed at its pinned ref.
# To move a pin, change its ref here and re-run.

set -euo pipefail

# owner/repo@ref. Pin a release tag so a new upstream commit never installs by itself.
PLUGINS=(
    "smarzban/herdr-file-viewer@v1.18.0"
)

installed=$(herdr plugin list --json)

for plugin in "${PLUGINS[@]}"; do
    source="${plugin%@*}"
    ref="${plugin#*@}"
    current=$(jq -r --arg owner "${source%%/*}" --arg repo "${source#*/}" \
        '.result.plugins[].source | select(.kind == "github" and .owner == $owner and .repo == $repo) | .requested_ref' \
        <<<"$installed")
    if [[ "$current" == "$ref" ]]; then
        echo "${source} already at ${ref}"
        continue
    fi
    herdr plugin install --yes --ref "$ref" "$source"
done
