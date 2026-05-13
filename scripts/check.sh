#!/usr/bin/env bash
# MQ Navigation comprehensive check script.
#
# Runs:
#   pub get
#   format check / optional fix
#   static analysis
#   tests
#   l10n generation
#   privacy guard
#   secret scan
#   optional debug APK build
#
# Usage:
#   ./scripts/check.sh
#   ./scripts/check.sh --quick
#   ./scripts/check.sh --fix
#   ./scripts/check.sh --verbose
#   ./scripts/check.sh --quick --fix

set -euo pipefail

# ── Project root ──────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

# ── Colours ───────────────────────────────────────────────
if [[ -t 1 && "${NO_COLOR:-}" == "" ]]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[0;33m'
  CYAN='\033[0;36m'
  NC='\033[0m'
else
  RED=''
  GREEN=''
  YELLOW=''
  CYAN=''
  NC=''
fi

QUICK=false
FIX=false
VERBOSE=false

for arg in "$@"; do
  case "$arg" in
    --quick) QUICK=true ;;
    --fix) FIX=true ;;
    --verbose) VERBOSE=true ;;
    --help|-h)
      echo "Usage: ./scripts/check.sh [--quick] [--fix] [--verbose]"
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown argument: $arg${NC}"
      echo "Usage: ./scripts/check.sh [--quick] [--fix] [--verbose]"
      exit 1
      ;;
  esac
done

PASS=0
FAIL=0
FAILED_STEPS=()

LOG_DIR=".dart_tool/check_logs"
mkdir -p "$LOG_DIR"

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
  FAILED_STEPS+=("$1")
}

run_step() {
  local name="$1"
  local command="$2"
  local log_file="$LOG_DIR/${name// /_}.log"

  if [[ "$VERBOSE" == true ]]; then
    echo -e "${YELLOW}$command${NC}"
    if bash -lc "$command" 2>&1 | tee "$log_file"; then
      pass "$name"
    else
      fail "$name"
      echo -e "${YELLOW}Log: $log_file${NC}"
    fi
  else
    if bash -lc "$command" > "$log_file" 2>&1; then
      pass "$name"
    else
      fail "$name"
      echo -e "${YELLOW}Last 40 log lines from $log_file:${NC}"
      tail -40 "$log_file" || true
    fi
  fi
}

# ── 1. Dependencies ──────────────────────────────────────
step "Install dependencies"
run_step "flutter pub get" "flutter pub get"

# ── 2. Format ────────────────────────────────────────────
step "Format"
FORMAT_TARGETS="lib test tools scripts integration_test"

EXISTING_FORMAT_TARGETS=""
for target in $FORMAT_TARGETS; do
  if [[ -e "$target" ]]; then
    EXISTING_FORMAT_TARGETS="$EXISTING_FORMAT_TARGETS $target"
  fi
done

if [[ "$FIX" == true ]]; then
  run_step "dart format fix" "dart format $EXISTING_FORMAT_TARGETS"
else
  run_step "dart format check" "dart format --set-exit-if-changed $EXISTING_FORMAT_TARGETS"
fi

# ── 3. Static analysis ───────────────────────────────────
step "Static analysis"
run_step "flutter analyze" "flutter analyze --no-fatal-infos"

# ── 4. Tests ─────────────────────────────────────────────
step "Tests"
run_step "flutter test" "flutter test"

# ── 5. Localisation generation ───────────────────────────
step "Localisation generation"
run_step "flutter gen-l10n" "flutter gen-l10n"

# ── 6. Localisation untranslated check ───────────────────
step "Localisation untranslated check"
UNTRANSLATED_FILE=".dart_tool/untranslated.json"

