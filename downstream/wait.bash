#!/usr/bin/env bash
REPO=${1}
POLL_INTERVAL=${2}
DOWNSTREAM_RUN_URL=${3}

DOWNSTREAM_RUN_ID=$(basename "$DOWNSTREAM_RUN_URL")

trap on_sigterm SIGTERM

on_sigterm() {
    echo "Timeout reached"
    fail
}

fail() {
    echo "Please check ${DOWNSTREAM_RUN_URL} for further information."
    exit 1
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

if [[ "${STATUS}" != "success" ]]; then
    echo "Downstream workflow failed."
    fail
fi

echo "Downstream workflow succeeded!"