#!/usr/bin/env bash
# =============================================================================
# run-tests.sh — Step 4: run Vitest and exit non-zero on any failure
# Usage: npm run apply-issue:test -- <issue-number>
# Note:  also runnable as plain `npm test` — issue number used for logging.
# =============================================================================
set -euo pipefail
STEPS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$STEPS_DIR/_lib.sh"

validate_issue_number "${1:-}" "apply-issue:test"
ISSUE_NUMBER="$1"
resolve_context

log_step "[4/7] Run tests for issue #$ISSUE_NUMBER"

TEST_OUTPUT_FILE="/tmp/vitest_output_${ISSUE_NUMBER}.txt"
TEST_EXIT_CODE=0

npm run test --prefix "$REPO_ROOT" -- --run 2>&1 | tee "$TEST_OUTPUT_FILE" || TEST_EXIT_CODE=$?

if [[ $TEST_EXIT_CODE -ne 0 ]]; then
  log_error "Tests FAILED. Aborting."
  log_warn  "Fix the failing tests, then re-run: npm run apply-issue:test -- $ISSUE_NUMBER"
  exit 1
fi

log_success "All tests passed"
