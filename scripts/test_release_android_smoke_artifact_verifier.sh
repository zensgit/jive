#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
VERIFIER="$SCRIPT_DIR/verify_release_android_smoke_artifacts.sh"

cd "$APP_DIR"

usage() {
  cat <<'EOF'
Usage:
  scripts/test_release_android_smoke_artifact_verifier.sh [--keep-fixtures]

Creates minimal local fixtures and validates:
  - guest-home artifacts pass
  - all-scenario artifacts pass
  - missing required anchors fail

This is a host-only contract self-test for the artifact verifier. It does not
run adb, start an emulator, build APKs, upload artifacts, or read secrets.
EOF
}

KEEP_FIXTURES=0
while (( "$#" )); do
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
      printf '[release-android-smoke-verifier-test] unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

ROOT="$(mktemp -d /tmp/jive-release-android-smoke-verifier-test.XXXXXX)"

cleanup() {
  if [[ "$KEEP_FIXTURES" -eq 1 ]]; then
    printf '[release-android-smoke-verifier-test] kept fixtures: %s\n' "$ROOT"
  else
    rm -rf "$ROOT"
  fi
}

trap cleanup EXIT INT TERM

log() {
  printf '[release-android-smoke-verifier-test] %s\n' "$*"
}

fail() {
  printf '[release-android-smoke-verifier-test] FAIL: %s\n' "$*" >&2
  exit 1
}

write_summary() {
  local dir="$1"
  local scenario="$2"
  local status="${3:-passed}"
  local final_crash_bytes="${4:-0}"

  cat > "$dir/summary.md" <<EOF
# Local Android Feature Smoke

- generatedAt: 20260507-000000
- status: $status
- message: fixture
- gitCommit: 0123456789abcdef0123456789abcdef01234567
- device: fixture-device
- emulator: fixture-emulator
- flavor: dev
- scenario: $scenario
- package: com.jivemoney.app.dev
- activity: com.jive.app.MainActivity
- artifactDir: $dir
- apkPath: /tmp/jive-fixture.apk
- apkSha256: 0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
- finalCrashBytes: $final_crash_bytes
- finalUiSummary: $dir/final_home.summary.txt
EOF
}

write_step() {
  local dir="$1"
  local prefix="$2"
  shift 2

  printf 'fixture image\n' > "$dir/$prefix.png"
  cat > "$dir/$prefix.xml" <<'EOF'
<hierarchy rotation="0">
  <node index="0" text="fixture" content-desc="" class="android.view.View" bounds="[0,0][100,100]" />
</hierarchy>
EOF
  : > "$dir/$prefix.crash.log"
  : > "$dir/$prefix.alerts.log"

  {
    printf 'fixture step: %s\n' "$prefix"
    local anchor
    for anchor in "$@"; do
      printf 'TextView: %s [0,0][100,100]\n' "$anchor"
    done
  } > "$dir/$prefix.summary.txt"
}

write_common_steps() {
  local dir="$1"
  write_step "$dir" launch "Jive" "欢迎"
  write_step "$dir" final_home "访客" "净资产" "打开菜单"
}

write_saas_steps() {
  local dir="$1"
  write_step "$dir" saas_settings "账户与订阅" "云同步设置"
  write_step "$dir" saas_subscription "升级方案" "当前方案"
  printf 'TextView: 云同步与多设备使用 [0,0][100,100]\n' > "$dir/saas_subscription_scrolled_1.summary.txt"
  printf 'TextView: 恢复购买 [0,0][100,100]\n' > "$dir/saas_subscription_restore_scrolled_1.summary.txt"
  write_step "$dir" saas_cloud_sync_gate "此功能需要订阅版" "了解订阅版" "稍后再说"
  write_step "$dir" saas_cloud_sync_subscription "升级方案" "云同步与多设备使用"
}

