#!/usr/bin/bash

set -e
set pipefail

get_ref() {
    local ref

    if [[ -n "${HEAD_REF}" ]]; then
        echo "refs/heads/${HEAD_REF}"
    else
        echo "${REF}"
    fi

}

ref="$(get_ref)"
echo "Local ref: ${ref}"

PR_NR=$(echo "${ref}" | sed -E -n "s|^refs/heads/gh-readonly-queue/[^/]+/pr-([0-9]+)-.*$|\1|p")
if [[ -n "${PR_NR}" ]]; then
    echo "Found merge queue ref with PR Nr. ${PR_NR}" 2>&1
    ref="refs/heads/$(gh pr view --repo "${CURRENT_REPO}" "${PR_NR}"  --jq '.headRefName' --json headRefName)"
fi

remote_ref=$(git ls-remote --heads "https://github.com/${REPO}" "${ref}" | cut -f 2)
if [[ -n "${remote_ref}" ]]; then
    version="${remote_ref#"refs/heads/"}"
else
    remote_ref=$(git ls-remote --heads "https://github.com/${REPO}" "refs/heads/${BASE_REF}" | cut -f 2)
    if [[ -n "${remote_ref}" ]]; then
        version="${remote_ref#"refs/heads/"}"
    fi
fi

if [[ -z "$version" ]]; then
    echo "$ref not found in ${REPO}, using fallback "
    version="${FALLBACK}"
fi

echo "Matching shopware version: $version"

echo "shopware-version=$version" >> "$GITHUB_OUTPUT"