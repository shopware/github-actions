# PHPStan

Runs PHPStan static analysis for Shopware extensions.

## What it does

1. Creates PHPStan configuration file
2. Sets up caching for PHPStan results
3. Builds PHPStan bootstrap
4. Runs PHPStan analysis

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `extensionName` | Your extension name | Yes | - |
| `cacheDir` | PHPStan cache directory | No | `$GITHUB_WORKSPACE/var/phpstan` |
| `errorFormat` | PHPStan error format | No | `github` |

## Usage

### Basic usage

```yaml
jobs:
  phpstan:
    uses: shopware/github-actions/phpstan@main
    with:
      extensionName: MyExtensionName
```

### With custom cache directory

```yaml
jobs:
  phpstan:
    uses: shopware/github-actions/phpstan@main
    with:
      extensionName: MyExtensionName
      cacheDir: ./cache/phpstan
```

## Requirements

- Your extension must have a `phpstan.neon.dist` file in the plugin root directory

Example `phpstan.neon.dist`:
```neon
parameters:
    level: max
    paths:
        - src
```
