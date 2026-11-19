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

# Merge-queue cases: the fake keeps the downstream run in progress until it is
# cancelled or has been polled twice, and answers the ref lookup per GH_REF_STATUS.
STATE_DIR=$(mktemp -d)
QUEUE_BIN=$(mktemp -d)
trap 'rm -rf "${TMP_DIR}" "${STATE_DIR}" "${QUEUE_BIN}"' EXIT

cat > "${QUEUE_BIN}/gh" <<'FAKE'
#!/usr/bin/env bash
if [[ "${1} ${2}" == "run view" ]]; then
    polls=$(( $(cat "${STATE_DIR}/polls" 2>/dev/null || echo 0) + 1 ))
    echo "${polls}" > "${STATE_DIR}/polls"
    if [[ -e "${STATE_DIR}/cancelled" ]]; then
        echo '{"status":"completed","conclusion":"cancelled"}'
    elif (( polls > 2 )); then
        echo '{"status":"completed","conclusion":"success"}'
    else
        echo '{"status":"in_progress","conclusion":""}'
    fi
    exit 0
fi
if [[ "${1} ${2}" == "run cancel" ]]; then
    touch "${STATE_DIR}/cancelled"
    echo "downstream cancel called"
    exit 0
fi
if [[ "${1}" == "api" ]]; then
    echo "${2}" >> "${STATE_DIR}/api_calls"
    case "${GH_REF_STATUS}" in
        exists) echo '{"ref":"x"}'; exit 0 ;;
        gone) echo "gh: Not Found (HTTP 404)" >&2; exit 1 ;;
        *) echo "gh: Server Error (HTTP 500)" >&2; exit 1 ;;
    esac
fi
exit 1
FAKE
chmod +x "${QUEUE_BIN}/gh"

run_queue_case() {
    local name=${1} ref=${2} ref_status=${3} expected_code=${4} expected_message=${5} unexpected_message=${6:-}
    local output code
    rm -f "${STATE_DIR}"/*

    set +e
    output=$(PATH="${QUEUE_BIN}:${PATH}" STATE_DIR="${STATE_DIR}" GH_REF_STATUS="${ref_status}" WAIT_POLL_SECONDS=0 \
        UPSTREAM_REPOSITORY=shopware/shopware UPSTREAM_REF="${ref}" \
        bash "${SCRIPT_DIR}/wait.bash" shopware/example 1 https://github.com/shopware/example/actions/runs/1 2>&1)
    code=$?
    set -e

    if [[ "${code}" -ne "${expected_code}" || "${output}" != *"${expected_message}"* ]]; then
        echo "Case '${name}': expected exit ${expected_code} and '${expected_message}', got exit ${code}"
        echo "${output}"
        exit 1
    fi
    if [[ -n "${unexpected_message}" && "${output}" == *"${unexpected_message}"* ]]; then
        echo "Case '${name}': output must not contain '${unexpected_message}'"
        echo "${output}"
        exit 1
    fi
}

QUEUE_REF=refs/heads/gh-readonly-queue/trunk/pr-1-abc
run_queue_case "queue branch deleted" "${QUEUE_REF}" gone 1 "Downstream workflow was cancelled."
grep -q "git/ref/heads/gh-readonly-queue/trunk/pr-1-abc" "${STATE_DIR}/api_calls" || { echo "Case 'queue branch deleted': wrong ref looked up"; exit 1; }
run_queue_case "queue branch exists" "${QUEUE_REF}" exists 0 "Downstream workflow succeeded!" "downstream cancel called"
run_queue_case "ref lookup errors" "${QUEUE_REF}" error 0 "Downstream workflow succeeded!" "downstream cancel called"
run_queue_case "not a merge queue run" refs/heads/trunk gone 0 "Downstream workflow succeeded!" "downstream cancel called"
[[ ! -e "${STATE_DIR}/api_calls" ]] || { echo "Case 'not a merge queue run': must not look up the ref"; exit 1; }

echo "All wait.bash cases passed."
