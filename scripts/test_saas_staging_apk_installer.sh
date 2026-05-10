#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="$SCRIPT_DIR/install_saas_staging_apk.sh"

usage() {
  cat <<'EOF'
Usage:
  scripts/test_saas_staging_apk_installer.sh [--keep-fixtures]

Runs host-only fixture tests for scripts/install_saas_staging_apk.sh using a
fake adb binary. No real Android device, emulator, APK install, or app data is
required.
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
      printf '[saas-apk-installer-test] unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

ROOT="$(mktemp -d /tmp/jive-saas-apk-installer-test.XXXXXX)"
BIN_DIR="$ROOT/bin"
APK_FILE="$ROOT/jive-staging.apk"
PACKAGE_ID="com.example.jive.dev"
mkdir -p "$BIN_DIR"
printf 'fixture apk\n' > "$APK_FILE"

cleanup() {
  if [[ "$KEEP_FIXTURES" -eq 1 ]]; then
    printf '[saas-apk-installer-test] kept fixtures: %s\n' "$ROOT"
  else
    rm -rf "$ROOT"
  fi
}

trap cleanup EXIT INT TERM

log() {
  printf '[saas-apk-installer-test] %s\n' "$*"
}

fail() {
  printf '[saas-apk-installer-test] FAIL: %s\n' "$*" >&2
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
mode="${JIVE_FAKE_ADB_INSTALL_MODE:-success}"
backup_fail="${JIVE_FAKE_ADB_BACKUP_FAIL:-0}"
count_file="${JIVE_FAKE_ADB_INSTALL_COUNT_FILE:?JIVE_FAKE_ADB_INSTALL_COUNT_FILE is required}"

if [[ "${1:-}" == "-s" ]]; then
  printf 'serial=%s\n' "${2:-}" >> "$log_file"
  shift 2
fi

printf '%s\n' "$*" >> "$log_file"

case "${1:-}" in
  get-serialno)
    printf 'fixture-serial\n'
    ;;
  install)
    count=0
    if [[ -f "$count_file" ]]; then
      count="$(cat "$count_file")"
    fi
    count=$((count + 1))
    printf '%s\n' "$count" > "$count_file"

    case "$mode" in
      success)
        printf 'Success\n'
        ;;
      signature-mismatch)
        printf 'Failure [INSTALL_FAILED_UPDATE_INCOMPATIBLE]\n'
        exit 1
        ;;
      signature-mismatch-then-success)
        if [[ "$count" -eq 1 ]]; then
          printf 'Failure [INSTALL_FAILED_UPDATE_INCOMPATIBLE]\n'
          exit 1
        fi
        printf 'Success\n'
        ;;
      *)
        printf 'unknown fake install mode: %s\n' "$mode" >&2
        exit 2
        ;;
    esac
    ;;
  uninstall)
    printf 'Success\n'
    ;;
  exec-out)
    if [[ "$backup_fail" == "1" ]]; then
      printf 'run-as: Package not debuggable\n' >&2
      exit 1
    fi
    tmp_dir="$(mktemp -d)"
    printf 'fixture app data\n' > "$tmp_dir/fixture.txt"
    tar -cf - -C "$tmp_dir" fixture.txt
    rm -rf "$tmp_dir"
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
        cat <<'DUMPSYS'
versionCode=100
versionName=1.0.0-fixture
firstInstallTime=2026-05-10 20:00:00
lastUpdateTime=2026-05-10 20:00:00
DUMPSYS
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

