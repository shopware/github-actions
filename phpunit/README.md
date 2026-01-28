# PHPUnit

Runs PHPUnit tests for Shopware extensions.

## What it does

1. Runs PHPUnit tests
2. Generates code coverage reports
3. Optionally uploads coverage to Codecov

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `extensionName` | Your extension name | Yes | - |
| `uploadCoverage` | Upload coverage to codecov (requires `CODECOV_TOKEN` secret) | No | `false` |
| `filterName` | PHPUnit 11 requires a testsuite filter | No | - |

## Usage

### Basic usage

```yaml
jobs:
  phpunit:
    uses: shopware/github-actions/phpunit@main
    with:
      extensionName: MyExtensionName
```

### With code coverage

```yaml
jobs:
  phpunit:
    uses: shopware/github-actions/phpunit@main
    with:
      extensionName: MyExtensionName
      uploadCoverage: true
```

### With testsuite filter (PHPUnit 11)

```yaml
jobs:
  phpunit:
    uses: shopware/github-actions/phpunit@main
    with:
      extensionName: MyExtensionName
      filterName: unit
```
