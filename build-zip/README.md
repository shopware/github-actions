# Build Extension Zip

Builds the extension zip and validates it using shopware-cli.

## What it does

1. Checks out the repository
2. Installs shopware-cli
3. Builds the extension zip using shopware-cli
4. Validates the zip file
5. Uploads the artifact

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `extensionName` | Your extension name | Yes | - |
| `path` | Path to your bundle | No | `.` |
| `skipCheckout` | Skip the checkout step | No | `false` |
| `disableGit` | Use the source folder as it is | No | `false` |

## Outputs

| Output | Description |
|--------|-------------|
| `artifact-id` | A unique identifier for the artifact |
| `artifact-url` | A download URL for the artifact |

## Usage

### Basic usage

```yaml
jobs:
  build-zip:
    uses: shopware/github-actions/build-zip@main
    with:
      extensionName: MyExtensionName
```

### With custom path

```yaml
jobs:
  build-zip:
    uses: shopware/github-actions/build-zip@main
    with:
      extensionName: MyExtensionName
      path: ./custom/plugins/MyExtension
```

### Skip checkout (if already checked out)

```yaml
jobs:
  build-zip:
    uses: shopware/github-actions/build-zip@main
    with:
      extensionName: MyExtensionName
      skipCheckout: 'true'
```

### Disable git (use source as-is)

```yaml
jobs:
  build-zip:
    uses: shopware/github-actions/build-zip@main
    with:
      extensionName: MyExtensionName
      disableGit: 'true'
```

### Using the artifact output

```yaml
jobs:
  build-zip:
    uses: shopware/github-actions/build-zip@main
    id: build
    with:
      extensionName: MyExtensionName
  download:
    needs: build-zip
    runs-on: ubuntu-latest
    steps:
      - run: echo "Download from: ${{ needs.build-zip.outputs.artifact-url }}"
```
