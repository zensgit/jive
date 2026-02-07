#!/usr/bin/env bash
set -euo pipefail

# Basic adb smoke verification for Jive Dev flows:
# 1) Launch app + capture home.
# 2) Open debug menu and verify entries.
# 3) Open recurring list screen and form screen.
# 4) Open budget screen and check it does not stay in loading spinner forever.
#
# Usage:
#   bash scripts/verify_dev_flow.sh [package]
# Example:
#   bash scripts/verify_dev_flow.sh com.jivemoney.app.dev

APP_ID="${1:-com.jivemoney.app.dev}"
ACTIVITY="${APP_ID}/com.jive.app.MainActivity"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT_DIR="/tmp/jive-verify-${STAMP}"
mkdir -p "${OUT_DIR}"

log() {
  echo "[verify] $*"
}

fail() {
  echo "[verify][FAIL] $*"
  echo "[verify] artifacts: ${OUT_DIR}"
  exit 1
}

dump_ui() {
  local name="$1"
  adb shell uiautomator dump /sdcard/"${name}.xml" >/dev/null
  adb pull /sdcard/"${name}.xml" "${OUT_DIR}/${name}.xml" >/dev/null
  sed 's/></>\
</g' "${OUT_DIR}/${name}.xml" > "${OUT_DIR}/${name}.nodes.xml"
}

cap() {
  local name="$1"
  adb exec-out screencap -p > "${OUT_DIR}/${name}.png"
}

tap_xy() {
  local x="$1"
  local y="$2"
  adb shell input tap "${x}" "${y}"
}

tap_text_once() {
  local text="$1"
  local xml="$2"
  local line bounds x1 y1 x2 y2 cx cy
  line="$(grep -m1 "text=\"${text}\"" "${xml}" || true)"
  if [[ -z "${line}" ]]; then
    line="$(grep -m1 "content-desc=\"${text}" "${xml}" || true)"
  fi
  if [[ -z "${line}" ]]; then
    return 1
  fi
  bounds="$(echo "${line}" | sed -E -n 's/.*bounds="\[([0-9]+),([0-9]+)\]\[([0-9]+),([0-9]+)\]".*/\1 \2 \3 \4/p')"
  if [[ -z "${bounds}" ]]; then
    return 1
  fi
  read -r x1 y1 x2 y2 <<<"${bounds}"
  cx="$(((x1 + x2) / 2))"
  cy="$(((y1 + y2) / 2))"
  tap_xy "${cx}" "${cy}"
  return 0
}

tap_text() {
  local text="$1"
  local name="$2"
  dump_ui "${name}"
  if ! tap_text_once "${text}" "${OUT_DIR}/${name}.nodes.xml"; then
    fail "cannot find text '${text}' in ${name}"
  fi
}

tap_text_with_scroll() {
  local text="$1"
  local base="$2"
  local max_try="${3:-6}"
  local i name
  for ((i = 1; i <= max_try; i++)); do
    name="${base}_${i}"
    dump_ui "${name}"
    if tap_text_once "${text}" "${OUT_DIR}/${name}.nodes.xml"; then
      return 0
    fi
    adb shell input swipe 540 2100 540 1200 300
    sleep 1
  done
  return 1
}

tap_top_right_clickable() {
  local xml="$1"
  local best=""
  local best_x2=0
  local line bounds x1 y1 x2 y2
  while IFS= read -r line; do
    bounds="$(echo "${line}" | sed -E -n 's/.*bounds="\[([0-9]+),([0-9]+)\]\[([0-9]+),([0-9]+)\]".*/\1 \2 \3 \4/p')"
    if [[ -z "${bounds}" ]]; then
      continue
    fi
    read -r x1 y1 x2 y2 <<<"${bounds}"
    if (( y2 <= 340 )) && (( (y2 - y1) >= 80 )) && (( x2 > best_x2 )); then
      best_x2="${x2}"
      best="${x1} ${y1} ${x2} ${y2}"
    fi
  done < <(grep 'clickable="true"' "${xml}" || true)

  if [[ -z "${best}" ]]; then
    return 1
  fi

  read -r x1 y1 x2 y2 <<<"${best}"
  tap_xy "$(((x1 + x2) / 2))" "$(((y1 + y2) / 2))"
  return 0
}

assert_text_exists() {
  local text="$1"
  local name="$2"
  if ! grep -q "${text}" "${OUT_DIR}/${name}.nodes.xml"; then
    fail "missing expected text '${text}' in ${name}"
  fi
}

