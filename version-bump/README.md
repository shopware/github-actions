# Version Bump

Detects whether the root `version` field in `composer.json` strictly increased between two git references.

## What it does

1. Reads the `version` field from `composer.json` at `old-ref` and at `new-ref`
2. Reports `bumped: true` only when the version strictly increased (version-aware compare, handles 3- and 4-segment versions)
3. Ignores no-op edits, downgrades/reverts, and cases where the version cannot be read (e.g. a newly created branch)

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `old-ref` | The git ref/sha for the previous state (e.g. the PR base sha) | Yes | - |
| `new-ref` | The git ref/sha for the new state (e.g. the PR head sha) | Yes | - |
| `path` | Path to the extension root containing `composer.json` | No | `.` |

## Outputs

| Output | Description |
|--------|-------------|
| `bumped` | `'true'` if the version strictly increased, otherwise `'false'` |
| `previous-version` | The version at `old-ref` (empty if not found) |
| `current-version` | The version at `new-ref` (empty if not found) |

> **Note:** the caller must check out the repository with `fetch-depth: 0` so both refs are available to `git show`.
>
> **Note:** this action requires `jq` and GNU `sort` (for `sort -V`) to be available on the runner.

## Usage

```yaml
- uses: actions/checkout@v7
  with:
    fetch-depth: 0
- uses: shopware/github-actions/version-bump@main
  id: detect
  with:
    old-ref: ${{ github.event.pull_request.base.sha }}
    new-ref: ${{ github.event.pull_request.head.sha }}
- if: steps.detect.outputs.bumped == 'true'
  run: echo "Version bumped ${{ steps.detect.outputs.previous-version }} -> ${{ steps.detect.outputs.current-version }}"
```

For the ready-made Slack notification, use the [`version-bump-notify`](../.github/workflows/version-bump-notify.yml) reusable workflow instead of wiring this action up yourself.