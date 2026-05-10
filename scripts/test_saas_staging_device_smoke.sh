#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="$SCRIPT_DIR/run_saas_staging_device_smoke.sh"

usage() {
  cat <<'EOF'
Usage:
  scripts/test_saas_staging_device_smoke.sh [--keep-fixtures]

Runs host-only fixture tests for scripts/run_saas_staging_device_smoke.sh using
a fake adb binary. No real Android device, emulator, APK install, UI session, or
app data access is required.
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
      printf '[saas-device-smoke-test] unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

ROOT="$(mktemp -d /tmp/jive-saas-device-smoke-test.XXXXXX)"
BIN_DIR="$ROOT/bin"
APK_FILE="$ROOT/jive-staging.apk"
PACKAGE_ID="com.example.jive.dev"
ACTIVITY="$PACKAGE_ID/com.jive.app.MainActivity"
mkdir -p "$BIN_DIR"
printf 'fixture apk\n' > "$APK_FILE"

cleanup() {
  if [[ "$KEEP_FIXTURES" -eq 1 ]]; then
    printf '[saas-device-smoke-test] kept fixtures: %s\n' "$ROOT"
  else
    rm -rf "$ROOT"
  fi
}

trap cleanup EXIT INT TERM

log() {
  printf '[saas-device-smoke-test] %s\n' "$*"
}

fail() {
  printf '[saas-device-smoke-test] FAIL: %s\n' "$*" >&2
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

write_fake_adb() {
  cat > "$BIN_DIR/adb" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

log_file="${JIVE_FAKE_ADB_LOG:?JIVE_FAKE_ADB_LOG is required}"
screen="${JIVE_FAKE_DEVICE_SCREEN:-home}"
pid_mode="${JIVE_FAKE_DEVICE_PID_MODE:-present}"
fatal_log="${JIVE_FAKE_DEVICE_FATAL_LOG:-0}"

if [[ "${1:-}" == "-s" ]]; then
  printf 'serial=%s\n' "${2:-}" >> "$log_file"
  shift 2
fi

printf '%s\n' "$*" >> "$log_file"

home_xml() {
  cat <<'XML'
<?xml version='1.0' encoding='UTF-8' standalone='yes' ?>
<hierarchy rotation="0">
  <node text="净资产" resource-id="net-worth" />
  <node text="最近交易" resource-id="recent-transactions" />
  <node text="访客" resource-id="guest" />
</hierarchy>
XML
}

auth_xml() {
  cat <<'XML'
<?xml version='1.0' encoding='UTF-8' standalone='yes' ?>
<hierarchy rotation="0">
  <node text="邮箱" resource-id="email" />
  <node text="跳过，以游客身份使用" resource-id="skip" />
</hierarchy>
XML
}

welcome_xml() {
  cat <<'XML'
<?xml version='1.0' encoding='UTF-8' standalone='yes' ?>
<hierarchy rotation="0">
  <node text="欢迎使用积叶" resource-id="welcome" />
</hierarchy>
XML
}

guided_xml() {
  cat <<'XML'
<?xml version='1.0' encoding='UTF-8' standalone='yes' ?>
<hierarchy rotation="0">
  <node text="可选步骤" resource-id="guided" />
  <node text="记一笔" resource-id="record" />
</hierarchy>
XML
}

case "${1:-}" in
  get-serialno)
    printf 'fixture-serial\n'
    ;;
  install)
    printf 'Success\n'
    ;;
  push)
    printf '%s: 1 file pushed\n' "${2:-file}"
    ;;
  exec-out)
    case "${2:-}" in
      screencap)
        printf '\211PNG\r\n\032\nfixture-screen\n'
        ;;
      uiautomator)
        case "$screen" in
          home) home_xml ;;
          auth) auth_xml ;;
          welcome) welcome_xml ;;
          guided) guided_xml ;;
          unknown) printf '<hierarchy rotation="0"></hierarchy>\n' ;;
          *) printf '<hierarchy rotation="0"></hierarchy>\n' ;;
        esac
        ;;
      *)
        printf '\n'
        ;;
    esac
    ;;
  logcat)
    if [[ "${2:-}" == "-c" ]]; then
      exit 0
    fi
    if [[ "$fatal_log" == "1" && "$*" == *"--pid"* ]]; then
      printf '05-10 20:00:00.000 E/flutter: Unhandled Exception: fixture\n'
    fi
    ;;
  shell)
    case "${2:-}" in
      getprop)
        case "${3:-}" in
          ro.product.model) printf 'Fixture Pixel\n' ;;
          ro.build.version.release) printf '15\n' ;;
          *) printf '\n' ;;
        esac
        ;;
      wm)
        printf 'Physical size: 1080x2400\n'
        ;;
      dumpsys)
        if [[ "${3:-}" == "package" ]]; then
          cat <<'DUMPSYS'
