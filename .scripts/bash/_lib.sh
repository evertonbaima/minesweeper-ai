#!/usr/bin/env bash
# =============================================================================
# _lib.sh — shared helpers for local scripts (install-deps, run-tests)
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

# ── Resolve repo root ─────────────────────────────────────────────────────────
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
