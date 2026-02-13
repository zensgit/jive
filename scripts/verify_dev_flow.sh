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
ORIG_ACCELEROMETER_ROTATION=""
ORIG_USER_ROTATION=""

log() {
  echo "[verify] $*"
}

fail() {
  echo "[verify][FAIL] $*"
  echo "[verify] artifacts: ${OUT_DIR}"
  exit 1
}

current_focus_pkg() {
  adb shell dumpsys activity activities 2>/dev/null \
    | sed -n 's/.*topResumedActivity=ActivityRecord{[^ ]* [^ ]* \([^ \/}]*\)\/.*/\1/p' \
    | tail -n 1
}

ensure_app_foreground() {
  local max_try="${1:-3}"
  local i pkg
  for ((i = 1; i <= max_try; i++)); do
    pkg="$(current_focus_pkg || true)"
    if [[ "${pkg}" == "${APP_ID}" ]]; then
      return 0
    fi
    adb shell am start -n "${ACTIVITY}" >/dev/null || true
    sleep 1
  done
  pkg="$(current_focus_pkg || true)"
  fail "app not foreground, current package: ${pkg:-unknown}"
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
    # Flutter a11y nodes sometimes merge section title + tile title + subtitle
    # into a single content-desc with line breaks.
    line="$(grep -m1 "content-desc=\"[^\"]*${text}[^\"]*\".*clickable=\"true\"" "${xml}" || true)"
  fi
  if [[ -z "${line}" ]]; then
    line="$(grep -m1 "content-desc=\"[^\"]*${text}[^\"]*\"" "${xml}" || true)"
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

dismiss_auto_permission_dialog_if_present() {
  local xml="$1"
  if ! grep -q "自动记账权限未开启" "${xml}"; then
    return 1
  fi
  log "dismiss auto permission dialog (overlay)"
  if tap_text_once "稍后" "${xml}"; then
    sleep 1
    return 0
  fi
  if tap_text_once "关闭" "${xml}"; then
    sleep 1
    return 0
  fi
  if tap_text_once "取消" "${xml}"; then
    sleep 1
    return 0
  fi
  fail "auto permission dialog present but cannot dismiss"
}

tap_text() {
  local text="$1"
  local name="$2"
  dump_ui "${name}"
  if dismiss_auto_permission_dialog_if_present "${OUT_DIR}/${name}.nodes.xml"; then
    dump_ui "${name}"
  fi
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
    if dismiss_auto_permission_dialog_if_present "${OUT_DIR}/${name}.nodes.xml"; then
      continue
    fi
    if tap_text_once "${text}" "${OUT_DIR}/${name}.nodes.xml"; then
      return 0
    fi
    adb shell input swipe 540 2100 540 1200 300
    sleep 1
  done
  return 1
}

tap_text_with_scroll_small() {
  local text="$1"
  local base="$2"
  local max_try="${3:-10}"
  local i name
  for ((i = 1; i <= max_try; i++)); do
    name="${base}_${i}"
    dump_ui "${name}"
    if dismiss_auto_permission_dialog_if_present "${OUT_DIR}/${name}.nodes.xml"; then
      continue
    fi
    if tap_text_once "${text}" "${OUT_DIR}/${name}.nodes.xml"; then
      return 0
    fi
    # Smaller scroll step for bottom sheets: avoids skipping items near edges.
    adb shell input swipe 540 2550 540 2200 250
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

tap_top_bar_clickable_rank_from_right() {
  # Tap the Nth clickable element in the top bar area (rank 1 = rightmost).
  local xml="$1"
  local rank="${2:-1}"
  local candidate bounds x1 y1 x2 y2 h

  candidate="$(
    grep 'clickable="true"' "${xml}" 2>/dev/null \
      | while IFS= read -r line; do
          bounds="$(echo "${line}" | sed -E -n 's/.*bounds="\\[([0-9]+),([0-9]+)\\]\\[([0-9]+),([0-9]+)\\]".*/\\1 \\2 \\3 \\4/p')"
          if [[ -z "${bounds}" ]]; then
            continue
          fi
          read -r x1 y1 x2 y2 <<<"${bounds}"
          h="$((y2 - y1))"
          # Some devices/layouts push the app bar slightly lower.
          if (( y2 <= 420 )) && (( h >= 80 )); then
            # Sort key: x2 desc => rightmost first
            echo "${x2} ${x1} ${y1} ${x2} ${y2}"
          fi
        done \
      | sort -nr -k1,1 \
      | sed -n "${rank}p"
  )"

  if [[ -z "${candidate}" ]]; then
    return 1
  fi

  read -r _ x1 y1 x2 y2 <<<"${candidate}"
  tap_xy "$(((x1 + x2) / 2))" "$(((y1 + y2) / 2))"
  return 0
}

