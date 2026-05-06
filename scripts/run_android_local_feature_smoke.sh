#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$APP_DIR"

STAMP="$(date +%Y%m%d-%H%M%S)"
DEVICE="${JIVE_ANDROID_LOCAL_FEATURE_SMOKE_DEVICE:-${JIVE_LOCAL_ANDROID_SMOKE_DEVICE:-emulator-5554}}"
EMULATOR_ID="${JIVE_ANDROID_LOCAL_FEATURE_SMOKE_EMULATOR:-${JIVE_LOCAL_ANDROID_SMOKE_EMULATOR:-Jive_Staging_API35}}"
FLAVOR="${JIVE_ANDROID_LOCAL_FEATURE_SMOKE_FLAVOR:-${JIVE_LOCAL_ANDROID_SMOKE_FLAVOR:-dev}}"
SCENARIO="${JIVE_ANDROID_LOCAL_FEATURE_SMOKE_SCENARIO:-guest-home}"
BUILD_APK=1
INSTALL_APK=1
LAUNCH_EMULATOR=1
DRIVE_ONBOARDING=1
FRESH_INSTALL=0
ALLOW_UNINSTALL_ON_SIGNATURE_MISMATCH=0
BOOT_TIMEOUT_SECONDS="${JIVE_ANDROID_LOCAL_FEATURE_SMOKE_BOOT_TIMEOUT_SECONDS:-${JIVE_LOCAL_ANDROID_SMOKE_BOOT_TIMEOUT_SECONDS:-180}}"
STARTUP_WAIT_SECONDS="${JIVE_ANDROID_LOCAL_FEATURE_SMOKE_STARTUP_WAIT_SECONDS:-${JIVE_LOCAL_ANDROID_SMOKE_STARTUP_WAIT_SECONDS:-8}}"
ARTIFACT_DIR="${JIVE_ANDROID_LOCAL_FEATURE_SMOKE_ARTIFACT_DIR:-${JIVE_LOCAL_ANDROID_SMOKE_ARTIFACT_DIR:-$APP_DIR/build/reports/local-android-feature-smoke/$STAMP}}"
SUPABASE_URL="${JIVE_ANDROID_LOCAL_FEATURE_SMOKE_SUPABASE_URL:-${JIVE_LOCAL_ANDROID_SMOKE_SUPABASE_URL:-https://jive-local-smoke.supabase.co}}"
SUPABASE_ANON_KEY="${JIVE_ANDROID_LOCAL_FEATURE_SMOKE_SUPABASE_ANON_KEY:-${JIVE_LOCAL_ANDROID_SMOKE_SUPABASE_ANON_KEY:-header.payload.signature}}"
ADMOB_BANNER_ID="${JIVE_ANDROID_LOCAL_FEATURE_SMOKE_ADMOB_BANNER_ID:-${JIVE_LOCAL_ANDROID_SMOKE_ADMOB_BANNER_ID:-ca-app-pub-1234567890123456/1234567890}}"
PACKAGE_NAME="${JIVE_ANDROID_LOCAL_FEATURE_SMOKE_PACKAGE:-${JIVE_LOCAL_ANDROID_SMOKE_PACKAGE:-}}"
ACTIVITY_NAME="${JIVE_ANDROID_LOCAL_FEATURE_SMOKE_ACTIVITY:-${JIVE_LOCAL_ANDROID_SMOKE_ACTIVITY:-com.jive.app.MainActivity}}"
APK_PATH="${JIVE_ANDROID_LOCAL_FEATURE_SMOKE_APK_PATH:-${JIVE_LOCAL_ANDROID_SMOKE_APK_PATH:-}}"

usage() {
  cat <<'EOF'
Usage:
  scripts/run_android_local_feature_smoke.sh [options]

Options:
  --device <serial>            adb device serial. Defaults to JIVE_ANDROID_LOCAL_FEATURE_SMOKE_DEVICE or emulator-5554.
  --emulator <id>              Emulator id to launch when the device is offline. Defaults to Jive_Staging_API35.
  --flavor <name>              Flutter flavor. Defaults to dev.
  --scenario <name>            guest-home, transaction-entry, quick-entry-hub, settings-navigation, saas-gates, or all. Defaults to guest-home.
  --package <id>               Android package id. Defaults from flavor.
  --activity <name>            Launcher activity class. Defaults to com.jive.app.MainActivity.
  --artifact-dir <path>        Artifact output directory.
  --apk-path <path>            APK path for install. Defaults to build/app/outputs/flutter-apk/app-<flavor>-debug.apk.
  --supabase-url <value>       Dart define for SUPABASE_URL. Use non-secret local/staging value only.
  --supabase-anon-key <value>  Dart define for SUPABASE_ANON_KEY. Never pass service_role keys.
  --admob-banner-id <value>    Dart define for ADMOB_BANNER_ID.
  --skip-build                 Reuse an existing APK.
  --skip-install               Do not install APK before launch.
  --skip-emulator-launch       Do not launch emulator automatically.
  --skip-onboarding            Only build/install/launch/capture; do not drive onboarding.
  --fresh-install              Uninstall the app before install. This resets local app data.
  --allow-uninstall-on-signature-mismatch
                               Retry install by uninstalling the existing package when signatures mismatch.
  --preserve-data              Keep app data. This is the default and is accepted for readability.
  --help                       Show this help.

Environment aliases:
  FLUTTER_BIN, ADB_BIN, EMULATOR_BIN can point to local tool paths.
  Preferred env prefix: JIVE_ANDROID_LOCAL_FEATURE_SMOKE_*.

Notes:
  This is a local smoke runner. It writes screenshots, UI XML, logcat snippets,
  and a Markdown summary under the artifact directory. It does not upload
  secrets, does not trigger GitHub Actions, and does not use production keys.
EOF
}

