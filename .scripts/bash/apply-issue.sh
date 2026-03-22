#!/usr/bin/env bash
# =============================================================================
# apply-issue.sh — orchestrator: runs all 7 steps in sequence
# Usage: npm run apply-issue -- <issue-number>
# =============================================================================
set -euo pipefail

STEPS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/steps" && pwd)"

# Colours (minimal — each step script has its own full set)
BOLD='\033[1m'; GREEN='\033[0;32m'; NC='\033[0m'
log_banner() { echo -e "\n${BOLD}${GREEN}━━━ $* ━━━${NC}"; }

if [[ $# -lt 1 ]]; then
  echo "Usage: npm run apply-issue -- <issue-number>"
  exit 1
fi

N="$1"

log_banner "apply-issue #$N — starting all steps"

bash "$STEPS_DIR/handle-zip.sh"    "$N"
bash "$STEPS_DIR/handle-branch.sh" "$N"
bash "$STEPS_DIR/install-deps.sh"  "$N"
bash "$STEPS_DIR/run-tests.sh"     "$N"
bash "$STEPS_DIR/commit-push.sh"   "$N"
bash "$STEPS_DIR/pull-request.sh"  "$N"
bash "$STEPS_DIR/code-review.sh"   "$N"

# ── Summary ───────────────────────────────────────────────────────────────────
source "$STEPS_DIR/_lib.sh"
ISSUE_NUMBER="$N"
resolve_context

echo ""
echo -e "${BOLD}${GREEN}════════════════════════════════════════${NC}"
echo -e "${BOLD}${GREEN}  Issue #${N} applied successfully! 🎉${NC}"
echo -e "${BOLD}${GREEN}════════════════════════════════════════${NC}"
echo ""
log_info "Branch : $BRANCH"
PR_NUMBER="$(gh pr list --head "$BRANCH" --state open --json number -q '.[0].number' 2>/dev/null || echo '')"
[[ -n "$PR_NUMBER" ]] && log_info "PR     : $(gh pr view "$PR_NUMBER" --json url -q .url 2>/dev/null || echo "#$PR_NUMBER")"
log_info "Next   : Review the PR, merge manually to close issue #${N}"
echo ""
