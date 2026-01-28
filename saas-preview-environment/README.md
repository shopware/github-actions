# SaaS Preview Environment

Create, migrate or archive a SaaS Preview Environment.

## What it does

1. Gets an authentication token (via octo-sts or custom token)
2. Triggers the preview environment workflow in the shopware/saas repository
3. Waits for the operation to complete

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `action` | Action to run (`create` or `archive`) | Yes | `create` |
| `token` | Token to use (if empty, octo-sts is used) | No | - |
| `refFallback` | Fallback ref in case there's no matching branch | No | `trunk` |

## Usage

### Create a preview environment

```yaml
name: Create Preview Environment

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  preview:
    runs-on: ubuntu-latest
    steps:
      - uses: shopware/github-actions/saas-preview-environment@main
        with:
          action: create
```

### Archive a preview environment

```yaml
name: Archive Preview Environment

on:
  pull_request:
    types: [closed]

jobs:
  preview:
    runs-on: ubuntu-latest
    steps:
      - uses: shopware/github-actions/saas-preview-environment@main
        with:
          action: archive
```

### With custom token

```yaml
jobs:
  preview:
    runs-on: ubuntu-latest
    steps:
      - uses: shopware/github-actions/saas-preview-environment@main
        with:
          action: create
          token: ${{ secrets.SAAS_TOKEN }}
```

### With custom fallback

```yaml
jobs:
  preview:
    runs-on: ubuntu-latest
    steps:
      - uses: shopware/github-actions/saas-preview-environment@main
        with:
          action: create
          refFallback: trunk
```

## Octo-sts configuration

This action uses octo-sts by default. Ensure you have the necessary permissions configured in the shopware/saas repository to use this feature.
