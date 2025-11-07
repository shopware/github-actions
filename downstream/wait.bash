#!/usr/bin/env bash
REPO=${1}
WORKFLOW=${2}
RUN_ID=${3}
POLL_INTERVAL=${4}

# TODO: Remove old logic when no branches are outdated
NEW_LOGIC=${NEW_LOGIC:-0}

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
    if [[ -z "${DOWNSTREAM_RUN_ID}" ]]; then
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
    # TODO: Remove old logic when no branches are outdated
    if [[ ${NEW_LOGIC} -ne 1 ]]; then
        gh run view $1 --repo $REPO --json jobs |
            jq '.jobs[] | select(.steps[] | .name | contains("upstream-connect")) | .databaseId'
        return
    fi
    gh run view $1 --repo $REPO --json jobs |
        jq --arg run_id "${RUN_ID}" '.jobs[] | select(.name | contains($run_id)) | .databaseId'
}

while true; do
    if [[ ${NEW_LOGIC} -eq 1 && ${ATTEMPT} -gt ${MAX_ATTEMPTS} ]]; then
        fail
    fi
    echo "Trying to get run id from downstream. Attempt: ${ATTEMPT}"
    ATTEMPT=$((ATTEMPT + 1))

    readarray -t RUNS < <(get_run_ids)

    echo $RUNS

    for RUN in "${RUNS[@]}"; do
        job_id=$(find_connect_step_job_id $RUN)
        echo $job_id

        if [[ -n $job_id ]]; then
            # TODO: Remove old logic when no branches are outdated
            if [[ ${NEW_LOGIC} -ne 1 && ! $(gh run view ${RUN} --repo $REPO --log -j $job_id | grep -q ${RUN_ID}) ]]; then
                continue
            fi
            # Break out of for and until loop
            DOWNSTREAM_RUN_ID=${RUN}
            break 2
        fi
    done

    sleep ${POLL_INTERVAL}
done

url=https://github.com/${REPO}/actions/runs/${DOWNSTREAM_RUN_ID}
echo "Downstream workflow: $url"

echo "downstream_run_id=${DOWNSTREAM_RUN_ID}" >>$GITHUB_OUTPUT
echo "downstream_run_url=${url}" >>$GITHUB_OUTPUT

ATTEMPT=1

while true; do
    echo "Trying to get run status... Attempt: ${ATTEMPT}"
    ATTEMPT=$((ATTEMPT + 1))
    STATUS=$(gh run view --repo ${REPO} ${DOWNSTREAM_RUN_ID} --json status,conclusion | jq -r 'select(.status == "completed") | .conclusion')

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
