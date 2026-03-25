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
| `clientId` | Your Shopware account client ID for API authentication | No* | - |
| `clientSecret` | Your Shopware account client secret for API authentication | No* | - |
| `accountUser` | Your Shopware account user (deprecated) | No* | - |
| `accountPassword` | Your Shopware account password (deprecated) | No* | - |
| `ghToken` | GitHub token | Yes | - |
| `skipCheckout` | Skip the checkout step | No | `false` |
| `disableGit` | Use the source folder as it is | No | `false` |
| `updateInfo` | Update extension information on the Shopware Store plugin page | No | `false` |

*\* Either `clientId`/`clientSecret` or `accountUser`/`accountPassword` must be provided.*

## Usage

### Basic usage (client credentials)

```yaml
name: Release to Store

on:
  workflow_dispatch:

jobs:
  build:
    uses: shopware/github-actions/store-release@main
    with:
      extensionName: MyExtensionName
      clientId: ${{ secrets.SHOPWARE_CLIENT_ID }}
      clientSecret: ${{ secrets.SHOPWARE_CLIENT_SECRET }}
      ghToken: ${{ secrets.GITHUB_TOKEN }}
```

### Basic usage (legacy username/password)

```yaml
name: Release to Store

on:
  workflow_dispatch:

jobs:
  build:
    uses: shopware/github-actions/store-release@main
    with:
      extensionName: MyExtensionName
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
      clientId: ${{ secrets.SHOPWARE_CLIENT_ID }}
      clientSecret: ${{ secrets.SHOPWARE_CLIENT_SECRET }}
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
      clientId: ${{ secrets.SHOPWARE_CLIENT_ID }}
      clientSecret: ${{ secrets.SHOPWARE_CLIENT_SECRET }}
      ghToken: ${{ secrets.GITHUB_TOKEN }}
```

## Requirements

- Shopware account credentials must be stored as secrets. Either:
  - `SHOPWARE_CLIENT_ID` and `SHOPWARE_CLIENT_SECRET` (recommended, generate at [Shopware Account](https://account.shopware.com/producer/development))
  - `SHOPWARE_ACCOUNT_USER` and `SHOPWARE_ACCOUNT_PASSWORD` (deprecated)
- GitHub token with `repo` permissions
