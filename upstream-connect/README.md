# Upstream Connect

Connects to upstream from downstream run.

## What it does

1. Receives upstream data from a triggered workflow
2. Sets environment variables from the upstream run
3. Displays information about the upstream workflow that triggered the run

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `upstream_data` | Upstream data (pass-through from workflow_dispatch event input) | Yes | - |

## Usage

### In downstream workflow

```yaml
on:
  workflow_dispatch:
    inputs:
      upstream_data:
        required: false

jobs:
  id:
    runs-on: ubuntu-latest
    steps:
      - if: ${{ inputs.upstream_data }}
        uses: shopware/github-actions/upstream-connect@main
        with:
          upstream_data: ${{ inputs.upstream_data }}
```

### Accessing upstream data

After using this action, the following environment variables are available:

- `upstream.id`: The run ID of the upstream workflow
- `upstream.ref`: The ref of the upstream workflow
- `upstream.repo`: The repository of the upstream workflow
- `upstream.github-token`: The GitHub token from upstream
- `upstream.url`: URL to the upstream workflow run

Any custom environment variables passed from upstream via the `env` input of the downstream action will also be set.

## Example: Combined with downstream action

**Upstream workflow:**
```yaml
jobs:
  trigger-downstream:
    runs-on: ubuntu-latest
    steps:
      - uses: shopware/github-actions/downstream@main
        with:
          repo: my-org/my-repo
          workflow: test
          ref: trunk
```

**Downstream workflow:**
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
      - run: |
          echo "Triggered by: ${{ env.upstream.repo }}"
          echo "Run URL: ${{ env.upstream.url }}"
```
