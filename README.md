# Reusable GitHub Actions for Shopware

A collection of reusable GitHub Actions and Workflows for Shopware extensions and projects.

## Actions

### Code Quality

| Action | Description | Link |
|--------|-------------|------|
| [cs-fixer](cs-fixer/) | PHP-CS-Fixer action for checking and enforcing code style | [README](cs-fixer/README.md) |
| [phpstan](phpstan/) | Runs PHPStan static analysis for Shopware extensions | [README](phpstan/README.md) |
| [eslint](eslint/) | Runs ESLint on administration or storefront files | [README](eslint/README.md) |
| [extension-verifier](extension-verifier/) | Validates and formats Shopware extensions using shopware-cli | [README](extension-verifier/README.md) |
| [project-validate](project-validate/) | Validates a Shopware project code style and structure | [README](project-validate/README.md) |

### Testing

| Action | Description | Link |
|--------|-------------|------|
| [admin-jest](admin-jest/) | Runs administration Jest tests | [README](admin-jest/README.md) |
| [phpunit](phpunit/) | Runs PHPUnit tests for Shopware extensions | [README](phpunit/README.md) |

### Build & Release

| Action | Description | Link |
|--------|-------------|------|
| [build-zip](build-zip/) | Builds the extension zip and validates it | [README](build-zip/README.md) |
| [store-release](store-release/) | Builds the extension and uploads it to the Shopware Store | [README](store-release/README.md) |

### Setup & Configuration

| Action | Description | Link |
|--------|-------------|------|
| [setup-extension](setup-extension/) | Checkouts Shopware and extension, installs dependencies | [README](setup-extension/README.md) |
| [shopware-version](shopware-version/) | Gets the Shopware version that matches the current branch | [README](shopware-version/README.md) |
| [versions](versions/) | Gets version information for current and LTS major versions | [README](versions/README.md) |

### Workflow Orchestration

| Action | Description | Link |
|--------|-------------|------|
| [downstream](downstream/) | Triggers a downstream workflow and waits for it to finish | [README](downstream/README.md) |
| [upstream-connect](upstream-connect/) | Connects to upstream from downstream run | [README](upstream-connect/README.md) |

### Deployment

| Action | Description | Link |
|--------|-------------|------|
| [project-deployer](project-deployer/) | Builds and deploys a Shopware project using shopware-cli and deployer | [README](project-deployer/README.md) |

### SaaS

| Action | Description | Link |
|--------|-------------|------|
| [saas-preview-environment](saas-preview-environment/) | Creates, migrates or archives a SaaS Preview Environment | [README](saas-preview-environment/README.md) |

## Usage

All actions follow the standard GitHub Actions format:

```yaml
steps:
  - uses: shopware/github-actions/[action-name]@main
    with:
      # action-specific inputs
```

## Extension Dependencies

For actions that support extension dependencies (e.g., `phpstan`, `phpunit`, `setup-extension`), you can specify them using the `dependencies` input:

```yaml
jobs:
  phpstan:
    uses: shopware/github-actions/phpstan@main
    with:
      extensionName: MyExtensionName
      dependencies: |-
        [
          {"name": "SwagPlatformDemoData", "repo": "git@github.com:shopware/SwagPlatformDemoData.git"}
        ]
```

For private dependencies, you can use variables that will be replaced with secrets:

```yaml
jobs:
  phpstan:
    uses: shopware/github-actions/setup-extension@main
    with:
      extensionName: MyExtensionName
      dependencies: |-
        [
          {"name": "MyPrivateExtension", "repo": "https://user:$MY_EXTENSION_TOKEN@gitlab.domain.com/org/my-extension.git"}
        ]
      env: MY_EXTENSION_TOKEN=${{ secrets.MY_EXTENSION_TOKEN }}
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
