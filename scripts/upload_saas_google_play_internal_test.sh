#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

ARTIFACT_DIR="${JIVE_SAAS_PLAY_UPLOAD_ARTIFACT_DIR:-}"
PACKAGE_NAME="${JIVE_SAAS_PLAY_PACKAGE_NAME:-com.jivemoney.app}"
PLAY_TRACK="${JIVE_SAAS_PLAY_TRACK:-internal}"
RELEASE_STATUS="${JIVE_SAAS_PLAY_RELEASE_STATUS:-draft}"
SERVICE_ACCOUNT_JSON_PATH="${JIVE_GOOGLE_PLAY_SERVICE_ACCOUNT_JSON_PATH:-${GOOGLE_PLAY_SERVICE_ACCOUNT_JSON_PATH:-}}"
SUPPLY_BIN="${JIVE_FASTLANE_BIN:-fastlane}"
OUTPUT_FILE="${JIVE_SAAS_PLAY_UPLOAD_HANDOFF_FILE:-$APP_DIR/build/reports/saas-internal-test-release/play-internal-upload-handoff.md}"
COMPLETION_REPORT="${JIVE_SAAS_INTERNAL_TEST_COMPLETION_REPORT:-}"
BUNDLETOOL_BIN="${JIVE_BUNDLETOOL_BIN:-bundletool}"
MANIFEST_DUMP_FILE="${JIVE_SAAS_PLAY_MANIFEST_DUMP_FILE:-}"
REQUIRE_MANIFEST_CHECK="${JIVE_SAAS_PLAY_REQUIRE_MANIFEST_CHECK:-false}"
PLAY_VERSION="${JIVE_SAAS_PLAY_VERSION:-}"
PLAY_RELEASE_ID="${JIVE_SAAS_PLAY_RELEASE_ID:-not-uploaded}"
TESTER_LINK="${JIVE_SAAS_PLAY_TESTER_LINK:-not-recorded}"
ROLLOUT_STATUS="${JIVE_SAAS_PLAY_ROLLOUT_STATUS:-not-uploaded}"
APPLY=0
RENDER_HANDOFF=1

READINESS_SCRIPT="${JIVE_SAAS_PLAY_UPLOAD_READINESS_SCRIPT:-$APP_DIR/scripts/check_saas_play_upload_readiness.sh}"
HANDOFF_SCRIPT="${JIVE_SAAS_PLAY_UPLOAD_HANDOFF_SCRIPT:-$APP_DIR/scripts/render_saas_play_internal_upload_handoff.sh}"

usage() {
  cat <<'EOF'
Usage:
  scripts/upload_saas_google_play_internal_test.sh [options]

Options:
  --artifact-dir <path>          Downloaded saas-release-candidate artifact directory.
  --package-name <id>            Google Play package name. Defaults to com.jivemoney.app.
  --track <name>                 Google Play track. Defaults to internal.
  --release-status <status>      Play release status. Defaults to draft.
  --service-account-json <path>  Google Play service account JSON path. Required with --apply.
  --supply-bin <path>            fastlane executable/wrapper. Defaults to fastlane.
  --bundletool <path>            bundletool executable for optional AAB manifest inspection.
  --manifest-dump <path>         Pre-rendered manifest XML/text dump for offline verification.
  --require-manifest-check       Fail if the AAB manifest cannot be inspected.
  --skip-manifest-check          Do not inspect the AAB manifest.
  --output <path>                Markdown handoff path rendered after readiness/upload.
  --completion-report <path>     Optional internal-test completion report from the same artifact.
  --play-version <value>         Optional Play Console version label to record.
  --play-release-id <id>         Optional Play release id after upload.
  --tester-link <url>            Optional internal testing link after upload.
  --rollout-status <value>       Optional rollout status after upload.
  --skip-handoff                 Do not render/update the Markdown handoff.
  --apply                        Execute fastlane supply. Without this, only dry-run checks run.
  --help                         Show this help.

Default mode is safe dry-run: validate the prod AAB artifact, print the command
shape, and render a redacted handoff report. --apply requires a local service
account JSON path and executes fastlane supply; the JSON file content is never
printed or read by this wrapper.
EOF
}

log() {
  printf '[saas-play-upload] %s\n' "$*"
}

die() {
  printf '[saas-play-upload] ERROR: %s\n' "$*" >&2
  exit 1
}

parse_args() {
  while (($#)); do
    case "$1" in
      --artifact-dir)
        ARTIFACT_DIR="${2:-}"
        shift 2
        ;;
      --package-name)
        PACKAGE_NAME="${2:-}"
        shift 2
        ;;
      --track)
        PLAY_TRACK="${2:-}"
        shift 2
        ;;
      --release-status)
        RELEASE_STATUS="${2:-}"
        shift 2
        ;;
      --service-account-json)
        SERVICE_ACCOUNT_JSON_PATH="${2:-}"
        shift 2
        ;;
      --supply-bin)
        SUPPLY_BIN="${2:-}"
        shift 2
        ;;
      --bundletool)
        BUNDLETOOL_BIN="${2:-}"
        shift 2
        ;;
      --manifest-dump)
        MANIFEST_DUMP_FILE="${2:-}"
        shift 2
        ;;
      --require-manifest-check)
        REQUIRE_MANIFEST_CHECK=true
        shift
        ;;
      --skip-manifest-check)
        REQUIRE_MANIFEST_CHECK=skip
        shift
        ;;
      --output)
        OUTPUT_FILE="${2:-}"
        shift 2
        ;;
      --completion-report)
        COMPLETION_REPORT="${2:-}"
        shift 2
        ;;
      --play-version)
        PLAY_VERSION="${2:-}"
        shift 2
        ;;
      --play-release-id)
        PLAY_RELEASE_ID="${2:-}"
        shift 2
        ;;
      --tester-link)
        TESTER_LINK="${2:-}"
        shift 2
        ;;
      --rollout-status)
        ROLLOUT_STATUS="${2:-}"
        shift 2
        ;;
      --skip-handoff)
        RENDER_HANDOFF=0
        shift
        ;;
      --apply)
        APPLY=1
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

