#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET="$SCRIPT_DIR/build_ios_release_candidate.sh"

usage() {
  cat <<'EOF'
Usage:
  scripts/test_ios_release_candidate_builder.sh [--keep-fixtures]

Runs host-only fixture tests for scripts/build_ios_release_candidate.sh using
fake flutter and xcodebuild binaries. No real Xcode build, device, code signing,
network, or Flutter SDK access is required.
EOF
}

KEEP_FIXTURES=0
while (($#)); do
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
      printf '[ios-release-candidate-test] unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

ROOT="$(mktemp -d /tmp/jive-ios-release-candidate-test.XXXXXX)"
BIN_DIR="$ROOT/bin"
mkdir -p "$BIN_DIR"

cleanup() {
  rm -rf "$APP_DIR/build/ios/iphoneos/Runner.app"
  if [[ "$KEEP_FIXTURES" -eq 1 ]]; then
    printf '[ios-release-candidate-test] kept fixtures: %s\n' "$ROOT"
  else
    rm -rf "$ROOT"
  fi
}

trap cleanup EXIT INT TERM

log() {
  printf '[ios-release-candidate-test] %s\n' "$*"
}

fail() {
  printf '[ios-release-candidate-test] FAIL: %s\n' "$*" >&2
  exit 1
}

assert_contains() {
  local file="$1"
  local expected="$2"
  grep -Fq -- "$expected" "$file" || fail "expected '$expected' in $file"
}

assert_json_value() {
  local file="$1"
  local key="$2"
  local expected="$3"

  python3 - "$file" "$key" "$expected" <<'PY'
import json
import sys
from pathlib import Path

file, key, expected = sys.argv[1:]
payload = json.loads(Path(file).read_text(encoding="utf-8"))
actual = payload.get(key)
if str(actual) != expected:
    raise SystemExit(f"expected {key}={expected!r}, got {actual!r}")
PY
}

write_fake_tools() {
  cat > "$BIN_DIR/flutter" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

log_file="${JIVE_FAKE_FLUTTER_LOG:?JIVE_FAKE_FLUTTER_LOG is required}"
printf '%s\n' "$*" >> "$log_file"

if [[ "${1:-}" == "pub" && "${2:-}" == "get" ]]; then
  printf '[fake-flutter] pub get\n'
  exit 0
fi

if [[ "${1:-}" == "build" && "${2:-}" == "ios" ]]; then
  if [[ "${JIVE_FAKE_FLUTTER_BUILD_FAIL:-}" == "1" ]]; then
    printf '[fake-flutter] build ios forced failure\n' >&2
    exit 42
  fi
  mkdir -p build/ios/iphoneos/Runner.app
  printf 'fixture app\n' > build/ios/iphoneos/Runner.app/fixture.txt
  printf '[fake-flutter] build ios success\n'
  exit 0
fi

printf '[fake-flutter] unsupported args: %s\n' "$*" >&2
exit 2
EOF

  cat > "$BIN_DIR/xcodebuild" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

log_file="${JIVE_FAKE_XCODEBUILD_LOG:?JIVE_FAKE_XCODEBUILD_LOG is required}"
printf '%s\n' "$*" >> "$log_file"

case "${JIVE_FAKE_XCODE_DESTINATIONS:-ready}" in
  missing-platform)
    printf 'Ineligible destinations for the "Runner" scheme:\n'
    printf '{ platform:iOS, name:Any iOS Device, error:iOS 18.0 is not installed. }\n'
    ;;
  empty)
    ;;
  ready)
    printf 'Available destinations for the "Runner" scheme:\n'
    printf '{ platform:iOS, id:fixture, name:Any iOS Device }\n'
    ;;
  *)
    printf '[fake-xcodebuild] unknown destinations mode\n' >&2
    exit 2
    ;;
esac
EOF

  chmod +x "$BIN_DIR/flutter" "$BIN_DIR/xcodebuild"
}

run_case() {
  local label="$1"
  local expected_status="$2"
  local destinations_mode="$3"
  local build_fail="$4"

  local out_dir="$ROOT/$label"
  local report_dir="$out_dir/reports"
  local artifact_dir="$out_dir/artifacts"
  local stdout="$out_dir/stdout.txt"
  local stderr="$out_dir/stderr.txt"
  local flutter_log="$out_dir/flutter.log"
  local xcode_log="$out_dir/xcodebuild.log"
  mkdir -p "$out_dir" "$report_dir" "$artifact_dir"

  set +e
  PATH="$BIN_DIR:$PATH" \
  JIVE_FAKE_FLUTTER_LOG="$flutter_log" \
  JIVE_FAKE_XCODEBUILD_LOG="$xcode_log" \
  JIVE_FAKE_XCODE_DESTINATIONS="$destinations_mode" \
  JIVE_FAKE_FLUTTER_BUILD_FAIL="$build_fail" \
  JIVE_IOS_RELEASE_REPORT_DIR="$report_dir" \
  JIVE_IOS_RELEASE_ARTIFACT_DIR="$artifact_dir" \
    bash "$TARGET" > "$stdout" 2> "$stderr"
  local status=$?
  set -e

  if [[ "$status" != "$expected_status" ]]; then
    printf '--- stdout ---\n' >&2
    cat "$stdout" >&2 || true
    printf '--- stderr ---\n' >&2
    cat "$stderr" >&2 || true
    fail "$label expected exit $expected_status, got $status"
  fi

  printf '%s\n' "$report_dir"
}

write_fake_tools

missing_report="$(run_case missing-platform 2 missing-platform 0)"
assert_json_value "$missing_report/ios-release-candidate-preflight.json" status missingPlatform
assert_contains "$missing_report/ios-release-candidate-preflight-latest.md" "iOS Release Candidate Preflight"
assert_contains "$missing_report/../flutter.log" "pub get"
if grep -Fq -- "build ios" "$missing_report/../flutter.log"; then
  fail "missing-platform case should stop before flutter build ios"
fi
log "pass fixture ok: missing iOS platform fast-fails with preflight report"

failure_report="$(run_case build-failure 42 ready 1)"
assert_json_value "$failure_report/ios-release-candidate.json" status block
assert_contains "$failure_report/latest.md" "flutter build ios failed before producing Runner.app"
assert_contains "$failure_report/ios-release-candidate-build.log" "forced failure"
log "pass fixture ok: build failure writes blocking release report"

success_report="$(run_case success 0 ready 0)"
assert_json_value "$success_report/ios-release-candidate.json" status review
assert_json_value "$success_report/ios-release-candidate.json" codesign disabled
assert_contains "$success_report/latest.md" "Unsigned iOS release candidate built successfully"
if [[ ! -f "$success_report/../artifacts/Runner.app/fixture.txt" ]]; then
  fail "success case did not copy Runner.app fixture"
fi
log "pass fixture ok: successful unsigned build writes review report and copies app"

log "all iOS release candidate builder self-tests passed"
