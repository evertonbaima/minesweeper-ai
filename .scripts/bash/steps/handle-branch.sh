#!/usr/bin/env bash
# =============================================================================
# handle-branch.sh — Step 2: create or check out the issue branch
# Usage: npm run apply-issue:branch -- <issue-number>
# =============================================================================
set -euo pipefail
STEPS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$STEPS_DIR/_lib.sh"

validate_issue_number "${1:-}" "apply-issue:branch"
ISSUE_NUMBER="$1"
resolve_context

log_step "[2/7] Handle branch for issue #$ISSUE_NUMBER  →  $BRANCH"

gh repo sync 2>/dev/null || true

CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"

if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
  log_info "Branch '$BRANCH' already exists locally."
  if [[ "$CURRENT_BRANCH" != "$BRANCH" ]]; then
    git checkout "$BRANCH"
    log_success "Checked out '$BRANCH'"
  else
    log_info "Already on '$BRANCH'"
  fi
elif git ls-remote --exit-code --heads origin "$BRANCH" &>/dev/null; then
  log_info "Branch '$BRANCH' exists on remote — checking out."
  git checkout -b "$BRANCH" "origin/$BRANCH"
  log_success "Checked out '$BRANCH' from remote"
else
  log_info "Branch '$BRANCH' does not exist — creating from main."
  git checkout main 2>/dev/null || git checkout master 2>/dev/null
  git pull origin "$(git rev-parse --abbrev-ref HEAD)" --quiet
  git checkout -b "$BRANCH"
  log_success "Created and checked out new branch '$BRANCH'"
fi
