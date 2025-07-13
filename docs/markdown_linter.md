# Markdown Linter Workflow

Runs markdown linting checks on repository files using markdownlint-cli2 with configurable rules.

## Purpose

Ensures consistent markdown formatting and style across documentation by automatically detecting formatting issues, style violations, and structural problems.

## Requirements

- Markdownlint configuration file in repository
- Markdown files to be checked
- Node.js runtime for markdownlint-cli2

## Inputs

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `config_file` | No | `.markdownlint.json` | Path to markdownlint configuration file (relative to repo root) |

## Permissions

- `statuses: write` - Updates commit status with results

## Example Usage

```yaml
markdown_linter:
  name: Linting
  permissions:
    statuses: write
  uses: lakruzz/workflows/.github/workflows/markdown_linter.yml@experimental
  with:
    config_file: .markdownlint.json # default
```

## Supported Config Formats

- `.markdownlint.json`
- `.markdownlint.yaml`
- `.markdownlint.yml`
- `.markdownlint.js`
- `markdownlint.config.js`
- Custom path/filename

## Behavior

1. Checks out repository code
2. Installs markdownlint-cli2 and GitHub CLI tools
3. Runs linting on all `**/*.md` files (excluding node_modules)
4. Reports results to step summary
5. Sets commit status (success/failure)
6. Fails workflow if linting errors found

## When It Fails

- Markdown formatting violations
- Style rule violations (heading levels, line length, etc.)
- Missing or invalid config file
- Markdownlint configuration errors
