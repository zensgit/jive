#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

ADB="${ADB:-}"
APK_PATH="${APK_PATH:-}"
DEVICE="${ANDROID_SERIAL:-}"
PACKAGE_ID="${JIVE_ANDROID_APP_ID:-com.jivemoney.app.dev}"
ACTIVITY="${JIVE_ANDROID_ACTIVITY:-}"
OUT_DIR="${JIVE_SAAS_DEVICE_SMOKE_OUT_DIR:-}"
WAIT_SECONDS="${JIVE_SAAS_DEVICE_SMOKE_WAIT_SECONDS:-45}"
POLL_INTERVAL_SECONDS="${JIVE_SAAS_DEVICE_SMOKE_POLL_INTERVAL_SECONDS:-3}"
ADB_TIMEOUT_SECONDS="${JIVE_SAAS_DEVICE_SMOKE_ADB_TIMEOUT_SECONDS:-25}"
EXPECT_SCREEN="${JIVE_SAAS_DEVICE_SMOKE_EXPECT:-any}"
ALLOW_UNINSTALL=0
BACKUP_BEFORE_UNINSTALL_DIR=""
SKIP_INSTALL=0
SEED_HOME_PREFS=0

usage() {
  cat <<'EOF'
Usage:
  scripts/run_saas_staging_device_smoke.sh --apk <path> [options]

Options:
  --apk <path>                         APK to install before launch.
  --skip-install                       Do not install; only launch and inspect the existing package.
  --device <serial>                    adb device serial. Falls back to ANDROID_SERIAL.
  --package <id>                       Package id. Defaults to JIVE_ANDROID_APP_ID or com.jivemoney.app.dev.
  --activity <component>               Activity component. Defaults to <package>/com.jive.app.MainActivity.
  --adb <path>                         adb binary. Falls back to ADB, PATH, or common Android SDK paths.
  --out-dir <path>                     Artifact directory. Defaults to /tmp/jive-saas-device-smoke-<stamp>.
  --wait-seconds <n>                   Max seconds to wait for a recognizable screen. Defaults to 45.
  --poll-interval-seconds <n>          Seconds between UI polls while waiting. Defaults to 3.
  --adb-timeout-seconds <n>            Timeout per adb command. Defaults to 25.
  --expect <any|welcome|home|auth|guided>
                                       Expected screen state after launch. Defaults to any.
  --seed-home-prefs                    Write debug SharedPreferences to skip onboarding/guided setup/auth.
                                       This is intended for staging smoke and overwrites Flutter prefs.
  --allow-uninstall-on-signature-mismatch
                                       Pass through to install_saas_staging_apk.sh.
  --backup-before-uninstall <dir>      Pass through to install_saas_staging_apk.sh.
  --help                               Show this help.

Notes:
  This smoke lane intentionally does not tap the device. Some physical Android builds block
  adb input injection, so this script validates install, launch, UI dump, screenshot, and
  process/crash health only.
EOF
}

log() {
  printf '[saas-device-smoke] %s\n' "$*"
}

die() {
  printf '[saas-device-smoke] ERROR: %s\n' "$*" >&2
  printf '[saas-device-smoke] artifacts: %s\n' "${OUT_DIR:-not-created}" >&2
  exit 1
}

require_value() {
  local flag="${1:-}"
  local value="${2:-}"
  [[ -n "$value" ]] || die "$flag requires a value"
}

