#!/usr/bin/env bash
set -euo pipefail

TMP_DIR=$(mktemp -d)
trap 'rm -rf "${TMP_DIR}"' EXIT

mkdir -p "${TMP_DIR}/custom/plugins/MyPlugin"

cat > "${TMP_DIR}/composer.json" <<'EOF'
{
  "name": "shopware/production",
  "repositories": [
    {
      "type": "path",
      "url": "custom/plugins/*",
      "options": {
        "symlink": true
      }
    },
    {
      "type": "path",
      "url": "custom/static-plugins/*",
      "options": {
        "symlink": true
      }
    }
  ]
}
EOF

cat > "${TMP_DIR}/custom/plugins/MyPlugin/composer.json" <<'EOF'
{
  "name": "swag/my-plugin",
  "autoload-dev": {
    "psr-4": {
      "Swag\\MyPlugin\\Tests\\": "tests/"
    }
  }
}
EOF

run_adjustments() {
  local extra_repos="${1}"
  local extension_name="MyPlugin"
  
  (
    cd "${TMP_DIR}"
    AUTOLOAD_DEV="$(jq '."autoload-dev"."psr-4" // {} | to_entries | map({"key": .key, "value": "custom/plugins/'"${extension_name}"'/\(.value)"}) | from_entries' < "custom/plugins/${extension_name}/composer.json")"
    jq -s '
      .[0] as $doc | .[1] as $extra | .[2] as $auto |
      $doc | .repositories = (
        if ($extra == null or $extra == {} or $extra == []) then
          .repositories
        elif (.repositories == null) then
          $extra
        elif (.repositories | type) == "array" then
          .repositories + (if ($extra | type) == "array" then $extra else ($extra | to_entries | map(.value)) end)
        elif (.repositories | type) == "object" and ($extra | type) == "object" then
          .repositories * $extra
        else
          (.repositories | to_entries | map(.value)) + (if ($extra | type) == "array" then $extra else ($extra | to_entries | map(.value)) end)
        end
      )
      | if .repositories == null then del(.repositories) else . end
      | . * {"autoload-dev": {"psr-4": $auto}}
    ' composer.json <(echo "${extra_repos}") <(echo "$AUTOLOAD_DEV") > composer.json.new
    mv composer.json.new composer.json
  )
}

# Test 1: Empty extraRepositories preserves path repos
run_adjustments "{}"
repo_count=$(jq '.repositories | length' "${TMP_DIR}/composer.json")
first_repo_url=$(jq -r '.repositories[0].url' "${TMP_DIR}/composer.json")
if [[ "${repo_count}" -ne 2 || "${first_repo_url}" != "custom/plugins/*" ]]; then
  echo "Test 1 failed: Expected path repositories to be preserved, got count ${repo_count} and url '${first_repo_url}'"
  cat "${TMP_DIR}/composer.json"
  exit 1
fi
echo "Test 1 passed: Default empty extraRepositories preserves path repos"

# Test 2: Object extraRepositories merges with path repos
extra_obj='{"my-custom-repo": {"type": "vcs", "url": "https://example.com/repo.git"}}'
run_adjustments "${extra_obj}"
repo_count=$(jq '.repositories | length' "${TMP_DIR}/composer.json")
third_repo_url=$(jq -r '.repositories[2].url' "${TMP_DIR}/composer.json")
if [[ "${repo_count}" -ne 3 || "${third_repo_url}" != "https://example.com/repo.git" ]]; then
  echo "Test 2 failed: Expected extra object repo to be merged, got count ${repo_count} and url '${third_repo_url}'"
  cat "${TMP_DIR}/composer.json"
  exit 1
fi
echo "Test 2 passed: Object extraRepositories merges with path repos"

# Test 3: Array extraRepositories merges with path repos
# Reset composer.json
cat > "${TMP_DIR}/composer.json" <<'EOF'
{
  "name": "shopware/production",
  "repositories": [
    {
      "type": "path",
      "url": "custom/plugins/*",
      "options": {
        "symlink": true
      }
    }
  ]
}
EOF
extra_arr='[{"type": "vcs", "url": "https://example.com/repo-array.git"}]'
run_adjustments "${extra_arr}"
repo_count=$(jq '.repositories | length' "${TMP_DIR}/composer.json")
second_repo_url=$(jq -r '.repositories[1].url' "${TMP_DIR}/composer.json")
if [[ "${repo_count}" -ne 2 || "${second_repo_url}" != "https://example.com/repo-array.git" ]]; then
  echo "Test 3 failed: Expected extra array repo to be merged, got count ${repo_count} and url '${second_repo_url}'"
  cat "${TMP_DIR}/composer.json"
  exit 1
fi
echo "Test 3 passed: Array extraRepositories merges with path repos"

echo "All setup-extension tests passed successfully!"
