#!/usr/bin/env bash
REPO=${1}
WORKFLOW=${2}
UPSTREAM_RUN_ID=${2}

FILTER_DATE=$(TZ=UTC date -d "-5 minutes" "+%Y-%m-%dT%H:%M")
MAX_ATTEMPTS=10
ATTEMPT=1

DOWNSTREAM_RUN_ID=0

get_run_ids() {
    gh run list --workflow=$WORKFLOW --event workflow_dispatch --repo $REPO --created ">=$FILTER_DATE" --json databaseId | jq '.[] | .databaseId'
}

find_connect_step() {
    gh run view $1 --repo shopware/swaglanguagepack --json jobs \
      | jq -r '.jobs[] | select(.name == "Upstream ID identifier" and .conclusion != "skipped") | .steps[].name' \
      | grep -o '[[:digit:]]*'
}

until [[ ${ATTEMPT} -eq ${MAX_ATTEMPTS} ]]; do
    echo "Trying to get run id from downstream. Attempt: ${ATTEMPT}"
    ATTEMPT=$((ATTEMPT + 1))
    
    readarray -t RUNS < <(get_run_ids)

    for RUN in "${RUNS[@]}"; do
        CHECK=$(
            curl -s \
                -H "Accept: application/vnd.github+json" \
                -H "Authorization: Bearer ${AUTH_TOKEN}" \
                "https://api.github.com/repos/${REPO}/actions/runs/${RUN}/jobs" 
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

url=https://github.com/${REPO}/actions/runs/${DOWNSTREAM_RUN_ID}
echo "Downstream Pipeline: $url"

echo "downstream_run_id=${DOWNSTREAM_RUN_ID}" >>$GITHUB_OUTPUT
echo "downstream_run_url=${url}" >>$GITHUB_OUTPUT