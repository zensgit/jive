#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
RENDERER="$SCRIPT_DIR/render_release_android_smoke_summary.sh"

cd "$APP_DIR"

usage() {
  cat <<'EOF'
Usage:
  scripts/test_release_android_smoke_summary_renderer.sh [--keep-fixtures]

Creates minimal local fixtures and validates the release Android smoke summary
renderer contract. It checks:
  - passed smoke + passed verification => overallStatus: passed
  - passed smoke + missing verification => overallStatus: missing
  - failed smoke => overallStatus: failed
  - repeated renders keep artifactFiles stable
  - report dir equal to artifact dir does not fail

This is a host-only self-test. It does not run adb, start an emulator, build
APKs, upload artifacts, or read secrets.
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
      printf '[release-android-smoke-summary-test] unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

ROOT="$(mktemp -d /tmp/jive-release-android-smoke-summary-test.XXXXXX)"
REPORT_ROOT="${JIVE_RELEASE_ANDROID_SMOKE_REPORT_DIR:-$ROOT/reports}"

cleanup() {
  if [[ "$KEEP_FIXTURES" -eq 1 ]]; then
    printf '[release-android-smoke-summary-test] kept fixtures: %s\n' "$ROOT"
  else
    rm -rf "$ROOT"
  fi
}

trap cleanup EXIT INT TERM

log() {
  printf '[release-android-smoke-summary-test] %s\n' "$*"
}

fail() {
  printf '[release-android-smoke-summary-test] FAIL: %s\n' "$*" >&2
  exit 1
}

value_from_markdown() {
  local file="$1"
  local key="$2"
  sed -n "s/^- $key: //p" "$file" | head -1
}

write_summary() {
  local dir="$1"
  local smoke_status="$2"
  local scenario="${3:-all}"

  cat > "$dir/summary.md" <<EOF
# Local Android Feature Smoke

- generatedAt: 20260507-000000
- status: $smoke_status
- message: fixture
- gitCommit: 0123456789abcdef0123456789abcdef01234567
- device: fixture-device
- emulator: fixture-emulator
- flavor: dev
- scenario: $scenario
- package: com.jivemoney.app.dev
- activity: com.jive.app.MainActivity
- artifactDir: $dir
- apkPath: /tmp/jive-fixture.apk
- apkSha256: 0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
- finalCrashBytes: 0
- finalUiSummary: $dir/final_home.summary.txt
EOF
}

write_verification() {
  local dir="$1"
  local verification_status="${2:-passed}"
  local failures="${3:-0}"
  local warnings="${4:-0}"

  cat > "$dir/release_android_smoke_artifact_verification.md" <<EOF
# Release Android Smoke Artifact Verification

- generatedAt: 2026-05-07T00:00:00Z
- status: $verification_status
- scenario: all
- artifactDir: $dir
- summary: $dir/summary.md
- failures: $failures
- warnings: $warnings

## Checks

- pass: fixture
EOF
}

create_fixture() {
  local name="$1"
  local smoke_status="$2"
  local include_verification="$3"
  local verification_status="${4:-passed}"
  local dir="$ROOT/$name"

  mkdir -p "$dir"
  write_summary "$dir" "$smoke_status"
  printf 'fixture png\n' > "$dir/final_home.png"
  printf '<hierarchy />\n' > "$dir/final_home.xml"
  printf 'TextView: fixture\n' > "$dir/final_home.summary.txt"
  : > "$dir/final_home.crash.log"
  : > "$dir/final_home.alerts.log"

  if [[ "$include_verification" == "yes" ]]; then
    write_verification "$dir" "$verification_status"
  fi

  printf '%s\n' "$dir"
}

render_fixture() {
  local dir="$1"
  local report_root="${2:-$REPORT_ROOT}"
  JIVE_RELEASE_ANDROID_SMOKE_REPORT_DIR="$report_root" "$RENDERER" "$dir" \
    > "$dir/renderer.stdout" 2> "$dir/renderer.stderr"
}

assert_value() {
  local file="$1"
  local key="$2"
  local expected="$3"
  local actual
  actual="$(value_from_markdown "$file" "$key")"
  [[ "$actual" == "$expected" ]] || fail "expected $key=$expected in $file, got '${actual:-missing}'"
}

assert_file_exists() {
  local file="$1"
  [[ -f "$file" ]] || fail "expected file to exist: $file"
}

test_passed_with_verification() {
  local dir
  local first_count
  local second_count
  dir="$(create_fixture passed-with-verification passed yes passed)"

  render_fixture "$dir"
  assert_file_exists "$dir/latest.md"
  assert_file_exists "$REPORT_ROOT/latest.md"
  assert_value "$dir/latest.md" overallStatus passed
  assert_value "$dir/latest.md" smokeStatus passed
  assert_value "$dir/latest.md" verificationStatus passed
  assert_value "$dir/latest.md" verificationFailures 0
  assert_value "$dir/latest.md" verificationWarnings 0
  first_count="$(value_from_markdown "$dir/latest.md" artifactFiles)"

  render_fixture "$dir"
  second_count="$(value_from_markdown "$dir/latest.md" artifactFiles)"
  [[ "$first_count" == "$second_count" ]] || fail "artifactFiles changed after repeated render: $first_count -> $second_count"

  log "pass fixture ok: passed smoke with passed verification"
}

test_missing_verification() {
  local dir
  dir="$(create_fixture missing-verification passed no)"

  render_fixture "$dir"
  assert_value "$dir/latest.md" overallStatus missing
  assert_value "$dir/latest.md" smokeStatus passed
  assert_value "$dir/latest.md" verificationStatus missing
  assert_value "$dir/latest.md" verificationFailures n/a
  assert_value "$dir/latest.md" verificationWarnings n/a

  log "pass fixture ok: missing verification is surfaced"
}

test_failed_smoke_wins() {
  local dir
  dir="$(create_fixture failed-smoke failed yes passed)"

  render_fixture "$dir"
  assert_value "$dir/latest.md" overallStatus failed
  assert_value "$dir/latest.md" smokeStatus failed
  assert_value "$dir/latest.md" verificationStatus passed

  log "pass fixture ok: failed smoke status wins"
}

test_same_path_report_dir() {
  local dir
  dir="$(create_fixture same-path passed yes passed)"

  render_fixture "$dir" "$dir"
  assert_file_exists "$dir/latest.md"
  assert_value "$dir/latest.md" overallStatus passed

  log "pass fixture ok: same-path report dir"
}

test_passed_with_verification
test_missing_verification
test_failed_smoke_wins
test_same_path_report_dir

log "all summary renderer self-tests passed"
