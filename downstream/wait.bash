#!/usr/bin/env bash
REPO=${1}
POLL_INTERVAL=${2}
DOWNSTREAM_RUN_URL=${3}
CANCEL_REQUESTED=0

DOWNSTREAM_RUN_ID=$(basename "$DOWNSTREAM_RUN_URL")

trap on_sigterm SIGTERM

on_sigterm() {
    if [[ "${CANCEL_REQUESTED}" == "1" ]]; then
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

    while true; do
        sleep 60
    done
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

    echo "Job is still running. Waiting 1 minute before retrying..."

    # Only check every minute
    sleep 60
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
