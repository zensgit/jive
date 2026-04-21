#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

ADB="${ADB:-}"
APK_PATH="${APK_PATH:-}"
DEVICE="${ANDROID_SERIAL:-}"
PACKAGE_ID="${JIVE_ANDROID_APP_ID:-com.jivemoney.app.dev}"
ALLOW_UNINSTALL=0

usage() {
  cat <<'EOF'
Usage:
  scripts/install_saas_staging_apk.sh --apk <path> [options]

Options:
  --apk <path>                         APK to install.
  --device <serial>                    adb device serial. Falls back to ANDROID_SERIAL.
  --package <id>                       Package id. Defaults to JIVE_ANDROID_APP_ID or com.jivemoney.app.dev.
  --adb <path>                         adb binary. Falls back to ADB, PATH, or common Android SDK paths.
  --allow-uninstall-on-signature-mismatch
                                       If install -r fails because existing signatures differ, uninstall
                                       the existing package and install again. This deletes app data.
  --help                               Show this help.

Notes:
  The default path is intentionally data-safe. It will not uninstall an existing app unless
  --allow-uninstall-on-signature-mismatch is explicitly passed.
EOF
}

log() {
  printf '[saas-apk-install] %s\n' "$*"
}

die() {
  printf '[saas-apk-install] ERROR: %s\n' "$*" >&2
  exit 1
}

parse_args() {
  while (($#)); do
    case "$1" in
      --apk)
        APK_PATH="${2:-}"
        shift 2
        ;;
      --device)
        DEVICE="${2:-}"
        shift 2
        ;;
      --package)
        PACKAGE_ID="${2:-}"
        shift 2
        ;;
      --adb)
        ADB="${2:-}"
        shift 2
        ;;
      --allow-uninstall-on-signature-mismatch)
        ALLOW_UNINSTALL=1
        shift
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
  "$ADB" "${serial_args[@]}" "$@"
}

print_device_info() {
  local serial model release size
  serial="$(run_adb get-serialno 2>/dev/null || true)"
  model="$(run_adb shell getprop ro.product.model 2>/dev/null | tr -d '\r' || true)"
  release="$(run_adb shell getprop ro.build.version.release 2>/dev/null | tr -d '\r' || true)"
  size="$(run_adb shell wm size 2>/dev/null | tr -d '\r' || true)"

  log "device=${serial:-unknown} model=${model:-unknown} android=${release:-unknown} ${size:-}"
}

install_apk() {
  local output status
  set +e
  output="$(run_adb install -r "$APK_PATH" 2>&1)"
  status=$?
  set -e
  printf '%s\n' "$output"

  if [[ "$status" -eq 0 ]]; then
    return 0
  fi

  if [[ "$output" != *"INSTALL_FAILED_UPDATE_INCOMPATIBLE"* ]]; then
    return "$status"
  fi

  if [[ "$ALLOW_UNINSTALL" -ne 1 ]]; then
    die "signature mismatch for $PACKAGE_ID. Re-run with --allow-uninstall-on-signature-mismatch only if deleting local app data is acceptable."
  fi

  log "signature mismatch detected; uninstalling $PACKAGE_ID because explicit uninstall flag was provided"
  run_adb uninstall "$PACKAGE_ID"
  run_adb install "$APK_PATH"
}

print_installed_version() {
  log "installed package metadata:"
  run_adb shell dumpsys package "$PACKAGE_ID" \
    | grep -E 'versionCode|versionName|firstInstallTime|lastUpdateTime' \
    || true
}

main() {
  parse_args "$@"
  [[ -n "$APK_PATH" ]] || die "--apk is required"
  [[ -f "$APK_PATH" ]] || die "apk not found: $APK_PATH"

  ADB="$(find_adb)"
  log "adb=$ADB"
  log "apk=$APK_PATH"
  log "package=$PACKAGE_ID"
  print_device_info
  install_apk
  print_installed_version
}

main "$@"
