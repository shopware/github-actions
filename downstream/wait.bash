#!/usr/bin/env bash
REPO=${1}
WORKFLOW=${2}
RUN_ID=${3}

FILTER_DATE=$(TZ=UTC date -d "-5 minutes" "+%Y-%m-%dT%H:%M")
MAX_ATTEMPTS=10
ATTEMPT=1

DOWNSTREAM_RUN_ID=invalid

trap on_sigterm SIGTERM 

on_sigterm() {
    echo "Timeout reached"
    fail
}

fail() {
    if [[ "${CHECK}" != "${RUN_ID}" ]]; then
        echo "Failed to find run id in downstream"
        exit 1
    fi

    echo "Please check https://github.com/${REPO}/actions/runs/${DOWNSTREAM_RUN_ID} for further information."
    exit 1
}

get_run_ids() {
    gh run list --workflow=$WORKFLOW --event workflow_dispatch --repo $REPO --created ">=$FILTER_DATE" --json databaseId | jq '.[] | .databaseId'
}

find_connect_step_job_id() {
    gh run view $1 --repo $REPO --json jobs \
        | jq '.jobs[] | select(.steps[] | .name | contains("upstream-connect")) | .databaseId'
}

while true; do
    echo "Trying to get run id from downstream. Attempt: ${ATTEMPT}"
    ATTEMPT=$((ATTEMPT + 1))
    
    readarray -t RUNS < <(get_run_ids)

    echo $RUNS

    for RUN in "${RUNS[@]}"; do
        job_id=$(find_connect_step_job_id $RUN)
        echo $job_id

        if [[ -n $job_id ]]; then
            if gh run view $1 --repo $REPO --log -j $job_id | grep -q ${RUN_ID}; then
                # Break out of for and until loop
                DOWNSTREAM_RUN_ID=${RUN}
                break 2
            fi
        fi
    done

    sleep 10
done

url=https://github.com/${REPO}/actions/runs/${DOWNSTREAM_RUN_ID}
echo "Downstream workflow: $url"

echo "downstream_run_id=${DOWNSTREAM_RUN_ID}" >>$GITHUB_OUTPUT
echo "downstream_run_url=${url}" >>$GITHUB_OUTPUT

while true; do
    ATTEMPT=$((ATTEMPT + 1))
    STATUS=$(gh run view --repo ${REPO} ${DOWNSTREAM_RUN_ID} --json status,conclusion | jq -r 'select(.status == "completed") | .conclusion')

    if [[ "${STATUS}" != "" ]]; then
        break
    fi

    # Only check every minute
    sleep 60
done

if [[ "${STATUS}" != "success" ]]; then
    echo "Downstream workflow failed."
    fail
fi

echo "Downstream workflow succeeded!"