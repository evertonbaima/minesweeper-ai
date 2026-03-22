#!/usr/bin/env bash
# =============================================================================
# pull-request.sh — Step 6: open a PR if the branch does not have one yet
# Usage: npm run apply-issue:pr -- <issue-number>
# =============================================================================
set -euo pipefail
STEPS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$STEPS_DIR/_lib.sh"

validate_issue_number "${1:-}" "apply-issue:pr"
ISSUE_NUMBER="$1"
resolve_context

log_step "[6/7] Pull request for issue #$ISSUE_NUMBER  →  $BRANCH"

EXISTING_PR="$(gh pr list --head "$BRANCH" --state open --json number -q '.[0].number' 2>/dev/null || echo '')"

if [[ -n "$EXISTING_PR" ]]; then
  log_info "Open PR #$EXISTING_PR already exists for '$BRANCH' — skipping creation."
  PR_URL="$(gh pr view "$EXISTING_PR" --json url -q .url 2>/dev/null || echo '')"
  [[ -n "$PR_URL" ]] && log_info "PR URL: $PR_URL"
  exit 0
fi

log_info "No open PR found — creating one."

ISSUE_TITLE="$(gh issue view "$ISSUE_NUMBER" --json title -q .title 2>/dev/null || echo "Issue #${ISSUE_NUMBER}")"

PR_BODY="## Summary
Implements **#${ISSUE_NUMBER} — ${ISSUE_TITLE}**.

## Changes
$(git log main.."$BRANCH" --oneline 2>/dev/null || echo '- See commits above')

## Related Issue
Closes #${ISSUE_NUMBER}

---
> ⚙️ This PR was opened automatically by \`apply-issue.sh\`."

PR_URL="$(gh pr create \
  --title "$ISSUE_TITLE" \
  --body "$PR_BODY" \
  --base main \
  --head "$BRANCH" \
  --label "in-review" 2>/dev/null || true)"

if [[ -n "$PR_URL" ]]; then
  log_success "Pull Request opened: $PR_URL"
else
  log_warn "Could not open PR automatically (label may not exist yet)."
  log_info  "Create it manually or run: gh label create 'in-review' --color '0075ca'"
  exit 1
fi
