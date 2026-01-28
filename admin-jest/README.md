# Admin Jest

Runs administration Jest tests for your Shopware extension.

## What it does

1. Runs Jest unit tests in the administration directory
2. Optionally uploads code coverage to Codecov

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `extensionName` | Your extension name | Yes | - |
| `uploadCoverage` | Upload coverage to codecov (requires `CODECOV_TOKEN` secret) | No | `false` |

## Usage

### Basic usage

```yaml
jobs:
  admin-jest:
    uses: shopware/github-actions/admin-jest@main
    with:
      extensionName: MyExtensionName
```

### With code coverage

```yaml
jobs:
  admin-jest:
    uses: shopware/github-actions/admin-jest@main
    with:
      extensionName: MyExtensionName
      uploadCoverage: true
```

## Requirements

- Your extension must have Jest tests in `src/Resources/app/administration`
