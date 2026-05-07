#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/verify_release_android_smoke_artifacts.sh <artifact-dir>

Verifies a local Android smoke artifact directory produced by:
  scripts/run_android_local_feature_smoke.sh
  scripts/run_release_android_smoke.sh

Checks:
  - summary.md exists and reports status: passed
  - final home crash/alert logs are empty
  - final home UI evidence contains guest/net-worth anchors
  - scenario-specific UI summary files contain expected text anchors
  - scenario-specific crash/alert logs are empty for key steps

Output:
  Writes release_android_smoke_artifact_verification.md in the artifact dir.
EOF
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi

ARTIFACT_DIR="${1:-}"
if [[ -z "$ARTIFACT_DIR" ]]; then
  usage >&2
  exit 2
fi

SUMMARY_FILE="$ARTIFACT_DIR/summary.md"
REPORT_FILE="$ARTIFACT_DIR/release_android_smoke_artifact_verification.md"
FAILURES=0
WARNINGS=0
DETAILS=()

file_size_bytes() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    printf 'missing\n'
    return 0
  fi
  if stat -f%z "$file" >/dev/null 2>&1; then
    stat -f%z "$file"
  else
    stat -c%s "$file"
  fi
}

summary_value() {
  local key="$1"
  sed -n "s/^- $key: //p" "$SUMMARY_FILE" | head -1
}

record_pass() {
  DETAILS+=("- pass: $*")
}

record_warn() {
  DETAILS+=("- warn: $*")
  WARNINGS=$((WARNINGS + 1))
}

record_fail() {
  DETAILS+=("- fail: $*")
  FAILURES=$((FAILURES + 1))
}

require_file() {
  local relative="$1"
  local file="$ARTIFACT_DIR/$relative"
  if [[ -f "$file" ]]; then
    record_pass "$relative exists"
  else
    record_fail "$relative is missing"
  fi
}

require_non_empty_file() {
  local relative="$1"
  local file="$ARTIFACT_DIR/$relative"
  local size
  size="$(file_size_bytes "$file")"
  if [[ "$size" =~ ^[0-9]+$ ]] && ((size > 0)); then
    record_pass "$relative exists and is non-empty"
  else
    record_fail "$relative expected non-empty, got $size"
  fi
}

require_zero_file() {
  local relative="$1"
  local file="$ARTIFACT_DIR/$relative"
  local size
  size="$(file_size_bytes "$file")"
  if [[ "$size" == "0" ]]; then
    record_pass "$relative is empty"
  else
    record_fail "$relative expected 0 bytes, got $size"
  fi
}

require_xml_hierarchy() {
  local relative="$1"
  local file="$ARTIFACT_DIR/$relative"
  if [[ ! -f "$file" ]]; then
    record_fail "$relative is missing"
    return
  fi

  if python3 - "$file" <<'PY'
import sys
import xml.etree.ElementTree as ET

path = sys.argv[1]
try:
    root = ET.parse(path).getroot()
except ET.ParseError:
    sys.exit(1)

sys.exit(0 if root.tag == "hierarchy" else 1)
PY
  then
    record_pass "$relative is parseable uiautomator XML"
  else
    record_fail "$relative is not parseable uiautomator XML"
  fi
}

require_contains() {
  local relative="$1"
  local needle="$2"
  local file="$ARTIFACT_DIR/$relative"
  if [[ ! -f "$file" ]]; then
    record_fail "$relative is missing; cannot find '$needle'"
    return
  fi
  if grep -Fq -- "$needle" "$file"; then
    record_pass "$relative contains '$needle'"
  else
    record_fail "$relative missing '$needle'"
  fi
}

