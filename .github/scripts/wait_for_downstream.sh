#!/usr/bin/env bash
REPO="${1}"
AUTH_TOKEN="${2}"
RUN_ID="${3}"

# timeout in minutes
TIMEOUT=30
ATTEMPT=29

until [[ $ATTEMPT -eq $TIMEOUT ]]; do
    ATTEMPT=$((ATTEMPT + 1))
    STATUS=$(curl \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer ${AUTH_TOKEN}" \
        "https://api.github.com/repos/${REPO}/actions/runs/${RUN_ID}" | jq -r 'select(.status == "completed") | .conclusion')

    if [[ "${STATUS}" != "" ]]; then
        break
    fi

    # Only check every minute
    sleep 60
done

if [[ "${STATUS}" != "success" ]]; then
    echo "Downstream pipeline failed."
    echo "Please check https://github.com/${REPO}/actions/runs/${RUN_ID} for further information."
    exit 1
fi

echo "Downstream pipeline succeeded!"
