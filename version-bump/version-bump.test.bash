#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
TMP_DIR=$(mktemp -d)

trap 'rm -rf "${TMP_DIR}"' EXIT

# Stub `git show <ref>:<path>` -> fixture keyed on both ref and file:
# composer.json fixtures come from STUB_OLD/STUB_NEW, manifest.xml from STUB_OLD_XML/STUB_NEW_XML
# (empty = missing file at that ref -> exit 128, so the script falls through / reports empty).
cat > "${TMP_DIR}/git" <<'EOF'
#!/usr/bin/env bash
if [[ "${1}" == "show" ]]; then
    spec="${2}"
    ref="${spec%%:*}"
    file="${spec#*:}"
    content=""
    case "${file}" in
        *composer.json)
            case "${ref}" in old) content="${STUB_OLD-}" ;; new) content="${STUB_NEW-}" ;; esac ;;
        *manifest.xml)
            case "${ref}" in old) content="${STUB_OLD_XML-}" ;; new) content="${STUB_NEW_XML-}" ;; esac ;;
    esac
    if [[ -z "${content}" ]]; then
        exit 128
    fi
    printf '%s' "${content}"
    exit 0
fi
exit 1
EOF
chmod +x "${TMP_DIR}/git"

# Asserts the script wrote `bumped=<expected>` to GITHUB_OUTPUT. Args: name code output out expected.
_assert_bumped() {
    local name="${1}" code="${2}" output="${3}" out="${4}" expected="${5}"

    if [[ "${code}" -ne 0 ]]; then
        echo "FAIL ${name}: version-bump.bash exited with ${code}"
        echo "${output}"; cat "${out}"; rm -f "${out}"; exit 1
    fi

    local got
    got=$(grep -m1 '^bumped=' "${out}" | cut -d= -f2 || true)
    if [[ -z "${got}" ]]; then
        echo "FAIL ${name}: did not write bumped=... to GITHUB_OUTPUT"
        echo "${output}"; cat "${out}"; rm -f "${out}"; exit 1
    fi
    if [[ "${got}" != "${expected}" ]]; then
        echo "FAIL ${name}: expected bumped=${expected}, got '${got}'"
        echo "${output}"; cat "${out}"; rm -f "${out}"; exit 1
    fi

    echo "ok - ${name} (bumped=${got})"
    rm -f "${out}"
}

# Plugin case: composer.json fixtures at old/new.
run_case() {
    local name="${1}" old_json="${2}" new_json="${3}" expected_bumped="${4}"
    local out; out=$(mktemp)
    local output code
    set +e
    output=$(PATH="${TMP_DIR}:${PATH}" \
        STUB_OLD="${old_json}" \
        STUB_NEW="${new_json}" \
        OLD_REF=old NEW_REF=new EXT_PATH=. \
        GITHUB_OUTPUT="${out}" \
        bash "${SCRIPT_DIR}/version-bump.bash" 2>&1)
    code=$?
    set -e
    _assert_bumped "${name}" "${code}" "${output}" "${out}" "${expected_bumped}"
}

# App case: manifest.xml fixtures at old/new (no composer.json present -> app path taken).
run_case_app() {
    local name="${1}" old_xml="${2}" new_xml="${3}" expected_bumped="${4}"
    local out; out=$(mktemp)
    local output code
    set +e
    output=$(PATH="${TMP_DIR}:${PATH}" \
        STUB_OLD_XML="${old_xml}" \
        STUB_NEW_XML="${new_xml}" \
        OLD_REF=old NEW_REF=new EXT_PATH=. \
        GITHUB_OUTPUT="${out}" \
        bash "${SCRIPT_DIR}/version-bump.bash" 2>&1)
    code=$?
    set -e
    _assert_bumped "${name}" "${code}" "${output}" "${out}" "${expected_bumped}"
}

run_case "minor bump"            '{"version":"5.3.0"}'    '{"version":"5.4.0"}'    true
run_case "patch bump"            '{"version":"5.3.0"}'    '{"version":"5.3.1"}'    true
run_case "no change"             '{"version":"5.3.0"}'    '{"version":"5.3.0"}'    false
run_case "downgrade"             '{"version":"5.4.0"}'    '{"version":"5.3.0"}'    false
run_case "four-segment bump"     '{"version":"6.6.10.0"}' '{"version":"6.6.10.1"}' true
run_case "version field removed" '{"version":"5.3.0"}'    '{"name":"swag/foo"}'    false
run_case "version field added"   '{"name":"swag/foo"}'    '{"version":"5.3.0"}'    false
run_case "missing old ref"       ''                       '{"version":"5.3.0"}'    false
run_case "leading v prefix"      '{"version":"v1.0.0"}'   '{"version":"v1.1.0"}'   true
run_case "v prefix only"         '{"version":"v1.0.0"}'   '{"version":"1.0.0"}'    false
run_case "rc to final"           '{"version":"1.0.0-rc1"}' '{"version":"1.0.0"}'   true
run_case "final to rc"           '{"version":"1.0.0"}'    '{"version":"1.0.0-rc1"}' false
run_case "rc to newer rc"        '{"version":"1.0.0-rc1"}' '{"version":"1.0.0-rc2"}' true
run_case "rc to older rc"        '{"version":"1.0.0-rc2"}' '{"version":"1.0.0-rc1"}' false
run_case "final to next rc"      '{"version":"1.0.0"}'    '{"version":"1.1.0-rc1"}' true

# --- app (manifest.xml) cases ---
manifest() { printf '<manifest><meta><name>swag/foo</name><version>%s</version></meta></manifest>' "${1}"; }
manifest_nover='<manifest><meta><name>swag/foo</name></meta></manifest>'

run_case_app "app minor bump"       "$(manifest 1.0.0)" "$(manifest 1.1.0)" true
run_case_app "app patch bump"       "$(manifest 4.0.0)" "$(manifest 4.0.1)" true
run_case_app "app no change"        "$(manifest 3.1.0)" "$(manifest 3.1.0)" false
run_case_app "app downgrade"        "$(manifest 4.0.0)" "$(manifest 3.9.9)" false
run_case_app "app version missing"  "${manifest_nover}" "$(manifest 1.0.0)" false
run_case_app "app new manifest"     ''                  "$(manifest 1.0.0)" false

# real manifests carry xmlns:xsi / xsi:noNamespaceSchemaLocation on the root — must not break the XPath
run_case_app "app with xsi namespace attrs" \
    '<manifest xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="x.xsd"><meta><version>1.0.0</version></meta></manifest>' \
    '<manifest xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="x.xsd"><meta><version>1.1.0</version></meta></manifest>' \
    true

# composer.json takes precedence when both files exist: no composer change -> false, despite a manifest bump
out=$(mktemp)
set +e
output=$(PATH="${TMP_DIR}:${PATH}" \
    STUB_OLD='{"version":"5.3.0"}' STUB_NEW='{"version":"5.3.0"}' \
    STUB_OLD_XML="$(manifest 1.0.0)" STUB_NEW_XML="$(manifest 2.0.0)" \
    OLD_REF=old NEW_REF=new EXT_PATH=. GITHUB_OUTPUT="${out}" \
    bash "${SCRIPT_DIR}/version-bump.bash" 2>&1)
code=$?
set -e
_assert_bumped "composer.json precedence over manifest.xml" "${code}" "${output}" "${out}" false

echo "All version-bump tests passed."