tap_first_parent_expand_toggle() {
  # Tap the left expand/collapse button of the first parent card (CategoryManagerScreen).
  local xml="$1"
  local candidate bounds x1 y1 x2 y2 h w

  candidate="$(
    grep 'clickable="true"' "${xml}" 2>/dev/null \
      | while IFS= read -r line; do
          bounds="$(echo "${line}" | sed -E -n 's/.*bounds="\\[([0-9]+),([0-9]+)\\]\\[([0-9]+),([0-9]+)\\]".*/\\1 \\2 \\3 \\4/p')"
          if [[ -z "${bounds}" ]]; then
            continue
          fi
          read -r x1 y1 x2 y2 <<<"${bounds}"
          h="$((y2 - y1))"
          w="$((x2 - x1))"
          # Body starts at y ~= 336. Pick the top-left-ish clickable button.
          if (( y1 >= 330 )) && (( y2 <= 1200 )) && (( x2 <= 360 )) && (( h >= 80 )) && (( w >= 80 )); then
            echo "${y1} ${x2} ${x1} ${y1} ${x2} ${y2}"
          fi
        done \
      | sort -n -k1,1 -k2,2 \
      | head -n 1
  )"

  if [[ -z "${candidate}" ]]; then
    return 1
  fi

  read -r _ _ x1 y1 x2 y2 <<<"${candidate}"
  tap_xy "$(((x1 + x2) / 2))" "$(((y1 + y2) / 2))"
  return 0
}

tap_first_parent_more_button() {
  # Tap the "more" button (right-side) on the first parent card header.
  local xml="$1"
  local candidate bounds x1 y1 x2 y2 h w

  candidate="$(
    grep 'class="android.widget.Button"' "${xml}" 2>/dev/null \
      | grep 'clickable="true"' \
      | grep 'content-desc=""' \
      | while IFS= read -r line; do
          bounds="$(echo "${line}" | sed -E -n 's/.*bounds=\"\\[([0-9]+),([0-9]+)\\]\\[([0-9]+),([0-9]+)\\]\".*/\\1 \\2 \\3 \\4/p')"
          if [[ -z "${bounds}" ]]; then
            continue
          fi
          read -r x1 y1 x2 y2 <<<"${bounds}"
          h="$((y2 - y1))"
          w="$((x2 - x1))"
          if (( y1 >= 500 )) && (( h >= 80 )) && (( w >= 80 )); then
            # Sort: topmost (y1 asc), then rightmost (x2 desc).
            echo "${y1} ${x2} ${x1} ${y1} ${x2} ${y2}"
          fi
        done \
      | sort -k1,1n -k2,2nr \
      | head -n 1
  )"

  if [[ -z "${candidate}" ]]; then
    return 1
  fi

  read -r _ _ x1 y1 x2 y2 <<<"${candidate}"
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

wait_for_text() {
  # Wait until a text appears in UI dump (useful to avoid capturing transition scrims).
  local text="$1"
  local base="$2"
  local max_try="${3:-8}"
  local i name
  for ((i = 1; i <= max_try; i++)); do
    name="${base}_${i}"
    dump_ui "${name}"
    if dismiss_auto_permission_dialog_if_present "${OUT_DIR}/${name}.nodes.xml"; then
      continue
    fi
    if grep -q "${text}" "${OUT_DIR}/${name}.nodes.xml"; then
      return 0
    fi
    sleep 1
  done
  return 1
}