versionCode=100
versionName=1.0.0-fixture
firstInstallTime=2026-05-10 20:00:00
lastUpdateTime=2026-05-10 20:00:00
DUMPSYS
        else
          printf 'ResumedActivity: %s\n' "${JIVE_FAKE_DEVICE_ACTIVITY:-com.example.jive.dev/com.jive.app.MainActivity}"
        fi
        ;;
      am)
        printf 'Starting: Intent { cmp=%s }\n' "${5:-unknown}"
        ;;
      pidof)
        if [[ "$pid_mode" == "missing" ]]; then
          exit 1
        fi
        printf '4242\n'
        ;;
      run-as)
        printf '\n'
        ;;
      *)
        printf '\n'
        ;;
    esac
    ;;
  *)
    printf 'unsupported fake adb command: %s\n' "$*" >&2
    exit 2
    ;;
esac
EOF

  chmod +x "$BIN_DIR/adb"
}

run_smoke() {
  local label="$1"
  local screen="$2"
  local pid_mode="$3"
  local fatal_log="$4"
  shift 4

  local out_dir="$ROOT/$label"
  mkdir -p "$out_dir/artifacts"
  : > "$out_dir/adb.log"

  set +e
  env \
    PATH="$BIN_DIR:$PATH" \
    JIVE_FAKE_ADB_LOG="$out_dir/adb.log" \
    JIVE_FAKE_DEVICE_SCREEN="$screen" \
    JIVE_FAKE_DEVICE_PID_MODE="$pid_mode" \
    JIVE_FAKE_DEVICE_FATAL_LOG="$fatal_log" \
    JIVE_FAKE_DEVICE_ACTIVITY="$ACTIVITY" \
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
    printf '--- adb log ---\n' >&2
    cat "$ROOT/$label/adb.log" >&2 || true
    fail "$label expected exit $expected, got $actual"
  fi
}

assert_summary_pass() {
  local label="$1"
  local expected_screen="$2"
  local out_dir="$ROOT/$label/artifacts"

  [[ -f "$out_dir/summary.md" ]] || fail "$label missing summary.md"
  [[ -s "$out_dir/launch.png" ]] || fail "$label missing launch.png"
  [[ -s "$out_dir/launch.xml" ]] || fail "$label missing launch.xml"
  [[ -f "$out_dir/app-fatal-log-lines.txt" ]] || fail "$label missing fatal log scan output"
  [[ ! -s "$out_dir/app-fatal-log-lines.txt" ]] || fail "$label fatal log scan output should be empty"

  assert_contains "$out_dir/summary.md" "- detectedScreen: $expected_screen"
  assert_contains "$out_dir/summary.md" "PASS"
  assert_contains "$out_dir/detected-screen.txt" "$expected_screen"
}

write_fake_adb

run_smoke invalid-expect home present 0 \
  --adb "$BIN_DIR/adb" \
  --skip-install \
  --package "$PACKAGE_ID" \
  --expect dashboard \
  --out-dir "$ROOT/invalid-expect/artifacts"
assert_status invalid-expect 1
assert_contains "$ROOT/invalid-expect/stderr.txt" "--expect must be one of"
log "negative fixture ok: invalid expected screen fails before adb"

run_smoke invalid-wait home present 0 \
  --adb "$BIN_DIR/adb" \
  --skip-install \
  --package "$PACKAGE_ID" \
  --wait-seconds 0 \
  --out-dir "$ROOT/invalid-wait/artifacts"
