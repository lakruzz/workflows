# Ruff Check Workflow

Runs Python code linting and formatting checks using Ruff with uv package management.

## Purpose

Ensures Python code quality and consistency by detecting style violations, potential bugs, and formatting issues using the fast Ruff linter.

## Requirements

- Python project with `pyproject.toml` or `requirements.txt`
- Ruff configuration (in `pyproject.toml` or `.ruff.toml`)
- `dev` extra dependencies group for development tools

## Inputs

None - workflow uses project's Ruff configuration.

## Permissions

- `statuses: write` - Updates commit status with results

## Example Usage

```yaml
ruff_check:
  name: Code Quality
  permissions:
    statuses: write
  uses: lakruzz/workflows/.github/workflows/ruff_check.yml@experimental
```

## Python Environment

- **Version:** Python 3.13
- **Package Manager:** uv (ultra-fast Python package installer)
- **Virtual Environment:** Automatically created and activated

## Behavior

1. Checks out repository code
2. Sets up Python 3.13 environment
3. Installs uv package manager
4. Creates virtual environment and syncs dev dependencies
5. Runs `ruff check` with concise output format
6. Reports results to step summary
7. Sets commit status based on linting results
8. Continues on error to ensure status is always set

## When It Fails

- Python syntax errors
- Style violations (PEP 8, etc.)
- Import sorting issues
- Unused imports or variables
- Missing or invalid Ruff configuration
