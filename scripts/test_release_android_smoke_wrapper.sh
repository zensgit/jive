#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="$SCRIPT_DIR/run_release_android_smoke.sh"

usage() {
  cat <<'EOF'
Usage:
  scripts/test_release_android_smoke_wrapper.sh [--keep-fixtures]

Runs host-only fixture tests for scripts/run_release_android_smoke.sh by copying
the wrapper into a temporary app skeleton with fake runner/verifier/renderer
scripts. No real Flutter build, Android SDK, adb, emulator, or device is used.
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
      printf '[release-android-wrapper-test] unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

ROOT="$(mktemp -d /tmp/jive-release-android-wrapper-test.XXXXXX)"

cleanup() {
  if [[ "$KEEP_FIXTURES" -eq 1 ]]; then
    printf '[release-android-wrapper-test] kept fixtures: %s\n' "$ROOT"
  else
    rm -rf "$ROOT"
  fi
}

trap cleanup EXIT INT TERM

log() {
  printf '[release-android-wrapper-test] %s\n' "$*"
}

fail() {
  printf '[release-android-wrapper-test] FAIL: %s\n' "$*" >&2
  exit 1
}

assert_contains() {
  local file="$1"
  local expected="$2"
  grep -Fq -- "$expected" "$file" || fail "expected '$expected' in $file"
}

create_fixture_app() {
  local app_dir="$1"
  local scripts_dir="$app_dir/scripts"

  mkdir -p "$scripts_dir"
  cp "$TARGET" "$scripts_dir/run_release_android_smoke.sh"
  chmod +x "$scripts_dir/run_release_android_smoke.sh"

  cat > "$scripts_dir/run_android_local_feature_smoke.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

log_file="${JIVE_FAKE_RELEASE_WRAPPER_LOG:?JIVE_FAKE_RELEASE_WRAPPER_LOG is required}"
artifact_dir=""
previous=""

{
  printf 'runner\n'
  for arg in "$@"; do
    printf 'arg=%s\n' "$arg"
    if [[ "$previous" == "--artifact-dir" ]]; then
      artifact_dir="$arg"
    fi
    previous="$arg"
  done
} >> "$log_file"

if [[ -z "$artifact_dir" ]]; then
  printf 'fake runner missing --artifact-dir\n' >&2
  exit 2
fi

mkdir -p "$artifact_dir"
cat > "$artifact_dir/summary.md" <<SUMMARY
# Fake Android Smoke

- status: passed
- artifactDir: $artifact_dir
SUMMARY
EOF

  cat > "$scripts_dir/verify_release_android_smoke_artifacts.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

log_file="${JIVE_FAKE_RELEASE_WRAPPER_LOG:?JIVE_FAKE_RELEASE_WRAPPER_LOG is required}"
artifact_dir="${1:-}"
[[ -n "$artifact_dir" ]] || {
  printf 'fake verifier missing artifact dir\n' >&2
  exit 2
}
[[ -f "$artifact_dir/summary.md" ]] || {
  printf 'fake verifier missing summary.md in %s\n' "$artifact_dir" >&2
  exit 3
}
{
  printf 'verifier\n'
  printf 'artifact=%s\n' "$artifact_dir"
} >> "$log_file"
printf 'verified\n' > "$artifact_dir/release_android_smoke_artifact_verification.md"
EOF

  cat > "$scripts_dir/render_release_android_smoke_summary.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

log_file="${JIVE_FAKE_RELEASE_WRAPPER_LOG:?JIVE_FAKE_RELEASE_WRAPPER_LOG is required}"
artifact_dir="${1:-}"
[[ -n "$artifact_dir" ]] || {
  printf 'fake renderer missing artifact dir\n' >&2
  exit 2
}
[[ -f "$artifact_dir/release_android_smoke_artifact_verification.md" ]] || {
  printf 'fake renderer expected verifier output in %s\n' "$artifact_dir" >&2
  exit 3
}
{
  printf 'renderer\n'
  printf 'artifact=%s\n' "$artifact_dir"
} >> "$log_file"
printf '# latest\n' > "$artifact_dir/latest.md"
EOF

  chmod +x \
    "$scripts_dir/run_android_local_feature_smoke.sh" \
    "$scripts_dir/verify_release_android_smoke_artifacts.sh" \
    "$scripts_dir/render_release_android_smoke_summary.sh"
}

run_fixture() {
  local label="$1"
  shift

  local fixture_dir="$ROOT/$label"
  local app_dir="$fixture_dir/app"
  mkdir -p "$fixture_dir"
  create_fixture_app "$app_dir"

  set +e
  env JIVE_FAKE_RELEASE_WRAPPER_LOG="$fixture_dir/calls.log" \
    "$app_dir/scripts/run_release_android_smoke.sh" "$@" \
    > "$fixture_dir/stdout.txt" 2> "$fixture_dir/stderr.txt"
  local status=$?
  set -e

  printf '%s\n' "$status" > "$fixture_dir/status.txt"
}

run_fixture_with_env() {
  local label="$1"
  shift

  local fixture_dir="$ROOT/$label"
  local app_dir="$fixture_dir/app"
  mkdir -p "$fixture_dir"
  create_fixture_app "$app_dir"

  set +e
  env \
    JIVE_FAKE_RELEASE_WRAPPER_LOG="$fixture_dir/calls.log" \
    "$@" \
    "$app_dir/scripts/run_release_android_smoke.sh" \
    > "$fixture_dir/stdout.txt" 2> "$fixture_dir/stderr.txt"
  local status=$?
  set -e

  printf '%s\n' "$status" > "$fixture_dir/status.txt"
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
    printf '--- calls ---\n' >&2
    cat "$ROOT/$label/calls.log" >&2 || true
    fail "$label expected exit $expected, got $actual"
  fi
}

assert_arg_sequence() {
  local label="$1"
  shift

  python3 - "$ROOT/$label/calls.log" "$@" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
expected = list(sys.argv[2:])
args = [
    line[4:]
    for line in path.read_text(encoding="utf-8").splitlines()
    if line.startswith("arg=")
]

cursor = 0
for value in expected:
    try:
        cursor = args.index(value, cursor) + 1
    except ValueError:
        raise SystemExit(f"missing expected argument {value!r} after position {cursor}; args={args!r}")
PY
}

assert_last_arg_value() {
  local label="$1"
  local flag="$2"
  local expected="$3"

  python3 - "$ROOT/$label/calls.log" "$flag" "$expected" <<'PY'
import sys
from pathlib import Path

path, flag, expected = sys.argv[1:]
args = [
    line[4:]
    for line in Path(path).read_text(encoding="utf-8").splitlines()
    if line.startswith("arg=")
]
values = [args[i + 1] for i, arg in enumerate(args[:-1]) if arg == flag]
if not values:
    raise SystemExit(f"missing flag {flag!r}; args={args!r}")
actual = values[-1]
if actual != expected:
    raise SystemExit(f"expected last {flag} value {expected!r}, got {actual!r}; args={args!r}")
PY
}

assert_post_steps_used_artifact() {
  local label="$1"
  local expected="$2"
  assert_contains "$ROOT/$label/calls.log" "verifier"
  assert_contains "$ROOT/$label/calls.log" "renderer"
  assert_contains "$ROOT/$label/calls.log" "artifact=$expected"
  [[ -f "$expected/latest.md" ]] || fail "$label expected latest.md in $expected"
}

"$TARGET" --help >/dev/null
log "help fixture ok: wrapper help exits without dependencies"

run_fixture default
assert_status default 0
default_artifact="$(grep '^arg=' "$ROOT/default/calls.log" | sed -n '/^arg=--artifact-dir$/{n;s/^arg=//;p;q;}')"
[[ "$default_artifact" == "$ROOT/default/app/build/reports/release-android-smoke/"* ]] \
  || fail "default artifact dir should be under fixture app build reports, got $default_artifact"
assert_arg_sequence default --scenario all --fresh-install --allow-uninstall-on-signature-mismatch --artifact-dir "$default_artifact"
assert_post_steps_used_artifact default "$default_artifact"
log "pass fixture ok: default wrapper delegates full smoke lane"

env_artifact="$ROOT/env-artifacts"
run_fixture_with_env env-overrides \
  JIVE_RELEASE_ANDROID_SMOKE_SCENARIO=guest-home \
  JIVE_RELEASE_ANDROID_SMOKE_ARTIFACT_DIR="$env_artifact"
assert_status env-overrides 0
assert_arg_sequence env-overrides --scenario guest-home --artifact-dir "$env_artifact"
assert_post_steps_used_artifact env-overrides "$env_artifact"
log "pass fixture ok: environment overrides scenario and artifact dir"

cli_artifact="$ROOT/cli-artifacts"
run_fixture cli-artifact \
  --skip-build \
  --apk-path "$ROOT/app-dev-debug.apk" \
  --artifact-dir "$cli_artifact" \
  --preserve-data
assert_status cli-artifact 0
cli_default_artifact="$(grep '^arg=' "$ROOT/cli-artifact/calls.log" | sed -n '/^arg=--artifact-dir$/{n;s/^arg=//;p;q;}')"
[[ "$cli_default_artifact" == "$ROOT/cli-artifact/app/build/reports/release-android-smoke/"* ]] \
  || fail "CLI fixture default artifact dir should be under fixture app build reports, got $cli_default_artifact"
assert_arg_sequence cli-artifact \
  --scenario all \
  --artifact-dir "$cli_default_artifact" \
  --skip-build \
  --apk-path "$ROOT/app-dev-debug.apk" \
  --artifact-dir "$cli_artifact" \
  --preserve-data
assert_last_arg_value cli-artifact --artifact-dir "$cli_artifact"
assert_post_steps_used_artifact cli-artifact "$cli_artifact"
log "pass fixture ok: CLI artifact override is used for verification and summary"

scenario_artifact="$ROOT/scenario-artifacts"
run_fixture scenario-pass-through \
  --scenario transaction-entry \
  --artifact-dir "$scenario_artifact"
assert_status scenario-pass-through 0
scenario_default_artifact="$(grep '^arg=' "$ROOT/scenario-pass-through/calls.log" | sed -n '/^arg=--artifact-dir$/{n;s/^arg=//;p;q;}')"
[[ "$scenario_default_artifact" == "$ROOT/scenario-pass-through/app/build/reports/release-android-smoke/"* ]] \
  || fail "scenario fixture default artifact dir should be under fixture app build reports, got $scenario_default_artifact"
assert_arg_sequence scenario-pass-through --scenario all --artifact-dir "$scenario_default_artifact" --scenario transaction-entry --artifact-dir "$scenario_artifact"
assert_last_arg_value scenario-pass-through --scenario transaction-entry
assert_post_steps_used_artifact scenario-pass-through "$scenario_artifact"
log "pass fixture ok: pass-through arguments can override default scenario"

log "all release Android smoke wrapper self-tests passed"
