# Copilot Instructions for `lakruzz/workflows`

This document is a durable implementation guide for GitHub Copilot in this repository.
It captures the action architecture and engineering principles established in this codebase.

## Core Goal

Build GitHub Actions that are:

- deterministic
- testable outside the Actions runner
- easy to debug from workflow logs
- minimal in YAML orchestration
- explicit about runtime assumptions

---

## Action Architecture Standard

### 1) Use one orchestrator script per action

For custom composite actions in this repository, prefer:

- one composite step in `action.yml`
- one orchestrator script in the same folder (for example `pr_to_ready.ah`, `ready.ah`)

Do **not** spread imperative business logic across many `run:` blocks in `action.yml` unless there is a strong reason.

#### Why

- YAML remains declarative and easy to scan
- script logic becomes easier to refactor, branch, and test
- behavior can be reproduced locally via harness scripts

### 2) Keep `action.yml` minimal and explicit

`action.yml` should primarily define:

- inputs
- one step with explicit `env`
- explicit script invocation

Use explicit script names:

- ✅ `run: ${{ github.action_path }}/pr_to_ready.ah`
- ❌ `run: ${{ github.action_path }}/${GITHUB_ACTION}.ah`

`GITHUB_ACTION` is not stable for filename derivation in all contexts.

### 3) Pass only true inputs via `env`

In the action step:

- pass only user-configurable action inputs
- do **not** pass values that are directly derivable from GitHub runtime context

Derive runtime context in script from variables like:

- `GITHUB_EVENT_NAME`
- `GITHUB_EVENT_PATH`
- `GITHUB_REPOSITORY`
- `GITHUB_REF_NAME`
- `GITHUB_SHA`

#### Why

- action interface stays small and clear
- script owns the responsibility of context interpretation
- fewer fragile data pipes between YAML and script

### 4) Caller workflow owns checkout

If action logic needs repository state:

- require checkout in the caller workflow before `uses: .../actions/<action>`
- caller should use `actions/checkout@v4` with `fetch-depth: 0`

Do not hide checkout inside the reusable action by default.

#### Why

- clearer contracts and expectations
- easier composition with other steps
- fewer hidden side effects

---

## Script Design Principles

### 5) Always use strict shell mode

Use at script top:

```bash
set -euo pipefail
```

### 6) Standardize messaging with `summary()` and `fail()`

Every orchestrator script should define:

- `summary()` to append readable diagnostics to `GITHUB_STEP_SUMMARY`
- `fail()` to write a clear summary failure + stderr + exit non-zero

Pattern:

```bash
summary() { echo "$1" >> "$GITHUB_STEP_SUMMARY"; }
fail() { summary "❌ $1"; echo "$1" >&2; exit 1; }
```

Use `fail()` for validation failures and unsupported contexts.

### 7) Validate early, fail fast

Validate:

- trigger/event eligibility
- required context fields parsed from event payload
- required inputs (user name/email, etc.)
- runtime preconditions (for example inside git work tree)

Emit actionable guidance in failure summaries.

### 8) Prefer explicit references over hidden state

Avoid unnecessary dependence on checkout state like `HEAD` when explicit SHAs are available.

Prefer:

- `origin/main.."$PR_HEAD_SHA"`

instead of:

- `origin/main..HEAD`

when SHA is already known.

### 9) Keep redundant git operations out

If behavior can be guaranteed by workflow contract, remove redundant commands.

Examples:

- avoid detached checkout if not needed
- fetch only what is required for correctness

---

## Test Harness Standard

Each action script should have a matching local harness under `tests/<action>/`.

Examples:

- `tests/pr-to-ready/test_pr_to_ready.sh`
- `tests/ready/test_ready.sh`

### 10) Harness goals

Harness scripts must allow local execution without GitHub Actions by:

- creating temporary workspace
- stubbing `git` and `gh` binaries
- injecting `GITHUB_*` and `INPUT_*` environment values
- asserting exit code and summary behavior

### 11) Verbosity contract (`VERBOSE=0|1|2`)

All harnesses use numeric verbosity levels:

- `0` (default): print only `[case] PASS/FAIL`
- `1`: print case headers + normal run context
- `2`: print full debug details (payloads, summaries, command log, action output) and preserve temp files

Invalid values must fail fast with an explicit error.

### 12) Capture action output for debugging

Harness should capture script stdout/stderr to per-case logs.

On failure, print:

- expected vs actual exit
- summary content
- captured action output

### 13) Make tests deterministic via stubs

Use explicit stub behaviors for `gh`/`git`.

If a case needs a variant behavior (for example “no PR found”), drive it via stub env flags such as `STUB_NO_PR=1`.

---

## Reuse and Consistency Rules

### 14) Same shape across actions

For all new actions in this repo:

- one orchestrator script
- one composite step invoking explicit script filename
- one harness script in `tests/<action>/`
- same `summary()/fail()` pattern
- same verbosity model for harnesses

### 15) Do not overfit to one action

Avoid hardcoding behavior assumptions that only fit one workflow/project.

Document contracts clearly (for example “caller must run checkout first”) and enforce them with validation and good error messages.

### 16) Keep output useful, not noisy

In production action runs:

- summary should explain what happened and why
- errors should be actionable
- avoid unnecessary chatter

In harness runs:

- default output is concise
- deep details are opt-in (`VERBOSE=2`)

---

## Practical Checklist for New/Refactored Actions

When creating or refactoring an action, ensure all items are true:

- [ ] `action.yml` is minimal and declarative
- [ ] action invokes explicit script name from `github.action_path`
- [ ] script uses `set -euo pipefail`
- [ ] script defines `summary()` and `fail()`
- [ ] script validates runtime prerequisites early
- [ ] script derives GitHub context internally where appropriate
- [ ] caller workflow includes checkout if repo state is required
- [ ] harness exists under `tests/<action>/`
- [ ] harness supports `VERBOSE=0|1|2`
- [ ] harness asserts both exit code and summary behavior

---

## Notes for Copilot Behavior

When asked to implement or modify actions in this repository:

1. Follow this file as the default architecture policy.
2. Keep changes focused and minimal for the requested scope.
3. Preserve existing behavior unless the request explicitly changes behavior.
4. Prefer reliability and debuggability over clever shortcuts.
5. Validate with local harnesses whenever possible.

If uncertain, choose the option that yields:

- clearer contracts
- easier local reproducibility
- better failure diagnostics in `GITHUB_STEP_SUMMARY`.