restore_rotation() {
  if [[ -n "${ORIG_ACCELEROMETER_ROTATION}" ]]; then
    adb shell settings put system accelerometer_rotation "${ORIG_ACCELEROMETER_ROTATION}" >/dev/null 2>&1 || true
  fi
  if [[ -n "${ORIG_USER_ROTATION}" ]]; then
    adb shell settings put system user_rotation "${ORIG_USER_ROTATION}" >/dev/null 2>&1 || true
  fi
}

log "artifacts dir: ${OUT_DIR}"
adb get-state >/dev/null 2>&1 || fail "no adb device"
trap restore_rotation EXIT

log "force portrait for stable coordinates"
ORIG_ACCELEROMETER_ROTATION="$(adb shell settings get system accelerometer_rotation 2>/dev/null | tr -d '\r' | tail -n 1)"
ORIG_USER_ROTATION="$(adb shell settings get system user_rotation 2>/dev/null | tr -d '\r' | tail -n 1)"
adb shell settings put system accelerometer_rotation 0 >/dev/null
adb shell settings put system user_rotation 0 >/dev/null
sleep 1

log "launch app: ${ACTIVITY}"
adb shell am force-stop "${APP_ID}" || true
adb shell am start -n "${ACTIVITY}" >/dev/null || fail "failed to start app"
sleep 2
ensure_app_foreground 5
cap "01_home"
dump_ui "01_home"
if grep -q "自动记账权限未开启" "${OUT_DIR}/01_home.nodes.xml"; then
  log "dismiss auto permission dialog"
  if ! tap_text_once "稍后" "${OUT_DIR}/01_home.nodes.xml"; then
    tap_text_once "关闭" "${OUT_DIR}/01_home.nodes.xml" || true
  fi
  sleep 1
  cap "01_home_after_dialog"
  dump_ui "01_home_after_dialog"
  if grep -q "自动记账权限未开启" "${OUT_DIR}/01_home_after_dialog.nodes.xml"; then
    fail "auto permission dialog still visible after dismiss"
  fi
fi

dump_ui "01_home_for_menu"
log "open debug sheet by tapping settings button"
if ! tap_top_right_clickable "${OUT_DIR}/01_home_for_menu.nodes.xml"; then
  tap_xy 1124 270
fi
sleep 1
ensure_app_foreground 3
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

log "open settings and verify category icon style dialog + switch to hybrid"
tap_text_with_scroll_small "设置" "02_debug_sheet_settings_scrolled" 10 || fail "cannot open 设置"
if ! wait_for_text "分类图标风格" "02_settings_wait" 8; then
  cap "02_settings_timeout"
  dump_ui "02_settings_timeout"
  fail "settings screen did not appear in time"
fi
cap "02_settings"
dump_ui "02_settings"
assert_text_exists "设置" "02_settings"
assert_text_exists "分类图标风格" "02_settings"

tap_text_with_scroll_small "分类图标风格" "02_settings_style_scrolled" 6 || fail "cannot open 分类图标风格"
sleep 1
  cap "02_icon_style_dialog"
  dump_ui "02_icon_style_dialog"
  assert_text_exists "分类图标风格" "02_icon_style_dialog"
  assert_text_exists "彩色" "02_icon_style_dialog"
  assert_text_exists "单色" "02_icon_style_dialog"
  assert_text_exists "混合" "02_icon_style_dialog"
  tap_text "混合" "02_icon_style_dialog"
  if ! wait_for_text "混合" "02_settings_after_icon_style_wait" 8; then
    cap "02_settings_after_icon_style_timeout"
    dump_ui "02_settings_after_icon_style_timeout"
    fail "icon style did not switch to hybrid"
  fi
  cap "02_settings_after_icon_style"
  dump_ui "02_settings_after_icon_style"
  assert_text_exists "混合" "02_settings_after_icon_style"

log "return to home from settings"
adb shell input keyevent 4
sleep 1
ensure_app_foreground 3
cap "02_home_after_settings"
dump_ui "02_home_after_settings"

