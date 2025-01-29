#!/usr/bin/bash

set -e
set pipefail

if [[ -n "${HEAD_REF}" ]]; then
    ref="refs/heads/${HEAD_REF}"
else
    ref="${REF}"
fi

echo "Local ref: ${ref}"

PR_NR=$(echo "${ref}" | sed -E -n "s|^refs/heads/gh-readonly-queue/[^/]+/pr-([0-9]+)-.*$|\1|p")
if [[ -n "${PR_NR}" ]]; then
    echo "Found merge queue ref with PR_NR: ${PR_NR}"
    version="$(gh pr view --repo "${REPO}" "${PR_NR}"  --jq '.headRefName' --json headRefName)"
else 
    remote_ref=$(git ls-remote --heads "https://github.com/${REPO}" "${ref}" | cut -f 2)
    if [[ -n "${remote_ref}" ]]; then
        version="${remote_ref#"refs/heads/"}"
    else
        remote_ref=$(git ls-remote --heads "https://github.com/${REPO}" "refs/heads/${BASE_REF}" | cut -f 2)
        if [[ -n "${remote_ref}" ]]; then
        version="${remote_ref#"refs/heads/"}"
        fi
    fi
fi

if [[ -z "$version" ]]; then
    echo "No matching branch found, using fallback "
    version="${FALLBACK}"
fi

echo "Matching shopware version: $version"

echo "shopware-version=$version" >> "$GITHUB_OUTPUT"