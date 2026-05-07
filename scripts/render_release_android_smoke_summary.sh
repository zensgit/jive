#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$APP_DIR"

usage() {
  cat <<'EOF'
Usage:
  scripts/render_release_android_smoke_summary.sh <artifact-dir>

Renders a concise release Android smoke summary from:
  <artifact-dir>/summary.md
  <artifact-dir>/release_android_smoke_artifact_verification.md

Output:
  - <artifact-dir>/latest.md
  - build/reports/release-android-smoke/latest.md

Notes:
  This renderer summarizes already-generated local smoke artifacts. It does not
  run adb, build APKs, upload artifacts, or read secrets.
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
VERIFICATION_FILE="$ARTIFACT_DIR/release_android_smoke_artifact_verification.md"
REPORT_ROOT="${JIVE_RELEASE_ANDROID_SMOKE_REPORT_DIR:-$APP_DIR/build/reports/release-android-smoke}"
LOCAL_LATEST="$ARTIFACT_DIR/latest.md"
GLOBAL_LATEST="$REPORT_ROOT/latest.md"

if [[ ! -f "$SUMMARY_FILE" ]]; then
  printf '[release-android-smoke-summary] missing summary: %s\n' "$SUMMARY_FILE" >&2
  exit 2
fi

value_from_markdown() {
  local file="$1"
  local key="$2"
  [[ -f "$file" ]] || return 0
  sed -n "s/^- $key: //p" "$file" | head -1
}

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

count_files() {
  find "$ARTIFACT_DIR" -maxdepth 1 -type f ! -name latest.md | wc -l | tr -d '[:space:]'
}

coverage_for_scenario() {
  local scenario="$1"
  case "$scenario" in
    guest-home|home)
      printf '%s\n' \
        "- guest-home: cold launch, onboarding skip, guest home evidence"
      ;;
    saas-gates)
      printf '%s\n' \
        "- guest-home: cold launch, onboarding skip, guest home evidence" \
        "- saas-gates: subscription entry and cloud-sync upgrade gate"
      ;;
    settings-navigation)
      printf '%s\n' \
        "- guest-home: cold launch, onboarding skip, guest home evidence" \
        "- settings-navigation: settings anchors, language picker, privacy policy"
      ;;
    quick-entry-hub)
      printf '%s\n' \
        "- guest-home: cold launch, onboarding skip, guest home evidence" \
        "- quick-entry-hub: long-press FAB hub and manual bookkeeping entry"
      ;;
    transaction-entry)
      printf '%s\n' \
        "- guest-home: cold launch, onboarding skip, guest home evidence" \
        "- transaction-entry: add-transaction anchors and 1+2×3=7.00 calculator flow"
      ;;
    all)
      printf '%s\n' \
        "- guest-home: cold launch, onboarding skip, guest home evidence" \
        "- saas-gates: subscription entry and cloud-sync upgrade gate" \
        "- settings-navigation: settings anchors, language picker, privacy policy" \
        "- quick-entry-hub: long-press FAB hub and manual bookkeeping entry" \
        "- transaction-entry: add-transaction anchors and 1+2×3=7.00 calculator flow"
      ;;
    *)
      printf '%s\n' "- unknown scenario: $scenario"
      ;;
  esac
}

generated_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
smoke_status="$(value_from_markdown "$SUMMARY_FILE" status)"
smoke_message="$(value_from_markdown "$SUMMARY_FILE" message)"
smoke_generated_at="$(value_from_markdown "$SUMMARY_FILE" generatedAt)"
git_commit="$(value_from_markdown "$SUMMARY_FILE" gitCommit)"
device="$(value_from_markdown "$SUMMARY_FILE" device)"
emulator="$(value_from_markdown "$SUMMARY_FILE" emulator)"
flavor="$(value_from_markdown "$SUMMARY_FILE" flavor)"
scenario="$(value_from_markdown "$SUMMARY_FILE" scenario)"
package_name="$(value_from_markdown "$SUMMARY_FILE" package)"
apk_path="$(value_from_markdown "$SUMMARY_FILE" apkPath)"
apk_sha256="$(value_from_markdown "$SUMMARY_FILE" apkSha256)"
final_crash_bytes="$(value_from_markdown "$SUMMARY_FILE" finalCrashBytes)"
final_ui_summary="$(value_from_markdown "$SUMMARY_FILE" finalUiSummary)"

