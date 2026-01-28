# Shopware Version

Gets the Shopware version that matches the current branch.

## What it does

1. Finds a matching Shopware version based on the current git reference
2. Returns a fallback version if no matching branch is found
3. Useful for testing against specific Shopware versions

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `fallback` | The fallback version if there's no matching branch | No | `trunk` |
| `repo` | The repo where to look for matching refs | No | `shopware/shopware` |
| `ref` | The git reference to match (defaults to `github.ref`) | No | - |
| `base-ref` | The base reference for pull requests (defaults to `github.base_ref`) | No | - |
| `head-ref` | The head reference for pull requests (defaults to `github.head_ref`) | No | - |
| `shopware-github-token` | Token used for checking out the shopware repository | No | - |

## Outputs

| Output | Description |
|--------|-------------|
| `shopware-version` | The matching shopware version or fallback |

## Usage

### Basic usage

```yaml
- uses: shopware/github-actions/shopware-version@main
  id: version
```

### With custom fallback

```yaml
- uses: shopware/github-actions/shopware-version@main
  id: version
  with:
    fallback: 6.5.0.0
```

### With custom repository

```yaml
- uses: shopware/github-actions/shopware-version@main
  id: version
  with:
    repo: my-org/shopware
    fallback: trunk
    shopware-github-token: ${{ secrets.SHOPWARE_TOKEN }}
```

### Using the output

```yaml
- uses: shopware/github-actions/shopware-version@main
  id: version
- name: Use version
  run: echo "Shopware version is ${{ steps.version.outputs.shopware-version }}"
```
