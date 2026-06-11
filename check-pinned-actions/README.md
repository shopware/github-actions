# check-pinned-actions

Fails if any non-Shopware GitHub Action in the repository is not pinned to a full commit SHA. Shopware-owned and local (`./`) actions are skipped.

Intended as a PR gate to prevent unpinned actions from being merged.

## Usage

```yaml
jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10 # v6.0.3
      - uses: shopware/github-actions/check-pinned-actions@main
```

## No inputs

This action takes no inputs. It exits with a non-zero status and prints each violation if unpinned actions are found, e.g.:

```
Found 2 unpinned action(s):

  .github/workflows/ci.yml:12  actions/checkout@v4
  .github/workflows/ci.yml:18  codecov/codecov-action@v3

Pin each action to a full commit SHA, e.g.:
  uses: actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10 # v6.0.3
```
