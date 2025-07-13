# workflows

**Each callable workflow in this repo has it's own separate documentation in the [`/docs`](./docs) folder. This README is a more generic intro to _callable_ workflows and how you make the best of them**

## Callable, reusable workflows

GitHub supports the same workflow to be reused among many different flows.

It's a bit like a poor-man's version of GitHub Actions. I call it a _poor-man's_ version because it has a few limitations but with the added value of great simplicity: It has the same structure as all you other flows.

Some basic rules apply:

### on workflow_call

>[!IMPORTANT]
>The `on:` clause must be set to `workflow_call`
>You can't combine this with other triggers.

Like this:

```yaml
on:
  workflow_call:
```

### It must reside in `.github/workflows`

>[!IMPORTANT]
>Callable workflows are called with a `uses` clause - like actions
>BUT — workflow files must reside in a `.github/workflows` folder.

Example:

```yaml
on:
  push:
    branches: 
      - '*'

jobs:
        
  cspell_check:
    name: Spelling
    permissions:
      statuses: write
    uses: lakruzz/workflows/.github/workflows/cspell_check.yml@experimental
    with:
      config_file: cspell.json # default is cspell.json
```

### It must point to a specific version

>[!IMPORTANT]
>When used, the specific version (e.g. `@main`) is not optional.
>You can reference a _branch_ a _tag_ or a _sha_ ...but not nothing

```yaml
    # Valid examples:
    uses: lakruzz/workflows/.github/workflows/cspell_check.yml@experimental
    uses: lakruzz/workflows/.github/workflows/cspell_check.yml@stable
    uses: lakruzz/workflows/.github/workflows/cspell_check.yml@0.9.0
    uses: lakruzz/workflows/.github/workflows/cspell_check.yml@b86731b4782617e5fef9b0f99b231b6642d30a02

    # Not valid
    uses: lakruzz/workflows/.github/workflows/cspell_check.yml
```

### Callable workflows can not read the `secrets` in the main flow

>[!IMPORTANT]
>Contrary to _normal_ jobs in your flows,
>Each callable workflow runs on a separate runner context.

Consequently, other than `secrets.GITHUB_TOKEN` which will _always_ be available on _any_ runner, any other secret – most likely a PAT (Personal Access Token) – must be explicitly passed on:

Here's an example of how the callable flow _requires_ a `READY_PUSHER` token

```yaml
on:
  workflow_call:
    secrets:
      READY_PUSHER:
        description: 'GitHub token for CLI operations'
        required: true
```

And here's an example of how the workflow will typically pass it on:

```yaml
  fast-forward-merge:
    name: Merge
    permissions:
      contents: write
    secrets:
      READY_PUSHER: ${{ secrets.READY_PUSHER }}
```

Here's what happens if you forget:
<img width="487" height="147" alt="Image" src="https://github.com/user-attachments/assets/7f9f843b-0208-467d-b6a7-81d149bfa65d" />

### Use inputs to make flows more useful

>[!TIP]
>Like _normal_ flows, callable workflows also supports `inputs`.
>This is key to making flows more generically useful

Here's an example of a callable flow that takes three parameters

```yaml
on:
  workflow_call:
    inputs:
      target_branch:
        description: 'Target branch to fast-forward merge into - default is main'
        required: false
        type: string
        default: 'main'
      user_name:
        description: 'Git user name for the merge commit'
        required: true
        type: string
      user_email:
        description: 'Git user email for the merge commit'
        required: true
        type: string
```

The full `fast_forward_merge` example looks like this:

```yaml
  fast-forward-merge:
    name: Merge
    needs:
      - cspell_check
      - markdown_linter
    permissions:
      contents: write
    secrets:
      READY_PUSHER: ${{ secrets.READY_PUSHER }}
    uses: lakruzz/workflows/.github/workflows/fast_forward.yml@experimental
    with:
      target_branch: main #default is main
      user_name: "Ready Pusher" #required 
      user_email: "ready-pusher@lakruzz.com" # required
```

## Key Benefits of Callable Workflows

- **DRY Principle**: Write once, use everywhere - avoid duplicating the same workflow logic
- **Centralized Maintenance**: Update the workflow in one place, all consumers get the fix
- **Standardization**: Ensure consistent behavior across projects and teams
- **Modular Design**: Break complex workflows into smaller, focused, reusable components

## Common Patterns and Best Practices

### Permissions Inheritance

>[!WARNING]
>While callable workflows **inherit** the permissions from the calling workflow by default.
>It's recommended that you don't rely on implicitly inherited permissions
>Set the permission explicitly in the callable flows.

Example,  a callable job that needs a certain permission:

```yaml
  ffmerge:
    name: Fast Forward Only
    permissions:
      contents: write
```

In the calling  workflow:

```yaml

  fast-forward-merge:
    name: Merge
    permissions:
      contents: read
```

This will generate a meaningful error, saying that `ffmerge` needs more permissions.

Example:

```shell
# Error: Insufficient permissions for contents: write (got: read)
```

You could have left out the permissions on `ffmerge` and relied on the caller to grant the implied  permissions.

```yaml

  fast-forward-merge:
    name: Merge
    permissions:
      contents: write
```

But this is hard to read, and worse to debug - don't do that.

### Error Handling and Dependencies

>[!IMPORTANT]
>If a callable workflow fails, it will fail the entire calling workflow.
>Use `needs:` to create proper job dependencies.

```yaml
  fast-forward-merge:
    name: Merge
    needs:
      - cspell_check
      - markdown_linter
```

### Output Passing

>[!TIP]
>Callable workflows can return outputs to the calling workflow.

```yaml
# In callable workflow
jobs:
  build:
    outputs:
      version: ${{ steps.version.outputs.value }}
    steps:
      - id: version
        run: echo "value=1.2.3" >> $GITHUB_OUTPUT

# In calling workflow  
jobs:
  call_build:
    uses: org/repo/.github/workflows/build.yml@main
    
  use_output:
    needs: call_build
    runs-on: ubuntu-latest
    steps:
      - run: echo "Built version ${{ needs.call_build.outputs.version }}"
```

## Workflow Development Tips

### Testing Callable Workflows

>[!TIP]
>Don't clutter your production repo, with workflow test runs.
>Create a simple test workflow in a different temporary _lab_ _repository to verify your callable workflow works.

Since your callable workflows are now in a separate repo you don't have to use your production repo to test all kinds of runs or endless trial-and-error commits. You can take them to a different temporary _lab_ repo with a simple generic footprint, that really doesn't change during development.

### Versioning Strategy

>[!TIP]
>Use a _floating tag_ to test stuff that's on development branches

I use a label `experimental` like this:

```yaml
uses: lakruzz/workflows/.github/workflows/fast_forward.yml@experimental
```

During my development on an issue branch in this repo - i might want to test something, that isn't release to `main` yet - I'm working on it.

Here's what I do:

- On a dev branch I commit my work
- Then I set a tag `experimental` that _floats_ meaning that it replaces any existing tag
- Then I push it to the origin
- Next time I trigger the run - or I rerun it - it will pick up the new version.

I have a git alias `mark-experimental` that does this:

```ini
  mark-experimental = "!f() { git tag -f experimental $1 && git push origin --tags --force; }; f"
```

It takes an optional parameter which is the commit to tag, if you don't give it any it will tag `HEAD` (which is what you want in the example flow I suggested)

so:

- _hack hack_
- `git add -A`
- `git commit -m "let's see if this works"`
- `git mark-experimental`
