#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="$SCRIPT_DIR/run_android_local_feature_smoke.sh"

usage() {
  cat <<'EOF'
Usage:
  scripts/test_android_local_feature_smoke_runner.sh [--keep-fixtures]

Runs host-only fixture tests for scripts/run_android_local_feature_smoke.sh with
fake flutter, adb, and emulator binaries. No Flutter build, Android SDK, adb
server, emulator, APK install, or physical device is required.
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
      printf '[android-local-feature-runner-test] unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

ROOT="$(mktemp -d /tmp/jive-android-local-feature-runner-test.XXXXXX)"

cleanup() {
  if [[ "$KEEP_FIXTURES" -eq 1 ]]; then
    printf '[android-local-feature-runner-test] kept fixtures: %s\n' "$ROOT"
  else
    rm -rf "$ROOT"
  fi
}

trap cleanup EXIT INT TERM

log() {
  printf '[android-local-feature-runner-test] %s\n' "$*"
}

fail() {
  printf '[android-local-feature-runner-test] FAIL: %s\n' "$*" >&2
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
  if [[ -f "$file" ]] && grep -Fq -- "$unexpected" "$file"; then
    fail "did not expect '$unexpected' in $file"
  fi
}

write_fake_xml() {
  cat <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<hierarchy rotation="0">
  <node text="访客" content-desc="" bounds="[0,0][160,80]" clickable="true" focusable="true" long-clickable="false" checked="false" selected="false" />
  <node text="净资产" content-desc="" bounds="[0,90][220,170]" clickable="false" focusable="false" long-clickable="false" checked="false" selected="false" />
  <node text="记一笔" content-desc="" bounds="[0,180][180,260]" clickable="true" focusable="true" long-clickable="false" checked="false" selected="false" />
  <node text="支出" content-desc="" bounds="[0,270][140,350]" clickable="true" focusable="true" long-clickable="false" checked="false" selected="false" />
  <node text="收入" content-desc="" bounds="[150,270][290,350]" clickable="true" focusable="true" long-clickable="false" checked="false" selected="false" />
  <node text="转账" content-desc="" bounds="[300,270][440,350]" clickable="true" focusable="true" long-clickable="false" checked="false" selected="false" />
  <node text="餐饮" content-desc="" bounds="[0,360][160,440]" clickable="true" focusable="true" long-clickable="false" checked="false" selected="false" />
  <node text="现金" content-desc="" bounds="[170,360][330,440]" clickable="true" focusable="true" long-clickable="false" checked="false" selected="false" />
  <node text="再记" content-desc="" bounds="[340,360][500,440]" clickable="true" focusable="true" long-clickable="false" checked="false" selected="false" />
  <node text="+ 长按×" content-desc="" bounds="[0,450][180,530]" clickable="true" focusable="true" long-clickable="true" checked="false" selected="false" />
  <node text="- 长按÷" content-desc="" bounds="[190,450][370,530]" clickable="true" focusable="true" long-clickable="true" checked="false" selected="false" />
  <node text="展开备注" content-desc="" bounds="[380,450][560,530]" clickable="true" focusable="true" long-clickable="false" checked="false" selected="false" />
  <node text="1" content-desc="" bounds="[0,540][120,620]" clickable="true" focusable="true" long-clickable="false" checked="false" selected="false" />
  <node text="2" content-desc="" bounds="[130,540][250,620]" clickable="true" focusable="true" long-clickable="false" checked="false" selected="false" />
  <node text="3" content-desc="" bounds="[260,540][380,620]" clickable="true" focusable="true" long-clickable="false" checked="false" selected="false" />
  <node text="当前×" content-desc="" bounds="[0,630][180,710]" clickable="false" focusable="false" long-clickable="false" checked="false" selected="false" />
  <node text="× 当前×" content-desc="" bounds="[190,630][370,710]" clickable="true" focusable="true" long-clickable="true" checked="false" selected="false" />
  <node text="1+2×3" content-desc="" bounds="[0,720][240,800]" clickable="false" focusable="false" long-clickable="false" checked="false" selected="false" />
  <node text="7.00" content-desc="" bounds="[250,720][430,800]" clickable="false" focusable="false" long-clickable="false" checked="false" selected="false" />
</hierarchy>
EOF
}

create_fixture_app() {
  local app_dir="$1"
  local bin_dir="$2"
  local scripts_dir="$app_dir/scripts"

  mkdir -p "$scripts_dir" "$bin_dir"
  cp "$TARGET" "$scripts_dir/run_android_local_feature_smoke.sh"
  chmod +x "$scripts_dir/run_android_local_feature_smoke.sh"

  cat > "$bin_dir/flutter" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'flutter:%s\n' "$*" >> "${JIVE_FAKE_ANDROID_SMOKE_LOG:?JIVE_FAKE_ANDROID_SMOKE_LOG is required}"
EOF

  cat > "$bin_dir/emulator" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'emulator:%s\n' "$*" >> "${JIVE_FAKE_ANDROID_SMOKE_LOG:?JIVE_FAKE_ANDROID_SMOKE_LOG is required}"
EOF

  cat > "$bin_dir/adb" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

log_file="${JIVE_FAKE_ANDROID_SMOKE_LOG:?JIVE_FAKE_ANDROID_SMOKE_LOG is required}"
state_dir="${JIVE_FAKE_ANDROID_SMOKE_STATE_DIR:?JIVE_FAKE_ANDROID_SMOKE_STATE_DIR is required}"

printf 'adb:%s\n' "$*" >> "$log_file"

if [[ "${1:-}" == "-s" ]]; then
  shift 2
fi

case "${1:-}" in
  get-state)
    printf 'device\n'
    ;;
  uninstall)
    printf 'Success\n'
    ;;
  install)
    if [[ "${JIVE_FAKE_ANDROID_SMOKE_INSTALL_MISMATCH_ONCE:-0}" == "1" && ! -f "$state_dir/install-retried" ]]; then
      touch "$state_dir/install-retried"
      printf 'Failure [INSTALL_FAILED_UPDATE_INCOMPATIBLE]\n'
      exit 1
    fi
    printf 'Success\n'
    ;;
  logcat)
    ;;
  exec-out)
    case "${2:-}" in
      screencap)
        printf 'fake-png'
        ;;
      uiautomator)
        cat "${JIVE_FAKE_ANDROID_SMOKE_XML:?JIVE_FAKE_ANDROID_SMOKE_XML is required}"
        ;;
      *)
        ;;
    esac
    ;;
  shell)
    case "${2:-}" in
      getprop)
        if [[ "${3:-}" == "sys.boot_completed" ]]; then
          printf '1\n'
        fi
        ;;
      am)
        printf 'Starting: Intent { cmp=%s }\n' "${5:-unknown}"
        ;;
      input)
        ;;
      *)
        ;;
    esac
    ;;
  *)
    ;;