find_aab() {
  python3 - "$ARTIFACT_DIR" <<'PY'
import sys
from pathlib import Path

artifact_dir = Path(sys.argv[1]).expanduser().resolve()
matches = sorted(artifact_dir.rglob("*.aab"))
if not matches:
    raise SystemExit(f"AAB artifact not found under {artifact_dir}")
if len(matches) > 1:
    raise SystemExit(f"expected one AAB artifact, found {len(matches)}")
print(matches[0])
PY
}

resolve_executable() {
  local candidate="$1"

  if command -v "$candidate" >/dev/null 2>&1; then
    command -v "$candidate"
    return
  fi
  if [[ -x "$candidate" ]]; then
    printf '%s\n' "$candidate"
    return
  fi
  return 1
}

run_readiness() {
  local args
  [[ -f "$READINESS_SCRIPT" ]] || die "readiness script not found: $READINESS_SCRIPT"

  args=(
    --artifact-dir "$ARTIFACT_DIR"
    --package-name "$PACKAGE_NAME"
    --expected-package "$PACKAGE_NAME"
    --track "$PLAY_TRACK"
    --release-status "$RELEASE_STATUS"
  )
  if [[ -n "$SERVICE_ACCOUNT_JSON_PATH" ]]; then
    args+=(--service-account-json "$SERVICE_ACCOUNT_JSON_PATH")
  fi
  if [[ "$APPLY" -eq 1 ]]; then
    args+=(--require-service-account)
  fi
  args+=(--bundletool "$BUNDLETOOL_BIN")
  if [[ -n "$MANIFEST_DUMP_FILE" ]]; then
    args+=(--manifest-dump "$MANIFEST_DUMP_FILE")
  fi
  case "$REQUIRE_MANIFEST_CHECK" in
    1|true|TRUE|yes|YES|required|REQUIRED)
      args+=(--require-manifest-check)
      ;;
    skip|SKIP)
      args+=(--skip-manifest-check)
      ;;
  esac

  "$READINESS_SCRIPT" "${args[@]}"
}

render_handoff() {
  local args
  [[ -f "$HANDOFF_SCRIPT" ]] || die "handoff script not found: $HANDOFF_SCRIPT"

  args=(
    --artifact-dir "$ARTIFACT_DIR"
    --output "$OUTPUT_FILE"
    --package-name "$PACKAGE_NAME"
    --track "$PLAY_TRACK"
    --release-status "$RELEASE_STATUS"
  )
  if [[ -n "$COMPLETION_REPORT" ]]; then
    args+=(--completion-report "$COMPLETION_REPORT")
  fi
  if [[ -n "$PLAY_VERSION" ]]; then
    args+=(--play-version "$PLAY_VERSION")
  fi
  if [[ -n "$SERVICE_ACCOUNT_JSON_PATH" ]]; then
    args+=(--service-account-json "$SERVICE_ACCOUNT_JSON_PATH")
  fi
  args+=(
    --play-release-id "$PLAY_RELEASE_ID"
    --tester-link "$TESTER_LINK"
    --rollout-status "$ROLLOUT_STATUS"
  )

  "$HANDOFF_SCRIPT" "${args[@]}"
}

main() {
  parse_args "$@"

  [[ -n "$ARTIFACT_DIR" ]] || die "--artifact-dir is required"
  [[ -d "$ARTIFACT_DIR" ]] || die "artifact directory not found: $ARTIFACT_DIR"

  log "checking Play internal upload readiness"
  run_readiness

  aab_path="$(find_aab)"
  supply_path="$SUPPLY_BIN"
  if [[ "$APPLY" -eq 1 ]]; then
    if ! supply_path="$(resolve_executable "$SUPPLY_BIN")"; then
      die "fastlane/supply executable not found: $SUPPLY_BIN"
    fi

    upload_cmd=(
      "$supply_path"
      supply
      --json_key "$SERVICE_ACCOUNT_JSON_PATH"
      --package_name "$PACKAGE_NAME"
      --track "$PLAY_TRACK"
      --aab "$aab_path"
      --release_status "$RELEASE_STATUS"
      --skip_upload_metadata
      --skip_upload_images
      --skip_upload_screenshots
    )

    log "uploading AAB to Google Play internal testing via fastlane supply"
    "${upload_cmd[@]}"
    log "upload command completed"
  else
    log "dry-run only; no Google Play upload was performed"
    printf '[saas-play-upload] command shape: %q supply --json_key %q --package_name %q --track %q --aab %q --release_status %q --skip_upload_metadata --skip_upload_images --skip_upload_screenshots\n' \
      "$SUPPLY_BIN" \
      "${SERVICE_ACCOUNT_JSON_PATH:-\$GOOGLE_PLAY_SERVICE_ACCOUNT_JSON_PATH}" \
      "$PACKAGE_NAME" \
      "$PLAY_TRACK" \
      "$aab_path" \
      "$RELEASE_STATUS"
  fi

  if [[ "$RENDER_HANDOFF" -eq 1 ]]; then
    log "rendering Play internal upload handoff"
    render_handoff
  else
    log "handoff rendering skipped"
  fi
}

main "$@"
