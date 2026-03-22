#!/usr/bin/env bash
# =============================================================================
# commit-push.sh — Step 5: stage all changes, commit, and push
# Usage: npm run apply-issue:push -- <issue-number>
# =============================================================================
set -euo pipefail
STEPS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$STEPS_DIR/_lib.sh"

validate_issue_number "${1:-}" "apply-issue:push"
ISSUE_NUMBER="$1"
resolve_context

log_step "[5/7] Commit and push for issue #$ISSUE_NUMBER"

cd "$REPO_ROOT"

if git diff --quiet && git diff --staged --quiet; then
  log_warn "No changes to commit — working tree is clean."
else
  git add -A
  COMMIT_MSG="close #${ISSUE_NUMBER} — ${SLUG//-/ }"
  git commit -m "$COMMIT_MSG"
  log_success "Committed: \"$COMMIT_MSG\""
fi

log_step "Pushing branch '$BRANCH' to origin"
git push origin "$BRANCH"
log_success "Pushed to origin/$BRANCH"
