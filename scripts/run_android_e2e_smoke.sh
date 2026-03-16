#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$APP_DIR"

DEVICE="${JIVE_ANDROID_E2E_DEVICE:-emulator-5554}"
FLAVOR="${JIVE_ANDROID_E2E_FLAVOR:-dev}"
RETRIES="${JIVE_ANDROID_E2E_RETRIES:-2}"
BOOT_TIMEOUT_SECONDS="${JIVE_ANDROID_E2E_BOOT_TIMEOUT_SECONDS:-180}"
ADB_COMMAND_TIMEOUT_SECONDS="${JIVE_ANDROID_E2E_ADB_COMMAND_TIMEOUT_SECONDS:-20}"
GRADLE_OPTS_E2E="${GRADLE_OPTS_E2E:--Dorg.gradle.project.split-per-abi=true}"

case "$FLAVOR" in
  dev)
    APP_ID_DEFAULT="com.jivemoney.app.dev"
    ;;
  auto)
    APP_ID_DEFAULT="com.jivemoney.app.auto"
    ;;
  *)
    APP_ID_DEFAULT="com.jivemoney.app"
    ;;
esac

APP_ID="${JIVE_ANDROID_E2E_APP_ID:-$APP_ID_DEFAULT}"
STAMP="$(date +%Y%m%d-%H%M%S)"
ARTIFACT_DIR="${JIVE_ANDROID_E2E_ARTIFACT_DIR:-$APP_DIR/build/android-e2e-smoke/$STAMP}"
mkdir -p "$ARTIFACT_DIR"
REPORT_DIR="$APP_DIR/build/reports/sync-runtime"
mkdir -p "$REPORT_DIR"

SMOKE_TESTS=(
  integration_test/backup_restore_stale_session_flow_test.dart
  integration_test/sync_runtime_backup_restore_rebind_flow_test.dart
  integration_test/import_center_failure_analytics_flow_test.dart
  integration_test/import_center_duplicate_resolution_flow_test.dart
  integration_test/import_center_preview_repair_flow_test.dart
  integration_test/import_center_column_mapping_repair_flow_test.dart
  integration_test/import_center_transfer_guard_flow_test.dart
  integration_test/import_center_transfer_preview_flow_test.dart
  integration_test/category_icon_picker_flow_test.dart
  integration_test/calendar_date_picker_flow_test.dart
  integration_test/transaction_search_flow_test.dart
)

log() {
  echo "[android-e2e] $*"
}

sanitize_name() {
  echo "$1" | tr '/.' '__'
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

adb_command() {
  run_with_timeout "$ADB_COMMAND_TIMEOUT_SECONDS" adb -s "$DEVICE" "$@"
}

adb_shell() {
  adb_command shell "$@"
}

adb_recover() {
  adb start-server >/dev/null 2>&1 || true
  adb reconnect offline >/dev/null 2>&1 || true
  adb reconnect >/dev/null 2>&1 || true
  adb_command wait-for-device >/dev/null 2>&1 || true
}

capture_diagnostics() {
  local prefix="$1"
  adb_command logcat -d > "$ARTIFACT_DIR/${prefix}.logcat.txt" || true
  adb_shell dumpsys activity activities \
    > "$ARTIFACT_DIR/${prefix}.activities.txt" || true
  adb_command exec-out screencap -p \
    > "$ARTIFACT_DIR/${prefix}.png" || rm -f "$ARTIFACT_DIR/${prefix}.png"
}

wait_for_boot_completed() {
  local deadline=$((SECONDS + BOOT_TIMEOUT_SECONDS))
  while ((SECONDS < deadline)); do
    local boot_completed
    if ! boot_completed="$(
      adb_shell getprop sys.boot_completed 2>/dev/null | tr -d '\r[:space:]'
    )"; then
      log "boot probe timed out or failed; restarting adb server"
      adb_recover
      sleep 2
      continue
    fi
    if [[ "$boot_completed" == "1" ]]; then
      return 0
    fi
    sleep 2
  done
  return 1
}

capture_preflight() {
  adb_shell getprop > "$ARTIFACT_DIR/preflight.getprop.txt" || true
  adb_shell wm size > "$ARTIFACT_DIR/preflight.wm_size.txt" || true
  adb_shell pm list packages "$APP_ID" \
    > "$ARTIFACT_DIR/preflight.packages.txt" || true
}

