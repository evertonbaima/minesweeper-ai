#!/usr/bin/env bash
# =============================================================================
# install-deps.sh — run npm install only when necessary
# Usage: npm run install-deps
# =============================================================================
set -euo pipefail
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPTS_DIR/_lib.sh"

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
