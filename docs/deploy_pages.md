# GitHub Pages Deploy Workflow

Deploys pre-built Jekyll sites to GitHub Pages from artifacts created by build workflows.

## Purpose

Handles the final deployment step for Jekyll sites by downloading build artifacts and publishing them to GitHub Pages with proper environment configuration and status reporting.

## Requirements

- Existing Jekyll site artifact from build workflow
- GitHub Pages enabled on repository
- `READY_PUSHER` secret with Pages deployment permissions

## Inputs

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `artifact_name` | No | `jekyll-site-${{ github.sha }}` | Name of artifact containing built site |

## Secrets

| Name | Description |
|------|-------------|
| `READY_PUSHER` | GitHub token with pages, statuses, and id-token write permissions |

## Permissions

- `statuses: write` - Update commit status
- `pages: write` - Deploy to GitHub Pages
- `id-token: write` - OIDC authentication for Pages

## Environment

Deploys to `github-pages` environment with automatic URL tracking.

## Example Usage

```yaml
call_deploy_pages:
  name: Deploy
  needs: call_jekyll_build
  permissions:
    statuses: write
    pages: write
    id-token: write
  secrets:
    READY_PUSHER: ${{ secrets.READY_PUSHER }}
  uses: lakruzz/workflows/.github/workflows/deploy_pages.yml@experimental
  with:
    artifact_name: jekyll-site-${{ github.sha }}
```

## Behavior

1. Downloads specified Jekyll site artifact
2. Verifies `_site` directory exists and contains files
3. Re-packages content as GitHub Pages artifact
4. Deploys to GitHub Pages using official action
5. Sets commit status with deployment URL or failure message
6. Updates environment with deployed site URL

## When It Fails

- Missing or invalid artifact name
- Empty or corrupted `_site` directory
- GitHub Pages configuration issues
- Insufficient deployment permissions
- OIDC authentication failures
