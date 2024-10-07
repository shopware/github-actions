# Reusable GitHub Actions and Workflows for Shopware Extensions

## Workflows

### Code Quality

#### cs-fixer

Installs PHP-CS-Fixer and runs [PER Coding Style 2.0](https://www.php-fig.org/per/coding-style/) through the Plugin.

```yaml
jobs:
    cs:
        uses: shopware/github-actions/.github/workflows/cs-fixer.yml@main
```

#### phpstan

Installs PHPStan together with Shopware and the Extension and runs PHPStan

```yaml
jobs:
    phpstan:
        uses: shopware/github-actions/.github/workflows/phpstan.yml@main
        with:
          # Extension name
          extensionName: MyExtensionName
          # Run against Shopware version
          shopwareVersion: 6.5.x
```

#### admin-eslint

Runs ESLint on the administration files of the plugin
```yaml
jobs:
    phpstan:
        uses: shopware/github-actions/.github/workflows/admin-eslint.yml@main
        with:
          # Extension name
          extensionName: MyExtensionName
          # Run against Shopware version
          shopwareVersion: 6.5.x
```

### Testing

#### admin-jest

Runs administration jest tests

```yaml
jobs:
    admin-jest:
        uses: shopware/github-actions/.github/workflows/admin-jest.yml@main
        with:
            # Extension Name
            extensionName: MyExtensionName
            # Run against Shopware version
            shopwareVersion: 6.5.x
```

#### phpunit

```yaml
jobs:
  phpunit:
    uses: shopware/github-actions/.github/workflows/phpunit.yml@main
    with:
      # Extension Name
      extensionName: MyExtensionName
      # Run against Shopware version
      shopwareVersion: 6.5.x
```

With Code Coverage with [codecov](https://about.codecov.io/)

```yaml
jobs:
  phpunit:
    uses: shopware/github-actions/.github/workflows/phpunit.yml@main
    with:
      extensionName: SwagPlatformDemoData
      shopwareVersion: 6.5.x
      uploadCoverage: true
    secrets:
      codecovToken: ${{ secrets.CODECOV_TOKEN }}
```

### Build Zip

Builds the Extension zip and validates the Zip using shopware-cli

```yaml
jobs:
  zip:
    uses: shopware/github-actions/.github/workflows/build-zip.yml@main
    with:
      # Extension Name
      extensionName: MyExtensionName
```

### Store Upload

Upload the Extension with the given Shopware Account credentials into the Account. It is recommended to use the `workflow_dispatch` event, so you have to manually trigger this from the Actions Tab.

```yaml
name: Release to Store
on:
  workflow_dispatch:
jobs:
  build:
    uses: shopware/github-actions/.github/workflows/store-release.yml@main
    with:
      extensionName: ${{ github.event.repository.name }}
    secrets:
      accountUser: ${{ secrets.SHOPWARE_ACCOUNT_USER }}
      accountPassword: ${{ secrets.SHOPWARE_ACCOUNT_PASSWORD }}
      ghToken: ${{ secrets.GITHUB_TOKEN }}
```

### Extension Dependencies (For PHPUnit & phpstan)

If your extension has dependencies, you can specify them with the `dependencies` input and they will also be installed. The
input should a JSON array of objects containing the extension name and repository URL:

```yaml
jobs:
    phpstan:
        uses: shopware/github-actions/.github/workflows/phpstan.yml@main
        with:
          extensionName: MyExtensionName
          shopwareVersion: 6.5.x
          dependencies: |-
            [
              {"name": "SwagPlatformDemoData", "repo": "git@github.com:shopware/SwagPlatformDemoData.git"}
            ]
```

If your extension is private, you can specify use variables in the repository URL. They will be replaced with a corresponding secret which you can pass using the `secrets.env` input.
The secret should be defined in your GitHub repository.

```yaml
jobs:
    phpstan:
        uses: shopware/github-actions/.github/workflows/phpstan.yml@main
        with:
          extensionName: MyExtensionName
          shopwareVersion: 6.5.x
          dependencies: |-
            [
              {"name": "MyPrivateExtension", "repo": "https://user:$MY_EXTENSION_TOKEN@gitlab.domain.com/org/my-extension.git"}
            ]
          secrets:
            env: MY_EXTENSION_TOKEN=${{ secrets.MY_EXTENSION_TOKEN }}
```

## Actions

### Downstream

Trigger a downstream pipeline in a project and wait for it to finish.
Job fails if downstream fails.

You need to configure octo-sts in the downstream to allow your project to trigger a action or pass a token that has permissions to trigger the workflow.

Example how to use the downstream action:
```yaml
permissions:
  id-token: write

jobs:
  downstream:
    runs-on: ubuntu-latest
    steps:
      - uses: shopware/github-actions/downstream@main
        with:
          repo: shopware/actions-test
          workflow: test
          ref: trunk
```

In your downstream workflow you also need to use the upstream-connect action:

```yaml
on:
  workflow_dispatch:
    inputs:
      upstream_data:
        required: false

jobs:
  id:
    runs-on: ubuntu-latest
    steps:
      - if: ${{ inputs.upstream_data }}
        uses: shopware/github-actions/upstream-connect@main
        with:
          upstream_data: ${{ inputs.upstream_data }}
```

To make it work with [octo-sts](https://github.com/octo-sts/app) you need to add a trust policy like this:

```yaml
# .github/chainguard/upstream.yaml

issuer: https://token.actions.githubusercontent.com
subject: repo:shopware/shopware:ref:refs/heads/main
# you can also use subject_pattern, if you want to use regex

claim_pattern:
  # restrict to a specificy upstream workflow
  job_workflow_ref: shopware/shopware/.github/workflows/downstream.yml@refs/heads/.*

permissions:
  actions: write

```

This policy only allows the `main` ref with the `downstream.yml` workflow of the `shopware/shopware` repository to get a token with the `actions:write` permissions.

You should make this as specific as possible.