run_installer() {
  local label="$1"
  local install_mode="$2"
  local backup_fail="$3"
  shift 3

  local out_dir="$ROOT/$label"
  mkdir -p "$out_dir"
  : > "$out_dir/adb.log"

  set +e
  env \
    PATH="$BIN_DIR:$PATH" \
    JIVE_FAKE_ADB_LOG="$out_dir/adb.log" \
    JIVE_FAKE_ADB_INSTALL_MODE="$install_mode" \
    JIVE_FAKE_ADB_BACKUP_FAIL="$backup_fail" \
    JIVE_FAKE_ADB_INSTALL_COUNT_FILE="$out_dir/install-count.txt" \
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

install_count() {
  local label="$1"
  cat "$ROOT/$label/install-count.txt" 2>/dev/null || printf '0'
}

write_fake_adb

run_installer missing-apk success 0 --adb "$BIN_DIR/adb" --apk "$ROOT/missing.apk" --package "$PACKAGE_ID"
assert_status missing-apk 1
assert_contains "$ROOT/missing-apk/stderr.txt" "apk not found"
log "negative fixture ok: missing APK fails before adb install"

run_installer success success 0 \
  --adb "$BIN_DIR/adb" \
  --apk "$APK_FILE" \
  --device emulator-5554 \
  --package "$PACKAGE_ID"
assert_status success 0
assert_contains "$ROOT/success/stdout.txt" "Success"
assert_contains "$ROOT/success/stdout.txt" "versionName=1.0.0-fixture"
assert_contains "$ROOT/success/adb.log" "serial=emulator-5554"
assert_contains "$ROOT/success/adb.log" "install -r $APK_FILE"
assert_not_contains "$ROOT/success/adb.log" "uninstall $PACKAGE_ID"
[[ "$(install_count success)" == "1" ]] || fail "success expected one install attempt"
log "pass fixture ok: APK installs without uninstall on compatible signature"

run_installer signature-blocked signature-mismatch 0 \
  --adb "$BIN_DIR/adb" \
  --apk "$APK_FILE" \
  --package "$PACKAGE_ID"
assert_status signature-blocked 1
assert_contains "$ROOT/signature-blocked/stderr.txt" "signature mismatch"
assert_not_contains "$ROOT/signature-blocked/adb.log" "uninstall $PACKAGE_ID"
[[ "$(install_count signature-blocked)" == "1" ]] || fail "signature-blocked expected one install attempt"
log "negative fixture ok: signature mismatch does not uninstall by default"

run_installer signature-allowed signature-mismatch-then-success 0 \
  --adb "$BIN_DIR/adb" \
  --apk "$APK_FILE" \
  --package "$PACKAGE_ID" \
  --allow-uninstall-on-signature-mismatch
assert_status signature-allowed 0
assert_contains "$ROOT/signature-allowed/adb.log" "uninstall $PACKAGE_ID"
[[ "$(install_count signature-allowed)" == "2" ]] || fail "signature-allowed expected two install attempts"
log "pass fixture ok: explicit uninstall handles signature mismatch"

backup_dir="$ROOT/backups"
run_installer backup-success signature-mismatch-then-success 0 \
  --adb "$BIN_DIR/adb" \
  --apk "$APK_FILE" \
  --package "$PACKAGE_ID" \
  --allow-uninstall-on-signature-mismatch \
  --backup-before-uninstall "$backup_dir"
assert_status backup-success 0
assert_contains "$ROOT/backup-success/adb.log" "exec-out run-as $PACKAGE_ID tar -cf - ."
assert_contains "$ROOT/backup-success/adb.log" "uninstall $PACKAGE_ID"
compgen -G "$backup_dir/${PACKAGE_ID}-appdata-*.tar" >/dev/null \
  || fail "backup-success expected backup tar"
compgen -G "$backup_dir/${PACKAGE_ID}-appdata-*.tar.list" >/dev/null \
  || fail "backup-success expected backup tar listing"
log "pass fixture ok: backup completes before explicit uninstall"

blocked_backup_dir="$ROOT/blocked-backups"
run_installer backup-fails signature-mismatch-then-success 1 \
  --adb "$BIN_DIR/adb" \
  --apk "$APK_FILE" \
  --package "$PACKAGE_ID" \
  --allow-uninstall-on-signature-mismatch \
  --backup-before-uninstall "$blocked_backup_dir"
assert_status backup-fails 1
assert_contains "$ROOT/backup-fails/stderr.txt" "uninstall aborted"
assert_not_contains "$ROOT/backup-fails/adb.log" "uninstall $PACKAGE_ID"
[[ "$(install_count backup-fails)" == "1" ]] || fail "backup-fails expected one install attempt"
log "negative fixture ok: failed backup aborts uninstall"

log "all SaaS staging APK installer self-tests passed"
