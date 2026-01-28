# Versions

Gets the first and latest versions of the current and previous (LTS) major versions.

## What it does

1. Retrieves version information for the current major version
2. Retrieves version information for the previous LTS major version
3. Calculates next minor and patch versions

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `major` | Current major prefix (e.g., `v6.7.`) | No | `v6.7.` |
| `lts-major` | LTS major prefix (e.g., `v6.6.`) | No | `v6.6.` |

## Outputs

| Output | Description |
|--------|-------------|
| `first-version` | The first version of the current major |
| `latest-version` | The latest version of the current major |
| `next-minor` | The next minor version |
| `next-patch` | The next patch version |
| `lts-first-version` | The first version of the lts major |
| `lts-latest-version` | The latest version of the lts major |
| `lts-next-patch` | The next patch version of the lts major |

## Usage

### Basic usage

```yaml
- uses: shopware/github-actions/versions@main
  id: versions
```

### With custom major versions

```yaml
- uses: shopware/github-actions/versions@main
  id: versions
  with:
    major: v6.7.
    lts-major: v6.6.
```

### Using outputs

```yaml
- uses: shopware/github-actions/versions@main
  id: versions
- name: Display versions
  run: |
    echo "Latest: ${{ steps.versions.outputs.latest-version }}"
    echo "Next patch: ${{ steps.versions.outputs.next-patch }}"
    echo "LTS latest: ${{ steps.versions.outputs.lts-latest-version }}"
```
