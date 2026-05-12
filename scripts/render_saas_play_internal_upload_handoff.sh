#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

ARTIFACT_DIR="${JIVE_SAAS_PLAY_UPLOAD_ARTIFACT_DIR:-}"
OUTPUT_FILE="${JIVE_SAAS_PLAY_UPLOAD_HANDOFF_FILE:-$APP_DIR/build/reports/saas-internal-test-release/play-internal-upload-handoff.md}"
COMPLETION_REPORT="${JIVE_SAAS_INTERNAL_TEST_COMPLETION_REPORT:-}"
PACKAGE_NAME="${JIVE_SAAS_PLAY_PACKAGE_NAME:-com.jivemoney.app}"
PLAY_TRACK="${JIVE_SAAS_PLAY_TRACK:-internal}"
RELEASE_STATUS="${JIVE_SAAS_PLAY_RELEASE_STATUS:-draft}"
PLAY_VERSION="${JIVE_SAAS_PLAY_VERSION:-}"
PLAY_RELEASE_ID="${JIVE_SAAS_PLAY_RELEASE_ID:-not-uploaded}"
TESTER_LINK="${JIVE_SAAS_PLAY_TESTER_LINK:-not-recorded}"
ROLLOUT_STATUS="${JIVE_SAAS_PLAY_ROLLOUT_STATUS:-not-uploaded}"
SERVICE_ACCOUNT_JSON_PATH="${JIVE_GOOGLE_PLAY_SERVICE_ACCOUNT_JSON_PATH:-${GOOGLE_PLAY_SERVICE_ACCOUNT_JSON_PATH:-}}"

usage() {
  cat <<'EOF'
Usage:
  scripts/render_saas_play_internal_upload_handoff.sh [options]

Options:
  --artifact-dir <path>          Downloaded saas-release-candidate artifact directory.
  --output <path>                Markdown handoff path. Defaults to build/reports/saas-internal-test-release/play-internal-upload-handoff.md.
  --completion-report <path>     Optional internal-test completion report produced from the same artifact.
  --package-name <id>            Google Play package name. Defaults to com.jivemoney.app.
  --track <name>                 Google Play track. Defaults to internal.
  --release-status <status>      Fastlane/Play release status. Defaults to draft.
  --play-version <value>         Optional Play Console version label to record.
  --play-release-id <id>         Optional Play release id after upload.
  --tester-link <url>            Optional internal testing link after upload.
  --rollout-status <value>       Optional rollout status after upload.
  --service-account-json <path>  Path placeholder for Google Play service account JSON. The file is never read.
  --help                         Show this help.

This script does not upload to Google Play and does not read secret values. It
validates the downloaded prod AAB artifact and renders a redacted upload handoff
report with the exact command shape operators can run after they provide a
service account key through their local secure channel.
EOF
}

die() {
  printf '[saas-play-upload-handoff] ERROR: %s\n' "$*" >&2
  exit 1
}

parse_args() {
  while (($#)); do
    case "$1" in
      --artifact-dir)
        ARTIFACT_DIR="${2:-}"
        shift 2
        ;;
      --output)
        OUTPUT_FILE="${2:-}"
        shift 2
        ;;
      --completion-report)
        COMPLETION_REPORT="${2:-}"
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
      --service-account-json)
        SERVICE_ACCOUNT_JSON_PATH="${2:-}"
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

