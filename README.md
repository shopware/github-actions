# Reuseable GitHub Actions for Shopware Extensions

## cs-fixer

Installs PHP-CS-Fixer and runs [PER Coding Style 2.0](https://www.php-fig.org/per/coding-style/) through the Plugin.

```yaml
jobs:
    cs:
        uses: shopware/github-actions/.github/workflows/cs-fixer.yml@main
```

## phpstan

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

## PHPUnit

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

## Build Zip

Builds the Extension zip and validates the Zip using shopware-cli

```yaml
jobs:
  zip:
    uses: shopware/github-actions/.github/workflows/build-zip.yml@main
    with:
      # Extension Name
      extensionName: MyExtensionName
```

## Store Upload

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

## Extension Dependencies (For PHPUnit & phpstan)

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