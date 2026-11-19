#!/usr/bin/env bash
REPO=${1}
POLL_INTERVAL=${2}
DOWNSTREAM_RUN_URL=${3}
CANCEL_REQUESTED=0
DOWNSTREAM_CANCEL_REQUESTED=0
POLL_SECONDS=${WAIT_POLL_SECONDS:-60}

DOWNSTREAM_RUN_ID=$(basename "$DOWNSTREAM_RUN_URL")

trap on_sigterm SIGTERM

on_sigterm() {
    if [[ "${CANCEL_REQUESTED}" == "1" ]]; then
        # GitHub sent SIGTERM after accepting our cancellation request.
        echo "Upstream workflow cancellation is taking over."
        exit 130
    fi

    echo "Timeout reached"
    fail
}

fail() {
    echo "Please check ${DOWNSTREAM_RUN_URL} for further information."
    exit 1
}

cancel_upstream() {
    if [[ -z "${UPSTREAM_TOKEN:-}" || -z "${UPSTREAM_REPOSITORY:-}" || -z "${UPSTREAM_RUN_ID:-}" ]]; then
        return 1
    fi

    echo "Cancelling upstream workflow run ${UPSTREAM_RUN_ID} in ${UPSTREAM_REPOSITORY}."

    if ! GH_TOKEN="${UPSTREAM_TOKEN}" gh run cancel "${UPSTREAM_RUN_ID}" --repo "${UPSTREAM_REPOSITORY}"; then
        echo "Could not cancel upstream workflow run."
        return 1
    fi

    CANCEL_REQUESTED=1

    # gh run cancel only requests cancellation. Keep this step alive so GitHub
    # can mark the upstream run as cancelled instead of racing our own failure.
    while true; do
        sleep 60
    done
}

# When a merge-queue entry is ejected, GitHub deletes its gh-readonly-queue branch.
# Downstream jobs that start afterwards fail at checkout, which shows up as a red
# downstream run although nothing in it broke. Only a 404 counts as gone.
upstream_ref_gone() {
    [[ "${UPSTREAM_REF:-}" == refs/heads/gh-readonly-queue/* && -n "${UPSTREAM_REPOSITORY:-}" ]] || return 1

    local output
    if output=$(GH_TOKEN="${UPSTREAM_TOKEN:-${GH_TOKEN:-}}" gh api "repos/${UPSTREAM_REPOSITORY}/git/ref/${UPSTREAM_REF#refs/}" 2>&1); then
        return 1
    fi
    [[ "${output}" == *"HTTP 404"* ]]
}

echo "Downstream workflow: ${DOWNSTREAM_RUN_URL}"

ATTEMPT=1

while true; do
    echo "Trying to get run status... Attempt: ${ATTEMPT}"
    ATTEMPT=$((ATTEMPT + 1))
    STATUS=$(gh run view --repo "${REPO}" "${DOWNSTREAM_RUN_ID}" --json status,conclusion | jq -r 'select(.status == "completed") | .conclusion')

    if [[ "${STATUS}" != "" ]]; then
        break
    fi

    if [[ "${DOWNSTREAM_CANCEL_REQUESTED}" == "0" ]] && upstream_ref_gone; then
        echo "${UPSTREAM_REF#refs/heads/} no longer exists: the entry left the merge queue. Cancelling the downstream run."
        if gh run cancel --repo "${REPO}" "${DOWNSTREAM_RUN_ID}"; then
            DOWNSTREAM_CANCEL_REQUESTED=1
        else
            echo "Could not cancel the downstream run."
        fi
    fi

    echo "Job is still running. Waiting ${POLL_SECONDS}s before retrying..."
    sleep "${POLL_SECONDS}"
done

if [[ "${STATUS}" == "cancelled" ]]; then
    echo "Downstream workflow was cancelled."
    cancel_upstream
    fail
fi

if [[ "${STATUS}" != "success" ]]; then
    echo "Downstream workflow concluded with '${STATUS}'."
    fail
fi

echo "Downstream workflow succeeded!"
