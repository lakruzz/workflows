#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
ACTION_SCRIPT="$ROOT_DIR/actions/pr-to-ready/pr_to_ready.ah"

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
  rev-parse|config|fetch|checkout|push)
    exit 0
    ;;
  log)
    printf 'abc123: chore: first\n'
    printf 'def456: feat: second\n'
    exit 0
    ;;
  commit-tree)
    printf 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeef\n'
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

if [[ "${1:-}" == "pr" && "${2:-}" == "view" ]]; then
  cat <<JSON
{"number":99,"title":"[WIP] Dispatch title","headRefName":"feature/dispatch","headRefOid":"0123456789abcdef0123456789abcdef01234567"}
JSON
  exit 0
fi

exit 1
EOF

chmod +x "$STUB_BIN/git" "$STUB_BIN/gh"

run_case() {
  local case_name="$1"
  local event_name="$2"
  local event_file="$3"
  local expected_summary="$4"
  local expected_exit="${5:-0}"

  if [[ "$VERBOSE" -ge 1 ]]; then
    echo
    echo "=== Running test: $case_name ==="
    echo "event_name=$event_name"
    echo "event_file=$event_file"
    echo "expect_summary_contains=$expected_summary"
  fi

  if [[ "$VERBOSE" == "2" ]]; then
    echo "event_payload:"
    cat "$event_file"
  fi

  local workdir="$TMP_ROOT/$case_name"
  mkdir -p "$workdir"
  local summary_file="$workdir/summary.md"
  local run_log="$workdir/run.log"

  : > "$summary_file"
  : > "$TEST_LOG"

  set +e
  TEST_LOG="$TEST_LOG" \
  PATH="$STUB_BIN:$PATH" \
  GH_TOKEN="test-token" \
  INPUT_USER_NAME="test-user" \
  INPUT_USER_EMAIL="test@example.com" \
  GITHUB_STEP_SUMMARY="$summary_file" \
  GITHUB_EVENT_PATH="$event_file" \
  GITHUB_EVENT_NAME="$event_name" \
  GITHUB_REPOSITORY="devopsdays-dk/devopsdays.dk" \
  RUNNER_TEMP="$workdir" \
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

  if ! grep -q "$expected_summary" "$summary_file"; then
    echo "[$case_name] FAIL" >&2
    echo "[$case_name] expected summary to contain: $expected_summary" >&2
    echo "[$case_name] actual summary:" >&2
    cat "$summary_file" >&2
    echo "[$case_name] action output:" >&2
    cat "$run_log" >&2
    exit 1
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

EVENT_APPROVED="$TMP_ROOT/event-approved.json"
cat > "$EVENT_APPROVED" <<'JSON'
{
  "review": { "state": "approved" },
  "pull_request": {
    "base": { "ref": "main" },
    "state": "open",
    "head": {
      "ref": "feature/awesome",
      "sha": "abcdefabcdefabcdefabcdefabcdefabcdefabcd",
      "repo": { "full_name": "devopsdays-dk/devopsdays.dk" }
    },
    "number": 123,
    "title": "[WIP] Add awesome feature"
  }
}
JSON

EVENT_DISPATCH="$TMP_ROOT/event-dispatch.json"
cat > "$EVENT_DISPATCH" <<'JSON'
{
  "inputs": {
    "pr_number": "99"
  }
}
JSON

EVENT_SKIP="$TMP_ROOT/event-skip.json"
cat > "$EVENT_SKIP" <<'JSON'
{}
JSON

run_case "approved_review" "pull_request_review" "$EVENT_APPROVED" "Delivered PR #123"
run_case "workflow_dispatch" "workflow_dispatch" "$EVENT_DISPATCH" "Delivered PR #99"
run_case "unsupported_event_fails" "push" "$EVENT_SKIP" "Event 'push' is not supported for PR delivery" 1

if [[ "$VERBOSE" -ge 1 ]]; then
  echo "All pr_to_ready harness tests passed"
fi