write_settings_steps() {
  local dir="$1"
  write_step "$dir" settings_navigation_top "设置" "账户与订阅" "云同步设置" "外观" "应用语言"
  write_step "$dir" settings_navigation_language_picker "选择语言" "简体中文" "English"
  write_step "$dir" settings_navigation_privacy_policy "Jive 积叶 隐私政策" "数据存储"
}

write_quick_entry_steps() {
  local dir="$1"
  write_step "$dir" quick_entry_hub "手动记账" "语音记账" "对话记账" "截图识别" "从模板记" "从分享记"
  write_step "$dir" quick_entry_manual_transaction "支出" "收入" "转账" "餐饮" "现金" "再记"
}

write_transaction_steps() {
  local dir="$1"
  write_step "$dir" transaction_entry "支出" "收入" "转账" "餐饮" "现金" "再记"
  write_step "$dir" transaction_entry_operator_toggle "当前×"
  write_step "$dir" transaction_entry_expression "1+2×3" "7.00" "展开备注"
}

create_fixture() {
  local name="$1"
  local scenario="$2"
  local dir="$ROOT/$name"

  mkdir -p "$dir"
  write_summary "$dir" "$scenario"
  write_common_steps "$dir"

  case "$scenario" in
    guest-home|home)
      ;;
    saas-gates)
      write_saas_steps "$dir"
      ;;
    settings-navigation)
      write_settings_steps "$dir"
      ;;
    quick-entry-hub)
      write_quick_entry_steps "$dir"
      ;;
    transaction-entry)
      write_transaction_steps "$dir"
      ;;
    all)
      write_saas_steps "$dir"
      write_settings_steps "$dir"
      write_quick_entry_steps "$dir"
      write_transaction_steps "$dir"
      ;;
    *)
      fail "unknown fixture scenario: $scenario"
      ;;
  esac

  printf '%s\n' "$dir"
}

assert_report_passed() {
  local dir="$1"
  grep -Fq -- "- status: passed" "$dir/release_android_smoke_artifact_verification.md" \
    || fail "expected verifier report to pass: $dir"
  grep -Fq -- "- failures: 0" "$dir/release_android_smoke_artifact_verification.md" \
    || fail "expected verifier report to have zero failures: $dir"
  grep -Fq -- "- warnings: 0" "$dir/release_android_smoke_artifact_verification.md" \
    || fail "expected verifier report to have zero warnings: $dir"
}

assert_report_failed_with() {
  local dir="$1"
  local needle="$2"
  grep -Fq -- "- status: failed" "$dir/release_android_smoke_artifact_verification.md" \
    || fail "expected verifier report to fail: $dir"
  grep -Fq -- "$needle" "$dir/release_android_smoke_artifact_verification.md" \
    || fail "expected verifier report to contain '$needle': $dir"
}

run_expected_pass() {
  local name="$1"
  local scenario="$2"
  local dir
  dir="$(create_fixture "$name" "$scenario")"

  "$VERIFIER" "$dir" > "$dir/verifier.stdout" 2> "$dir/verifier.stderr"
  assert_report_passed "$dir"
  log "pass fixture ok: $scenario"
}

run_missing_anchor_fails() {
  local dir
  dir="$(create_fixture missing-anchor all)"

  grep -Fv "7.00" "$dir/transaction_entry_expression.summary.txt" > "$dir/transaction_entry_expression.summary.tmp"
  mv "$dir/transaction_entry_expression.summary.tmp" "$dir/transaction_entry_expression.summary.txt"

  if "$VERIFIER" "$dir" > "$dir/verifier.stdout" 2> "$dir/verifier.stderr"; then
    fail "expected missing-anchor fixture to fail"
  fi

  assert_report_failed_with "$dir" "transaction_entry_expression.summary.txt missing '7.00'"
  log "negative fixture ok: missing required transaction result anchor"
}

run_expected_pass guest-home-pass guest-home
run_expected_pass all-pass all
run_missing_anchor_fails

log "all verifier self-tests passed"
