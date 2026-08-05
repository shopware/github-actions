# Upstream Connect

Connects to upstream from downstream run.

## What it does

1. Receives upstream data from a triggered workflow
2. Displays information about the upstream workflow that triggered the run
3. Sets custom environment variables passed from the upstream run

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

This action logs the upstream workflow run URL when `upstream_data` contains upstream metadata.

Custom environment variables passed from upstream via the `env` input of the downstream action are written to `$GITHUB_ENV` and become available to later steps.

Upstream metadata (`id`, `ref`, `repo`, `url`, etc.) stays inside the JSON `upstream_data` input. Access it with `fromJSON`, for example:

```yaml
- run: |
    echo "Triggered by: ${{ fromJSON(inputs.upstream_data).upstream.repo }}"
    echo "Run URL: ${{ fromJSON(inputs.upstream_data).upstream.url }}"
```

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
          workflow: test.yml
          ref: trunk
          env: |
            PLATFORM_BRANCH=trunk
            FOO=bar
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
          echo "Custom env from upstream: $PLATFORM_BRANCH $FOO"
          echo "Upstream run URL: ${{ fromJSON(inputs.upstream_data).upstream.url }}"
```
