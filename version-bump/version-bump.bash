#!/usr/bin/env bash

# Detects whether the extension version strictly increased between two git references.
# Plugins carry the version in composer.json, apps in manifest.xml (<manifest><meta><version>).
#
# Global environment variables required:
# OLD_REF  - git ref/sha for the previous state (e.g. the PR base sha)
# NEW_REF  - git ref/sha for the new state (e.g. the PR head sha)
# EXT_PATH - path to the extension root containing composer.json or manifest.xml (default: .)

set -euo pipefail

EXT_PATH="${EXT_PATH:-.}"
if [[ "${EXT_PATH}" == "." || -z "${EXT_PATH}" ]]; then
    prefix=""
else
    prefix="${EXT_PATH%/}/"
fi
COMPOSER_PATH="${prefix}composer.json"
MANIFEST_PATH="${prefix}manifest.xml"

if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq is required but was not found on PATH" >&2
    exit 1
fi

read_version() {
    # Missing ref/file -> empty (no notification); a parse error propagates (fail loud).
    # composer.json (plugin) takes precedence over manifest.xml (app) when both exist.
    local ref="${1}" content
    if content=$(git show "${ref}:${COMPOSER_PATH}" 2>/dev/null); then
        jq -r '.version // empty' <<<"${content}"
        return 0
    fi
    if content=$(git show "${ref}:${MANIFEST_PATH}" 2>/dev/null); then
        if ! command -v python3 >/dev/null 2>&1; then
            echo "Error: python3 is required to read manifest.xml but was not found on PATH" >&2
            exit 1
        fi
        # Apps keep the version in <manifest><meta><version>; there is no default namespace,
        # so a plain element path works. A missing node prints empty (no notification); a
        # malformed manifest raises and propagates (fail loud), matching the composer.json path.
        printf '%s' "${content}" | python3 -c '
import sys, xml.etree.ElementTree as ET
root = ET.fromstring(sys.stdin.read())
el = root.find("./meta/version")
sys.stdout.write((el.text or "").strip() if el is not None else "")
'
        return 0
    fi
    return 0
}

OLD_VERSION=$(read_version "${OLD_REF}")
NEW_VERSION=$(read_version "${NEW_REF}")

version_gt() {
    local a="${1#v}" b="${2#v}"
    local a_core="${a%%-*}" b_core="${b%%-*}"
    local a_pre="" b_pre=""
    if [[ "${a}" == *-* ]]; then a_pre="${a#*-}"; fi
    if [[ "${b}" == *-* ]]; then b_pre="${b#*-}"; fi

    if [[ "${a_core}" != "${b_core}" ]]; then
        if [[ "$(printf '%s\n%s\n' "${a_core}" "${b_core}" | sort -V | tail -n1)" == "${b_core}" ]]; then
            return 0
        fi
        return 1
    fi

    if [[ "${a_pre}" == "${b_pre}" ]]; then return 1; fi   # identical version
    if [[ -z "${b_pre}" ]]; then return 0; fi              # equal core: b is final, a is pre-release
    if [[ -z "${a_pre}" ]]; then return 1; fi              # equal core: a is final, b is pre-release
    if [[ "$(printf '%s\n%s\n' "${a_pre}" "${b_pre}" | sort -V | tail -n1)" == "${b_pre}" ]]; then
        return 0
    fi
    return 1
}

bumped=false
if [[ -n "${OLD_VERSION}" && -n "${NEW_VERSION}" ]] && version_gt "${OLD_VERSION}" "${NEW_VERSION}"; then
    bumped=true
fi

echo "Previous version: '${OLD_VERSION:-<none>}'"
echo "Current version:  '${NEW_VERSION:-<none>}'"
echo "Bumped: ${bumped}"

# Multiline delimiter form so a newline in a value can't forge extra output entries.
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
