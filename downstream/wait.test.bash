#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
TMP_DIR=$(mktemp -d)

trap 'rm -rf "${TMP_DIR}"' EXIT

cat > "${TMP_DIR}/gh" <<'EOF'
#!/usr/bin/env bash
if [[ "${1} ${2}" == "run view" ]]; then
    printf '{"status":"completed","conclusion":"%s"}\n' "${GH_CONCLUSION}"
    exit 0
fi

if [[ "${1} ${2}" == "run cancel" ]]; then
    echo "cancel called"
    exit "${GH_CANCEL_EXIT:-0}"
fi

exit 1
EOF
chmod +x "${TMP_DIR}/gh"

run_case() {
    local conclusion=${1}
    local expected_code=${2}
    local expected_message=${3}
    local output
    local code

    set +e
    output=$(PATH="${TMP_DIR}:${PATH}" GH_CONCLUSION="${conclusion}" bash "${SCRIPT_DIR}/wait.bash" shopware/example 1 https://github.com/shopware/example/actions/runs/1 2>&1)
    code=$?
    set -e

    if [[ "${code}" -ne "${expected_code}" ]]; then
        echo "Expected exit code ${expected_code} for ${conclusion}, got ${code}"
        echo "${output}"
        exit 1
    fi

    if [[ "${output}" != *"${expected_message}"* ]]; then
        echo "Expected output for ${conclusion} to contain: ${expected_message}"
        echo "${output}"
        exit 1
    fi
}

run_case success 0 "Downstream workflow succeeded!"
run_case failure 1 "Downstream workflow concluded with 'failure'."
run_case cancelled 1 "Downstream workflow was cancelled."

set +e
output=$(PATH="${TMP_DIR}:${PATH}" GH_CONCLUSION="cancelled" GH_CANCEL_EXIT=1 UPSTREAM_TOKEN=token UPSTREAM_REPOSITORY=shopware/shopware UPSTREAM_RUN_ID=1 bash "${SCRIPT_DIR}/wait.bash" shopware/example 1 https://github.com/shopware/example/actions/runs/1 2>&1)
code=$?
set -e

if [[ "${code}" -ne 1 || "${output}" != *"Could not cancel upstream workflow run."* ]]; then
    echo "Expected failed upstream cancellation to fall back to a failed downstream wait"
    echo "${output}"
    exit 1
fi
