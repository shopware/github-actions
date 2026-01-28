# Store Release

Builds the extension and uploads a zip of it to the Shopware Store.

## What it does

1. Builds the extension zip
2. Validates the zip
3. Uploads to Shopware Store
4. Optionally creates a GitHub release
5. Optionally creates a git tag

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `extensionName` | Your extension name | Yes | - |
| `publishOnly` | Publish only to Shopware Store and don't create a tag | No | `false` |
| `path` | Path to your bundle | No | `.` |
| `accountUser` | Your Shopware account user | Yes | - |
| `accountPassword` | Your Shopware account password | Yes | - |
| `ghToken` | GitHub token | Yes | - |
| `skipCheckout` | Skip the checkout step | No | `false` |
| `disableGit` | Use the source folder as it is | No | `false` |
| `updateInfo` | Update extension information on the Shopware Store plugin page | No | `false` |

## Usage

### Basic usage

```yaml
name: Release to Store

on:
  workflow_dispatch:

jobs:
  build:
    uses: shopware/github-actions/store-release@main
    with:
      extensionName: MyExtensionName
    secrets:
      accountUser: ${{ secrets.SHOPWARE_ACCOUNT_USER }}
      accountPassword: ${{ secrets.SHOPWARE_ACCOUNT_PASSWORD }}
      ghToken: ${{ secrets.GITHUB_TOKEN }}
```

### Publish only (no GitHub release)

```yaml
jobs:
  build:
    uses: shopware/github-actions/store-release@main
    with:
      extensionName: MyExtensionName
      publishOnly: 'true'
    secrets:
      accountUser: ${{ secrets.SHOPWARE_ACCOUNT_USER }}
      accountPassword: ${{ secrets.SHOPWARE_ACCOUNT_PASSWORD }}
      ghToken: ${{ secrets.GITHUB_TOKEN }}
```

### Update extension info

```yaml
jobs:
  build:
    uses: shopware/github-actions/store-release@main
    with:
      extensionName: MyExtensionName
      updateInfo: 'true'
    secrets:
      accountUser: ${{ secrets.SHOPWARE_ACCOUNT_USER }}
      accountPassword: ${{ secrets.SHOPWARE_ACCOUNT_PASSWORD }}
      ghToken: ${{ secrets.GITHUB_TOKEN }}
```

## Requirements

- Shopware account credentials must be stored as secrets:
  - `SHOPWARE_ACCOUNT_USER`
  - `SHOPWARE_ACCOUNT_PASSWORD`
- GitHub token with `repo` permissions