log "open debug sheet for category checks"
dump_ui "02_home_for_debug"
if ! tap_top_right_clickable "${OUT_DIR}/02_home_for_debug.nodes.xml"; then
  tap_xy 1124 270
fi
sleep 1
ensure_app_foreground 3
cap "02_debug_sheet_after_settings"
dump_ui "02_debug_sheet_after_settings"
assert_text_exists "分类管理" "02_debug_sheet_after_settings"

log "open category manager"
tap_text "分类管理" "02_debug_sheet_after_settings"
sleep 1
cap "03_category_manager"
dump_ui "03_category_manager"
assert_text_exists "分类管理" "03_category_manager"

if grep -q "一键添加常用分类" "${OUT_DIR}/03_category_manager.nodes.xml" \
  || grep -q "一键添加" "${OUT_DIR}/03_category_manager.nodes.xml"; then
  log "category manager empty, quick add common categories"
  if ! tap_text_once "一键添加常用分类" "${OUT_DIR}/03_category_manager.nodes.xml"; then
    tap_text_once "一键添加" "${OUT_DIR}/03_category_manager.nodes.xml" || true
  fi
  sleep 3
  cap "03_category_manager_after_seed"
  dump_ui "03_category_manager_after_seed"
fi

dump_ui "03_category_manager_for_add_parent"
log "verify create category screen contains force-tinted switch (parent category)"
if ! tap_top_bar_clickable_rank_from_right "${OUT_DIR}/03_category_manager_for_add_parent.nodes.xml" 2; then
  # Fallback to an approximate coordinate for the + button.
  tap_xy 1012 240
fi
sleep 1
cap "03_create_parent"
dump_ui "03_create_parent"
assert_text_exists "图标强制单色" "03_create_parent"
adb shell input keyevent 4
sleep 1

log "verify subcategory create screen contains force-tinted switch"
dump_ui "03_category_manager_for_parent_actions_sub"
if ! tap_first_parent_more_button "${OUT_DIR}/03_category_manager_for_parent_actions_sub.nodes.xml"; then
  # Fallback to a rough coordinate (first parent card "more" button).
  tap_xy 1030 868
fi
sleep 1
dump_ui "03_parent_actions_menu_sub"
assert_text_exists "修改" "03_parent_actions_menu_sub"
tap_text_with_scroll_small "添加子类" "03_parent_actions_add_sub" 8 || fail "cannot find 添加子类 action"
sleep 1
cap "04_create_sub"
dump_ui "04_create_sub"
assert_text_exists "图标强制单色" "04_create_sub"
adb shell input keyevent 4
sleep 1

log "verify edit category screen contains force-tinted switch"
dump_ui "03_category_manager_for_parent_actions_edit"
if ! tap_first_parent_more_button "${OUT_DIR}/03_category_manager_for_parent_actions_edit.nodes.xml"; then
  tap_xy 1030 868
fi
sleep 1
dump_ui "03_parent_actions_menu_edit"
assert_text_exists "修改" "03_parent_actions_menu_edit"
tap_text_with_scroll_small "修改" "03_parent_actions_edit" 6 || fail "cannot find 修改 action"
sleep 1
cap "04_category_edit"
dump_ui "04_category_edit"
assert_text_exists "编辑分类" "04_category_edit"
assert_text_exists "图标强制单色" "04_category_edit"

FORCE_TINTED_ORIG="$(
  grep 'android.widget.Switch' "${OUT_DIR}/04_category_edit.nodes.xml" 2>/dev/null \
    | grep '图标强制单色' \
    | sed -E -n 's/.*checked="([^"]+)".*/\\1/p' \
    | head -n 1 \
    | tr -d '\r' \
    || true
)"
FORCE_TINTED_ORIG="$(echo "${FORCE_TINTED_ORIG}" | tr -d '\n' | xargs || true)"
if [[ "${FORCE_TINTED_ORIG}" != "true" && "${FORCE_TINTED_ORIG}" != "false" ]]; then
  FORCE_TINTED_ORIG="false"
fi
log "force-tinted original checked=${FORCE_TINTED_ORIG}"

