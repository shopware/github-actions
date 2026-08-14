# Extension Verifier

Validates and formats Shopware extensions using shopware-cli.

## What it does

1. Installs Shopware-CLI
2. Validates extension structure and compliance
3. Optionally formats extension code

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `version` | The extension verifier version to use | No | `latest` |
| `action` | The action to run (`check` or `format`) | Yes | `check` |
| `check-against` | The version to check against | No | `highest` |
| `exclude` | Comma-separated list of tools to exclude from the check (e.g. `phpstan,eslint`) | No | *(none)* |

## Usage

### Check extension

```yaml
jobs:
  verify:
    uses: shopware/github-actions/extension-verifier@main
    with:
      action: check
```

### Check against specific version

```yaml
jobs:
  verify:
    uses: shopware/github-actions/extension-verifier@main
    with:
      action: check
      check-against: v6.6.0.0
```

### Exclude specific tools

```yaml
jobs:
  verify:
    uses: shopware/github-actions/extension-verifier@main
    with:
      action: check
      exclude: phpstan,eslint
```

### Format extension (dry-run)

```yaml
jobs:
  format:
    uses: shopware/github-actions/extension-verifier@main
    with:
      action: format
```