verification_status="missing"
verification_failures="n/a"
verification_warnings="n/a"
if [[ -f "$VERIFICATION_FILE" ]]; then
  verification_status="$(value_from_markdown "$VERIFICATION_FILE" status)"
  verification_failures="$(value_from_markdown "$VERIFICATION_FILE" failures)"
  verification_warnings="$(value_from_markdown "$VERIFICATION_FILE" warnings)"
fi

overall_status="unknown"
if [[ "$smoke_status" != "passed" ]]; then
  overall_status="${smoke_status:-unknown}"
elif [[ "$verification_status" != "passed" ]]; then
  overall_status="${verification_status:-unknown}"
else
  overall_status="passed"
fi

artifact_files="$(count_files)"
final_home_png_bytes="$(file_size_bytes "$ARTIFACT_DIR/final_home.png")"
final_home_xml_bytes="$(file_size_bytes "$ARTIFACT_DIR/final_home.xml")"

mkdir -p "$ARTIFACT_DIR" "$REPORT_ROOT"

{
  printf '# Release Android Smoke Latest\n\n'
  printf -- '- generatedAt: %s\n' "$generated_at"
  printf -- '- overallStatus: %s\n' "${overall_status:-unknown}"
  printf -- '- smokeStatus: %s\n' "${smoke_status:-unknown}"
  printf -- '- smokeMessage: %s\n' "${smoke_message:-}"
  printf -- '- smokeGeneratedAt: %s\n' "${smoke_generated_at:-unknown}"
  printf -- '- verificationStatus: %s\n' "${verification_status:-unknown}"
  printf -- '- verificationFailures: %s\n' "${verification_failures:-n/a}"
  printf -- '- verificationWarnings: %s\n' "${verification_warnings:-n/a}"
  printf -- '- scenario: %s\n' "${scenario:-unknown}"
  printf -- '- flavor: %s\n' "${flavor:-unknown}"
  printf -- '- package: %s\n' "${package_name:-unknown}"
  printf -- '- device: %s\n' "${device:-unknown}"
  printf -- '- emulator: %s\n' "${emulator:-unknown}"
  printf -- '- gitCommit: %s\n' "${git_commit:-unknown}"
  printf -- '- apkSha256: %s\n' "${apk_sha256:-unknown}"
  printf -- '- finalCrashBytes: %s\n' "${final_crash_bytes:-unknown}"
  printf -- '- artifactFiles: %s\n' "$artifact_files"
  printf -- '- finalHomePngBytes: %s\n' "$final_home_png_bytes"
  printf -- '- finalHomeXmlBytes: %s\n' "$final_home_xml_bytes"
  printf -- '- artifactDir: %s\n' "$ARTIFACT_DIR"
  printf -- '- apkPath: %s\n\n' "${apk_path:-unknown}"

  printf '## Reports\n\n'
  printf -- '- smoke summary: `%s`\n' "$SUMMARY_FILE"
  if [[ -f "$VERIFICATION_FILE" ]]; then
    printf -- '- artifact verification: `%s`\n' "$VERIFICATION_FILE"
  else
    printf -- '- artifact verification: missing\n'
  fi
  printf -- '- final UI summary: `%s`\n\n' "${final_ui_summary:-$ARTIFACT_DIR/final_home.summary.txt}"

  printf '## Coverage\n\n'
  coverage_for_scenario "${scenario:-unknown}"

  printf '\n## Notes\n\n'
  printf -- '- This is a local pre-deployment smoke summary.\n'
  printf -- '- It does not prove production payment, production Supabase connectivity, or store receipt validation.\n'
  printf -- '- Use `summary.md` for runner details and `release_android_smoke_artifact_verification.md` for full artifact checks.\n'
} > "$LOCAL_LATEST"

if ! python3 - "$LOCAL_LATEST" "$GLOBAL_LATEST" <<'PY'
import pathlib
import sys

left = pathlib.Path(sys.argv[1]).expanduser().resolve()
right = pathlib.Path(sys.argv[2]).expanduser().resolve()
sys.exit(0 if left == right else 1)
PY
then
  cp "$LOCAL_LATEST" "$GLOBAL_LATEST"
fi

printf '[release-android-smoke-summary] wrote: %s\n' "$LOCAL_LATEST"
printf '[release-android-smoke-summary] wrote: %s\n' "$GLOBAL_LATEST"
