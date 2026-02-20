#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
ACTION_SCRIPT="$ROOT_DIR/actions/ready/ready.ah"

if [[ ! -f "$ACTION_SCRIPT" ]]; then
  echo "Missing action script: $ACTION_SCRIPT" >&2
  exit 1
fi

TMP_ROOT=$(mktemp -d)
VERBOSE="${VERBOSE:-0}"

if ! [[ "$VERBOSE" =~ ^[0-2]$ ]]; then
  echo "Invalid VERBOSE='$VERBOSE' (expected 0, 1, or 2)" >&2
  exit 1
fi

if [[ "$VERBOSE" == "2" ]]; then
  echo "VERBOSE=2: preserving temp directory for debugging: $TMP_ROOT"
else
  trap 'rm -rf "$TMP_ROOT"' EXIT
fi

STUB_BIN="$TMP_ROOT/stub-bin"
mkdir -p "$STUB_BIN"
TEST_LOG="$TMP_ROOT/commands.log"

cat > "$STUB_BIN/git" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

echo "git $*" >> "${TEST_LOG:?}"

case "${1:-}" in
  rev-parse|config|fetch|checkout|merge|push)
    exit 0
    ;;
  *)
    exit 0
    ;;
esac
EOF

cat > "$STUB_BIN/gh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

echo "gh $*" >> "${TEST_LOG:?}"

if [[ "${1:-}" == "pr" && "${2:-}" == "list" ]]; then
  if [[ "${STUB_NO_PR:-0}" == "1" ]]; then
    printf ''
  else
    printf '42\n'
  fi
  exit 0
fi

if [[ "${1:-}" == "pr" && "${2:-}" == "close" ]]; then
  exit 0
fi

if [[ "${1:-}" == "api" && "${2:-}" == "graphql" ]]; then
  printf '101\n102\n'
  exit 0
fi

if [[ "${1:-}" == "issue" && "${2:-}" == "close" ]]; then
  exit 0
fi

exit 1
EOF

chmod +x "$STUB_BIN/git" "$STUB_BIN/gh"

run_case() {
  local case_name="$1"
  local ref_name="$2"
  local expected_summary="$3"
  local expected_exit="${4:-0}"
  local close_pr="${5:-true}"
  local close_issue="${6:-true}"
  local delete_ready="${7:-true}"
  local delete_dev="${8:-true}"
  local stub_no_pr="${9:-0}"

  if [[ "$VERBOSE" -ge 1 ]]; then
    echo
    echo "=== Running test: $case_name ==="
    echo "ref_name=$ref_name"
    echo "expect_summary_contains=$expected_summary"
  fi

  local workdir="$TMP_ROOT/$case_name"
  mkdir -p "$workdir"
  local summary_file="$workdir/summary.md"
  local run_log="$workdir/run.log"

  : > "$summary_file"
  : > "$TEST_LOG"

  set +e
  TEST_LOG="$TEST_LOG" \
  STUB_NO_PR="$stub_no_pr" \
  PATH="$STUB_BIN:$PATH" \
  GH_TOKEN="test-token" \
  INPUT_TARGET_BRANCH="main" \
  INPUT_USER_NAME="ready-user" \
  INPUT_USER_EMAIL="ready@example.com" \
  INPUT_DELETE_DEV_BRANCH="$delete_dev" \
  INPUT_DELETE_READY_BRANCH="$delete_ready" \
  INPUT_CLOSE_PR="$close_pr" \
  INPUT_CLOSE_ISSUE="$close_issue" \
  GITHUB_REF_NAME="$ref_name" \
  GITHUB_SHA="deadbeefdeadbeefdeadbeefdeadbeefdeadbeef" \
  GITHUB_REPOSITORY="devopsdays-dk/devopsdays.dk" \
  GITHUB_REPOSITORY_OWNER="devopsdays-dk" \
  GITHUB_STEP_SUMMARY="$summary_file" \
  "$ACTION_SCRIPT" >"$run_log" 2>&1
  local actual_exit=$?
  set -e

  if [[ "$actual_exit" -ne "$expected_exit" ]]; then
    echo "[$case_name] FAIL" >&2
    echo "[$case_name] expected exit code: $expected_exit, got: $actual_exit" >&2
    echo "[$case_name] actual summary:" >&2
    cat "$summary_file" >&2
    echo "[$case_name] action output:" >&2
    cat "$run_log" >&2
    exit 1
  fi

  if [[ -n "$expected_summary" ]]; then
    if ! grep -q "$expected_summary" "$summary_file"; then
      echo "[$case_name] FAIL" >&2
      echo "[$case_name] expected summary to contain: $expected_summary" >&2
      echo "[$case_name] actual summary:" >&2
      cat "$summary_file" >&2
      echo "[$case_name] action output:" >&2
      cat "$run_log" >&2
      exit 1
    fi
  fi

  echo "[$case_name] PASS"

  if [[ "$VERBOSE" == "2" ]]; then
    echo "step_summary:"
    cat "$summary_file"
    echo "command_log:"
    cat "$TEST_LOG"
    echo "action_output:"
    cat "$run_log"
  fi
}

run_case "happy_path_ready_branch" "ready/123-sample" "Deleted development branch '123-sample'"
run_case "invalid_ref_fails" "feature/not-ready" "" 1
run_case "close_issue_skip_message" "ready/no-ticket-branch" "No PR-linked issue or issue-prefixed branch found; skipping issue closure" 0 false true false false 1

if [[ "$VERBOSE" -ge 1 ]]; then
  echo "All ready harness tests passed"
fi
