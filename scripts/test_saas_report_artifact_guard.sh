#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
GUARD="$SCRIPT_DIR/guard_saas_report_artifacts.sh"

usage() {
  cat <<'EOF'
Usage:
  scripts/test_saas_report_artifact_guard.sh [--keep-fixtures]

Creates local report artifact fixtures and validates the SaaS/release artifact
guard contract. This is host-only and does not read real secrets.
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
      printf '[saas-report-artifact-guard-test] unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

cd "$APP_DIR"

ROOT="$(mktemp -d /tmp/jive-saas-report-artifact-guard-test.XXXXXX)"

cleanup() {
  if [[ "$KEEP_FIXTURES" -eq 1 ]]; then
    printf '[saas-report-artifact-guard-test] kept fixtures: %s\n' "$ROOT"
  else
    rm -rf "$ROOT"
  fi
}

trap cleanup EXIT INT TERM

log() {
  printf '[saas-report-artifact-guard-test] %s\n' "$*"
}

fail() {
  printf '[saas-report-artifact-guard-test] FAIL: %s\n' "$*" >&2
  exit 1
}

assert_pass() {
  local label="$1"
  shift
  local stdout_file="$ROOT/$label.stdout"
  local stderr_file="$ROOT/$label.stderr"

  if ! "$@" > "$stdout_file" 2> "$stderr_file"; then
    cat "$stdout_file" >&2
    cat "$stderr_file" >&2
    fail "$label expected pass"
  fi

  log "pass fixture ok: $label"
}

assert_fail() {
  local label="$1"
  local expected="$2"
  shift 2
  local stdout_file="$ROOT/$label.stdout"
  local stderr_file="$ROOT/$label.stderr"

  if "$@" > "$stdout_file" 2> "$stderr_file"; then
    cat "$stdout_file" >&2
    fail "$label expected failure"
  fi

  if ! grep -Fq -- "$expected" "$stderr_file"; then
    cat "$stderr_file" >&2
    fail "$label expected stderr to contain: $expected"
  fi

  log "negative fixture ok: $label"
}

clean_dir="$ROOT/clean"
mkdir -p "$clean_dir/nested"
printf '# Summary\n\nNo secrets here.\n' > "$clean_dir/summary.md"
printf '{"status":"passed"}\n' > "$clean_dir/nested/report.json"

assert_pass clean-root "$GUARD" --label "Clean reports" --root "$clean_dir"
assert_pass missing-root "$GUARD" --label "Missing reports" --root "$ROOT/missing"

blocked_dir="$ROOT/blocked"
mkdir -p "$blocked_dir"
printf 'SUPABASE_ANON_KEY=fake\n' > "$blocked_dir/staging.env"
assert_fail blocked-env-file "blocked sensitive-looking files" \
  "$GUARD" --label "Blocked reports" --root "$blocked_dir"

blocked_name_dir="$ROOT/blocked-name"
mkdir -p "$blocked_name_dir"
printf '{}\n' > "$blocked_name_dir/runtime-dart-defines.json"
assert_fail blocked-dart-defines "runtime-dart-defines.json" \
  "$GUARD" --label "Blocked reports" --root "$blocked_name_dir"

multi_root_dir="$ROOT/multi-root"
mkdir -p "$multi_root_dir"
printf 'private\n' > "$multi_root_dir/release.pem"
assert_fail multi-root-blocked "release.pem" \
  "$GUARD" --label "Multi reports" --root "$clean_dir" --root "$multi_root_dir"

leak_dir="$ROOT/leak"
mkdir -p "$leak_dir"
fake_secret="jive_fake_secret_value_12345"
printf 'summary contains %s\n' "$fake_secret" > "$leak_dir/summary.md"
assert_fail leaked-secret-value "FAKE_SECRET" \
  env FAKE_SECRET="$fake_secret" "$GUARD" \
    --label "Leaky reports" \
    --root "$leak_dir" \
    --secret-env FAKE_SECRET

short_value_dir="$ROOT/short-value"
mkdir -p "$short_value_dir"
printf 'abc123\n' > "$short_value_dir/summary.md"
assert_pass short-secret-value-ignored \
  env SHORT_SECRET="abc123" "$GUARD" \
    --label "Short value reports" \
    --root "$short_value_dir" \
    --secret-env SHORT_SECRET

unset_value_dir="$ROOT/unset-value"
mkdir -p "$unset_value_dir"
printf 'still clean\n' > "$unset_value_dir/summary.md"
assert_pass unset-secret-env-ignored \
  "$GUARD" \
    --label "Unset value reports" \
    --root "$unset_value_dir" \
    --secret-env UNSET_SECRET_VALUE

log "all artifact guard self-tests passed"