if [[ -f "$UNTRANSLATED_FILE" ]]; then
  # Quick check: is the file empty (just {} after stripping whitespace)?
  json_size="$(wc -c < "$UNTRANSLATED_FILE" | tr -d ' ')"
  if [[ "$json_size" -lt 10 ]]; then
    pass "no untranslated l10n messages"
  else
    echo -e "${YELLOW}Untranslated l10n keys detected — expected for new features.${NC}"
    echo -e "${YELLOW}Run a full ARB sync to propagate translations across 34 locales.${NC}"
    pass "untranslated l10n tracked (non-blocking)"
  fi
else
  echo -e "${YELLOW}No untranslated file found at $UNTRANSLATED_FILE. Skipping.${NC}"
fi

# ── 7. Privacy guard ─────────────────────────────────────
step "Privacy guard"

FORBIDDEN_PACKAGES=(
  "firebase_analytics"
  "google_analytics"
  "appsflyer"
  "amplitude"
  "mixpanel"
  "segment"
  "sentry_flutter"
  "facebook_app_events"
)

PRIVACY_FAIL=false

for package in "${FORBIDDEN_PACKAGES[@]}"; do
  if grep -q "^[[:space:]]*$package:" pubspec.yaml 2>/dev/null ||
     grep -q "name: $package" pubspec.lock 2>/dev/null; then
    echo -e "${RED}Forbidden tracking/analytics package found: $package${NC}"
    PRIVACY_FAIL=true
  fi
done

if [[ "$PRIVACY_FAIL" == true ]]; then
  fail "privacy guard"
else
  pass "privacy guard"
fi

# ── 8. Secret scan ───────────────────────────────────────
step "Secret scan"

# Only scan source code and config (NOT supabase/ edge functions —
# they use Deno.env.get() for runtime env vars like SUPABASE_SERVICE_ROLE_KEY,
# which are injected by Supabase at deploy time, not hardcoded).
SECRET_SCAN_DIRS="lib test scripts"
SECRET_FAIL=false

for dir in $SECRET_SCAN_DIRS; do
  if [[ ! -d "$dir" ]]; then continue; fi

  # Patterns: sk-* (OpenAI-style), AIza* (Google API keys)
  # Exclude: own check.sh source line (pattern literal), .arb files, generated code
  if grep -RIE "(sk-[A-Za-z0-9]{20,}|AIza[0-9A-Za-z_-]{20,})" \
    "$dir" \
    --exclude-dir=.dart_tool \
    --exclude-dir=build \
    --exclude-dir=.git \
    --exclude='*.g.dart' \
    --exclude='*.freezed.dart' \
    --exclude='*.env' \
    --exclude='.env.example' \
    2>/dev/null | grep -v ".arb:" | grep -v "check.sh:" > /tmp/mq_secret_scan.txt; then
    echo -e "${RED}Possible hardcoded API key/secret found in $dir:${NC}"
    cat /tmp/mq_secret_scan.txt
    SECRET_FAIL=true
  fi
done

rm -f /tmp/mq_secret_scan.txt

if [[ "$SECRET_FAIL" == true ]]; then
  fail "secret scan"
else
  pass "secret scan"
fi

# ── 9. Build ─────────────────────────────────────────────
if [[ "$QUICK" == false ]]; then
  step "Build check"
  run_step "flutter build apk debug" "flutter build apk --debug"
else
  step "Build check"
  echo -e "${YELLOW}Skipped because --quick was used.${NC}"
fi

# ── Summary ──────────────────────────────────────────────
echo ""
echo -e "${CYAN}━━━ Summary ━━━${NC}"
echo -e "  ${GREEN}Passed: $PASS${NC}"
echo -e "  ${RED}Failed: $FAIL${NC}"

if [[ "$FAIL" -gt 0 ]]; then
  echo ""
  echo -e "${RED}Failed steps:${NC}"
  for failed in "${FAILED_STEPS[@]}"; do
    echo -e "  ${RED}- $failed${NC}"
  done
  echo ""
  echo -e "${YELLOW}Logs saved in: $LOG_DIR${NC}"
  exit 1
fi

echo -e "${GREEN}All checks passed.${NC}"
