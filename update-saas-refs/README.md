# Update SAAS Refs Action

Action to create a PR with updated SAAS refs for a given branch.

## What it does

1. Checks if the target branch exists in the saas repository
2. create a PR to update the upstream refs in the target branch to the latest commit

## Inputs

| Input           | Description                          | Required | Default |
|-----------------|--------------------------------------|----------|---------|
| `target-branch` | target branch in the saas repository | No | `${{ github.base_ref }}` |

## Usage

### Basic usage

```yaml
jobs:
  create_saas_update_pr:
    name: Create SaaS Update PR
    runs-on: ubuntu-latest
    if: ${{ github.event.pull_request.merged && github.repository == 'shopware/shopware' }}
    permissions:
      id-token: write
    steps:
      - uses: shopware/github-actions/update-saas-refs@main
```
