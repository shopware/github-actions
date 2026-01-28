# CS Fixer

PHP-CS-Fixer action for checking and enforcing code style.

## What it does

1. Checks out code
2. Sets up PHP with PHP-CS-Fixer and cs2pr tools
3. Runs PHP-CS-Fixer in dry-run mode and formats output for GitHub PRs

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `rules` | Default rules to check with php-cs-fixer | No | `@PER-CS2.0,no_unused_imports` |

## Usage

### Basic usage

```yaml
jobs:
  cs-fixer:
    uses: shopware/github-actions/cs-fixer@main
```

### With custom rules

```yaml
jobs:
  cs-fixer:
    uses: shopware/github-actions/cs-fixer@main
    with:
      rules: "@Symfony,no_unused_imports"
```