main() {
  parse_args "$@"

  [[ -n "$ARTIFACT_DIR" ]] || die "--artifact-dir is required"
  [[ -d "$ARTIFACT_DIR" ]] || die "artifact directory not found: $ARTIFACT_DIR"
  if [[ -n "$COMPLETION_REPORT" && ! -f "$COMPLETION_REPORT" ]]; then
    die "completion report not found: $COMPLETION_REPORT"
  fi

  mkdir -p "$(dirname "$OUTPUT_FILE")"

  python3 - \
    "$ARTIFACT_DIR" \
    "$OUTPUT_FILE" \
    "$COMPLETION_REPORT" \
    "$PACKAGE_NAME" \
    "$PLAY_TRACK" \
    "$RELEASE_STATUS" \
    "$PLAY_VERSION" \
    "$PLAY_RELEASE_ID" \
    "$TESTER_LINK" \
    "$ROLLOUT_STATUS" \
    "$SERVICE_ACCOUNT_JSON_PATH" <<'PY'
import hashlib
import json
import shlex
import sys
from datetime import datetime, timezone
from pathlib import Path

artifact_dir = Path(sys.argv[1]).expanduser().resolve()
output_file = Path(sys.argv[2]).expanduser().resolve()
completion_report = Path(sys.argv[3]).expanduser().resolve() if sys.argv[3] else None
package_name = sys.argv[4] or "com.jivemoney.app"
play_track = sys.argv[5] or "internal"
release_status = sys.argv[6] or "draft"
play_version = sys.argv[7] or "not-recorded"
play_release_id = sys.argv[8] or "not-uploaded"
tester_link = sys.argv[9] or "not-recorded"
rollout_status = sys.argv[10] or "not-uploaded"
service_account_json_path = sys.argv[11]


def fail(message: str) -> None:
    raise SystemExit(message)


def find_one(pattern: str, label: str) -> Path:
    matches = sorted(artifact_dir.rglob(pattern))
    if not matches:
        fail(f"{label} not found under {artifact_dir}")
    if len(matches) > 1:
        fail(f"expected one {label}, found {len(matches)}")
    return matches[0]


report_json = find_one("release-candidate.json", "release-candidate.json")
aab_path = find_one("*.aab", "AAB artifact")
payload = json.loads(report_json.read_text(encoding="utf-8"))

errors: list[str] = []
expected = {
    "status": "passed",
    "flavor": "prod",
    "dryRun": False,
    "strictSigning": True,
    "signingMode": "release-configured",
    "dartDefinesConfigured": True,
}
for key, value in expected.items():
    if payload.get(key) != value:
        errors.append(f"{key} expected {value!r}, got {payload.get(key)!r}")

actual_bytes = aab_path.stat().st_size
actual_sha256 = hashlib.sha256(aab_path.read_bytes()).hexdigest()
if payload.get("artifactName") and payload["artifactName"] != aab_path.name:
    errors.append(f"artifactName expected {aab_path.name!r}, got {payload['artifactName']!r}")
if payload.get("artifactBytes") != actual_bytes:
    errors.append(f"artifactBytes expected {actual_bytes!r}, got {payload.get('artifactBytes')!r}")
if payload.get("sha256") != actual_sha256:
    errors.append(f"sha256 expected {actual_sha256!r}, got {payload.get('sha256')!r}")

if errors:
    fail("\n".join(errors))

service_account_arg = service_account_json_path or "$GOOGLE_PLAY_SERVICE_ACCOUNT_JSON_PATH"
fastlane_args = [
    "fastlane",
    "supply",
    "--json_key",
    service_account_arg,
    "--package_name",
    package_name,
    "--track",
    play_track,
    "--aab",
    str(aab_path),
    "--release_status",
    release_status,
    "--skip_upload_metadata",
    "--skip_upload_images",
    "--skip_upload_screenshots",
]
fastlane_command = " \\\n+  ".join(shlex.quote(arg) for arg in fastlane_args)

generated_at = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
build_name = payload.get("buildName", "")
build_number = payload.get("buildNumber", "")
git_branch = payload.get("gitBranch", "")
git_commit = payload.get("gitCommit", "")

lines = [
    "# SaaS Play Internal Test Upload Handoff",
    "",
    f"Generated: {generated_at}",
    "",
    "## Source Artifact",
    "",
    f"- Package name: `{package_name}`",
    f"- Play track: `{play_track}`",
    f"- Release status: `{release_status}`",
    f"- Play version: `{play_version}`",
    f"- Build name: `{build_name}`",
    f"- Build number: `{build_number}`",
    f"- Git branch: `{git_branch}`",
    f"- Git commit: `{git_commit}`",
    f"- AAB: `{aab_path}`",
    f"- AAB bytes: `{actual_bytes}`",
    f"- AAB SHA-256: `{actual_sha256}`",
    f"- Release report: `{report_json}`",
    f"- Completion report: `{completion_report or 'not-recorded'}`",
    "",
    "## Dry-Run Upload Command",
    "",
    "The command shape below is intentionally rendered but not executed by this script.",
    "Keep the Google Play service account JSON outside the repository and pass only its local path.",
    "",
    "```bash",
    fastlane_command,
    "```",
    "",
    "## Post-Upload Record",
    "",
    f"- Play release id: `{play_release_id}`",
    f"- Tester link: `{tester_link}`",
    f"- Rollout status: `{rollout_status}`",
    "",
    "## Manual Verification Checklist",
    "",
    "- [ ] AAB uploaded to the Google Play internal testing track.",
    "- [ ] Package name is `com.jivemoney.app`.",
    "- [ ] Version is visible in Play Console.",
    "- [ ] Internal tester accounts are attached to the track.",
    "- [ ] Internal test link opens for tester accounts.",
    "- [ ] App installs from Play internal testing.",
    "- [ ] Cold start has no crash.",
    "- [ ] Login, subscription, cloud sync gate, and manual transaction smoke pass.",
    "- [ ] Purchase or restore-purchase path is verified with a Play license tester.",
    "- [ ] Logcat has no Flutter fatal, crash, or uncaught exception.",
    "",
]

output_file.write_text("\n".join(lines), encoding="utf-8")
print(f"[saas-play-upload-handoff] wrote {output_file}")
PY
}

main "$@"