log() {
  printf '[local-android-smoke] %s\n' "$*"
}

fail() {
  printf '[local-android-smoke] FAIL: %s\n' "$*" >&2
  write_summary "failed" "$*"
  exit 1
}

parse_args() {
  while (( "$#" )); do
    case "$1" in
      --device)
        DEVICE="${2:-}"
        shift 2
        ;;
      --emulator)
        EMULATOR_ID="${2:-}"
        shift 2
        ;;
      --flavor)
        FLAVOR="${2:-}"
        shift 2
        ;;
      --scenario)
        SCENARIO="${2:-}"
        shift 2
        ;;
      --package)
        PACKAGE_NAME="${2:-}"
        shift 2
        ;;
      --activity)
        ACTIVITY_NAME="${2:-}"
        shift 2
        ;;
      --artifact-dir)
        ARTIFACT_DIR="${2:-}"
        shift 2
        ;;
      --apk-path)
        APK_PATH="${2:-}"
        shift 2
        ;;
      --supabase-url)
        SUPABASE_URL="${2:-}"
        shift 2
        ;;
      --supabase-anon-key)
        SUPABASE_ANON_KEY="${2:-}"
        shift 2
        ;;
      --admob-banner-id)
        ADMOB_BANNER_ID="${2:-}"
        shift 2
        ;;
      --skip-build)
        BUILD_APK=0
        shift
        ;;
      --skip-install)
        INSTALL_APK=0
        shift
        ;;
      --skip-emulator-launch)
        LAUNCH_EMULATOR=0
        shift
        ;;
      --skip-onboarding)
        DRIVE_ONBOARDING=0
        shift
        ;;
      --fresh-install)
        FRESH_INSTALL=1
        shift
        ;;
      --allow-uninstall-on-signature-mismatch)
        ALLOW_UNINSTALL_ON_SIGNATURE_MISMATCH=1
        shift
        ;;
      --preserve-data)
        FRESH_INSTALL=0
        shift
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        printf '[local-android-smoke] unknown argument: %s\n' "$1" >&2
        usage
        exit 2
        ;;
    esac
  done

  case "$SCENARIO" in
    guest-home|transaction-entry|quick-entry-hub|settings-navigation|saas-gates|all)
      ;;
    home)
      SCENARIO="guest-home"
      ;;
    *)
      printf '[local-android-smoke] unknown scenario: %s\n' "$SCENARIO" >&2
      usage
      exit 2
      ;;
  esac
}

package_default_for_flavor() {
  case "$1" in
    dev)
      printf 'com.jivemoney.app.dev\n'
      ;;
    auto)
      printf 'com.jivemoney.app.auto\n'
      ;;
    prod)
      printf 'com.jivemoney.app\n'
      ;;
    *)
      printf 'com.jivemoney.app.%s\n' "$1"
      ;;
  esac
}

