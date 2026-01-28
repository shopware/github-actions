# Project Deployer

This GitHub Action builds and deploys a Shopware project using shopware-cli and deployer.

## What it does

1. Checks out your repository (optional)
2. Sets up PHP with the specified version
3. Installs Shopware CLI
4. Builds the project using `shopware-cli project ci`
5. Deploys using deployphp/action

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `phpVersion` | PHP version to use | No | `8.4` |
| `sshPrivateKey` | SSH private key for deployment (use `secrets.SSH_PRIVATE_KEY`) | Yes | - |
| `deployCommand` | Deploy command to run | No | `deploy` |
| `path` | Path to the project | No | `.` |
| `skipCheckout` | Skip the checkout step | No | `false` |

## Usage

### Basic usage

```yaml
name: Deploy

on:
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: shopware/github-actions/project-deployer@main
        with:
          sshPrivateKey: ${{ secrets.SSH_PRIVATE_KEY }}
```

### With custom PHP version and path

```yaml
- uses: shopware/github-actions/project-deployer@main
  with:
    phpVersion: '8.3'
    path: './shopware'
    sshPrivateKey: ${{ secrets.SSH_PRIVATE_KEY }}
    deployCommand: 'deploy production'
```

### Skip checkout (if already checked out)

```yaml
- uses: actions/checkout@v6
- uses: shopware/github-actions/project-deployer@main
  with:
    skipCheckout: 'true'
    sshPrivateKey: ${{ secrets.SSH_PRIVATE_KEY }}
```

## Requirements

- SSH private key must be stored as a repository secret named `SSH_PRIVATE_KEY`
- Your project must have a deployer configuration file (deploy.php)