assert_status invalid-wait 1
assert_contains "$ROOT/invalid-wait/stderr.txt" "--wait-seconds must be a positive integer"
log "negative fixture ok: invalid wait seconds fails before adb"

run_smoke home-skip home present 0 \
  --adb "$BIN_DIR/adb" \
  --skip-install \
  --package "$PACKAGE_ID" \
  --expect home \
  --wait-seconds 1 \
  --poll-interval-seconds 1 \
  --out-dir "$ROOT/home-skip/artifacts"
assert_status home-skip 0
assert_summary_pass home-skip home
assert_contains "$ROOT/home-skip/adb.log" "shell am start -n $ACTIVITY"
assert_not_contains "$ROOT/home-skip/adb.log" "install -r"
log "pass fixture ok: skip-install launches and detects home"

run_smoke serial-install welcome present 0 \
  --adb "$BIN_DIR/adb" \
  --apk "$APK_FILE" \
  --device emulator-5554 \
  --package "$PACKAGE_ID" \
  --expect welcome \
  --wait-seconds 1 \
  --poll-interval-seconds 1 \
  --out-dir "$ROOT/serial-install/artifacts"
assert_status serial-install 0
assert_summary_pass serial-install welcome
assert_contains "$ROOT/serial-install/adb.log" "serial=emulator-5554"
assert_contains "$ROOT/serial-install/adb.log" "install -r $APK_FILE"
assert_contains "$ROOT/serial-install/artifacts/install.log" "Success"
log "pass fixture ok: install path forwards device serial and APK"

run_smoke seed-prefs home present 0 \
  --adb "$BIN_DIR/adb" \
  --skip-install \
  --package "$PACKAGE_ID" \
  --seed-home-prefs \
  --expect home \
  --wait-seconds 1 \
  --poll-interval-seconds 1 \
  --out-dir "$ROOT/seed-prefs/artifacts"
assert_status seed-prefs 0
assert_summary_pass seed-prefs home
assert_contains "$ROOT/seed-prefs/adb.log" "push $ROOT/seed-prefs/artifacts/FlutterSharedPreferences.xml /data/local/tmp/jive_saas_smoke_prefs.xml"
assert_contains "$ROOT/seed-prefs/adb.log" "shell run-as $PACKAGE_ID mkdir -p shared_prefs"
assert_contains "$ROOT/seed-prefs/adb.log" "shell run-as $PACKAGE_ID cp /data/local/tmp/jive_saas_smoke_prefs.xml shared_prefs/FlutterSharedPreferences.xml"
log "pass fixture ok: seed-home-prefs writes Flutter shared prefs"

run_smoke expect-mismatch auth present 0 \
  --adb "$BIN_DIR/adb" \
  --skip-install \
  --package "$PACKAGE_ID" \
  --expect home \
  --wait-seconds 1 \
  --poll-interval-seconds 1 \
  --out-dir "$ROOT/expect-mismatch/artifacts"
assert_status expect-mismatch 1
assert_contains "$ROOT/expect-mismatch/stderr.txt" "expected screen 'home' but detected 'auth'"
log "negative fixture ok: expected screen mismatch fails"

run_smoke pid-missing home missing 0 \
  --adb "$BIN_DIR/adb" \
  --skip-install \
  --package "$PACKAGE_ID" \
  --expect home \
  --wait-seconds 1 \
  --poll-interval-seconds 1 \
  --out-dir "$ROOT/pid-missing/artifacts"
assert_status pid-missing 1
assert_contains "$ROOT/pid-missing/stderr.txt" "app process is not running after launch"
log "negative fixture ok: missing app pid fails"

run_smoke fatal-log home present 1 \
  --adb "$BIN_DIR/adb" \
  --skip-install \
  --package "$PACKAGE_ID" \
  --expect home \
  --wait-seconds 1 \
  --poll-interval-seconds 1 \
  --out-dir "$ROOT/fatal-log/artifacts"
assert_status fatal-log 1
assert_contains "$ROOT/fatal-log/stderr.txt" "fatal app log pattern detected"
assert_contains "$ROOT/fatal-log/artifacts/app-fatal-log-lines.txt" "Unhandled Exception"
log "negative fixture ok: fatal app logs fail smoke"

log "all SaaS staging device smoke self-tests passed"
