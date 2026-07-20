# Plugin lifecycle validation

Validates a plugin's install / uninstall / reinstall lifecycle and its Data Abstraction Layer (DAL) wiring against an already-installed Shopware.

Use it to catch the class of breakage where a plugin compiles against `trunk` but
references core symbols or schema that do not exist on the released version a
merchant runs — the container-compile failure only shows up when the plugin is
actually installed on that version.

## What it does

1. `plugin:refresh`, then `plugin:install --activate` — boots the container, so a plugin that does not compile against the installed Shopware release fails here
2. `dal:validate` — validates every registered definition and its associations against the real database schema
3. `plugin:uninstall`, then asserts the configured tables are gone (clean uninstall)
4. `plugin:install --activate` again, asserts the configured tables are back, and re-runs `dal:validate` (working reinstall)

It expects Shopware to be installed already (e.g. via
[`setup-extension`](../setup-extension/) with `install: true`) and reads the
database connection from the `DATABASE_URL` environment variable that Shopware
exposes in CI. It is meant for plugins; apps have no install lifecycle of this
kind.

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `extensionName` | The plugin (technical) name to validate | Yes | - |
| `tables` | Whitespace-separated list of tables the plugin owns; asserted dropped on uninstall and recreated on reinstall. Leave empty to validate the lifecycle and DAL only | No | - |

## Usage

Run it as a step in a job that has already set up Shopware, ideally across a
version matrix so the plugin is validated on the versions merchants actually run.

```yaml
jobs:
  lifecycle:
    strategy:
      fail-fast: false
      matrix:
        shopwareVersion: [v6.7.4.2, trunk]
    runs-on: ubuntu-latest
    steps:
      - uses: shopware/github-actions/setup-extension@main
        with:
          extensionName: MyPlugin
          shopwareVersion: ${{ matrix.shopwareVersion }}
          install: true
          # Required for older floors whose composer.lock pins a flagged
          # dependency. No-op on newer versions.
          allow-insecure-versions: true

      - uses: shopware/github-actions/plugin-lifecycle@main
        with:
          extensionName: MyPlugin
          tables: |
            my_plugin_foo
            my_plugin_bar
```

### Combine with a dynamic version matrix

Pair it with [`versions`](../versions/) so the "latest release" leg of the
matrix updates itself without a manual bump on every Shopware release:

```yaml
jobs:
  versions:
    runs-on: ubuntu-latest
    outputs:
      list: ${{ steps.build.outputs.list }}
    steps:
      - uses: shopware/github-actions/versions@main
        id: resolve
        with:
          major: v6.7.
      - id: build
        run: echo 'list=["v6.7.4.2", "${{ steps.resolve.outputs.latest-version }}", "trunk"]' >> "$GITHUB_OUTPUT"

  lifecycle:
    needs: versions
    strategy:
      fail-fast: false
      matrix:
        shopwareVersion: ${{ fromJSON(needs.versions.outputs.list) }}
    runs-on: ubuntu-latest
    steps:
      - uses: shopware/github-actions/setup-extension@main
        with:
          extensionName: MyPlugin
          shopwareVersion: ${{ matrix.shopwareVersion }}
          install: true
          allow-insecure-versions: true
      - uses: shopware/github-actions/plugin-lifecycle@main
        with:
          extensionName: MyPlugin
          tables: my_plugin_foo my_plugin_bar
```