extract_sync_runtime_telemetry_report() {
  local smoke_test="$1"
  local log_file="$2"
  local safe_name
  safe_name="$(sanitize_name "$smoke_test")"

  if python3 - "$smoke_test" "$log_file" "$REPORT_DIR" "$ARTIFACT_DIR" "$safe_name" <<'PY'
import csv
import json
import os
import sys

smoke_test, log_file, report_dir, artifact_dir, safe_name = sys.argv[1:]

with open(log_file, "r", encoding="utf-8", errors="ignore") as handle:
    lines = handle.readlines()

capturing = False
json_lines = []
found = False
for raw_line in lines:
    line = raw_line.rstrip("\n")
    if "SYNC_RUNTIME_TELEMETRY_JSON_START" in line:
        capturing = True
        json_lines = []
        found = True
        continue
    if "SYNC_RUNTIME_TELEMETRY_JSON_END" in line and capturing:
        break
    if capturing:
        json_lines.append(raw_line)

if not found:
    sys.exit(10)

payload = "".join(json_lines).strip()
if not payload:
    sys.exit(11)

data = json.loads(payload)
report_name = f"android-{os.path.splitext(os.path.basename(smoke_test))[0]}"
os.makedirs(report_dir, exist_ok=True)
json_path = os.path.join(report_dir, f"{report_name}.json")
md_path = os.path.join(report_dir, f"{report_name}.md")
csv_path = os.path.join(report_dir, f"{report_name}.csv")
artifact_json_path = os.path.join(artifact_dir, f"{safe_name}.telemetry.json")

with open(json_path, "w", encoding="utf-8") as handle:
    json.dump(data, handle, ensure_ascii=False, indent=2)
with open(artifact_json_path, "w", encoding="utf-8") as handle:
    json.dump(data, handle, ensure_ascii=False, indent=2)

status = data.get("status", "unknown")
telemetry_level = data.get("telemetryLevel", "n/a")
reason = str(data.get("reason", "")).strip()
action = str(data.get("action", "")).strip()
recommendation = str(data.get("recommendation", "")).strip()
generated_at = str(data.get("generatedAt", "")).strip()
input_data = data.get("input", {})

with open(md_path, "w", encoding="utf-8") as handle:
    handle.write("# Android Sync Runtime 遥测回归报告\n\n")
    handle.write(f"- sourceTest: {smoke_test}\n")
    handle.write(f"- status: {status}\n")
    handle.write(f"- telemetryLevel: {telemetry_level}\n")
    if reason:
        handle.write(f"- reason: {reason}\n")
    if action:
        handle.write(f"- action: {action}\n")
    if recommendation:
        handle.write(f"- recommendation: {recommendation}\n")
    if generated_at:
        handle.write(f"- generatedAt: {generated_at}\n")
    if input_data:
        handle.write("\n## Input\n")
        for key, value in input_data.items():
            handle.write(f"- {key}: {value}\n")

rows = [
    ["field", "value"],
    ["sourceTest", smoke_test],
    ["status", status],
    ["telemetryLevel", telemetry_level],
    ["reason", reason],
    ["action", action],
    ["recommendation", recommendation],
    ["generatedAt", generated_at],
]
for key, value in input_data.items():
    rows.append([f"input.{key}", str(value)])

with open(csv_path, "w", encoding="utf-8", newline="") as handle:
    writer = csv.writer(handle)
    writer.writerows(rows)
PY
  then
    log "sync runtime telemetry artifact generated for ${smoke_test}"
    return 0
  else
    local rc=$?
    if [[ "$smoke_test" == "integration_test/sync_runtime_backup_restore_rebind_flow_test.dart" ]]; then
      log "sync runtime telemetry extraction failed for ${smoke_test} (rc=${rc})"
      return 1
    fi
    return 0
  fi
}

run_smoke_test() {
  local smoke_test="$1"
  local safe_name
  safe_name="$(sanitize_name "$smoke_test")"

  for ((attempt = 1; attempt <= RETRIES; attempt++)); do
    local log_file="$ARTIFACT_DIR/${safe_name}.attempt${attempt}.log"
    log "running ${smoke_test} (attempt ${attempt}/${RETRIES})"
    adb_shell pm clear "$APP_ID" >/dev/null 2>&1 || true
    adb_command logcat -c >/dev/null 2>&1 || true

    if GRADLE_OPTS="${GRADLE_OPTS:-} ${GRADLE_OPTS_E2E}" flutter test \
      "$smoke_test" \
      -d "$DEVICE" \
      --flavor "$FLAVOR" \
      --dart-define=JIVE_E2E=true 2>&1 | tee "$log_file"; then
      extract_sync_runtime_telemetry_report "$smoke_test" "$log_file"
      return 0
    fi

    capture_diagnostics "${safe_name}.attempt${attempt}"
    adb_shell am force-stop "$APP_ID" >/dev/null 2>&1 || true
    adb_command logcat -c >/dev/null 2>&1 || true
    adb_recover

    if ((attempt < RETRIES)); then
      sleep 2
    fi
  done

  return 1
}

log "artifacts will be collected under $ARTIFACT_DIR"
adb start-server >/dev/null 2>&1 || true
adb_command wait-for-device >/dev/null 2>&1 || true
if ! wait_for_boot_completed; then
  log "device boot did not complete within ${BOOT_TIMEOUT_SECONDS}s"
  capture_diagnostics "preflight.boot_timeout"
  exit 1
fi
adb_shell input keyevent 82 >/dev/null 2>&1 || true
adb_command logcat -c >/dev/null 2>&1 || true
capture_preflight

for smoke_test in "${SMOKE_TESTS[@]}"; do
  run_smoke_test "$smoke_test"
done

log "all Android E2E smoke tests passed"
