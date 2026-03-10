#!/usr/bin/env bash
# Comprehensive check script — Flutter equivalent of the web app's `npm run check`.
#
# Runs: format:check → analyze → test → gen-l10n → build (debug APK)
#
# Usage:
#   ./scripts/check.sh          # full check
#   ./scripts/check.sh --quick  # skip build step

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

QUICK=false
if [[ "${1:-}" == "--quick" ]]; then
  QUICK=true
fi

PASS=0
FAIL=0

step() {
  echo ""
  echo -e "${CYAN}━━━ $1 ━━━${NC}"
}

pass() {
  echo -e "${GREEN}✓ $1${NC}"
  PASS=$((PASS + 1))
}

fail() {
  echo -e "${RED}✗ $1${NC}"
  FAIL=$((FAIL + 1))
}

# ── 1. Dependencies ──────────────────────────────────────
step "Install dependencies"
flutter pub get > /dev/null 2>&1 && pass "flutter pub get" || fail "flutter pub get"

# ── 2. Format check ──────────────────────────────────────
step "Format check"
dart format --set-exit-if-changed lib/ test/ tools/ > /dev/null 2>&1 \
  && pass "dart format" || fail "dart format (run 'dart format .' to fix)"

# ── 3. Static analysis ───────────────────────────────────
step "Static analysis"
flutter analyze --no-fatal-infos 2>&1 | tail -1
if flutter analyze --no-fatal-infos > /dev/null 2>&1; then
  pass "flutter analyze"
else
  fail "flutter analyze"
fi

# ── 4. Tests ──────────────────────────────────────────────
step "Tests"
if flutter test 2>&1 | tail -1; then
  pass "flutter test"
else
  fail "flutter test"
fi

# ── 5. Localisation generation ────────────────────────────
step "Localisation generation (gen-l10n)"
if flutter gen-l10n > /dev/null 2>&1; then
  pass "flutter gen-l10n"
else
  fail "flutter gen-l10n"
fi

# ── 6. Build (optional) ──────────────────────────────────
if [ "$QUICK" = false ]; then
  step "Build check (debug APK)"
  if flutter build apk --debug > /dev/null 2>&1; then
    pass "flutter build apk --debug"
  else
    fail "flutter build apk --debug"
  fi
else
  step "Build check (skipped — quick mode)"
fi

# ── Summary ───────────────────────────────────────────────
echo ""
echo -e "${CYAN}━━━ Summary ━━━${NC}"
echo -e "  ${GREEN}Passed: $PASS${NC}"
if [ $FAIL -gt 0 ]; then
  echo -e "  ${RED}Failed: $FAIL${NC}"
  exit 1
else
  echo -e "  ${RED}Failed: $FAIL${NC}"
  echo -e "${GREEN}All checks passed!${NC}"
fi
