# Jekyll Build Workflow

Builds Jekyll sites with artifact caching for efficient reuse across workflows and branches.

## Purpose

Provides optimized Jekyll site building with smart artifact restoration to avoid rebuilding unchanged content. Automatically caches built sites for reuse by deployment workflows.

## Requirements

- Jekyll project with `Gemfile` and `_config.yml`
- ImageMagick dependencies (for image processing)
- `READY_PUSHER` secret for cross-workflow artifact access

## Inputs

None - workflow uses commit SHA for artifact naming.

## Secrets

| Name | Description |
|------|-------------|
| `READY_PUSHER` | GitHub token for downloading artifacts across workflow runs |

## Example Usage

```yaml
call_jekyll_build: 
  name: Build
  permissions:
    statuses: write
  secrets:
    READY_PUSHER: ${{ secrets.READY_PUSHER }}
  uses: lakruzz/workflows/.github/workflows/jekyll_build.yml@experimental
```

## Artifact Strategy

**Artifact name:** `jekyll-site-{github.sha}`

- Enables reuse across different branches with same content
- Allows fast-forward merges without rebuilding
- 3-day retention for recent builds

## Behavior

### Restore Job

1. Attempts to download existing artifact for current SHA
2. Sets output flag indicating if artifact was found
3. Skips build job if artifact exists

### Build Job (conditional)

1. Only runs if no existing artifact found
2. Installs Jekyll dependencies and ImageMagick
3. Configures GitHub Pages base path
4. Builds site with production environment
5. Uploads artifact for future reuse
6. Sets commit status based on build result

## When It Fails

- Missing or invalid Jekyll configuration
- Bundle dependency conflicts
- ImageMagick installation issues
- Insufficient disk space for build
- Network issues downloading dependencies