if [[ "${FORCE_TINTED_ORIG}" != "true" ]]; then
  log "toggle force-tinted on and verify '单色' badge appears"
  if ! tap_text_once "图标强制单色" "${OUT_DIR}/04_category_edit.nodes.xml"; then
    fail "cannot toggle 图标强制单色 in category edit"
  fi
  sleep 1
  if ! tap_text_once "保存" "${OUT_DIR}/04_category_edit.nodes.xml"; then
    fail "cannot tap 保存 in category edit"
  fi
  sleep 2
else
  log "force-tinted already enabled, return to category manager"
  adb shell input keyevent 4
  sleep 1
fi

cap "04_category_manager_after_force_tinted"
dump_ui "04_category_manager_after_force_tinted"
if grep -q "单色" "${OUT_DIR}/04_category_manager_after_force_tinted.nodes.xml"; then
  log "badge '单色' detected in category manager UI dump"
else
  log "badge '单色' not found in uiautomator dump; fallback to verify switch checked state"
  dump_ui "04_category_manager_for_badge_fallback"
  if ! tap_first_parent_more_button "${OUT_DIR}/04_category_manager_for_badge_fallback.nodes.xml"; then
    tap_xy 1030 868
  fi
  sleep 1
  dump_ui "04_parent_actions_menu_badge_fallback"
  tap_text_with_scroll_small "修改" "04_parent_actions_edit_badge_fallback" 6 || fail "cannot find 修改 action (badge fallback)"
  sleep 1
  dump_ui "04_category_edit_badge_fallback"
  FORCE_TINTED_NOW="$(
    grep 'android.widget.Switch' "${OUT_DIR}/04_category_edit_badge_fallback.nodes.xml" 2>/dev/null \
      | grep '图标强制单色' \
      | sed -E -n 's/.*checked="([^"]+)".*/\\1/p' \
      | head -n 1 \
      | tr -d '\r' \
      || true
  )"
  FORCE_TINTED_NOW="$(echo "${FORCE_TINTED_NOW}" | tr -d '\n' | xargs || true)"
  if [[ "${FORCE_TINTED_NOW}" != "true" ]]; then
    fail "force-tinted switch not enabled after save (checked=${FORCE_TINTED_NOW:-unknown})"
  fi
  adb shell input keyevent 4
  sleep 1
fi

if [[ "${FORCE_TINTED_ORIG}" != "true" ]]; then
  log "restore force-tinted to off"
  dump_ui "04_category_manager_for_restore"
  if ! tap_first_parent_more_button "${OUT_DIR}/04_category_manager_for_restore.nodes.xml"; then
    tap_xy 1030 868
  fi
  sleep 1
  dump_ui "04_parent_actions_menu_restore"
  tap_text_with_scroll_small "修改" "04_parent_actions_edit_restore" 6 || fail "cannot find 修改 action (restore)"
  sleep 1
  dump_ui "04_category_edit_restore"
  if ! tap_text_once "图标强制单色" "${OUT_DIR}/04_category_edit_restore.nodes.xml"; then
    fail "cannot toggle 图标强制单色 off during restore"
  fi
  sleep 1
  if ! tap_text_once "保存" "${OUT_DIR}/04_category_edit_restore.nodes.xml"; then
    fail "cannot tap 保存 during restore"
  fi
  sleep 2
fi

log "return to home from category manager"
adb shell input keyevent 4
sleep 1
ensure_app_foreground 3
cap "04_home_after_categories"
dump_ui "04_home_after_categories"

log "open debug sheet for recurring"
dump_ui "04_home_for_recurring_menu"
if ! tap_top_right_clickable "${OUT_DIR}/04_home_for_recurring_menu.nodes.xml"; then
  tap_xy 1124 270
fi
sleep 1
ensure_app_foreground 3
cap "04_debug_sheet_recurring"
dump_ui "04_debug_sheet_recurring"

log "open recurring page"
tap_text_with_scroll "周期记账" "04_debug_sheet_scrolled" 8 || fail "cannot open 周期记账"
sleep 1
cap "05_recurring_list"
dump_ui "05_recurring_list"
assert_text_exists "周期记账" "05_recurring_list"