require_any_contains() {
  local pattern="$1"
  local needle="$2"
  local matches=()
  local file

  while IFS= read -r file; do
    matches+=("$file")
  done < <(compgen -G "$ARTIFACT_DIR/$pattern" || true)

  if ((${#matches[@]} == 0)); then
    record_fail "no files match '$pattern'; cannot find '$needle'"
    return
  fi

  for file in "${matches[@]}"; do
    if grep -Fq -- "$needle" "$file"; then
      record_pass "$pattern contains '$needle' in ${file#$ARTIFACT_DIR/}"
      return
    fi
  done

  record_fail "$pattern missing '$needle'"
}

require_summary_field() {
  local key="$1"
  local value
  value="$(summary_value "$key")"
  if [[ -n "$value" ]]; then
    record_pass "summary $key is present"
  else
    record_fail "summary $key is missing"
  fi
}

require_summary_sha256() {
  local value
  value="$(summary_value apkSha256)"
  if [[ "$value" =~ ^[0-9a-f]{64}$ ]]; then
    record_pass "summary apkSha256 is a 64-char hex digest"
  else
    record_fail "summary apkSha256 expected 64-char hex digest, got '${value:-missing}'"
  fi
}

require_summary_artifact_dir_matches() {
  local value
  value="$(summary_value artifactDir)"
  if [[ -z "$value" ]]; then
    record_fail "summary artifactDir is missing"
    return
  fi

  if python3 - "$ARTIFACT_DIR" "$value" <<'PY'
import pathlib
import sys

expected = pathlib.Path(sys.argv[1]).expanduser().resolve()
actual = pathlib.Path(sys.argv[2]).expanduser().resolve()
sys.exit(0 if expected == actual else 1)
PY
  then
    record_pass "summary artifactDir matches checked directory"
  else
    record_fail "summary artifactDir '$value' does not match checked directory '$ARTIFACT_DIR'"
  fi
}

require_step_artifacts() {
  local prefix="$1"
  require_non_empty_file "$prefix.png"
  require_xml_hierarchy "$prefix.xml"
  require_non_empty_file "$prefix.summary.txt"
  require_zero_file "$prefix.crash.log"
  require_zero_file "$prefix.alerts.log"
}

verify_common() {
  require_file "summary.md"
  if [[ ! -f "$SUMMARY_FILE" ]]; then
    return
  fi

  local status
  local final_crash_bytes
  status="$(summary_value status)"
  final_crash_bytes="$(summary_value finalCrashBytes)"

  require_summary_field "gitCommit"
  require_summary_field "device"
  require_summary_field "flavor"
  require_summary_field "scenario"
  require_summary_field "package"
  require_summary_field "apkPath"
  require_summary_sha256
  require_summary_artifact_dir_matches

  if [[ "$status" == "passed" ]]; then
    record_pass "summary status is passed"
  else
    record_fail "summary status expected passed, got '${status:-missing}'"
  fi

  if [[ "$final_crash_bytes" == "0" ]]; then
    record_pass "summary finalCrashBytes is 0"
  else
    record_fail "summary finalCrashBytes expected 0, got '${final_crash_bytes:-missing}'"
  fi

  require_step_artifacts "launch"
  require_step_artifacts "final_home"
  require_contains "final_home.summary.txt" "访客"
  require_contains "final_home.summary.txt" "净资产"
  if grep -Fq -- "打开菜单" "$ARTIFACT_DIR/final_home.summary.txt" 2>/dev/null; then
    record_pass "final_home.summary.txt contains optional '打开菜单' anchor"
  else
    record_warn "final_home.summary.txt missing optional '打开菜单' anchor"
  fi
}

verify_saas_gates() {
  require_step_artifacts "saas_settings"
  require_step_artifacts "saas_subscription"
  require_step_artifacts "saas_cloud_sync_gate"
  require_step_artifacts "saas_cloud_sync_subscription"
  require_contains "saas_settings.summary.txt" "账户与订阅"
  require_contains "saas_settings.summary.txt" "云同步设置"
  require_contains "saas_subscription.summary.txt" "升级方案"
  require_contains "saas_subscription.summary.txt" "当前方案"
  require_any_contains "saas_subscription*.summary.txt" "云同步与多设备使用"
  require_any_contains "saas_subscription_restore*.summary.txt" "恢复购买"
  require_contains "saas_cloud_sync_gate.summary.txt" "此功能需要订阅版"
  require_contains "saas_cloud_sync_gate.summary.txt" "了解订阅版"
  require_contains "saas_cloud_sync_gate.summary.txt" "稍后再说"
}

verify_settings_navigation() {
  require_step_artifacts "settings_navigation_top"
  require_step_artifacts "settings_navigation_language_picker"
  require_step_artifacts "settings_navigation_privacy_policy"
  require_contains "settings_navigation_top.summary.txt" "设置"
  require_contains "settings_navigation_top.summary.txt" "账户与订阅"
  require_contains "settings_navigation_top.summary.txt" "云同步设置"
  require_contains "settings_navigation_top.summary.txt" "外观"
  require_contains "settings_navigation_top.summary.txt" "应用语言"
  require_contains "settings_navigation_language_picker.summary.txt" "选择语言"
  require_contains "settings_navigation_language_picker.summary.txt" "简体中文"
  require_contains "settings_navigation_language_picker.summary.txt" "English"
  require_contains "settings_navigation_privacy_policy.summary.txt" "Jive 积叶 隐私政策"
  require_contains "settings_navigation_privacy_policy.summary.txt" "数据存储"
}

verify_quick_entry_hub() {
  require_step_artifacts "quick_entry_hub"
  require_step_artifacts "quick_entry_manual_transaction"
  for anchor in "手动记账" "语音记账" "对话记账" "截图识别" "从模板记" "从分享记"; do
    require_contains "quick_entry_hub.summary.txt" "$anchor"
  done
  for anchor in "支出" "收入" "转账" "餐饮" "现金" "再记"; do
    require_contains "quick_entry_manual_transaction.summary.txt" "$anchor"
  done
}

verify_transaction_entry() {
  require_step_artifacts "transaction_entry"
  require_step_artifacts "transaction_entry_operator_toggle"
  require_step_artifacts "transaction_entry_expression"
  for anchor in "支出" "收入" "转账" "餐饮" "现金" "再记"; do
    require_contains "transaction_entry.summary.txt" "$anchor"
  done
  require_contains "transaction_entry_operator_toggle.summary.txt" "当前×"
  require_contains "transaction_entry_expression.summary.txt" "1+2×3"
  require_contains "transaction_entry_expression.summary.txt" "7.00"
  require_contains "transaction_entry_expression.summary.txt" "展开备注"
}

write_report() {
  local status="$1"
  local scenario="$2"
  local generated_at
  generated_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

  {
    printf '# Release Android Smoke Artifact Verification\n\n'
    printf -- '- generatedAt: %s\n' "$generated_at"
    printf -- '- status: %s\n' "$status"
    printf -- '- scenario: %s\n' "${scenario:-unknown}"
    printf -- '- artifactDir: %s\n' "$ARTIFACT_DIR"
    printf -- '- summary: %s\n' "$SUMMARY_FILE"
    printf -- '- failures: %s\n' "$FAILURES"
    printf -- '- warnings: %s\n\n' "$WARNINGS"
    printf '## Checks\n\n'
    printf '%s\n' "${DETAILS[@]}"
  } > "$REPORT_FILE"
}

verify_common

SCENARIO=""
if [[ -f "$SUMMARY_FILE" ]]; then
  SCENARIO="$(summary_value scenario)"
fi

case "$SCENARIO" in
  guest-home|home)
    ;;
  saas-gates)
    verify_saas_gates
    ;;
  settings-navigation)
    verify_settings_navigation
    ;;
  quick-entry-hub)
    verify_quick_entry_hub
    ;;
  transaction-entry)
    verify_transaction_entry
    ;;
  all)
    verify_saas_gates
    verify_settings_navigation
    verify_quick_entry_hub
    verify_transaction_entry
    ;;
  "")
    record_fail "summary scenario is missing"
    ;;
  *)
    record_fail "unknown summary scenario '$SCENARIO'"
    ;;
esac

if ((FAILURES == 0)); then
  write_report "passed" "$SCENARIO"
  printf '[release-android-smoke-verifier] passed: %s\n' "$REPORT_FILE"
  exit 0
fi

write_report "failed" "$SCENARIO"
printf '[release-android-smoke-verifier] failed with %s failure(s): %s\n' "$FAILURES" "$REPORT_FILE" >&2
exit 1
