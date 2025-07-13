# Pytest with Coverage Workflow

Runs Python unit tests with coverage reporting using pytest and coverage.py.

## Purpose

Ensures code quality through automated testing and enforces coverage thresholds to maintain test completeness across Python projects.

## Requirements

- Python project with test files
- pytest configuration and test markers
- Coverage configuration (`.coveragerc` file)
- `dev` extra dependencies group including pytest and coverage

## Inputs

None - workflow uses project's pytest and coverage configuration.

## Permissions

- `statuses: write` - Updates commit status with results

## Example Usage

```yaml
pytest_with_coverage:
  name: Unit Tests
  permissions:
    statuses: write
  uses: lakruzz/workflows/.github/workflows/pytest_with_coverage.yml@experimental
```

## Python Environment

- **Version:** Python 3.13
- **Package Manager:** uv (ultra-fast Python package installer)
- **Virtual Environment:** Automatically created and activated

## Test Configuration

- **Test Marker:** `-m unittest` (runs only tests marked as unittest)
- **Coverage:** Measures line coverage across entire codebase
- **Coverage Config:** Uses `.coveragerc` for configuration
- **Threshold:** Enforced via coverage configuration file

## Behavior

1. Checks out repository code
2. Sets up Python 3.13 environment
3. Installs uv package manager
4. Creates virtual environment and syncs dev dependencies
5. Runs pytest with coverage measurement
6. Checks coverage against configured thresholds
7. Sets commit status based on test and coverage results
8. Fails if tests fail or coverage below threshold

## When It Fails

- Unit test failures
- Test assertion errors
- Coverage below configured threshold
- Missing test dependencies
- Invalid pytest or coverage configuration
