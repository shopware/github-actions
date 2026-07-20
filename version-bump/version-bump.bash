#!/usr/bin/env bash

# Detects whether the root `version` field in composer.json strictly increased
# between two git references.
#
# Global environment variables required:
# OLD_REF  - git ref/sha for the previous state (e.g. the PR base sha)
# NEW_REF  - git ref/sha for the new state (e.g. the PR head sha)
# EXT_PATH - path to the extension root containing composer.json (default: .)

set -euo pipefail

EXT_PATH="${EXT_PATH:-.}"
if [[ "${EXT_PATH}" == "." || -z "${EXT_PATH}" ]]; then
    COMPOSER_PATH="composer.json"
else
    COMPOSER_PATH="${EXT_PATH%/}/composer.json"
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq is required but was not found on PATH" >&2
    exit 1
fi

read_version() {
    # Prints the composer.json version at a ref. A missing ref/file yields nothing;
    # a genuine JSON parse error propagates and fails the action loudly rather than
    # being silently masked (which would suppress a release notification).
    local json
    if ! json=$(git show "${1}:${COMPOSER_PATH}" 2>/dev/null); then
        return 0
    fi
    jq -r '.version // empty' <<<"${json}"
}

OLD_VERSION=$(read_version "${OLD_REF}")
NEW_VERSION=$(read_version "${NEW_REF}")

bumped=false
if [[ -n "${OLD_VERSION}" && -n "${NEW_VERSION}" ]]; then
    # Compare on a v-stripped value so a leading "v" never skews the ordering — and
    # compare the stripped values for equality too, so "v1.0.0" -> "1.0.0" is a no-op.
    old_cmp="${OLD_VERSION#v}"
    new_cmp="${NEW_VERSION#v}"
    if [[ -n "${old_cmp}" && -n "${new_cmp}" && "${old_cmp}" != "${new_cmp}" ]]; then
        highest=$(printf '%s\n%s\n' "${old_cmp}" "${new_cmp}" | sort -V | tail -n1)
        if [[ "${highest}" == "${new_cmp}" ]]; then
            bumped=true
        fi
    fi
fi

echo "Previous version: '${OLD_VERSION:-<none>}'"
echo "Current version:  '${NEW_VERSION:-<none>}'"
echo "Bumped: ${bumped}"

# Write version values with the multiline delimiter form so a value containing a
# newline can never forge additional GITHUB_OUTPUT entries. `bumped` is a fixed literal.
delim="__VERSION_BUMP_EOF_${RANDOM}_${RANDOM}__"
while [[ "${OLD_VERSION}${NEW_VERSION}" == *"${delim}"* ]]; do
    delim="__VERSION_BUMP_EOF_${RANDOM}_${RANDOM}__"
done
{
    echo "bumped=${bumped}"
    echo "previous-version<<${delim}"
    printf '%s\n' "${OLD_VERSION}"
    echo "${delim}"
    echo "current-version<<${delim}"
    printf '%s\n' "${NEW_VERSION}"
    echo "${delim}"
} >>"${GITHUB_OUTPUT}"