esac
EOF

  chmod +x "$bin_dir/flutter" "$bin_dir/emulator" "$bin_dir/adb"
}

run_fixture() {
  local label="$1"
  shift
  local -a extra_env=()

  while (($#)) && [[ "$1" == *=* ]]; do
    extra_env+=("$1")
    shift
  done

  local fixture_dir="$ROOT/$label"
  local app_dir="$fixture_dir/app"
  local bin_dir="$fixture_dir/bin"
  local state_dir="$fixture_dir/state"
  local xml_file="$fixture_dir/fake-ui.xml"
  mkdir -p "$fixture_dir" "$state_dir"
  write_fake_xml > "$xml_file"
  create_fixture_app "$app_dir" "$bin_dir"

  set +e
  if ((${#extra_env[@]})); then
    env \
      FLUTTER_BIN="$bin_dir/flutter" \
      ADB_BIN="$bin_dir/adb" \
      EMULATOR_BIN="$bin_dir/emulator" \
      JIVE_FAKE_ANDROID_SMOKE_LOG="$fixture_dir/calls.log" \
      JIVE_FAKE_ANDROID_SMOKE_STATE_DIR="$state_dir" \
      JIVE_FAKE_ANDROID_SMOKE_XML="$xml_file" \
      "${extra_env[@]}" \
      "$app_dir/scripts/run_android_local_feature_smoke.sh" "$@" \
      > "$fixture_dir/stdout.txt" 2> "$fixture_dir/stderr.txt"
  else
    env \
      FLUTTER_BIN="$bin_dir/flutter" \
      ADB_BIN="$bin_dir/adb" \
      EMULATOR_BIN="$bin_dir/emulator" \
      JIVE_FAKE_ANDROID_SMOKE_LOG="$fixture_dir/calls.log" \
      JIVE_FAKE_ANDROID_SMOKE_STATE_DIR="$state_dir" \
      JIVE_FAKE_ANDROID_SMOKE_XML="$xml_file" \
      "$app_dir/scripts/run_android_local_feature_smoke.sh" "$@" \
      > "$fixture_dir/stdout.txt" 2> "$fixture_dir/stderr.txt"
  fi
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
    printf '%s\n' '--- stdout ---' >&2
    cat "$ROOT/$label/stdout.txt" >&2 || true
    printf '%s\n' '--- stderr ---' >&2
    cat "$ROOT/$label/stderr.txt" >&2 || true
    printf '%s\n' '--- calls ---' >&2
    cat "$ROOT/$label/calls.log" >&2 || true
    fail "$label expected exit $expected, got $actual"
  fi
}

assert_summary_status() {
  local label="$1"
  local artifact_dir="$2"
  local expected_scenario="$3"
  local summary="$artifact_dir/summary.md"

  [[ -f "$summary" ]] || fail "$label expected summary at $summary"
  assert_contains "$summary" "- status: passed"
  assert_contains "$summary" "- scenario: $expected_scenario"
  assert_contains "$summary" "- artifactDir: $artifact_dir"
}

"$TARGET" --help >/dev/null
log "help fixture ok: runner help exits without dependencies"

set +e
"$TARGET" --scenario not-a-real-scenario > "$ROOT/invalid.stdout.txt" 2> "$ROOT/invalid.stderr.txt"
invalid_status=$?
set -e
[[ "$invalid_status" == "2" ]] || fail "invalid scenario expected exit 2, got $invalid_status"
assert_contains "$ROOT/invalid.stderr.txt" "unknown scenario"
log "invalid scenario fixture ok: parse errors fail before tool resolution"

guest_artifact="$ROOT/guest-artifacts"
run_fixture guest \
  --skip-build \
  --skip-install \
  --skip-emulator-launch \
  --skip-onboarding \
  --scenario guest-home \
  --artifact-dir "$guest_artifact"
assert_status guest 0
assert_summary_status guest "$guest_artifact" guest-home
assert_contains "$ROOT/guest/calls.log" "adb:-s emulator-5554 shell am start -n com.jivemoney.app.dev/com.jive.app.MainActivity"
assert_not_contains "$ROOT/guest/calls.log" "flutter:"
assert_not_contains "$ROOT/guest/calls.log" "emulator:"
log "guest fixture ok: skip-build/install/emulator/onboarding still launches and summarizes"

transaction_artifact="$ROOT/transaction-artifacts"
run_fixture transaction \
  --skip-build \
  --skip-install \
  --skip-emulator-launch \
  --skip-onboarding \
  --scenario transaction-entry \
  --artifact-dir "$transaction_artifact"
assert_status transaction 0
assert_summary_status transaction "$transaction_artifact" transaction-entry
assert_contains "$transaction_artifact/transaction_entry_expression.summary.txt" "node: 1+2×3"
assert_contains "$transaction_artifact/transaction_entry_expression.summary.txt" "node: 7.00"
assert_contains "$ROOT/transaction/calls.log" "shell input swipe"
log "transaction fixture ok: keypad/operator smoke works with fake UI hierarchy"

install_artifact="$ROOT/install-artifacts"
install_apk="$ROOT/fake-app-dev-debug.apk"
printf 'fake-apk' > "$install_apk"
run_fixture install-retry \
  JIVE_FAKE_ANDROID_SMOKE_INSTALL_MISMATCH_ONCE=1 \
  --skip-build \
  --skip-emulator-launch \
  --skip-onboarding \
  --scenario guest-home \
  --artifact-dir "$install_artifact" \
  --apk-path "$install_apk" \
  --fresh-install \
  --allow-uninstall-on-signature-mismatch
assert_status install-retry 0
assert_summary_status install-retry "$install_artifact" guest-home
install_count="$(grep -c ' install -r ' "$ROOT/install-retry/calls.log")"
[[ "$install_count" == "2" ]] || fail "expected two install attempts after signature mismatch, got $install_count"
assert_contains "$ROOT/install-retry/calls.log" "adb:-s emulator-5554 uninstall com.jivemoney.app.dev"
assert_contains "$install_artifact/install.log" "INSTALL_FAILED_UPDATE_INCOMPATIBLE"
log "install fixture ok: signature mismatch retry uninstalls and reinstalls"

log "all Android local feature smoke runner self-tests passed"
