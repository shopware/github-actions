#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
TMP_DIR=$(mktemp -d)

trap 'rm -rf "${TMP_DIR}"' EXIT

# Stub `git show <ref>:<path>` -> composer.json fixture for that ref (STUB_OLD/STUB_NEW; empty = missing).
cat > "${TMP_DIR}/git" <<'EOF'
#!/usr/bin/env bash
if [[ "${1}" == "show" ]]; then
    ref="${2%%:*}"
    case "${ref}" in
        old) content="${STUB_OLD-}" ;;
        new) content="${STUB_NEW-}" ;;
        *)   content="" ;;
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

run_case() {
    local name="${1}"
    local old_json="${2}"
    local new_json="${3}"
    local expected_bumped="${4}"
    local out
    out=$(mktemp)

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

    if [[ "${code}" -ne 0 ]]; then
        echo "FAIL ${name}: version-bump.bash exited with ${code}"
        echo "${output}"
        cat "${out}"
        rm -f "${out}"
        exit 1
    fi

    local got
    got=$(grep -m1 '^bumped=' "${out}" | cut -d= -f2 || true)
    if [[ -z "${got}" ]]; then
        echo "FAIL ${name}: did not write bumped=... to GITHUB_OUTPUT"
        echo "${output}"
        cat "${out}"
        rm -f "${out}"
        exit 1
    fi
    if [[ "${got}" != "${expected_bumped}" ]]; then
        echo "FAIL ${name}: expected bumped=${expected_bumped}, got '${got}'"
        echo "${output}"
        cat "${out}"
        rm -f "${out}"
        exit 1
    fi

    echo "ok - ${name} (bumped=${got})"
    rm -f "${out}"
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

echo "All version-bump tests passed."