parse_args() {
  while (($#)); do
    case "$1" in
      --apk)
        require_value "$1" "${2:-}"
        APK_PATH="${2:-}"
        shift 2
        ;;
      --skip-install)
        SKIP_INSTALL=1
        shift
        ;;
      --device)
        require_value "$1" "${2:-}"
        DEVICE="${2:-}"
        shift 2
        ;;
      --package)
        require_value "$1" "${2:-}"
        PACKAGE_ID="${2:-}"
        shift 2
        ;;
      --activity)
        require_value "$1" "${2:-}"
        ACTIVITY="${2:-}"
        shift 2
        ;;
      --adb)
        require_value "$1" "${2:-}"
        ADB="${2:-}"
        shift 2
        ;;
      --out-dir)
        require_value "$1" "${2:-}"
        OUT_DIR="${2:-}"
        shift 2
        ;;
      --wait-seconds)
        require_value "$1" "${2:-}"
        WAIT_SECONDS="${2:-}"
        shift 2
        ;;
      --poll-interval-seconds)
        require_value "$1" "${2:-}"
        POLL_INTERVAL_SECONDS="${2:-}"
        shift 2
        ;;
      --adb-timeout-seconds)
        require_value "$1" "${2:-}"
        ADB_TIMEOUT_SECONDS="${2:-}"
        shift 2
        ;;
      --expect)
        require_value "$1" "${2:-}"
        EXPECT_SCREEN="${2:-}"
        shift 2
        ;;
      --seed-home-prefs)
        SEED_HOME_PREFS=1
        shift
        ;;
      --allow-uninstall-on-signature-mismatch)
        ALLOW_UNINSTALL=1
        shift
        ;;
      --backup-before-uninstall)
        require_value "$1" "${2:-}"
        BACKUP_BEFORE_UNINSTALL_DIR="${2:-}"
        shift 2
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        die "unknown argument: $1"
        ;;
    esac
  done
}

run_with_timeout() {
  local timeout_seconds="$1"
  shift
  python3 - "$timeout_seconds" "$@" <<'PY'
import subprocess
import sys

timeout_seconds = float(sys.argv[1])
command = sys.argv[2:]

try:
    completed = subprocess.run(command, stdout=sys.stdout, stderr=sys.stderr, timeout=timeout_seconds)
except subprocess.TimeoutExpired:
    sys.exit(124)

sys.exit(completed.returncode)
PY
}

