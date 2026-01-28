# Downstream Workflow

Trigger a downstream workflow in another repository and wait for it to finish.

## What it does

1. Gets an authentication token (via octo-sts or custom token)
2. Finds matching ref in downstream repository
3. Triggers the downstream workflow
4. Waits for the workflow to complete
5. Fails if downstream workflow fails

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `repo` | Downstream repo | Yes | - |
| `token-scope` | Scope for the sts token | No | - |
| `workflow` | Workflow to dispatch in downstream | Yes | - |
| `ref` | Downstream ref (`.auto` to auto-detect matching refs) | No | `.auto` |
| `refFallback` | Fallback ref in case there's no matching branch | No | `trunk` |
| `env` | Environment variables to pass to downstream workflow | No | - |
| `identity` | Identity for octo-sts | No | `upstream` |
| `token` | Token to authenticate (if not provided, octo-sts is used) | No | - |
| `timeout` | Timeout for the downstream workflow | No | `30m` |
| `poll_interval` | Poll interval for checking status | No | `2m` |

## Outputs

| Output | Description |
|--------|-------------|
| `run_id` | The run id of the downstream workflow |
| `run_url` | The api url of the downstream workflow |

## Usage

### Basic usage

```yaml
permissions:
  id-token: write

jobs:
  downstream:
    runs-on: ubuntu-latest
    steps:
      - uses: shopware/github-actions/downstream@main
        with:
          repo: my-org/my-repo
          workflow: test
          ref: trunk
```

### Auto-detect matching ref

```yaml
jobs:
  downstream:
    runs-on: ubuntu-latest
    steps:
      - uses: shopware/github-actions/downstream@main
        with:
          repo: my-org/my-repo
          workflow: test
          ref: .auto
          refFallback: trunk
```

### With environment variables

```yaml
jobs:
  downstream:
    runs-on: ubuntu-latest
    steps:
      - uses: shopware/github-actions/downstream@main
        with:
          repo: my-org/my-repo
          workflow: test
          env: |
            PLATFORM_BRANCH=trunk
            FOO=bar
```

### With custom timeout and poll interval

```yaml
jobs:
  downstream:
    runs-on: ubuntu-latest
    steps:
      - uses: shopware/github-actions/downstream@main
        with:
          repo: my-org/my-repo
          workflow: test
          timeout: 60m
          poll_interval: 1m
```

### Using custom token

```yaml
jobs:
  downstream:
    runs-on: ubuntu-latest
    steps:
      - uses: shopware/github-actions/downstream@main
        with:
          repo: my-org/my-repo
          workflow: test
          token: ${{ secrets.CUSTOM_TOKEN }}
```

## Octo-sts configuration

To use octo-sts, add a trust policy in the downstream repository:

```yaml
# .github/chainguard/upstream.yaml
issuer: https://token.actions.githubusercontent.com
subject: repo:my-org/my-upstream-repo:ref:refs/heads/main

claim_pattern:
  job_workflow_ref: my-org/my-upstream-repo/.github/workflows/downstream.yml@refs/heads/.*

permissions:
  actions: write
```

## Requirements

- Downstream workflow must have `workflow_dispatch` event
- Downstream workflow must use `upstream-connect` action to handle upstream data

### Example downstream workflow

```yaml
on:
  workflow_dispatch:
    inputs:
      upstream_data:
        required: false

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: shopware/github-actions/upstream-connect@main
        with:
          upstream_data: ${{ inputs.upstream_data }}
      # Your test steps here
```
