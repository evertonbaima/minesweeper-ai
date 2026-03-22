#!/usr/bin/env bash
# =============================================================================
# apply-issue.sh
# Usage: ./.scripts/bash/apply-issue.sh <issue-number>
# Example: npm run apply-issue -- 1
# =============================================================================

set -euo pipefail

# ── Colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Colour

log_info()    { echo -e "${BLUE}ℹ${NC}  $*"; }
log_success() { echo -e "${GREEN}✅${NC} $*"; }
log_warn()    { echo -e "${YELLOW}⚠️${NC}  $*"; }
log_error()   { echo -e "${RED}❌${NC} $*"; }
log_step()    { echo -e "\n${BOLD}${CYAN}▶ $*${NC}"; }

# ── Validate input ────────────────────────────────────────────────────────────
if [[ $# -lt 1 ]]; then
  log_error "No issue number provided."
  echo "  Usage: npm run apply-issue -- <issue-number>"
  exit 1
fi

ISSUE_NUMBER="$1"

if ! [[ "$ISSUE_NUMBER" =~ ^[0-9]+$ ]]; then
  log_error "Issue number must be a positive integer. Got: '$ISSUE_NUMBER'"
  exit 1
fi

# ── Resolve paths ─────────────────────────────────────────────────────────────
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
ZIP_DIR="$REPO_ROOT/.zip"
DONE_DIR="$ZIP_DIR/done"
REPO_SLUG="$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo '')"

mkdir -p "$DONE_DIR"

# ── Locate the zip file for this issue ───────────────────────────────────────
log_step "Locating zip file for issue #$ISSUE_NUMBER"

# Accept any zip that starts with "issue-{N}-" or exactly "issue-{N}.zip"
ZIP_FILE="$(find "$ZIP_DIR" -maxdepth 1 -name "issue-${ISSUE_NUMBER}-*.zip" -o -name "issue-${ISSUE_NUMBER}.zip" 2>/dev/null | head -n 1)"

if [[ -z "$ZIP_FILE" ]]; then
  log_error "No zip file found for issue #$ISSUE_NUMBER in $ZIP_DIR"
  log_info  "Expected pattern: $ZIP_DIR/issue-${ISSUE_NUMBER}-<slug>.zip"
  exit 1
fi

ZIP_BASENAME="$(basename "$ZIP_FILE")"
log_success "Found: $ZIP_BASENAME"

# ── Derive slug and branch name ───────────────────────────────────────────────
# Strip leading "issue-N-" and trailing ".zip" to get the slug
SLUG="${ZIP_BASENAME#issue-${ISSUE_NUMBER}-}"
SLUG="${SLUG%.zip}"
# Fallback slug if filename was exactly "issue-N.zip"
if [[ -z "$SLUG" || "$SLUG" == "$ZIP_BASENAME" ]]; then
  SLUG="task"
fi

BRANCH="issue-${ISSUE_NUMBER}/${SLUG}"
log_info "Branch: $BRANCH"

# ── Check if already unzipped (sentinel file) ────────────────────────────────
SENTINEL="$DONE_DIR/.applied-issue-${ISSUE_NUMBER}"

log_step "Checking if issue #$ISSUE_NUMBER was already applied"

if [[ -f "$SENTINEL" ]]; then
  log_warn "Issue #$ISSUE_NUMBER was already applied (sentinel found). Skipping unzip."
  log_info "Proceeding directly to test → commit → push."
  SKIP_UNZIP=true
else
  SKIP_UNZIP=false
fi

# ── Ensure the branch exists and is checked out ──────────────────────────────
log_step "Preparing branch: $BRANCH"

# Fetch remote info silently
gh repo sync 2>/dev/null || true

CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"

# Check if branch exists locally
if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
  log_info "Branch '$BRANCH' already exists locally."
  if [[ "$CURRENT_BRANCH" != "$BRANCH" ]]; then
    git checkout "$BRANCH"
    log_success "Checked out '$BRANCH'"
  else
    log_info "Already on '$BRANCH'"
  fi
else
  # Check if branch exists on remote
  if git ls-remote --exit-code --heads origin "$BRANCH" &>/dev/null; then
    log_info "Branch '$BRANCH' exists on remote. Checking out."
    git checkout -b "$BRANCH" "origin/$BRANCH"
    log_success "Checked out '$BRANCH' from remote"
  else
    log_info "Branch '$BRANCH' does not exist. Creating from main."
    git checkout main 2>/dev/null || git checkout master 2>/dev/null
    git pull origin "$(git rev-parse --abbrev-ref HEAD)" --quiet
    git checkout -b "$BRANCH"
    log_success "Created and checked out new branch '$BRANCH'"
  fi
fi

# ── Unzip ─────────────────────────────────────────────────────────────────────
if [[ "$SKIP_UNZIP" == false ]]; then
  log_step "Unzipping $ZIP_BASENAME into project root"

  if unzip -o "$ZIP_FILE" -d "$REPO_ROOT" > /tmp/unzip_output.txt 2>&1; then
    log_success "Unzip successful"

    # Mark as applied
    touch "$SENTINEL"
    log_info "Sentinel created: $SENTINEL"

    # Move zip to done/
    mv "$ZIP_FILE" "$DONE_DIR/$ZIP_BASENAME"
    log_success "Moved $ZIP_BASENAME → .zip/done/"
  else
    log_error "Unzip failed. Output:"
    cat /tmp/unzip_output.txt
    exit 1
  fi
fi

# ── Install dependencies (only if necessary) ─────────────────────────────────
log_step "Checking if dependency install is needed"

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

# ── Run tests ─────────────────────────────────────────────────────────────────
log_step "Running tests"

TEST_OUTPUT_FILE="/tmp/vitest_output_${ISSUE_NUMBER}.txt"
TEST_EXIT_CODE=0

npm run test --prefix "$REPO_ROOT" -- --run 2>&1 | tee "$TEST_OUTPUT_FILE" || TEST_EXIT_CODE=$?

if [[ $TEST_EXIT_CODE -ne 0 ]]; then
  log_error "Tests FAILED. Aborting commit and push."
  log_warn  "Fix the failing tests, then re-run: npm run apply-issue -- $ISSUE_NUMBER"
  exit 1
fi

log_success "All tests passed"

# ── Stage and commit ──────────────────────────────────────────────────────────
log_step "Committing changes"

cd "$REPO_ROOT"

# Check if there is anything to commit
if git diff --quiet && git diff --staged --quiet; then
  log_warn "No changes to commit. Working tree is clean."
else
  git add -A
  COMMIT_MSG="close #${ISSUE_NUMBER} — ${SLUG//-/ }"
  git commit -m "$COMMIT_MSG"
  log_success "Committed: \"$COMMIT_MSG\""
fi

# ── Push ──────────────────────────────────────────────────────────────────────
log_step "Pushing branch '$BRANCH' to origin"

FIRST_PUSH=false

# Detect if remote branch already exists
if ! git ls-remote --exit-code --heads origin "$BRANCH" &>/dev/null; then
  FIRST_PUSH=true
fi

git push origin "$BRANCH"
log_success "Pushed to origin/$BRANCH"

# ── Open Pull Request (first push only) ───────────────────────────────────────
if [[ "$FIRST_PUSH" == true ]]; then
  log_step "Opening Pull Request"

  # Fetch issue title from GitHub
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
    log_warn "Could not open PR automatically (label may not exist yet). Create it manually."
  fi
fi

# ── Code review via Claude (gh pr review) ────────────────────────────────────
log_step "Fetching PR diff for code review"

# Get the PR number for this branch
PR_NUMBER="$(gh pr view "$BRANCH" --json number -q .number 2>/dev/null || echo '')"

if [[ -z "$PR_NUMBER" ]]; then
  log_warn "No open PR found for branch '$BRANCH'. Skipping code review step."
else
  DIFF_FILE="/tmp/pr_diff_${ISSUE_NUMBER}.txt"
  gh pr diff "$PR_NUMBER" > "$DIFF_FILE" 2>/dev/null || true

  if [[ ! -s "$DIFF_FILE" ]]; then
    log_warn "PR diff is empty. Skipping code review."
  else
    log_info "PR #$PR_NUMBER diff captured ($(wc -l < "$DIFF_FILE") lines). Posting review comments..."

    # Build a structured review comment summarising the diff
    REVIEW_BODY="## 🤖 Automated Code Review — Issue #${ISSUE_NUMBER}

> Generated by \`apply-issue.sh\` after push to \`${BRANCH}\`

### Checklist reviewed
- [ ] All acceptance criteria from issue #${ISSUE_NUMBER} appear to be addressed
- [ ] No leftover TODO / FIXME comments
- [ ] No \`console.log\` debug statements committed
- [ ] Test file(s) included and covering the new logic
- [ ] Types are explicit — no unintentional \`any\`
- [ ] Styled Components use theme/CSS variables, not hardcoded values
- [ ] No unused imports

### Diff stats
\`\`\`
$(cd "$REPO_ROOT" && git diff origin/main..."$BRANCH" --stat 2>/dev/null || cat "$DIFF_FILE" | head -20)
\`\`\`

> If any items above are unchecked, please address them before merging."

    gh pr review "$PR_NUMBER" \
      --comment \
      --body "$REVIEW_BODY" 2>/dev/null && log_success "Code review comment posted to PR #$PR_NUMBER" \
      || log_warn "Could not post review comment. Check gh auth scopes (needs pull_requests: write)."
  fi
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}════════════════════════════════════════${NC}"
echo -e "${BOLD}${GREEN}  Issue #${ISSUE_NUMBER} applied successfully! 🎉${NC}"
echo -e "${BOLD}${GREEN}════════════════════════════════════════${NC}"
echo ""
log_info "Branch  : $BRANCH"
[[ -n "${PR_NUMBER:-}" ]] && log_info "PR      : $(gh pr view "$PR_NUMBER" --json url -q .url 2>/dev/null || echo "#$PR_NUMBER")"
log_info "Next    : Review the PR, merge manually to close issue #${ISSUE_NUMBER}"
echo ""