log "open recurring form"
if ! tap_text_once "新建规则" "${OUT_DIR}/05_recurring_list.nodes.xml"; then
  if ! tap_top_right_clickable "${OUT_DIR}/05_recurring_list.nodes.xml"; then
    tap_xy 1160 240
  fi
fi
sleep 1
cap "06_recurring_form"
dump_ui "06_recurring_form"
if ! grep -q "新建周期规则" "${OUT_DIR}/06_recurring_form.nodes.xml" \
  && ! grep -q "规则名称" "${OUT_DIR}/06_recurring_form.nodes.xml" \
  && ! grep -q "周期设置" "${OUT_DIR}/06_recurring_form.nodes.xml"; then
  fail "cannot open recurring form from recurring list"
fi

log "open category picker from recurring form"
if ! tap_text_once "分类" "${OUT_DIR}/06_recurring_form.nodes.xml"; then
  fail "cannot open category picker from recurring form"
fi
sleep 1
cap "06_recurring_category_picker"
dump_ui "06_recurring_category_picker"
assert_text_exists "选择分类" "06_recurring_category_picker"
adb shell input keyevent 4
sleep 1

log "return to home"
adb shell input keyevent 4
sleep 1
adb shell input keyevent 4
sleep 1
cap "07_home_after_recurring"
dump_ui "07_home_after_recurring"

log "open debug sheet for budget"
dump_ui "07_home_for_debug"
HOME_DEBUG_XML="${OUT_DIR}/07_home_for_debug.nodes.xml"
if grep -q "自动记账权限未开启" "${OUT_DIR}/07_home_for_debug.nodes.xml"; then
  log "dismiss auto permission dialog (before budget)"
  tap_text_once "稍后" "${OUT_DIR}/07_home_for_debug.nodes.xml" || tap_text_once "关闭" "${OUT_DIR}/07_home_for_debug.nodes.xml" || true
  sleep 1
  dump_ui "07_home_for_debug_after_dialog"
  HOME_DEBUG_XML="${OUT_DIR}/07_home_for_debug_after_dialog.nodes.xml"
fi
if ! tap_top_right_clickable "${HOME_DEBUG_XML}"; then
  tap_xy 1124 270
fi
sleep 1
ensure_app_foreground 3
cap "08_debug_sheet_budget"
dump_ui "08_debug_sheet_budget"
if ! grep -q "分类管理" "${OUT_DIR}/08_debug_sheet_budget.nodes.xml"; then
  log "budget step: debug sheet not detected, retry opening"
  tap_xy 1124 270
  sleep 1
  cap "08_debug_sheet_budget_retry"
  dump_ui "08_debug_sheet_budget_retry"
  if grep -q "分类管理" "${OUT_DIR}/08_debug_sheet_budget_retry.nodes.xml"; then
    cp "${OUT_DIR}/08_debug_sheet_budget_retry.nodes.xml" "${OUT_DIR}/08_debug_sheet_budget.nodes.xml"
    cp "${OUT_DIR}/08_debug_sheet_budget_retry.xml" "${OUT_DIR}/08_debug_sheet_budget.xml"
    cp "${OUT_DIR}/08_debug_sheet_budget_retry.png" "${OUT_DIR}/08_debug_sheet_budget.png"
  else
    fail "budget step: cannot open debug sheet"
  fi
fi

tap_text_with_scroll_small "预算管理" "08_debug_sheet_budget_scrolled" 12 || fail "cannot open 预算管理"
sleep 2
cap "09_budget_open"
dump_ui "09_budget_open"
assert_text_exists "预算管理" "09_budget_open"

log "check loading spinner does not persist"
sleep 4
cap "10_budget_after_wait"
dump_ui "10_budget_after_wait"
if grep -q "progressbar" "${OUT_DIR}/10_budget_after_wait.nodes.xml"; then
  fail "budget screen still shows loading indicator after wait"
fi

log "PASS"
echo "[verify] artifacts: ${OUT_DIR}"
