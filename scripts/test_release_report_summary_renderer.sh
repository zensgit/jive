#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
RENDERER="$SCRIPT_DIR/render_release_report_summary.sh"

usage() {
  cat <<'EOF'
Usage:
  scripts/test_release_report_summary_renderer.sh [--keep-fixtures]

Creates local JSON report fixtures and validates the release report summary
renderer contract. This is host-only: it does not run Flutter, adb, Xcode,
Supabase, network calls, or read secrets.
EOF
}

KEEP_FIXTURES=0
while (( "$#" )); do
  case "$1" in
    --keep-fixtures)
      KEEP_FIXTURES=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      printf '[release-report-summary-test] unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

cd "$APP_DIR"

ROOT="$(mktemp -d /tmp/jive-release-report-summary-test.XXXXXX)"
REPORT_DIR="$ROOT/reports"

cleanup() {
  if [[ "$KEEP_FIXTURES" -eq 1 ]]; then
    printf '[release-report-summary-test] kept fixtures: %s\n' "$ROOT"
  else
    rm -rf "$ROOT"
  fi
}

trap cleanup EXIT INT TERM

log() {
  printf '[release-report-summary-test] %s\n' "$*"
}

fail() {
  printf '[release-report-summary-test] FAIL: %s\n' "$*" >&2
  exit 1
}

assert_contains() {
  local file="$1"
  local expected="$2"
  grep -Fq -- "$expected" "$file" || fail "expected '$expected' in $file"
}

assert_not_contains() {
  local file="$1"
  local unexpected="$2"
  if grep -Fq -- "$unexpected" "$file"; then
    fail "did not expect '$unexpected' in $file"
  fi
}

render_to_file() {
  local context="$1"
  local output="$2"
  JIVE_RELEASE_REPORT_DIR="$REPORT_DIR" "$RENDERER" "$context" > "$output"
}

write_json() {
  local path="$1"
  local body="$2"
  mkdir -p "$(dirname "$path")"
  printf '%s\n' "$body" > "$path"
}

test_empty_reports() {
  local output="$ROOT/empty.md"

  render_to_file release "$output"

  assert_contains "$output" "## Release Report Summary"
  assert_contains "$output" '- No JSON reports found under `build/reports`.'

  log "empty report root surfaces no-report message"
}

test_all_sections_and_fields() {
  local output="$ROOT/full.md"

  write_json "$REPORT_DIR/release-candidate/release-candidate.json" '{
    "status": "block",
    "mode": "strict",
    "artifactName": "app-prod-release.aab",
    "flavor": "prod",
    "signingMode": "release",
    "message": "Strict signing is required."
  }'

  write_json "$REPORT_DIR/ios-release-candidate/ios-release-candidate-preflight.json" '{
    "status": "missingPlatform",
    "codesign": "notAvailable",
    "reason": "iOS platform missing",
    "recommendation": "Install Xcode iOS platform."
  }'

  write_json "$REPORT_DIR/sync-runtime/sync-runtime.json" '{
    "status": "passed",
    "telemetryLevel": "info",
    "action": "none"
  }'

  write_json "$REPORT_DIR/account-book-import-sync/account-book-import-sync.json" '{
    "status": "warning",
    "message": "Fixture warning"
  }'

  write_json "$REPORT_DIR/import-column-mapping/import-column-mapping.json" '{
    "status": "passed",
    "telemetryLevel": "low"
  }'

  render_to_file staging "$output"

  assert_contains "$output" "## Staging Release Report Summary"
  assert_contains "$output" "### Android Release Candidate"
  assert_contains "$output" '- `release-candidate.json`: `block` / `strict`'
  assert_contains "$output" "  - artifact: app-prod-release.aab"
  assert_contains "$output" "  - flavor: prod"
  assert_contains "$output" "  - signingMode: release"
  assert_contains "$output" "  - message: Strict signing is required."
  assert_contains "$output" "### iOS Release Candidate"
  assert_contains "$output" "  - codesign: notAvailable"
  assert_contains "$output" "  - reason: iOS platform missing"
  assert_contains "$output" "  - recommendation: Install Xcode iOS platform."
  assert_contains "$output" "### Sync Runtime Reports"
  assert_contains "$output" "  - action: none"
  assert_contains "$output" "### Account Book / Import / Sync Reports"
  assert_contains "$output" "### Import Column Mapping Reports"
  assert_not_contains "$output" "No JSON reports found"

  log "all sections and optional fields render"
}

test_step_summary_append() {
  local stdout_file="$ROOT/summary-stdout.md"
  local summary_file="$ROOT/github-step-summary.md"

  : > "$summary_file"
  JIVE_RELEASE_REPORT_DIR="$REPORT_DIR" GITHUB_STEP_SUMMARY="$summary_file" \
    "$RENDERER" release > "$stdout_file"

  assert_contains "$stdout_file" "## Release Report Summary"
  assert_contains "$summary_file" "## Release Report Summary"
  assert_contains "$summary_file" "### Android Release Candidate"

  log "GITHUB_STEP_SUMMARY append works"
}

test_repeated_render_is_stable() {
  local first="$ROOT/repeat-1.md"
  local second="$ROOT/repeat-2.md"

  render_to_file release "$first"
  render_to_file release "$second"

  cmp -s "$first" "$second" || fail "repeated render output changed"

  log "repeated render is stable"
}

test_empty_reports
test_all_sections_and_fields
test_step_summary_append
test_repeated_render_is_stable

log "all summary renderer self-tests passed"