find_adb() {
  if [[ -n "$ADB" ]]; then
    [[ -x "$ADB" ]] || die "adb is not executable: $ADB"
    printf '%s\n' "$ADB"
    return 0
  fi

  if command -v adb >/dev/null 2>&1; then
    command -v adb
    return 0
  fi

  local candidate
  for candidate in \
    "${ANDROID_HOME:-}/platform-tools/adb" \
    "${ANDROID_SDK_ROOT:-}/platform-tools/adb" \
    "$HOME/Library/Android/sdk/platform-tools/adb"; do
    if [[ -n "$candidate" && -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  die "adb not found. Set ADB, ANDROID_HOME, ANDROID_SDK_ROOT, or add adb to PATH."
}

run_adb() {
  local -a serial_args=()
  if [[ -n "$DEVICE" ]]; then
    serial_args=(-s "$DEVICE")
  fi
  run_with_timeout "$ADB_TIMEOUT_SECONDS" "$ADB" "${serial_args[@]}" "$@"
}

validate_positive_integer() {
  local name="$1"
  local value="$2"
  if [[ ! "$value" =~ ^[1-9][0-9]*$ ]]; then
    die "$name must be a positive integer"
  fi
}

write_metadata() {
  {
    printf 'timestamp=%s\n' "$(date '+%Y-%m-%d %H:%M:%S %Z')"
    printf 'adb=%s\n' "$ADB"
    printf 'device=%s\n' "${DEVICE:-default}"
    printf 'package=%s\n' "$PACKAGE_ID"
    printf 'activity=%s\n' "$ACTIVITY"
    printf 'apk=%s\n' "${APK_PATH:-skip-install}"
    printf 'expect=%s\n' "$EXPECT_SCREEN"
    printf 'wait_seconds=%s\n' "$WAIT_SECONDS"
    printf 'poll_interval_seconds=%s\n' "$POLL_INTERVAL_SECONDS"
    printf 'seed_home_prefs=%s\n' "$SEED_HOME_PREFS"
    run_adb get-serialno 2>/dev/null | sed 's/^/adb_serial=/'
    run_adb shell getprop ro.product.model 2>/dev/null | tr -d '\r' | sed 's/^/device_model=/'
    run_adb shell getprop ro.build.version.release 2>/dev/null | tr -d '\r' | sed 's/^/android_release=/'
    run_adb shell wm size 2>/dev/null | tr -d '\r' | sed 's/^/wm_size=/'
  } >"$OUT_DIR/metadata.txt"
}

install_apk() {
  if [[ "$SKIP_INSTALL" -eq 1 ]]; then
    log "skipping install"
    return 0
  fi

  [[ -n "$APK_PATH" ]] || die "--apk is required unless --skip-install is set"
  [[ -f "$APK_PATH" ]] || die "apk not found: $APK_PATH"

  local -a install_args=(--adb "$ADB" --package "$PACKAGE_ID" --apk "$APK_PATH")
  if [[ -n "$DEVICE" ]]; then
    install_args+=(--device "$DEVICE")
  fi
  if [[ "$ALLOW_UNINSTALL" -eq 1 ]]; then
    install_args+=(--allow-uninstall-on-signature-mismatch)
  fi
  if [[ -n "$BACKUP_BEFORE_UNINSTALL_DIR" ]]; then
    install_args+=(--backup-before-uninstall "$BACKUP_BEFORE_UNINSTALL_DIR")
  fi

  log "installing APK"
  bash "$APP_DIR/scripts/install_saas_staging_apk.sh" "${install_args[@]}" \
    | tee "$OUT_DIR/install.log"
}

seed_home_prefs() {
  [[ "$SEED_HOME_PREFS" -eq 1 ]] || return 0

  local prefs_file="$OUT_DIR/FlutterSharedPreferences.xml"
  cat >"$prefs_file" <<'EOF'
<?xml version='1.0' encoding='utf-8' standalone='yes' ?>
<map>
    <boolean name="flutter.guided_setup_complete" value="true" />
    <boolean name="flutter.onboarding_complete" value="true" />
    <boolean name="flutter.auth_skipped_as_guest" value="true" />
</map>
EOF

  log "seeding debug home prefs"
  run_adb push "$prefs_file" /data/local/tmp/jive_saas_smoke_prefs.xml >/dev/null
  run_adb shell run-as "$PACKAGE_ID" mkdir -p shared_prefs
  run_adb shell run-as "$PACKAGE_ID" cp /data/local/tmp/jive_saas_smoke_prefs.xml shared_prefs/FlutterSharedPreferences.xml
}

capture_package_metadata() {
  run_adb shell dumpsys package "$PACKAGE_ID" >"$OUT_DIR/package-dumpsys.txt" || true
  grep -E 'versionCode|versionName|firstInstallTime|lastUpdateTime' \
    "$OUT_DIR/package-dumpsys.txt" >"$OUT_DIR/package-version.txt" || true
}

detect_screen_from_xml() {
  local xml="$1"
  local detected="unknown"

  if [[ -s "$xml" ]]; then
    if grep -q '欢迎使用积叶' "$xml"; then
      detected="welcome"
    elif grep -Eq '净资产|最近交易|Home 第|访客' "$xml"; then
      detected="home"
    elif grep -Eq '跳过，以游客身份使用|邮箱|手机号|验证码' "$xml"; then
      detected="auth"
    elif grep -Eq '可选步骤|记一笔|选择分类|设分类' "$xml"; then
      detected="guided"
    fi
  fi

  printf '%s\n' "$detected"
}

capture_launch_snapshot() {
  run_adb exec-out screencap -p >"$OUT_DIR/launch.png" \
    || rm -f "$OUT_DIR/launch.png"
  run_adb exec-out uiautomator dump /dev/tty >"$OUT_DIR/launch.xml" \
    || true
  run_adb shell dumpsys activity activities >"$OUT_DIR/activities.txt" \
    || true
}

wait_for_launch_screen() {
  local start deadline now elapsed remaining sleep_seconds detected
  local poll_log="$OUT_DIR/screen-poll-log.tsv"

  start="$SECONDS"
  deadline=$((start + WAIT_SECONDS))
  printf 'elapsed_seconds\tdetected_screen\n' >"$poll_log"

  while true; do
    capture_launch_snapshot
    now="$SECONDS"
    elapsed=$((now - start))
    detected="$(detect_screen_from_xml "$OUT_DIR/launch.xml")"
    printf '%s\t%s\n' "$elapsed" "$detected" >>"$poll_log"
    printf '%s\n' "$detected" >"$OUT_DIR/detected-screen.txt"

    if [[ "$detected" != "unknown" ]]; then
      log "detected screen=$detected after ${elapsed}s"
      return 0
    fi

    if ((now >= deadline)); then
      log "screen remained unknown after ${WAIT_SECONDS}s"
      return 0
    fi

    remaining=$((deadline - now))
    sleep_seconds="$POLL_INTERVAL_SECONDS"
    if ((sleep_seconds > remaining)); then
      sleep_seconds="$remaining"
    fi
    sleep "$sleep_seconds"
  done
}

launch_and_capture() {
  log "launching $ACTIVITY"
  run_adb logcat -c >/dev/null || true
  run_adb shell am force-stop "$PACKAGE_ID" >/dev/null || true
  run_adb shell am start -n "$ACTIVITY" >"$OUT_DIR/am-start.txt"
  wait_for_launch_screen

  local pid
  pid="$(run_adb shell pidof -s "$PACKAGE_ID" 2>/dev/null | tr -d '\r[:space:]' || true)"
  printf '%s\n' "$pid" >"$OUT_DIR/pid.txt"
  [[ -n "$pid" ]] || die "app process is not running after launch"

  run_adb logcat --pid "$pid" -d >"$OUT_DIR/app-pid-logcat.txt" || true
  run_adb logcat -b crash -d >"$OUT_DIR/crash-buffer.txt" || true
}

detect_screen() {
  local xml="$OUT_DIR/launch.xml"
  local detected

  detected="$(detect_screen_from_xml "$xml")"

  printf '%s\n' "$detected" >"$OUT_DIR/detected-screen.txt"

  if [[ "$EXPECT_SCREEN" != "any" && "$detected" != "$EXPECT_SCREEN" ]]; then
    die "expected screen '$EXPECT_SCREEN' but detected '$detected'"
  fi

  if [[ "$detected" == "unknown" ]]; then
    die "could not identify launch screen after ${WAIT_SECONDS}s"
  fi
}

scan_logs() {
  local pattern='FATAL EXCEPTION|E/flutter|Unhandled Exception|ANR in|CRASH|Fatal signal'
  if grep -E "$pattern" "$OUT_DIR/app-pid-logcat.txt" >"$OUT_DIR/app-fatal-log-lines.txt"; then
    die "fatal app log pattern detected"
  fi
  : >"$OUT_DIR/app-fatal-log-lines.txt"
}

write_summary() {
  local detected
  detected="$(cat "$OUT_DIR/detected-screen.txt" 2>/dev/null || printf 'unknown')"

  cat >"$OUT_DIR/summary.md" <<EOF
# SaaS Staging Device Smoke

- timestamp: $(date '+%Y-%m-%d %H:%M:%S %Z')
- device: ${DEVICE:-default}
- package: $PACKAGE_ID
- activity: $ACTIVITY
- apk: ${APK_PATH:-skip-install}
- expectedScreen: $EXPECT_SCREEN
- detectedScreen: $detected
- waitSeconds: $WAIT_SECONDS
- pollIntervalSeconds: $POLL_INTERVAL_SECONDS
- seedHomePrefs: $SEED_HOME_PREFS
- artifacts: $OUT_DIR
- screenPollLog: $OUT_DIR/screen-poll-log.tsv

## Result

PASS
EOF
}

main() {
  parse_args "$@"
  case "$EXPECT_SCREEN" in
    any|welcome|home|auth|guided) ;;
    *) die "--expect must be one of: any, welcome, home, auth, guided" ;;
  esac
  validate_positive_integer "--wait-seconds" "$WAIT_SECONDS"
  validate_positive_integer "--poll-interval-seconds" "$POLL_INTERVAL_SECONDS"

  ADB="$(find_adb)"
  ACTIVITY="${ACTIVITY:-$PACKAGE_ID/com.jive.app.MainActivity}"
  if [[ -z "$OUT_DIR" ]]; then
    OUT_DIR="/tmp/jive-saas-device-smoke-$(date +%Y%m%d-%H%M%S)"
  fi
  mkdir -p "$OUT_DIR"

  log "artifacts: $OUT_DIR"
  write_metadata
  install_apk
  seed_home_prefs
  capture_package_metadata
  launch_and_capture
  detect_screen
  scan_logs
  write_summary
  log "PASS"
}

main "$@"
