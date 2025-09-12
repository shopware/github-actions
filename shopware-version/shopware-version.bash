#!/usr/bin/bash

# Global environment variables required:
# REF - The current git reference (e.g., refs/heads/6.4.1.0)
# BASE_REF - The base reference for pull requests (e.g., 6.4.1.0)
# HEAD_REF - The head reference for pull requests (optional)
# REPO - The target repository to search for matching branches (e.g., shopware/shopware or https://github.com/shopware/shopware)
# CURRENT_REPO - The current repository (e.g., shopware/platform)
# FALLBACK - The fallback branch to use if no matching branch is found (default: trunk)

set -e
set pipefail

get_ref() {
    local ref

    PR_NR=$(echo "${REF}" | sed -E -n "s|^refs/heads/gh-readonly-queue/[^/]+/pr-([0-9]+)-.*$|\1|p")
    if [[ -n "${PR_NR}" ]]; then
        echo "refs/heads/$(gh pr view --repo "${CURRENT_REPO}" "${PR_NR}"  --jq '.headRefName' --json headRefName)"
    fi

    #remove whitespace from HEAD_REF with bash substitution
    HEAD_REF=${HEAD_REF// /}
    if [[ -n "${HEAD_REF}" ]]; then
        echo "refs/heads/${HEAD_REF#"refs/heads/"}"
    else
        #remove whitespace from REF with bash substitution
        REF=${REF// /}
        echo "refs/heads/${REF#"refs/heads/"}"
    fi
}

get_base_ref() {
    PR_NR=$(echo "${1}" | sed -E -n "s|^refs/heads/gh-readonly-queue/[^/]+/pr-([0-9]+)-.*$|\1|p")
    if [[ -n "${PR_NR}" ]]; then
        echo "$(gh pr view --repo "${CURRENT_REPO}" "${PR_NR}"  --jq '.baseRefName' --json baseRefName)"
    fi

    #remove whitespace from BASE_REF with bash substitution
    BASE_REF=${BASE_REF// /}
    if [[ -n "${BASE_REF}" ]]; then
        echo "refs/heads/${BASE_REF#"refs/heads/"}"
    fi
}

REF="$(get_ref)"
echo "ref: ${REF}"
BASE_REF="$(get_base_ref "${REF}")"
echo "base ref: ${BASE_REF}"

# if REPO does not start with https add https://github.com/
if [[ "${REPO}" != https://* ]]; then
    REPO="https://github.com/${REPO}"
fi

# Algo for finding the matching branch in another repo
# 1. if REF exists in target repo, use it
# 2. if BASE_REF exists in target repo, use it
# 3. if the next minor branch of BASE_REF exists in target repo, use it
# 4. if the next major branch of BASE_REF exists in target repo, use it
# 5. use fallback

# to get the next minor from a patch branch replace last part with x
# to get the next major from a patch branch replace last two parts with x


echo "Step 1: Checking if REF '${REF}' exists in target repo '${REPO}'"
remote_ref=$(git ls-remote --heads "${REPO}" "${REF}" | cut -f 2)
if [[ -n "${remote_ref}" ]]; then
    version="${remote_ref#"refs/heads/"}"
    echo "✓ Found matching REF: ${version}"
else
    BASE_REF=${BASE_REF// /}
    if [[ -z "${BASE_REF}" ]]; then
        echo "✗ BASE_REF not set, using REF '${REF}'"
        BASE_REF="${REF}"
    fi

    echo "✗ REF not found, checking BASE_REF '${BASE_REF}'"
    # Check if BASE_REF exists in target repo
    remote_ref=$(git ls-remote --heads "${REPO}" "${BASE_REF}" | cut -f 2)
    if [[ -n "${remote_ref}" ]]; then
        version="${remote_ref#"refs/heads/"}"
        echo "✓ Found matching BASE_REF: ${version}"
    else
        echo "✗ BASE_REF not found, checking next minor branch"
        # Check next minor branch (replace last digit with x)
        next_minor=$(echo "${BASE_REF}" | sed -E 's/[0-9]+$/x/')
        echo "  Checking next minor: ${next_minor}"
        remote_ref=$(git ls-remote --heads "${REPO}" "${next_minor}" | cut -f 2)
        if [[ -n "${remote_ref}" ]]; then
            version="${remote_ref#"refs/heads/"}"
            echo "✓ Found matching next minor: ${version}"
        else
            echo "✗ Next minor not found, checking next major branch"
            # Check next major branch (replace last two digits with x)
            next_major=$(echo "${BASE_REF}" | sed -E 's/[0-9]+\.[0-9]+$/x/')
            echo "  Checking next major: ${next_major}"
            remote_ref=$(git ls-remote --heads "${REPO}" "${next_major}" | cut -f 2)

            if [[ -n "${remote_ref}" ]]; then
                version="${remote_ref#"refs/heads/"}"
                echo "✓ Found matching next major: ${version}"
            else
                echo "✗ No matching branch found, using fallback: ${FALLBACK}"
                # Use fallback
                version="${FALLBACK}"
            fi
        fi
    fi
fi

if [[ -z "$version" ]]; then
    echo "$REF not found in ${REPO}, using fallback "
    version="${FALLBACK}"
fi

echo "Matching shopware version: $version"

echo "shopware-version=$version" >> "$GITHUB_OUTPUT"