resolve_tool() {
  local env_name="$1"
  local command_name="$2"
  shift 2

  local configured="${!env_name:-}"
  if [[ -n "$configured" && -x "$configured" ]]; then
    printf '%s\n' "$configured"
    return 0
  fi

  if command -v "$command_name" >/dev/null 2>&1; then
    command -v "$command_name"
    return 0
  fi

  local candidate
  for candidate in "$@"; do
    if [[ -n "$candidate" && -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  return 1
}

ui_contains() {
  local xml_file="$1"
  local needle="$2"

  python3 - "$xml_file" "$needle" <<'PY'
import html
import re
import sys
import xml.etree.ElementTree as ET

xml_file, needle = sys.argv[1:]
try:
    root = ET.parse(xml_file).getroot()
except ET.ParseError:
    sys.exit(1)
normalized_needle = " ".join(needle.split())

for node in root.iter("node"):
    text = html.unescape(node.attrib.get("text", ""))
    desc = html.unescape(node.attrib.get("content-desc", ""))
    haystack = "\n".join(value for value in [text, desc] if value)
    normalized_haystack = re.sub(r"\s+", " ", haystack).strip()
    if needle in haystack or normalized_needle in normalized_haystack:
        sys.exit(0)

sys.exit(1)
PY
}

sanitize_uiautomator_xml() {
  local xml_file="$1"

  python3 - "$xml_file" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
raw = path.read_text(encoding="utf-8", errors="ignore")
start = raw.find("<hierarchy")
end = raw.rfind("</hierarchy>")

if start == -1 or end == -1:
    sys.exit(1)

path.write_text(raw[start : end + len("</hierarchy>")], encoding="utf-8")
PY
}

pick_node_center() {
  local xml_file="$1"
  local needle="$2"

  python3 - "$xml_file" "$needle" <<'PY'
import html
import re
import sys
import xml.etree.ElementTree as ET

xml_file, needle = sys.argv[1:]
try:
    root = ET.parse(xml_file).getroot()
except ET.ParseError:
    sys.exit(1)
matches = []

for node in root.iter("node"):
    text = html.unescape(node.attrib.get("text", ""))
    desc = html.unescape(node.attrib.get("content-desc", ""))
    haystack = "\n".join(value for value in [text, desc] if value)
    normalized_needle = " ".join(needle.split())
    normalized_haystack = re.sub(r"\s+", " ", haystack).strip()
    if needle not in haystack and normalized_needle not in normalized_haystack:
        continue
    bounds = node.attrib.get("bounds", "")
    match = re.match(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]", bounds)
    if not match:
        continue
    x1, y1, x2, y2 = map(int, match.groups())
    clickable = node.attrib.get("clickable") == "true"
    focusable = node.attrib.get("focusable") == "true"
    exact = (
        text == needle
        or desc == needle
        or haystack == needle
        or normalized_haystack == normalized_needle
    )
    area = max(1, (x2 - x1) * (y2 - y1))
    matches.append((not exact, not clickable, not focusable, area, (x1 + x2) // 2, (y1 + y2) // 2))

if not matches:
    sys.exit(1)

matches.sort()
print(matches[0][4], matches[0][5])
PY
}

pick_long_node_center() {
  local xml_file="$1"
  local needle="$2"

  python3 - "$xml_file" "$needle" <<'PY'
import html
import re
import sys
import xml.etree.ElementTree as ET

xml_file, needle = sys.argv[1:]
try:
    root = ET.parse(xml_file).getroot()
except ET.ParseError:
    sys.exit(1)
matches = []

for node in root.iter("node"):
    text = html.unescape(node.attrib.get("text", ""))
    desc = html.unescape(node.attrib.get("content-desc", ""))
    haystack = "\n".join(value for value in [text, desc] if value)
    normalized_needle = " ".join(needle.split())
    normalized_haystack = re.sub(r"\s+", " ", haystack).strip()
    if needle not in haystack and normalized_needle not in normalized_haystack:
        continue
    bounds = node.attrib.get("bounds", "")
    match = re.match(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]", bounds)
    if not match:
        continue
    x1, y1, x2, y2 = map(int, match.groups())
    long_clickable = node.attrib.get("long-clickable") == "true"
    clickable = node.attrib.get("clickable") == "true"
    focusable = node.attrib.get("focusable") == "true"
    exact = (
        text == needle
        or desc == needle
        or haystack == needle
        or normalized_haystack == normalized_needle
    )
    area = max(1, (x2 - x1) * (y2 - y1))
    matches.append((not exact, not long_clickable, not clickable, not focusable, area, (x1 + x2) // 2, (y1 + y2) // 2))

if not matches:
    sys.exit(1)

matches.sort()
print(matches[0][5], matches[0][6])
PY
}

summarize_ui() {
  local xml_file="$1"
  local output_file="$2"

  python3 - "$xml_file" "$output_file" <<'PY'
import html
import sys
import xml.etree.ElementTree as ET

xml_file, output_file = sys.argv[1:]
root = ET.parse(xml_file).getroot()
lines = []

for node in root.iter("node"):
    text = html.unescape(node.attrib.get("text", "")).strip()
    desc = html.unescape(node.attrib.get("content-desc", "")).strip()
    label = desc or text
    if not label:
        continue
    label = " ".join(label.split())
    cls = node.attrib.get("class", "node").split(".")[-1]
    bounds = node.attrib.get("bounds", "")
    clickable = node.attrib.get("clickable") == "true"
    checked = node.attrib.get("checked") == "true"
    selected = node.attrib.get("selected") == "true"
    flags = ",".join(
        flag
        for flag, enabled in [
            ("clickable", clickable),
            ("checked", checked),
            ("selected", selected),
        ]
        if enabled
    )
    suffix = f" flags={flags}" if flags else ""
    lines.append(f"{cls}: {label} {bounds}{suffix}".rstrip())

with open(output_file, "w", encoding="utf-8") as handle:
    handle.write("\n".join(lines[:120]) + "\n")
PY
}

tap_label() {
  local xml_file="$1"
  local label="$2"
  local coords

  coords="$(pick_node_center "$xml_file" "$label")" || return 1
  # shellcheck disable=SC2086
  "$ADB_BIN" -s "$DEVICE" shell input tap $coords
}

long_tap_label() {
  local xml_file="$1"
  local label="$2"
  local coords

  coords="$(pick_long_node_center "$xml_file" "$label")" || return 1
  # shellcheck disable=SC2086
  "$ADB_BIN" -s "$DEVICE" shell input swipe $coords $coords 1400
}

press_back() {
  "$ADB_BIN" -s "$DEVICE" shell input keyevent 4
}

assert_ui_contains() {
  local xml_file="$1"
  local needle="$2"
  local message="${3:-missing UI text: $needle}"

  ui_contains "$xml_file" "$needle" || fail "$message"
}

swipe_up() {
  "$ADB_BIN" -s "$DEVICE" shell input swipe 540 2100 540 900 500
}

scroll_until_contains() {
  local xml_file="$1"
  local needle="$2"
  local capture_prefix="$3"
  local index

  if ui_contains "$xml_file" "$needle"; then
    printf '%s\n' "$xml_file"
    return 0
  fi

  for index in 1 2 3 4 5; do
    swipe_up
    sleep 1
    capture_step "${capture_prefix}_scrolled_$index"
    xml_file="$ARTIFACT_DIR/${capture_prefix}_scrolled_$index.xml"
    if ui_contains "$xml_file" "$needle"; then
      printf '%s\n' "$xml_file"
      return 0
    fi
  done

  return 1
}

capture_step() {
  local name="$1"
  local xml_file="$ARTIFACT_DIR/$name.xml"
  local summary_file="$ARTIFACT_DIR/$name.summary.txt"
  local attempt

  "$ADB_BIN" -s "$DEVICE" exec-out screencap -p > "$ARTIFACT_DIR/$name.png" || true
  "$ADB_BIN" -s "$DEVICE" logcat -b crash -d > "$ARTIFACT_DIR/$name.crash.log" || true
  "$ADB_BIN" -s "$DEVICE" logcat -d \
    | grep -Ei 'FATAL EXCEPTION|FlutterError|Unhandled Exception' \
    > "$ARTIFACT_DIR/$name.alerts.log" || true

  for attempt in 1 2 3 4; do
    "$ADB_BIN" -s "$DEVICE" exec-out uiautomator dump /dev/tty > "$xml_file" || true
    if [[ -s "$xml_file" ]] && sanitize_uiautomator_xml "$xml_file"; then
      summarize_ui "$xml_file" "$summary_file" || true
      return 0
    fi
    sleep 1
  done
}

file_size_bytes() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    printf '0\n'
    return 0
  fi
  if stat -f%z "$file" >/dev/null 2>&1; then
    stat -f%z "$file"
  else
    stat -c%s "$file"
  fi
}

write_summary() {
  local status="${1:-unknown}"
  local message="${2:-}"
  local summary="$ARTIFACT_DIR/summary.md"
  local git_commit
  local apk_sha=""
  local final_crash_bytes="n/a"
  local final_ui="n/a"

  mkdir -p "$ARTIFACT_DIR"
  git_commit="$(git rev-parse HEAD 2>/dev/null || printf 'unknown')"
  if [[ -f "$APK_PATH" ]]; then
    apk_sha="$(shasum -a 256 "$APK_PATH" | awk '{print $1}')"
  fi
  if [[ -f "$ARTIFACT_DIR/final_home.crash.log" ]]; then
    final_crash_bytes="$(file_size_bytes "$ARTIFACT_DIR/final_home.crash.log")"
  fi
  if [[ -f "$ARTIFACT_DIR/final_home.summary.txt" ]]; then
    final_ui="$ARTIFACT_DIR/final_home.summary.txt"
  fi

  cat > "$summary" <<EOF
# Local Android Feature Smoke

- generatedAt: $STAMP
- status: $status
- message: $message
- gitCommit: $git_commit
- device: $DEVICE
- emulator: $EMULATOR_ID
- flavor: $FLAVOR
- scenario: $SCENARIO
- package: $PACKAGE_NAME
- activity: $ACTIVITY_NAME
- artifactDir: $ARTIFACT_DIR
- apkPath: $APK_PATH
- apkSha256: $apk_sha
- finalCrashBytes: $final_crash_bytes
- finalUiSummary: $final_ui

## Covered Flow

- Build dev debug APK unless --skip-build is used.
- Install app on the selected adb target unless --skip-install is used.
- Reset app data only when --fresh-install is used.
- Cold launch the app.
- Skip welcome.
- In onboarding entry, select the Catering category and continue.
- Skip remaining onboarding steps.
- Continue as guest and confirm guest mode.
- Verify the home screen contains guest and net-worth content.
- When scenario is transaction-entry or all, open the add-transaction page,
  verify keypad/category/account controls, and calculate 1+2×3 = 7.00.
- When scenario is quick-entry-hub or all, long-press the home FAB, verify the
  quick-entry hub, and open manual bookkeeping without saving a transaction.
- When scenario is settings-navigation or all, open Settings, verify the main
  section anchors, open the language picker, open privacy policy, and return
  home without changing persisted settings.
- When scenario is saas-gates or all, open Settings, verify subscription
  entry points, and confirm the cloud-sync upgrade gate.

## Artifacts

- launch screenshot/xml/logs: $ARTIFACT_DIR/launch.*
- onboarding screenshots/xml/logs: $ARTIFACT_DIR/onboarding_*.*
- auth screenshots/xml/logs: $ARTIFACT_DIR/auth*.*
- final home screenshot/xml/logs: $ARTIFACT_DIR/final_home.*
- transaction-entry scenario artifacts: $ARTIFACT_DIR/transaction_entry*.*
- quick-entry-hub scenario artifacts: $ARTIFACT_DIR/quick_entry*.*
- settings-navigation scenario artifacts: $ARTIFACT_DIR/settings_navigation*.*
- saas-gates scenario artifacts: $ARTIFACT_DIR/saas_*.*
EOF
}

wait_for_device() {
  local deadline=$((SECONDS + BOOT_TIMEOUT_SECONDS))
  while ((SECONDS < deadline)); do
    if "$ADB_BIN" -s "$DEVICE" get-state >/dev/null 2>&1; then
      return 0
    fi
    sleep 2
  done
  return 1
}

wait_for_boot_completed() {
  local deadline=$((SECONDS + BOOT_TIMEOUT_SECONDS))
  while ((SECONDS < deadline)); do
    local boot_completed
    boot_completed="$("$ADB_BIN" -s "$DEVICE" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r[:space:]' || true)"
    if [[ "$boot_completed" == "1" ]]; then
      return 0
    fi
    sleep 2
  done
  return 1
}

launch_emulator_if_needed() {
  if "$ADB_BIN" -s "$DEVICE" get-state >/dev/null 2>&1; then
    return 0
  fi

  if [[ "$LAUNCH_EMULATOR" -ne 1 ]]; then
    fail "device $DEVICE is offline and emulator launch is disabled"
  fi

  log "launching emulator $EMULATOR_ID"
  "$EMULATOR_BIN" -avd "$EMULATOR_ID" -no-snapshot-load -no-audio -no-boot-anim \
    > "$ARTIFACT_DIR/emulator.log" 2>&1 &
  echo "$!" > "$ARTIFACT_DIR/emulator.pid"
}

build_apk() {
  if [[ "$BUILD_APK" -ne 1 ]]; then
    log "skipping APK build"
    return 0
  fi

  log "building $FLAVOR debug APK"
  "$FLUTTER_BIN" build apk \
    --debug \
    --flavor "$FLAVOR" \
    --dart-define=SUPABASE_URL="$SUPABASE_URL" \
    --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
    --dart-define=ADMOB_BANNER_ID="$ADMOB_BANNER_ID" \
    2>&1 | tee "$ARTIFACT_DIR/flutter-build.log"

  [[ -f "$APK_PATH" ]] || fail "APK not found: $APK_PATH"
}

install_apk() {
  if [[ "$INSTALL_APK" -ne 1 ]]; then
    log "skipping APK install"
    return 0
  fi

  [[ -f "$APK_PATH" ]] || fail "APK not found: $APK_PATH"

  if [[ "$FRESH_INSTALL" -eq 1 ]]; then
    "$ADB_BIN" -s "$DEVICE" uninstall "$PACKAGE_NAME" >/dev/null 2>&1 || true
  fi

  log "installing $APK_PATH"
  if "$ADB_BIN" -s "$DEVICE" install -r "$APK_PATH" \
    > "$ARTIFACT_DIR/install.log" 2>&1; then
    return 0
  fi

  if grep -q "INSTALL_FAILED_UPDATE_INCOMPATIBLE" "$ARTIFACT_DIR/install.log"; then
    if [[ "$ALLOW_UNINSTALL_ON_SIGNATURE_MISMATCH" -ne 1 ]]; then
      fail "APK install failed because signatures mismatch. Re-run with --allow-uninstall-on-signature-mismatch if resetting app data on this device is acceptable."
    fi
    log "signature mismatch found; uninstalling stale package and retrying"
    "$ADB_BIN" -s "$DEVICE" uninstall "$PACKAGE_NAME" >/dev/null 2>&1 || true
    "$ADB_BIN" -s "$DEVICE" install -r "$APK_PATH" \
      >> "$ARTIFACT_DIR/install.log" 2>&1
    return 0
  fi

  fail "APK install failed; see $ARTIFACT_DIR/install.log"
}

launch_app() {
  log "launching $PACKAGE_NAME/$ACTIVITY_NAME"
  "$ADB_BIN" -s "$DEVICE" logcat -c || true
  "$ADB_BIN" -s "$DEVICE" shell am start -n "$PACKAGE_NAME/$ACTIVITY_NAME" \
    > "$ARTIFACT_DIR/launch-am-start.log" 2>&1 \
    || fail "app launch failed; see $ARTIFACT_DIR/launch-am-start.log"
  sleep "$STARTUP_WAIT_SECONDS"
  capture_step "launch"
}

drive_onboarding() {
  local xml="$ARTIFACT_DIR/launch.xml"
  local index

  if [[ "$DRIVE_ONBOARDING" -ne 1 ]]; then
    log "skipping onboarding drive"
    return 0
  fi

  if ui_contains "$xml" "访客" && ui_contains "$xml" "净资产"; then
    log "home is already visible"
    cp "$xml" "$ARTIFACT_DIR/final_home.xml"
    cp "$ARTIFACT_DIR/launch.png" "$ARTIFACT_DIR/final_home.png" || true
    cp "$ARTIFACT_DIR/launch.summary.txt" "$ARTIFACT_DIR/final_home.summary.txt" || true
    cp "$ARTIFACT_DIR/launch.crash.log" "$ARTIFACT_DIR/final_home.crash.log" || true
    cp "$ARTIFACT_DIR/launch.alerts.log" "$ARTIFACT_DIR/final_home.alerts.log" || true
    return 0
  fi

  for index in 1 2 3 4 5 6 7 8 9 10; do
    if ui_contains "$xml" "跳过，以游客身份使用" ||
      ui_contains "$xml" "邮箱登录" ||
      ui_contains "$xml" "Jive 积叶"; then
      break
    fi

    if ui_contains "$xml" "欢迎使用积叶"; then
      tap_label "$xml" "跳过" || fail "cannot tap welcome skip"
      sleep 2
      capture_step "onboarding_progress_$index"
      xml="$ARTIFACT_DIR/onboarding_progress_$index.xml"
      continue
    fi

    if ui_contains "$xml" "记一笔"; then
      tap_label "$xml" "餐饮" || fail "cannot tap onboarding category"
      sleep 1
      tap_label "$xml" "下一步" || fail "cannot tap next after category selection"
      sleep 2
      capture_step "onboarding_progress_$index"
      xml="$ARTIFACT_DIR/onboarding_progress_$index.xml"
      continue
    fi

    if tap_label "$xml" "跳过"; then
      sleep 2
      capture_step "onboarding_progress_$index"
      xml="$ARTIFACT_DIR/onboarding_progress_$index.xml"
      continue
    fi

    if tap_label "$xml" "下一步"; then
      sleep 2
      capture_step "onboarding_progress_$index"
      xml="$ARTIFACT_DIR/onboarding_progress_$index.xml"
      continue
    fi

    if tap_label "$xml" "完成"; then
      sleep 2
      capture_step "onboarding_progress_$index"
      xml="$ARTIFACT_DIR/onboarding_progress_$index.xml"
      continue
    fi

    swipe_up
    sleep 2
    capture_step "onboarding_progress_$index"
    xml="$ARTIFACT_DIR/onboarding_progress_$index.xml"
  done

  xml="$(scroll_until_contains "$xml" "跳过，以游客身份使用" "auth_guest")" ||
    fail "cannot find guest mode entry"
  cp "$xml" "$ARTIFACT_DIR/auth.xml"

  tap_label "$xml" "跳过，以游客身份使用" || fail "cannot tap guest mode entry"
  sleep 2
  capture_step "guest_confirm"
  xml="$ARTIFACT_DIR/guest_confirm.xml"

  tap_label "$xml" "进入游客模式" || fail "cannot confirm guest mode"
  sleep 5
  capture_step "final_home"
  xml="$ARTIFACT_DIR/final_home.xml"

  if ! ui_contains "$xml" "访客"; then
    fail "guest home did not contain visitor label"
  fi
  if ! ui_contains "$xml" "净资产"; then
    fail "guest home did not contain net worth label"
  fi
}

drive_transaction_entry() {
  local xml="$ARTIFACT_DIR/final_home.xml"

  if [[ ! -f "$xml" ]]; then
    xml="$ARTIFACT_DIR/launch.xml"
  fi

  if ui_contains "$xml" "支出" && ui_contains "$xml" "再记"; then
    log "transaction entry is already visible"
    capture_step "transaction_entry"
    xml="$ARTIFACT_DIR/transaction_entry.xml"
  else
    if tap_label "$xml" "记一笔"; then
      log "opened transaction entry from home add button"
    elif tap_label "$xml" "支出"; then
      log "opened transaction entry from home expense shortcut"
    else
      fail "cannot tap home add transaction entry"
    fi
    sleep 4
    capture_step "transaction_entry"
    xml="$ARTIFACT_DIR/transaction_entry.xml"
  fi

  assert_ui_contains "$xml" "支出" "transaction entry missing expense tab"
  assert_ui_contains "$xml" "收入" "transaction entry missing income tab"
  assert_ui_contains "$xml" "转账" "transaction entry missing transfer tab"
  assert_ui_contains "$xml" "餐饮" "transaction entry missing category grid"
  assert_ui_contains "$xml" "现金" "transaction entry missing cash account"
  assert_ui_contains "$xml" "再记" "transaction entry missing save-and-new action"
  assert_ui_contains "$xml" "+ 长按×" "transaction entry missing plus long-press hint"
  assert_ui_contains "$xml" "- 长按÷" "transaction entry missing minus long-press hint"
  assert_ui_contains "$xml" "展开备注" "transaction entry missing inline note toggle"

  tap_label "$xml" "1" || fail "cannot tap amount key 1"
  sleep 0.2
  tap_label "$xml" "+ 长按×" || fail "cannot tap plus key"
  sleep 0.2
  tap_label "$xml" "2" || fail "cannot tap amount key 2"
  sleep 0.2
  long_tap_label "$xml" "+ 长按×" || fail "cannot long press plus key"
  sleep 0.4
  capture_step "transaction_entry_operator_toggle"
  xml="$ARTIFACT_DIR/transaction_entry_operator_toggle.xml"

  assert_ui_contains "$xml" "当前×" "transaction entry plus key did not toggle to multiplication"
  tap_label "$xml" "× 当前×" || fail "cannot tap multiplication key"
  sleep 0.2
  tap_label "$xml" "3" || fail "cannot tap amount key 3"
  sleep 1
  capture_step "transaction_entry_expression"
  xml="$ARTIFACT_DIR/transaction_entry_expression.xml"

  assert_ui_contains "$xml" "1+2×3" "transaction entry formula did not show 1+2×3"
  assert_ui_contains "$xml" "7.00" "transaction entry result did not show 7.00"
}

return_to_home() {
  local index
  local xml

  for index in 1 2 3 4 5; do
    capture_step "return_home_$index"
    xml="$ARTIFACT_DIR/return_home_$index.xml"
    if ui_contains "$xml" "访客" && ui_contains "$xml" "净资产"; then
      cp "$xml" "$ARTIFACT_DIR/final_home.xml"
      cp "$ARTIFACT_DIR/return_home_$index.png" "$ARTIFACT_DIR/final_home.png" || true
      cp "$ARTIFACT_DIR/return_home_$index.summary.txt" "$ARTIFACT_DIR/final_home.summary.txt" || true
      cp "$ARTIFACT_DIR/return_home_$index.crash.log" "$ARTIFACT_DIR/final_home.crash.log" || true
      cp "$ARTIFACT_DIR/return_home_$index.alerts.log" "$ARTIFACT_DIR/final_home.alerts.log" || true
      return 0
    fi
    press_back
    sleep 1
  done

  fail "could not return to guest home"
}

drive_saas_gates() {
  local xml="$ARTIFACT_DIR/final_home.xml"

  if [[ ! -f "$xml" ]]; then
    xml="$ARTIFACT_DIR/launch.xml"
  fi

  tap_label "$xml" "打开菜单" || fail "cannot tap home settings menu"
  sleep 1
  capture_step "saas_menu"
  xml="$ARTIFACT_DIR/saas_menu.xml"

  assert_ui_contains "$xml" "设置" "home menu missing settings entry"
  tap_label "$xml" "设置" || fail "cannot tap settings entry"
  sleep 2
  capture_step "saas_settings"
  xml="$ARTIFACT_DIR/saas_settings.xml"

  assert_ui_contains "$xml" "账户与订阅" "settings missing subscription entry"
  assert_ui_contains "$xml" "云同步设置" "settings missing cloud sync entry"
  assert_ui_contains "$xml" "外观" "settings missing appearance section"

  tap_label "$xml" "账户与订阅" || fail "cannot tap subscription entry"
  sleep 2
  capture_step "saas_subscription"
  xml="$ARTIFACT_DIR/saas_subscription.xml"

  assert_ui_contains "$xml" "升级方案" "subscription screen missing title"
  assert_ui_contains "$xml" "当前方案" "subscription screen missing current plan"
  xml="$(scroll_until_contains "$xml" "云同步与多设备使用" "saas_subscription")" ||
    fail "subscription screen missing cloud sync feature copy"
  assert_ui_contains "$xml" "云同步与多设备使用" "subscription screen missing cloud sync feature copy"

  xml="$(scroll_until_contains "$xml" "恢复购买" "saas_subscription_restore")" ||
    fail "subscription screen missing restore action"
  assert_ui_contains "$xml" "恢复购买" "subscription screen missing restore action"

  press_back
  sleep 1
  capture_step "saas_settings_after_subscription"
  xml="$ARTIFACT_DIR/saas_settings_after_subscription.xml"

  tap_label "$xml" "云同步设置" || fail "cannot tap cloud sync settings gate"
  sleep 1
  capture_step "saas_cloud_sync_gate"
  xml="$ARTIFACT_DIR/saas_cloud_sync_gate.xml"

  assert_ui_contains "$xml" "此功能需要订阅版" "cloud sync gate missing subscriber copy"
  assert_ui_contains "$xml" "了解订阅版" "cloud sync gate missing learn more action"
  assert_ui_contains "$xml" "稍后再说" "cloud sync gate missing later action"

  tap_label "$xml" "了解订阅版" || fail "cannot open subscription from cloud sync gate"
  sleep 2
  capture_step "saas_cloud_sync_subscription"
  xml="$ARTIFACT_DIR/saas_cloud_sync_subscription.xml"

  assert_ui_contains "$xml" "升级方案" "cloud sync gate did not navigate to subscription screen"
  xml="$(scroll_until_contains "$xml" "云同步与多设备使用" "saas_cloud_sync_subscription")" ||
    fail "cloud sync subscription screen missing feature copy"
  assert_ui_contains "$xml" "云同步与多设备使用" "cloud sync subscription screen missing feature copy"

  return_to_home
}

drive_settings_navigation() {
  local xml="$ARTIFACT_DIR/final_home.xml"

  if [[ ! -f "$xml" ]]; then
    xml="$ARTIFACT_DIR/launch.xml"
  fi

  tap_label "$xml" "打开菜单" || fail "cannot tap home settings menu"
  sleep 1
  capture_step "settings_navigation_menu"
  xml="$ARTIFACT_DIR/settings_navigation_menu.xml"

  assert_ui_contains "$xml" "设置" "home menu missing settings entry"
  tap_label "$xml" "设置" || fail "cannot tap settings entry"
  sleep 2
  capture_step "settings_navigation_top"
  xml="$ARTIFACT_DIR/settings_navigation_top.xml"

  assert_ui_contains "$xml" "设置" "settings screen missing title"
  assert_ui_contains "$xml" "账户与订阅" "settings screen missing subscription entry"
  assert_ui_contains "$xml" "云同步设置" "settings screen missing cloud sync entry"
  assert_ui_contains "$xml" "外观" "settings screen missing appearance section"

  xml="$(scroll_until_contains "$xml" "应用语言" "settings_navigation_language")" ||
    fail "settings screen missing language entry"
  assert_ui_contains "$xml" "语言" "settings screen missing language section"
  assert_ui_contains "$xml" "应用语言" "settings screen missing app language entry"

  tap_label "$xml" "应用语言" || fail "cannot tap app language entry"
  sleep 1
  capture_step "settings_navigation_language_picker"
  xml="$ARTIFACT_DIR/settings_navigation_language_picker.xml"

  assert_ui_contains "$xml" "选择语言" "language picker missing title"
  assert_ui_contains "$xml" "简体中文" "language picker missing Simplified Chinese option"
  assert_ui_contains "$xml" "English" "language picker missing English option"

  press_back
  sleep 1
  capture_step "settings_navigation_after_language"
  xml="$ARTIFACT_DIR/settings_navigation_after_language.xml"

  xml="$(scroll_until_contains "$xml" "语音设置" "settings_navigation_voice")" ||
    fail "settings screen missing voice settings entry"
  assert_ui_contains "$xml" "语音与智能" "settings screen missing voice section"
  assert_ui_contains "$xml" "语音设置" "settings screen missing voice settings entry"

  xml="$(scroll_until_contains "$xml" "导出数据" "settings_navigation_data")" ||
    fail "settings screen missing export data entry"
  assert_ui_contains "$xml" "数据" "settings screen missing data section"
  assert_ui_contains "$xml" "WebDAV 同步" "settings screen missing WebDAV entry"
  assert_ui_contains "$xml" "导出数据" "settings screen missing export data entry"

  xml="$(scroll_until_contains "$xml" "隐私政策" "settings_navigation_privacy")" ||
    fail "settings screen missing privacy policy entry"
  assert_ui_contains "$xml" "关于" "settings screen missing about section"
  assert_ui_contains "$xml" "隐私政策" "settings screen missing privacy policy entry"

  tap_label "$xml" "隐私政策" || fail "cannot tap privacy policy entry"
  sleep 1
  capture_step "settings_navigation_privacy_policy"
  xml="$ARTIFACT_DIR/settings_navigation_privacy_policy.xml"

  assert_ui_contains "$xml" "隐私政策" "privacy policy screen missing title"
  assert_ui_contains "$xml" "Jive 积叶 隐私政策" "privacy policy screen missing heading"
  assert_ui_contains "$xml" "数据存储" "privacy policy screen missing data storage copy"

  return_to_home
}

drive_quick_entry_hub() {
  local xml="$ARTIFACT_DIR/final_home.xml"

  if [[ ! -f "$xml" ]]; then
    xml="$ARTIFACT_DIR/launch.xml"
  fi

  long_tap_label "$xml" "新增记账" || fail "cannot long press home quick-entry FAB"
  sleep 1
  capture_step "quick_entry_hub"
  xml="$ARTIFACT_DIR/quick_entry_hub.xml"

  assert_ui_contains "$xml" "手动记账" "quick entry hub missing manual entry"
  assert_ui_contains "$xml" "语音记账" "quick entry hub missing voice entry"
  assert_ui_contains "$xml" "对话记账" "quick entry hub missing conversation entry"
  assert_ui_contains "$xml" "截图识别" "quick entry hub missing screenshot entry"
  assert_ui_contains "$xml" "从模板记" "quick entry hub missing template entry"
  assert_ui_contains "$xml" "从分享记" "quick entry hub missing share entry"

  tap_label "$xml" "手动记账" || fail "cannot tap manual entry from quick-entry hub"
  sleep 2
  capture_step "quick_entry_manual_transaction"
  xml="$ARTIFACT_DIR/quick_entry_manual_transaction.xml"

  assert_ui_contains "$xml" "支出" "quick entry manual flow missing expense tab"
  assert_ui_contains "$xml" "收入" "quick entry manual flow missing income tab"
  assert_ui_contains "$xml" "转账" "quick entry manual flow missing transfer tab"
  assert_ui_contains "$xml" "餐饮" "quick entry manual flow missing category grid"
  assert_ui_contains "$xml" "现金" "quick entry manual flow missing cash account"
  assert_ui_contains "$xml" "再记" "quick entry manual flow missing save-and-new action"

  return_to_home
}

run_selected_scenario() {
  case "$SCENARIO" in
    guest-home)
      ;;
    transaction-entry)
      drive_transaction_entry
      ;;
    quick-entry-hub)
      drive_quick_entry_hub
      ;;
    settings-navigation)
      drive_settings_navigation
      ;;
    saas-gates)
      drive_saas_gates
      ;;
    all)
      drive_saas_gates
      drive_settings_navigation
      drive_quick_entry_hub
      drive_transaction_entry
      ;;
  esac
}

