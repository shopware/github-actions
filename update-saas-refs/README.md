# Update SAAS Refs Action

Action to trigger an update of SAAS upstream refs for a given branch.

## What it does

1. Checks if the target branch exists in the saas repository
2. Triggers the `core-update.yml` workflow in `shopware/saas` to update upstream refs on that branch

## Inputs

| Input           | Description                          | Required | Default |
|-----------------|--------------------------------------|----------|---------|
| `pull_request` | The pull request that triggered the update | No | `${{ github.event.pull_request }}` |
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
