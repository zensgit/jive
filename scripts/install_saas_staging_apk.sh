#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

ADB="${ADB:-}"
APK_PATH="${APK_PATH:-}"
DEVICE="${ANDROID_SERIAL:-}"
PACKAGE_ID="${JIVE_ANDROID_APP_ID:-com.jivemoney.app.dev}"
ALLOW_UNINSTALL=0
BACKUP_BEFORE_UNINSTALL_DIR=""

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
  --backup-before-uninstall <dir>      Store a tar backup of app data in <dir> before uninstalling.
                                       Only used when --allow-uninstall-on-signature-mismatch is set.
                                       If the backup cannot be created and verified, uninstall is aborted.
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
      --adb)
        require_value "$1" "${2:-}"
        ADB="${2:-}"
        shift 2
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

backup_app_data() {
  local backup_dir backup_stamp backup_file tmp_file err_file status stderr_output

  [[ -n "$BACKUP_BEFORE_UNINSTALL_DIR" ]] || return 0

  backup_dir="$BACKUP_BEFORE_UNINSTALL_DIR"
  mkdir -p "$backup_dir" || die "cannot create backup directory: $backup_dir"

  backup_stamp="$(date +%Y%m%d-%H%M%S)"
  backup_file="$backup_dir/${PACKAGE_ID}-appdata-${backup_stamp}.tar"
  tmp_file="${backup_file}.tmp"
  err_file="${tmp_file}.err"

  log "backing up app data for $PACKAGE_ID to $backup_file"
  set +e
  run_adb exec-out run-as "$PACKAGE_ID" tar -cf - . >"$tmp_file" 2>"$err_file"
  status=$?
  set -e

  if [[ "$status" -ne 0 ]]; then
    stderr_output="$(tr -d '\r' < "$err_file" | tail -n 1 || true)"
    rm -f "$tmp_file" "$err_file"
    if [[ -n "$stderr_output" ]]; then
      die "failed to back up app data for $PACKAGE_ID; uninstall aborted. $stderr_output"
    fi
    die "failed to back up app data for $PACKAGE_ID; uninstall aborted."
  fi

  mv "$tmp_file" "$backup_file" || {
    rm -f "$tmp_file" "$err_file"
    die "failed to finalize app data backup for $PACKAGE_ID; uninstall aborted."
  }
  rm -f "$err_file"

  tar -tf "$backup_file" >"${backup_file}.list" \
    || die "failed to verify app data backup for $PACKAGE_ID; uninstall aborted."
  wc -c "$backup_file" >"${backup_file}.size" || true
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$backup_file" >"${backup_file}.sha256" || true
  fi

  log "app data backup complete: $backup_file"
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

  backup_app_data
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
