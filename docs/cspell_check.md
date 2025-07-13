# CSpell Check Workflow

Runs spelling checks on repository files using CSpell with configurable rules.

## Purpose

Maintains consistent spelling and terminology across documentation, comments, and text files by automatically detecting typos and unknown words.

## Requirements

- CSpell configuration file in repository root
- Files to be checked must be readable by CSpell

## Inputs

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `config_file` | No | `cspell.json` | Path to CSpell configuration file (relative to repo root) |

## Permissions

- `statuses: write` - Updates commit status with results

## Example Usage

```yaml
cspell_check:
  name: Spelling
  permissions:
    statuses: write
  uses: lakruzz/workflows/.github/workflows/cspell_check.yml@experimental
  with:
    config_file: cspell.json # default
```

## Supported Config Formats

- `cspell.json`
- `cspell.config.js`
- `cspell.config.yaml`
- `.cspellrc`
- Custom path/filename

## Behavior

1. Checks out repository code
2. Installs CSpell and GitHub CLI tools
3. Runs spelling check with specified config
4. Reports results to step summary
5. Sets commit status (success/failure)
6. Fails workflow if spelling errors found

## When It Fails

- Misspelled words detected
- Unknown terms not in dictionary
- Missing or invalid config file
- CSpell configuration errors
