#!/usr/bin/env bash

PREV_MAJOR="${PREV_MAJOR:-"v6.6."}"
CUR_MAJOR="${CUR_MAJOR:-"v6.7."}"

# make sure tag is prefixed with v
PREV_MAJOR="v${PREV_MAJOR#v}"
CUR_MAJOR="v${CUR_MAJOR#v}"

get_tags() {
    git -c 'versionsort.suffix=-' ls-remote --exit-code --refs --sort='version:refname' --tags https://github.com/shopware/shopware 2>/dev/null |
        cut -d '/' -f 3 | grep -v -i -E '(dev|beta|alpha)'
}

get_tags_without_rc() {
    git -c 'versionsort.suffix=-' ls-remote --exit-code --refs --sort='version:refname' --tags https://github.com/shopware/shopware 2>/dev/null |
        cut -d '/' -f 3 | grep -v -i -E 'rc'
}

get_next_minor_and_patch() {
    version=${1}
    local max_tag=$(get_tags_without_rc | grep -E "^${version}" | tail -n 1)
    if [[ -z $max_tag ]]; then
        max_tag=$(get_tags | grep -E "^${version}" | tail -n 1)
    fi
    IFS='.' read -r -a parts <<<"${max_tag}"

    # check if release branch already exists for 2 minor versions ahead
    # if that is the case, that is the next minor release, as the final branch split for the version 1 minor ahead did already happen
    NEXT_MINOR_RELEASE="${parts[0]}.${parts[1]}.$((${parts[2]} + 2)).x"
    NEXT_MINOR_RELEASE="${NEXT_MINOR_RELEASE:1}" # remove leading 'v'
    local branch_exists=$(git ls-remote --heads https://github.com/shopware/shopware ${NEXT_MINOR_RELEASE})

    if [[ -z ${branch_exists} ]]; then
        echo "NEXT_MINOR=${parts[0]}.${parts[1]}.$((${parts[2]} + 1)).0"
        echo "SPLITTED_MINOR=${parts[0]}.${parts[1]}.$((${parts[2]})).0"
    else
        echo "NEXT_MINOR=${parts[0]}.${parts[1]}.$((${parts[2]} + 2)).0"
        echo "SPLITTED_MINOR=${parts[0]}.${parts[1]}.$((${parts[2]} + 1)).0"
    fi

    echo "NEXT_PATCH=${parts[0]}.${parts[1]}.${parts[2]}.$((${parts[3]} + 1))"

    local max_lts_tag=$(get_tags_without_rc | grep -E "^${PREV_MAJOR}" | tail -n 1)
    if [[ -z $max_lts_tag ]]; then
        max_lts_tag=$(get_tags | grep -E "^${PREV_MAJOR}" | tail -n 1)
    fi
    IFS='.' read -r -a lts_parts <<<"${max_lts_tag}"

    echo "NEXT_LTS_PATCH=${lts_parts[0]}.${lts_parts[1]}.${lts_parts[2]}.$((${lts_parts[3]} + 1))"
}

print_min_max_tag() {
    local min_tag=$(get_tags_without_rc | grep -E "^$2" | head -n 1)
    if [[ -z $min_tag ]]; then
        min_tag=$(get_tags | grep -E "^$2" | head -n 1)
    fi

    echo "${1}_MIN_TAG=$min_tag"

    local max_tag=$(get_tags_without_rc | grep -E "^$2" | tail -n 1)
    if [[ -z $max_tag ]]; then
        max_tag=$(get_tags | grep -E "^$2" | tail -n 1)
    fi

    echo "${1}_MAX_TAG=$max_tag"
}

print_min_max_tag PREV_MAJOR "$PREV_MAJOR"
print_min_max_tag CUR_MAJOR "$CUR_MAJOR"
get_next_minor_and_patch "${CUR_MAJOR}"
