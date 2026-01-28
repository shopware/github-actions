# ESLint

Runs ESLint on the administration or storefront files of a Shopware extension.

## What it does

1. Clones Shopware repository
2. Clones your extension
3. Installs npm dependencies
4. Runs the lint command

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `extensionName` | Your extension name | Yes | - |
| `projectPath` | Path to the JS project to be linted | No | `src/Resources/app/administration` |
| `npmLintCmd` | The npm command to run | No | `lint` |
| `shopwareVersion` | Shopware version (`.auto` to auto-detect) | No | `.auto` |
| `shopwareVersionFallback` | Fallback version in case there's no matching branch | No | `trunk` |
| `shopware-repository` | The shopware repository to checkout | No | `shopware/shopware` |
| `shopware-github-token` | Token used for checking out the shopware repository | No | `$GITHUB_TOKEN` |
| `forceInstallAdminDeps` | Install platform admin deps | No | - |
| `forceInstallStorefrontDeps` | Install platform storefront deps | No | - |

## Usage

### Basic usage (administration)

```yaml
jobs:
  eslint:
    uses: shopware/github-actions/eslint@main
    with:
      extensionName: MyExtensionName
```

### Lint storefront

```yaml
jobs:
  eslint:
    uses: shopware/github-actions/eslint@main
    with:
      extensionName: MyExtensionName
      projectPath: src/Resources/app/storefront
```

### With custom Shopware version

```yaml
jobs:
  eslint:
    uses: shopware/github-actions/eslint@main
    with:
      extensionName: MyExtensionName
      shopwareVersion: 6.5.x
```

### With custom repository and token

```yaml
jobs:
  eslint:
    uses: shopware/github-actions/eslint@main
    with:
      extensionName: MyExtensionName
      shopware-repository: my-org/shopware
      shopware-github-token: ${{ secrets.SHOPWARE_TOKEN }}
```

### With custom lint command

```yaml
jobs:
  eslint:
    uses: shopware/github-actions/eslint@main
    with:
      extensionName: MyExtensionName
      npmLintCmd: lint:fix
```
