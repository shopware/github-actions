# AI Release Notes

Generate polished, AI-powered release notes from GitHub's auto-generated changelog and optionally create a draft GitHub release.

The action compares the current tag with the previous one, fetches the raw changelog via the GitHub API, rewrites it with an AI model, and creates a draft release with the result.

Two providers are supported via the `provider` input:

- **`openai`** (default) — any OpenAI-compatible chat completions endpoint, authenticated with a static `api-key`.
- **`bedrock`** — Claude on Amazon Bedrock, authenticated with the ambient AWS credentials. Combined with `aws-actions/configure-aws-credentials` and an OIDC role this needs **no stored secret at all** — only short-lived STS credentials derived from the workflow's OIDC token. The request goes through the `aws` CLI preinstalled on GitHub-hosted runners, so the action stays dependency-free.

> **Note:** This action previously used the GitHub Models API, which was [fully retired on July 30, 2026](https://github.blog/changelog/2026-07-30-github-models-is-now-retired/).

In all cases the AI rewrite degrades gracefully: when no credentials are configured or the AI call fails, the raw GitHub changelog is used and the release is still created.

## Prerequisites

The calling workflow must:

1. **Check out the repository** with full history (`fetch-depth: 0`) so previous tags can be detected.
2. **Grant permissions** for `contents: write` (to create releases).
3. **Provide credentials** — either an `api-key` for an OpenAI-compatible provider, or (for `provider: bedrock`) AWS credentials via `aws-actions/configure-aws-credentials`, which additionally needs `id-token: write` permission. Without credentials, the release falls back to the raw GitHub changelog.

## Usage

### Minimal Example

Reproduces the default behaviour — no PR links, no authors, bold feature names, sections: *New Features, Improvements, Bug Fixes, Other*.

```yaml
name: AI Release Notes
on:
  push:
    tags: ["v*"]

permissions:
  contents: write

jobs:
  release-notes:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - uses: shopware/github-actions/ai-release-notes@main
        with:
          product-name: "My Product"
          api-key: ${{ secrets.OPENAI_API_KEY }}
```

### Claude on Amazon Bedrock (no stored secret)

Authenticates with short-lived STS credentials from the workflow's OIDC token. `BEDROCK_ROLE_ARN` and `BEDROCK_AWS_REGION` are non-secret repository **variables**; the IAM role needs `bedrock:InvokeModel*` on the inference profile ARN **and** on the underlying foundation-model ARNs in every region the profile routes to.

```yaml
name: AI Release Notes
on:
  push:
    tags: ["v*"]

permissions:
  contents: write
  id-token: write

jobs:
  release-notes:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - uses: aws-actions/configure-aws-credentials@v6
        with:
          role-to-assume: ${{ vars.BEDROCK_ROLE_ARN }}
          aws-region: ${{ vars.BEDROCK_AWS_REGION }}

      - uses: shopware/github-actions/ai-release-notes@main
        with:
          product-name: "My Product"
          provider: "bedrock"
```

The default Bedrock model is the `eu.anthropic.claude-sonnet-5` cross-region inference profile — a bare model id is rejected for on-demand throughput in `eu-central-1`, and the `eu.` prefix keeps routing inside EU regions. `temperature` is not sent on this path (Claude Sonnet 5 and Opus 5 reject sampling parameters).

### Using a Different OpenAI-Compatible Provider

Any OpenAI-compatible chat completions endpoint works — for example the Anthropic API:

```yaml
      - uses: shopware/github-actions/ai-release-notes@main
        with:
          product-name: "My Product"
          api-endpoint: "https://api.anthropic.com/v1/chat/completions"
          api-key: ${{ secrets.ANTHROPIC_API_KEY }}
          model: "claude-sonnet-5"
```

### Customised Example

Override formatting, sections, and release settings.

```yaml
      - uses: shopware/github-actions/ai-release-notes@main
        with:
          product-name: "Databus"
          product-description: "A workflow execution engine written in Go"
          include-pr-links: "true"
          include-authors: "true"
          bold-features: "false"
          sections: "Breaking Changes,New Features,Improvements,Bug Fixes,Internal"
          collapse-types: "dependency,CI,refactor"
          tag-pattern: "^v"
          release-name: "{tag}"
          draft: "false"
```

### Generate Notes Without Creating a Release

Use the action as a pure notes generator — for example to post to Slack or append to a changelog file.

```yaml
      - uses: shopware/github-actions/ai-release-notes@main
        id: notes
        with:
          product-name: "Nexus Contracts"
          create-release: "false"

      - name: Post to Slack
        run: echo "${{ steps.notes.outputs.release-notes }}"
```

## Inputs

| Input | Required | Default | Description |
|---|---|---|---|
| `product-name` | **yes** | — | Product name used in the AI prompt |
| `product-description` | no | `""` | Optional product context for better AI output |
| `bold-features` | no | `"true"` | Use **bold** for feature names in bullets |
| `include-pr-links` | no | `"false"` | Include PR links in bullets |
| `include-authors` | no | `"false"` | Include author attributions in bullets |
| `sections` | no | `"New Features,Improvements,Bug Fixes,Other"` | Comma-separated list of sections in desired order |
| `collapse-types` | no | `"dependency,translation,CI"` | Change types collapsed under the last section |
| `additional-rules` | no | `""` | Extra rules appended to the default prompt |
| `custom-prompt` | no | `""` | Completely override the system prompt (ignores all formatting inputs) |
| `provider` | no | `"openai"` | AI provider: `"openai"` or `"bedrock"` |
| `api-endpoint` | no | `"https://api.openai.com/v1/chat/completions"` | OpenAI-compatible chat completions endpoint URL (`provider: openai` only) |
| `api-key` | no | `""` | API key (`provider: openai` only) — when empty, the AI rewrite is skipped and the raw changelog is used |
| `model` | no | per provider | `"gpt-4o"` for `openai`, `"eu.anthropic.claude-sonnet-5"` for `bedrock` |
| `temperature` | no | `"0.4"` | AI temperature — only sent on the `openai` path |
| `max-output-tokens` | no | `"8192"` | Output token budget (`provider: bedrock` only) — Claude's adaptive thinking draws from the same budget |
| `tag-pattern` | no | `"^v"` | Regex pattern to match tags when detecting the previous release |
| `release-name` | no | `"Release {tag}"` | Release name template — use `{tag}` as placeholder for the tag name |
| `draft` | no | `"true"` | Create the release as a draft |
| `prerelease` | no | `"false"` | Mark the release as a prerelease |
| `create-release` | no | `"true"` | Whether to create a GitHub release (`"false"` = only generate notes) |
| `github-token` | no | `${{ github.token }}` | GitHub token (needs `contents:write`) |

## Outputs

| Output | Description |
|---|---|
| `release-notes` | The AI-generated release notes (Markdown) — or the raw changelog when the AI rewrite was skipped |
| `raw-notes` | The raw GitHub-generated changelog before AI rewrite |
| `release-url` | URL of the created release (empty if `create-release` is `"false"`) |
| `previous-tag` | The detected previous git tag |

## How the Prompt Works

By default, the action builds a system prompt dynamically from the inputs. The prompt instructs the AI to:

- Group changes under the configured **sections** (omitting empty ones)
- **Collapse** dependency bumps, translations, and CI changes under the last section
- Optionally **bold** feature names, include/exclude **PR links** and **authors**
- Start with a `## Release Notes — <tag>` heading
- Keep the "Full Changelog" comparison link

### Extending the Default Prompt

Use `additional-rules` to add domain-specific instructions without replacing the entire prompt:

```yaml
        with:
          product-name: "My API"
          additional-rules: |
            - Always mention the affected API endpoint in parentheses.
            - Flag any breaking changes with a ⚠️ emoji.
```

### Full Prompt Override

Use `custom-prompt` when you need complete control. All formatting inputs (`bold-features`, `include-pr-links`, etc.) are ignored when a custom prompt is set:

```yaml
        with:
          product-name: "My Product"
          custom-prompt: |
            You are a changelog writer. Summarise the changes in 3 bullet points.
            Be extremely concise. Output Markdown only.
```
