#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET="$SCRIPT_DIR/build_saas_staging_apk.sh"

usage() {
  cat <<'EOF'
Usage:
  scripts/test_saas_staging_apk_builder.sh [--keep-fixtures]

Runs host-only fixture tests for scripts/build_saas_staging_apk.sh using a fake
Flutter binary. No real Flutter build, Android SDK, Supabase project, device,
network, or secret access is required.
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
      printf '[saas-staging-apk-builder-test] unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

ROOT="$(mktemp -d /tmp/jive-saas-staging-apk-builder-test.XXXXXX)"
BIN_DIR="$ROOT/bin"
mkdir -p "$BIN_DIR"

cleanup() {
  rm -rf "$APP_DIR/build/app/outputs/flutter-apk" "$APP_DIR/build/app/outputs/bundle"
  if [[ "$KEEP_FIXTURES" -eq 1 ]]; then
    printf '[saas-staging-apk-builder-test] kept fixtures: %s\n' "$ROOT"
  else
    rm -rf "$ROOT"
  fi
}

trap cleanup EXIT INT TERM

log() {
  printf '[saas-staging-apk-builder-test] %s\n' "$*"
}

fail() {
  printf '[saas-staging-apk-builder-test] FAIL: %s\n' "$*" >&2
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

write_fake_flutter() {
  cat > "$BIN_DIR/flutter" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

log_file="${JIVE_FAKE_FLUTTER_LOG:?JIVE_FAKE_FLUTTER_LOG is required}"
snapshot="${JIVE_FAKE_DART_DEFINE_SNAPSHOT:-}"
printf '%s\n' "$*" >> "$log_file"

if [[ "${1:-}" == "pub" && "${2:-}" == "get" ]]; then
  printf '[fake-flutter] pub get\n'
  exit 0
fi

if [[ "${1:-}" == "build" ]]; then
  kind="${2:-}"
  flavor=""
  mode="debug"
  previous=""

  for arg in "$@"; do
    if [[ "$previous" == "--flavor" ]]; then
      flavor="$arg"
    fi
    if [[ "$arg" == "--release" ]]; then
      mode="release"
    elif [[ "$arg" == "--debug" ]]; then
      mode="debug"
    fi
    if [[ "$arg" == --dart-define-from-file=* && -n "$snapshot" ]]; then
      define_file="${arg#--dart-define-from-file=}"
      {
        printf -- '--- dart defines ---\n'
        cat "$define_file"
        printf '\n'
      } >> "$snapshot"
    fi
    previous="$arg"
  done

  if [[ -z "$flavor" ]]; then
    printf '[fake-flutter] missing --flavor\n' >&2
    exit 2
  fi

  case "$kind" in
    apk)
      mkdir -p build/app/outputs/flutter-apk
      printf 'fixture apk %s %s\n' "$flavor" "$mode" \
        > "build/app/outputs/flutter-apk/app-$flavor-$mode.apk"
      printf '[fake-flutter] build apk %s %s\n' "$flavor" "$mode"
      ;;
    appbundle)
      mkdir -p "build/app/outputs/bundle/${flavor}Release"
      printf 'fixture appbundle %s %s\n' "$flavor" "$mode" \
        > "build/app/outputs/bundle/${flavor}Release/app-$flavor-release.aab"
      printf '[fake-flutter] build appbundle %s %s\n' "$flavor" "$mode"
      ;;
    *)
      printf '[fake-flutter] unsupported build kind: %s\n' "$kind" >&2
      exit 2
      ;;
  esac
  exit 0
fi

printf '[fake-flutter] unsupported args: %s\n' "$*" >&2
exit 2
EOF

  chmod +x "$BIN_DIR/flutter"
}

write_env_file() {
  local path="$1"
  {
    printf 'SUPABASE_URL=https://fixture.supabase.co\n'
    printf 'SUPABASE_ANON_KEY=fixture-anon-key\n'
    printf 'SUPABASE_SERVICE_ROLE_KEY=fixture-service-role-should-not-pass\n'
  } > "$path"
}

run_builder() {
  local label="$1"
  shift

  local out_dir="$ROOT/$label"
  mkdir -p "$out_dir"

  set +e
  PATH="$BIN_DIR:$PATH" \
  FLUTTER_BIN="$BIN_DIR/flutter" \
  JIVE_FAKE_FLUTTER_LOG="$out_dir/flutter.log" \
  JIVE_FAKE_DART_DEFINE_SNAPSHOT="$out_dir/dart-defines.snapshot" \
  JIVE_SAAS_BUILD_ARTIFACT_DIR="$out_dir/artifacts" \
  JIVE_SAAS_BUILD_REPORT_DIR="$out_dir/reports" \
    bash "$TARGET" "$@" > "$out_dir/stdout.txt" 2> "$out_dir/stderr.txt"
  local status=$?
  set -e

  printf '%s\n' "$status" > "$out_dir/status.txt"
}

