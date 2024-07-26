#!/usr/bin/env bash
REPO=${1}
AUTH_TOKEN=${2}
RUN_ID=${3}
FILTER_DATE=$(date -d "-5 minutes" "+%Y-%m-%dT%H:%M")
MAX_ATTEMPTS=10
ATTEMPT=1
DOWNSTREAM_RUN_ID=0
until [[ ${ATTEMPT} -eq ${MAX_ATTEMPTS} ]]; do
    echo "Trying to get run id from downstream. Attempt: ${ATTEMPT}"
    ATTEMPT=$((ATTEMPT + 1))
    readarray -t RUNS < <(curl -s \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer ${AUTH_TOKEN}" \
        "https://api.github.com/repos/${REPO}/actions/runs?created:%3E${FILTER_DATE}&event=workflow_dispatch" | jq -r '.workflow_runs[].id')

    for RUN in "${RUNS[@]}"; do
        CHECK=$(
            curl -s \
                -H "Accept: application/vnd.github+json" \
                -H "Authorization: Bearer ${AUTH_TOKEN}" \
                "https://api.github.com/repos/${REPO}/actions/runs/${RUN}/jobs" | jq -r '.jobs[] | select(.name == "Upstream ID identifier" and .conclusion != "skipped") | .steps[].name' | grep -o '[[:digit:]]*'
        )
        if [[ "${CHECK}" -eq "${RUN_ID}" ]]; then
            # Break out of for and until loop
            DOWNSTREAM_RUN_ID=${RUN}
            break 2
        fi
    done

    sleep 10
done

if [[ ${ATTEMPT} -eq ${MAX_ATTEMPTS} ]] && [[ "${CHECK}" != "${RUN_ID}" ]]; then
    echo "Failed to find run id in downstream"
    exit 1
fi

echo "Downstream Pipeline: https://github.com/${REPO}/actions/runs/${DOWNSTREAM_RUN_ID}"
echo "downstream_run_id=${DOWNSTREAM_RUN_ID}" >>$GITHUB_OUTPUT
