#!/usr/bin/env bash
# =============================================================================
# run-tests.sh — run Vitest and exit non-zero on any failure
# Usage: npm run run-tests
# =============================================================================
set -euo pipefail
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPTS_DIR/_lib.sh"

log_step "Running tests"

TEST_EXIT_CODE=0
npm run test --prefix "$REPO_ROOT" -- --run 2>&1 | tee /tmp/vitest_output.txt || TEST_EXIT_CODE=$?

if [[ $TEST_EXIT_CODE -ne 0 ]]; then
  log_error "Tests FAILED."
  exit 1
fi

log_success "All tests passed"