main() {
  parse_args "$@"
  if [[ -z "$PACKAGE_NAME" ]]; then
    PACKAGE_NAME="$(package_default_for_flavor "$FLAVOR")"
  fi
  if [[ -z "$APK_PATH" ]]; then
    APK_PATH="$APP_DIR/build/app/outputs/flutter-apk/app-$FLAVOR-debug.apk"
  fi
  mkdir -p "$ARTIFACT_DIR"

  FLUTTER_BIN="$(resolve_tool FLUTTER_BIN flutter /Users/chauhua/development/flutter/bin/flutter)" \
    || fail "flutter not found"
  ADB_BIN="$(resolve_tool ADB_BIN adb "${ANDROID_HOME:-}/platform-tools/adb" "${ANDROID_SDK_ROOT:-}/platform-tools/adb" /Users/chauhua/Library/Android/sdk/platform-tools/adb)" \
    || fail "adb not found"
  EMULATOR_BIN="$(resolve_tool EMULATOR_BIN emulator "${ANDROID_HOME:-}/emulator/emulator" "${ANDROID_SDK_ROOT:-}/emulator/emulator" /Users/chauhua/Library/Android/sdk/emulator/emulator)" \
    || EMULATOR_BIN=""

  if [[ "$LAUNCH_EMULATOR" -eq 1 && -z "$EMULATOR_BIN" ]]; then
    fail "emulator tool not found"
  fi

  log "artifact dir: $ARTIFACT_DIR"
  log "flutter: $FLUTTER_BIN"
  log "adb: $ADB_BIN"

  launch_emulator_if_needed
  wait_for_device || fail "device $DEVICE did not come online"
  wait_for_boot_completed || fail "device $DEVICE did not finish booting"
  build_apk
  install_apk
  launch_app
  drive_onboarding
  run_selected_scenario
  write_summary "passed" "Local Android feature smoke completed"
  log "summary: $ARTIFACT_DIR/summary.md"
}

main "$@"
