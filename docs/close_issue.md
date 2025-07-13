# Close Issue Workflow

Closes GitHub issues and cleans up associated branches after successful delivery.

## Purpose

Automates the cleanup process after issue completion by closing the GitHub issue, adding delivery comments, and optionally removing related branches.

## Requirements

- Branch name must follow `ready/{issue-number}-{description}` format
- Valid GitHub issue number in branch name
- Git user credentials for branch operations

## Inputs

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `user_name` | Yes | - | Git user name for operations |
| `user_email` | Yes | - | Git user email for operations |
| `delete_issue_branch` | No | `true` | Delete original issue branch |
| `delete_ready_branch` | No | `true` | Delete ready branch |

## Permissions

- `issues: write` - Close GitHub issues
- `contents: write` - Delete branches

## Example Usage

```yaml
close_issue:
  needs: fast-forward-merge
  permissions:
    issues: write
    contents: write
  uses: lakruzz/workflows/.github/workflows/close_issue.yml@experimental
  with:
    user_name: "Ready Pusher"
    user_email: "ready-pusher@lakruzz.com"
    delete_issue_branch: true
    delete_ready_branch: true
```

## Branch Format

Must match: `ready/{issue-number}-{description}`

**Valid examples:**

- `ready/123-fix-bug`
- `ready/456-add-feature`

**Invalid examples:**

- `ready/123` (missing dash)
- `feature/123-fix` (wrong prefix)

## Behavior

1. Validates branch name format
2. Configures git user settings
3. Extracts issue number from branch name
4. Closes GitHub issue with delivery comment
5. Conditionally deletes ready branch
6. Conditionally deletes original issue branch

## When It Fails

- Invalid branch name format
- Non-existent issue number
- Insufficient permissions
- Branch deletion conflicts
