#!/usr/bin/env bash
# =============================================================================
# install-deps.sh — Step 3: run npm install only when necessary
# Usage: npm run apply-issue:install -- <issue-number>
# Note:  also runnable as plain `npm install` — the issue number is only used
#        for consistent logging with the other steps.
# =============================================================================
set -euo pipefail
STEPS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$STEPS_DIR/_lib.sh"

validate_issue_number "${1:-}" "apply-issue:install"
ISSUE_NUMBER="$1"
resolve_context

log_step "[3/7] Install dependencies for issue #$ISSUE_NUMBER"

NEEDS_INSTALL=false

if [[ ! -d "$REPO_ROOT/node_modules" ]]; then
  log_info "node_modules not found — install required."
  NEEDS_INSTALL=true
elif [[ "$REPO_ROOT/package.json" -nt "$REPO_ROOT/node_modules" ]]; then
  log_info "package.json is newer than node_modules — install required."
  NEEDS_INSTALL=true
elif [[ -f "$REPO_ROOT/package-lock.json" && "$REPO_ROOT/package-lock.json" -nt "$REPO_ROOT/node_modules" ]]; then
  log_info "package-lock.json is newer than node_modules — install required."
  NEEDS_INSTALL=true
else
  log_info "node_modules is up to date — skipping install."
fi

if [[ "$NEEDS_INSTALL" == true ]]; then
  npm install --prefix "$REPO_ROOT"
  log_success "Dependencies installed"
fi
