# Project Validate

This GitHub Action validates a Shopware project code style and structure.

## What it does

1. Checks out your repository (optional)
2. Sets up PHP with the specified version
3. Installs Shopware CLI
4. Installs composer dependencies
5. Validates the project structure using `shopware-cli project validate`
6. Checks code style using `shopware-cli project format --dry-run`

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `phpVersion` | PHP version to use | No | `8.4` |
| `path` | Path to the project | No | `.` |
| `skipCheckout` | Skip the checkout step | No | `false` |

## Usage

### Basic usage

```yaml
name: Check

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: shopware/github-actions/project-validate@main
```

### With custom PHP version

```yaml
- uses: shopware/github-actions/project-validate@main
  with:
    phpVersion: '8.3'
```

### With custom path

```yaml
- uses: shopware/github-actions/project-validate@main
  with:
    path: './shopware'
```

### Skip checkout (if already checked out)

```yaml
- uses: actions/checkout@v6
- uses: shopware/github-actions/project-validate@main
  with:
    skipCheckout: 'true'
```

## Requirements

- Your project must have a `composer.json` file
- The project should follow Shopware project structure
