# Fast Forward Merge Workflow

Performs a fast-forward-only merge from the current branch to a target branch.

## Purpose

Ensures clean, linear git history by only allowing merges when the target branch can be fast-forwarded without creating merge commits.

## Requirements

- Current branch must be ahead of target branch
- No divergent commits between branches
- `READY_PUSHER` secret with `contents: write` permission

## Inputs

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `target_branch` | No | `main` | Branch to merge into |
| `user_name` | Yes | - | Git user name for merge |
| `user_email` | Yes | - | Git user email for merge |

## Secrets

| Name | Description |
|------|-------------|
| `READY_PUSHER` | GitHub token with contents write permission |

## Example Usage

```yaml
fast-forward-merge:
  permissions:
    contents: write
  secrets:
    READY_PUSHER: ${{ secrets.READY_PUSHER }}
  uses: lakruzz/workflows/.github/workflows/fast_forward.yml@experimental
  with:
    target_branch: main
    user_name: "Ready Pusher"
    user_email: "ready-pusher@lakruzz.com"
```

## Behavior

1. Checks out target branch with full history
2. Configures git user settings
3. Attempts fast-forward merge of `${{ github.sha }}`
4. Pushes merged changes to origin
5. Fails if fast-forward is not possible

## When It Fails

- Target branch has commits not in current branch
- Merge conflicts exist
- Invalid branch references
- Insufficient permissions
