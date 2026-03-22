#!/usr/bin/env bash
# =============================================================================
# _lib.sh — shared helpers sourced by every step script.
# Never executed directly.
# =============================================================================

# ── Colours ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}ℹ${NC}  $*"; }
log_success() { echo -e "${GREEN}✅${NC} $*"; }
log_warn()    { echo -e "${YELLOW}⚠️${NC}  $*"; }
log_error()   { echo -e "${RED}❌${NC} $*"; }
log_step()    { echo -e "\n${BOLD}${CYAN}▶ $*${NC}"; }

# ── Validate issue number ─────────────────────────────────────────────────────
# Usage: validate_issue_number <value> <npm-command>
validate_issue_number() {
  local value="$1"
  local cmd="${2:-apply-issue}"
  if [[ -z "$value" ]]; then
    log_error "No issue number provided."
    echo "  Usage: npm run ${cmd} -- <issue-number>"
    exit 1
  fi
  if ! [[ "$value" =~ ^[0-9]+$ ]]; then
    log_error "Issue number must be a positive integer. Got: '$value'"
    exit 1
  fi
}

# ── Resolve shared context variables ─────────────────────────────────────────
# Sets: REPO_ROOT, ZIP_DIR, DONE_DIR, SENTINEL, ZIP_FILE,
#       ZIP_BASENAME, SLUG, BRANCH
# Requires: ISSUE_NUMBER already set.
resolve_context() {
  REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  ZIP_DIR="$REPO_ROOT/.zip"
  DONE_DIR="$ZIP_DIR/done"
  SENTINEL="$DONE_DIR/.applied-issue-${ISSUE_NUMBER}"

  mkdir -p "$DONE_DIR"

  # Locate zip — accept issue-N-slug.zip or issue-N.zip
  ZIP_FILE="$(find "$ZIP_DIR" -maxdepth 1 \
    \( -name "issue-${ISSUE_NUMBER}-*.zip" -o -name "issue-${ISSUE_NUMBER}.zip" \) \
    2>/dev/null | head -n 1)"

  # If zip already moved to done/, look there too
  if [[ -z "$ZIP_FILE" ]]; then
    ZIP_FILE="$(find "$DONE_DIR" -maxdepth 1 \
      \( -name "issue-${ISSUE_NUMBER}-*.zip" -o -name "issue-${ISSUE_NUMBER}.zip" \) \
      2>/dev/null | head -n 1)"
  fi

  ZIP_BASENAME="$(basename "${ZIP_FILE:-issue-${ISSUE_NUMBER}.zip}")"

  # Derive slug from filename
  SLUG="${ZIP_BASENAME#issue-${ISSUE_NUMBER}-}"
  SLUG="${SLUG%.zip}"
  if [[ -z "$SLUG" || "$SLUG" == "$ZIP_BASENAME" ]]; then
    SLUG="task"
  fi

  BRANCH="issue-${ISSUE_NUMBER}/${SLUG}"
}