assert_status() {
  local label="$1"
  local expected="$2"
  local actual
  actual="$(cat "$ROOT/$label/status.txt")"
  if [[ "$actual" != "$expected" ]]; then
    printf '--- stdout ---\n' >&2
    cat "$ROOT/$label/stdout.txt" >&2 || true
    printf '--- stderr ---\n' >&2
    cat "$ROOT/$label/stderr.txt" >&2 || true
    fail "$label expected exit $expected, got $actual"
  fi
}

assert_success_report() {
  local label="$1"
  local flavor="$2"
  local mode="$3"
  local kind="$4"
  local artifact_name="$5"

  local report_dir="$ROOT/$label/reports"
  local artifact="$ROOT/$label/artifacts/$artifact_name"

  [[ -f "$artifact" ]] || fail "$label missing copied artifact: $artifact"
  [[ -f "$report_dir/saas-staging-build.json" ]] || fail "$label missing JSON report"
  [[ -f "$report_dir/latest.md" ]] || fail "$label missing Markdown report"

  assert_json_value "$report_dir/saas-staging-build.json" flavor "$flavor"
  assert_json_value "$report_dir/saas-staging-build.json" mode "$mode"
  assert_json_value "$report_dir/saas-staging-build.json" buildKind "$kind"
  assert_json_value "$report_dir/saas-staging-build.json" artifactName "$artifact_name"
  assert_json_value "$report_dir/saas-staging-build.json" supabaseUrlConfigured True
  assert_json_value "$report_dir/saas-staging-build.json" supabaseAnonKeyConfigured True
  assert_json_value "$report_dir/saas-staging-build.json" serviceRolePassedToClient False
  assert_contains "$report_dir/latest.md" "serviceRolePassedToClient: false"
  assert_not_contains "$ROOT/$label/dart-defines.snapshot" "SUPABASE_SERVICE_ROLE_KEY"
  assert_not_contains "$ROOT/$label/dart-defines.snapshot" "fixture-service-role-should-not-pass"
  assert_contains "$ROOT/$label/dart-defines.snapshot" "SUPABASE_URL"
  assert_contains "$ROOT/$label/dart-defines.snapshot" "SUPABASE_ANON_KEY"
}

write_fake_flutter

env_file="$ROOT/staging.env"
write_env_file "$env_file"

run_builder missing-env --env-file "$ROOT/missing.env"
assert_status missing-env 1
assert_contains "$ROOT/missing-env/stderr.txt" "env file not found"
log "negative fixture ok: missing env file fails before Flutter"

run_builder missing-anon --env-file "$ROOT/missing-anon.env"
assert_status missing-anon 1
assert_contains "$ROOT/missing-anon/stderr.txt" "env file not found"
log "negative fixture ok: missing env file path reports clearly"

{
  printf 'SUPABASE_URL=https://fixture.supabase.co\n'
} > "$ROOT/no-anon.env"
run_builder no-anon --env-file "$ROOT/no-anon.env"
assert_status no-anon 1
assert_contains "$ROOT/no-anon/stderr.txt" "SUPABASE_ANON_KEY is missing"
log "negative fixture ok: missing anon key fails before Flutter"

{
  printf 'SUPABASE_ANON_KEY=fixture-anon-key\n'
} > "$ROOT/no-url.env"
run_builder no-url --env-file "$ROOT/no-url.env"
assert_status no-url 1
assert_contains "$ROOT/no-url/stderr.txt" "SUPABASE_URL is missing"
log "negative fixture ok: missing Supabase URL fails before Flutter"

run_builder prod-rejected --env-file "$env_file" --flavor prod --mode debug
assert_status prod-rejected 1
assert_contains "$ROOT/prod-rejected/stderr.txt" "staging build refuses prod flavor"
log "negative fixture ok: prod flavor is rejected by default"

run_builder invalid-appbundle --env-file "$env_file" --flavor dev --mode debug --kind appbundle
assert_status invalid-appbundle 1
assert_contains "$ROOT/invalid-appbundle/stderr.txt" "appbundle builds must use --mode release"
log "negative fixture ok: appbundle requires release mode"

run_builder debug-apk --env-file "$env_file" --flavor dev --mode debug --kind apk
assert_status debug-apk 0
assert_success_report debug-apk dev debug apk app-dev-debug.apk
assert_contains "$ROOT/debug-apk/flutter.log" "build apk --debug --flavor dev"
log "pass fixture ok: debug APK writes artifact and redacted report"

run_builder prod-allowed --env-file "$env_file" --flavor prod --mode debug --kind apk --allow-prod-flavor
assert_status prod-allowed 0
assert_success_report prod-allowed prod debug apk app-prod-debug.apk
assert_contains "$ROOT/prod-allowed/flutter.log" "build apk --debug --flavor prod"
log "pass fixture ok: prod flavor only builds when explicitly allowed"

run_builder release-appbundle --env-file "$env_file" --flavor qa --mode release --kind appbundle
assert_status release-appbundle 0
assert_success_report release-appbundle qa release appbundle app-qa-release.aab
assert_contains "$ROOT/release-appbundle/flutter.log" "build appbundle --release --flavor qa"
log "pass fixture ok: release appbundle writes artifact and redacted report"

log "all SaaS staging APK builder self-tests passed"