log "artifacts dir: ${OUT_DIR}"
adb get-state >/dev/null 2>&1 || fail "no adb device"

log "force portrait for stable coordinates"
adb shell settings put system accelerometer_rotation 0 >/dev/null
adb shell settings put system user_rotation 0 >/dev/null
sleep 1

log "launch app: ${ACTIVITY}"
adb shell am force-stop "${APP_ID}" || true
adb shell am start -n "${ACTIVITY}" >/dev/null || fail "failed to start app"
sleep 2
cap "01_home"
dump_ui "01_home"
assert_text_exists "Recent Transactions" "01_home"

log "open debug sheet by tapping settings button"
if ! tap_top_right_clickable "${OUT_DIR}/01_home.nodes.xml"; then
  tap_xy 1124 270
fi
sleep 1
cap "02_debug_sheet"
dump_ui "02_debug_sheet"
if ! grep -q "分类管理" "${OUT_DIR}/02_debug_sheet.nodes.xml"; then
  tap_xy 1124 270
  sleep 1
  cap "02_debug_sheet_retry"
  dump_ui "02_debug_sheet_retry"
  if grep -q "分类管理" "${OUT_DIR}/02_debug_sheet_retry.nodes.xml"; then
    cp "${OUT_DIR}/02_debug_sheet_retry.nodes.xml" "${OUT_DIR}/02_debug_sheet.nodes.xml"
    cp "${OUT_DIR}/02_debug_sheet_retry.xml" "${OUT_DIR}/02_debug_sheet.xml"
    cp "${OUT_DIR}/02_debug_sheet_retry.png" "${OUT_DIR}/02_debug_sheet.png"
  fi
fi
assert_text_exists "分类管理" "02_debug_sheet"

log "open recurring page"
tap_text_with_scroll "周期记账" "02_debug_sheet_scrolled" 8 || fail "cannot open 周期记账"
sleep 1
cap "03_recurring_list"
dump_ui "03_recurring_list"
assert_text_exists "周期记账" "03_recurring_list"

log "open recurring form"
if ! tap_text_once "新建规则" "${OUT_DIR}/03_recurring_list.nodes.xml"; then
  tap_xy 990 170
fi
sleep 1
cap "04_recurring_form"
dump_ui "04_recurring_form"
assert_text_exists "新建周期规则" "04_recurring_form"

log "return to home"
adb shell input keyevent 4
sleep 1
adb shell input keyevent 4
sleep 1
cap "05_home_after_recurring"
dump_ui "05_home_after_recurring"

log "open debug sheet for budget"
dump_ui "05_home_for_debug"
if ! tap_top_right_clickable "${OUT_DIR}/05_home_for_debug.nodes.xml"; then
  tap_xy 1124 270
fi
sleep 1
cap "06_debug_sheet_budget"
dump_ui "06_debug_sheet_budget"
if ! grep -q "预算管理" "${OUT_DIR}/06_debug_sheet_budget.nodes.xml"; then
  tap_xy 1124 270
  sleep 1
  cap "06_debug_sheet_budget_retry"
  dump_ui "06_debug_sheet_budget_retry"
  if grep -q "预算管理" "${OUT_DIR}/06_debug_sheet_budget_retry.nodes.xml"; then
    cp "${OUT_DIR}/06_debug_sheet_budget_retry.nodes.xml" "${OUT_DIR}/06_debug_sheet_budget.nodes.xml"
    cp "${OUT_DIR}/06_debug_sheet_budget_retry.xml" "${OUT_DIR}/06_debug_sheet_budget.xml"
    cp "${OUT_DIR}/06_debug_sheet_budget_retry.png" "${OUT_DIR}/06_debug_sheet_budget.png"
  fi
fi

tap_text_with_scroll "预算管理" "06_debug_sheet_budget_scrolled" 8 || fail "cannot open 预算管理"
sleep 2
cap "07_budget_open"
dump_ui "07_budget_open"
assert_text_exists "预算管理" "07_budget_open"

log "check loading spinner does not persist"
sleep 4
cap "08_budget_after_wait"
dump_ui "08_budget_after_wait"
if grep -q "progressbar" "${OUT_DIR}/08_budget_after_wait.nodes.xml"; then
  fail "budget screen still shows loading indicator after wait"
fi

log "PASS"
echo "[verify] artifacts: ${OUT_DIR}"
