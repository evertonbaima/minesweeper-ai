#!/usr/bin/env bash
# =============================================================================
# handle-zip.sh — Step 1: locate, unzip, sentinel, move to done/
# Usage: npm run apply-issue:zip -- <issue-number>
# =============================================================================
set -euo pipefail
STEPS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$STEPS_DIR/_lib.sh"

validate_issue_number "${1:-}" "apply-issue:zip"
ISSUE_NUMBER="$1"
resolve_context

log_step "[1/7] Handle zip file for issue #$ISSUE_NUMBER"

if [[ -z "$ZIP_FILE" || ! -f "$ZIP_FILE" ]]; then
  log_error "No zip file found for issue #$ISSUE_NUMBER in $ZIP_DIR"
  log_info  "Expected pattern: $ZIP_DIR/issue-${ISSUE_NUMBER}-<slug>.zip"
  exit 1
fi
log_success "Found: $ZIP_BASENAME  →  branch will be: $BRANCH"

if [[ -f "$SENTINEL" ]]; then
  log_warn "Sentinel exists — issue #$ISSUE_NUMBER was already unzipped. Skipping."
  exit 0
fi

log_step "Unzipping into project root"
if unzip -o "$ZIP_FILE" -d "$REPO_ROOT" > /tmp/unzip_output.txt 2>&1; then
  log_success "Unzip successful"
  touch "$SENTINEL"
  log_info "Sentinel created: $SENTINEL"
  mv "$ZIP_FILE" "$DONE_DIR/$ZIP_BASENAME"
  log_success "Moved $ZIP_BASENAME → .zip/done/"
else
  log_error "Unzip failed:"
  cat /tmp/unzip_output.txt
  exit 1
fi
