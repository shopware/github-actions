# update-pinned-actions

Checks all GitHub Actions in the repository for updates and opens a PR with each action pinned to the latest release's commit SHA. Shopware-owned and local (`./`) actions are skipped.

## Usage

```yaml
jobs:
  update:
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write
    steps:
      - uses: actions/checkout@v4
      - uses: shopware/github-actions/update-pinned-actions@main
        with:
          github-token: ${{ github.token }}
```

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `github-token` | yes | — | GitHub token with `contents: write` and `pull-requests: write` |
| `base-branch` | no | `main` | Base branch for the pull request |
| `reviewers` | no | — | Comma-separated reviewers to request (users or `org/team-slug`, e.g. `octocat,shopware/product-operations`) |
