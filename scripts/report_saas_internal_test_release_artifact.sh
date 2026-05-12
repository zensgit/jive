#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

ARTIFACT_DIR="${JIVE_SAAS_INTERNAL_TEST_ARTIFACT_DIR:-}"
OUTPUT_FILE="${JIVE_SAAS_INTERNAL_TEST_REPORT_FILE:-$APP_DIR/build/reports/saas-internal-test-release/latest.md}"
PLAY_TRACK="${JIVE_SAAS_INTERNAL_TEST_PLAY_TRACK:-internal}"
PLAY_VERSION="${JIVE_SAAS_INTERNAL_TEST_PLAY_VERSION:-}"
WORKFLOW_RUN_ID="${JIVE_SAAS_INTERNAL_TEST_WORKFLOW_RUN_ID:-}"
EXPECTED_PACKAGE="${JIVE_SAAS_INTERNAL_TEST_EXPECTED_PACKAGE:-com.jivemoney.app}"
BUNDLETOOL_BIN="${JIVE_BUNDLETOOL_BIN:-bundletool}"
MANIFEST_DUMP_FILE="${JIVE_SAAS_INTERNAL_TEST_MANIFEST_DUMP_FILE:-}"
REQUIRE_MANIFEST_CHECK="${JIVE_SAAS_INTERNAL_TEST_REQUIRE_MANIFEST_CHECK:-false}"

usage() {
  cat <<'EOF'
Usage:
  scripts/report_saas_internal_test_release_artifact.sh [options]

Options:
  --artifact-dir <path>      Downloaded saas-release-candidate artifact directory.
  --output <path>            Markdown report path. Defaults to build/reports/saas-internal-test-release/latest.md.
  --play-track <name>        Play Console track label. Defaults to internal.
  --play-version <value>     Optional Play Console release/version label.
  --workflow-run-id <id>     Optional release candidate workflow run id.
  --expected-package <id>    Expected Android package id. Defaults to com.jivemoney.app.
  --bundletool <path>        bundletool executable for AAB manifest inspection. Defaults to bundletool.
  --manifest-dump <path>     Pre-rendered manifest XML/text dump, mainly for offline verification.
  --require-manifest-check   Fail if the AAB manifest cannot be inspected.
  --skip-manifest-check      Do not inspect the AAB manifest.
  --help                     Show this help.

The script validates the final production AAB artifact and renders a redacted
Markdown report suitable for internal-test release records. It never prints or
reads secret values.
EOF
}

die() {
  printf '[saas-internal-artifact-report] ERROR: %s\n' "$*" >&2
  exit 1
}

log() {
  printf '[saas-internal-artifact-report] %s\n' "$*"
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
      --play-track)
        PLAY_TRACK="${2:-}"
        shift 2
        ;;
      --play-version)
        PLAY_VERSION="${2:-}"
        shift 2
        ;;
      --workflow-run-id)
        WORKFLOW_RUN_ID="${2:-}"
        shift 2
        ;;
      --expected-package)
        EXPECTED_PACKAGE="${2:-}"
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

  mkdir -p "$(dirname "$OUTPUT_FILE")"

  python3 - "$ARTIFACT_DIR" "$OUTPUT_FILE" "$PLAY_TRACK" "$PLAY_VERSION" "$WORKFLOW_RUN_ID" "$EXPECTED_PACKAGE" "$BUNDLETOOL_BIN" "$MANIFEST_DUMP_FILE" "$REQUIRE_MANIFEST_CHECK" <<'PY'
import hashlib
import json
import re
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

artifact_dir = Path(sys.argv[1]).expanduser().resolve()
output_file = Path(sys.argv[2]).expanduser().resolve()
play_track = sys.argv[3] or "internal"
play_version = sys.argv[4]
workflow_run_id = sys.argv[5]
expected_package = sys.argv[6]
bundletool_bin = sys.argv[7] or "bundletool"
manifest_dump_file = Path(sys.argv[8]).expanduser().resolve() if sys.argv[8] else None
manifest_mode = sys.argv[9].strip().lower()
require_manifest_check = manifest_mode in {"1", "true", "yes", "required"}
skip_manifest_check = manifest_mode == "skip"

secret_name_re = re.compile(
    r"(\.env$|key\.properties$|keystore|credential|secret|dart-defines|service[_-]?role|private[_-]?key)",
    re.IGNORECASE,
)


def fail(message: str) -> None:
    raise SystemExit(message)


def find_one(pattern: str, label: str) -> Path:
    matches = sorted(artifact_dir.rglob(pattern))
    if not matches:
        fail(f"{label} not found under {artifact_dir}")
    if len(matches) > 1:
        fail(f"expected one {label}, found {len(matches)}")
    return matches[0]


def parse_manifest_value(manifest_text: str, key: str) -> str:
    patterns = [
        rf'\b{re.escape(key)}="([^"]+)"',
        rf"\b{re.escape(key)}='([^']+)'",
        rf'\bandroid:{re.escape(key)}="([^"]+)"',
        rf"\bandroid:{re.escape(key)}='([^']+)'",
        rf'\b{re.escape(key)}: "([^"]+)"',
        rf"\b{re.escape(key)}: '([^']+)'",
        rf"\b{re.escape(key)}:\s*([^\s,]+)",
    ]
    for pattern in patterns:
        match = re.search(pattern, manifest_text)
        if match:
            return match.group(1)
    return ""


def inspect_manifest(aab_path: Path) -> dict[str, str]:
    if skip_manifest_check:
        return {"status": "skipped", "reason": "disabled"}

    manifest_text = ""
    source = ""
    if manifest_dump_file:
        if not manifest_dump_file.is_file():
            if require_manifest_check:
                fail(f"manifest dump file not found: {manifest_dump_file}")
            return {"status": "skipped", "reason": f"manifest dump file not found: {manifest_dump_file}"}
        manifest_text = manifest_dump_file.read_text(encoding="utf-8")
        source = str(manifest_dump_file)
    else:
        bundletool_path = shutil.which(bundletool_bin)
        if bundletool_path is None and Path(bundletool_bin).expanduser().is_file():
            bundletool_path = str(Path(bundletool_bin).expanduser().resolve())
        if bundletool_path is None:
            if require_manifest_check:
                fail(f"bundletool not found: {bundletool_bin}")
            return {"status": "skipped", "reason": f"bundletool not found: {bundletool_bin}"}

        try:
            completed = subprocess.run(
                [bundletool_path, "dump", "manifest", f"--bundle={aab_path}"],
                check=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
            )
        except subprocess.CalledProcessError as error:
            stderr = error.stderr.strip()
            if require_manifest_check:
                fail(f"bundletool manifest dump failed: {stderr or error}")
            return {"status": "skipped", "reason": f"bundletool manifest dump failed: {stderr or error}"}
        manifest_text = completed.stdout
        source = bundletool_path

    package_name = parse_manifest_value(manifest_text, "package")
    version_name = parse_manifest_value(manifest_text, "versionName")
    version_code = parse_manifest_value(manifest_text, "versionCode")

    if not package_name:
        if require_manifest_check:
            fail("manifest package was not found")
        return {"status": "skipped", "reason": "manifest package was not found"}

    if expected_package and package_name != expected_package:
        fail(f"manifest package expected {expected_package!r}, got {package_name!r}")

    return {
        "status": "passed",
        "source": source,
        "package": package_name,
        "versionName": version_name or "not-recorded",
        "versionCode": version_code or "not-recorded",
    }


leaky_files = [
    path
    for path in artifact_dir.rglob("*")
    if path.is_file() and secret_name_re.search(path.name)
]
if leaky_files:
    rendered = "\n".join(f"- {path.relative_to(artifact_dir)}" for path in leaky_files)
    fail(f"artifact contains forbidden secret-like file names:\n{rendered}")

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
manifest_check = inspect_manifest(aab_path)

if payload.get("artifactName") and payload["artifactName"] != aab_path.name:
    errors.append(f"artifactName expected {aab_path.name!r}, got {payload['artifactName']!r}")
if payload.get("artifactBytes") != actual_bytes:
    errors.append(f"artifactBytes expected {actual_bytes!r}, got {payload.get('artifactBytes')!r}")
if payload.get("sha256") != actual_sha256:
    errors.append(f"sha256 expected {actual_sha256!r}, got {payload.get('sha256')!r}")

if errors:
    fail("\n".join(errors))

sequence_summary = next(iter(sorted(artifact_dir.rglob("saas-release-candidate-sequence-summary.md"))), None)
if not workflow_run_id and sequence_summary:
    match = re.search(r"finalRunId: `([^`]+)`", sequence_summary.read_text(encoding="utf-8"))
    if match:
        workflow_run_id = match.group(1)

generated_at = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
build_name = payload.get("buildName", "")
build_number = payload.get("buildNumber", "")
git_commit = payload.get("gitCommit", "")
git_branch = payload.get("gitBranch", "")

lines = [
    "# SaaS Internal Test Release Completion",
    "",
    f"Generated: {generated_at}",
    "",
    "## Artifact",
    "",
    f"- Status: `ready-for-play-{play_track}`",
    f"- Workflow run id: `{workflow_run_id or 'not-recorded'}`",
    f"- Play track: `{play_track}`",
    f"- Play version: `{play_version or 'not-recorded'}`",
    f"- Build name: `{build_name}`",
    f"- Build number: `{build_number}`",
    f"- Git branch: `{git_branch}`",
    f"- Git commit: `{git_commit}`",
    f"- AAB: `{aab_path}`",
    f"- AAB bytes: `{actual_bytes}`",
    f"- AAB SHA-256: `{actual_sha256}`",
    f"- Release report: `{report_json}`",
    f"- Expected package: `{expected_package or 'not-set'}`",
    f"- Manifest check: `{manifest_check['status']}`",
]
if manifest_check["status"] == "passed":
    lines.extend(
        [
            f"- Manifest package: `{manifest_check['package']}`",
            f"- Manifest version name: `{manifest_check['versionName']}`",
            f"- Manifest version code: `{manifest_check['versionCode']}`",
            f"- Manifest source: `{manifest_check['source']}`",
        ]
    )
else:
    lines.append(f"- Manifest check reason: `{manifest_check.get('reason', 'not-recorded')}`")
lines.extend(
    [
    "",
    "## Release Candidate Report Checks",
    "",
    "- `status=passed`",
    "- `flavor=prod`",
    "- `dryRun=false`",
    "- `strictSigning=true`",
    "- `signingMode=release-configured`",
    "- `dartDefinesConfigured=true`",
    "- AAB bytes and SHA-256 match the downloaded artifact.",
    "- No forbidden secret-like file names were found in the artifact directory.",
    f"- Android manifest check status: `{manifest_check['status']}`.",
]
)
if manifest_check["status"] == "passed":
    lines.append(f"- Android manifest package matches `{expected_package}`.")
lines.extend(
    [
    "",
    "## Google Play Internal Test Checklist",
    "",
    "- [ ] Upload the AAB to the Google Play internal test track.",
    "- [ ] Confirm package name `com.jivemoney.app` in Play Console.",
    "- [ ] Add internal tester accounts.",
    "- [ ] Install through the Play internal test link.",
    "- [ ] Cold start without crash.",
    "- [ ] Open home, settings, login, subscription, and cloud sync entry points.",
    "- [ ] Verify subscriber-only sync is gated for free users.",
    "- [ ] Verify purchase or restore-purchase path in the Play test environment.",
    "- [ ] Add a manual transaction and confirm it appears in recent transactions.",
    "- [ ] Capture logcat and confirm no Flutter fatal, crash, or uncaught exception.",
    "",
    "## Deferred For Public Launch",
    "",
    "- Store listing assets and copy.",
    "- Privacy policy and terms URLs.",
    "- Production payment review.",
    "- Crashlytics or Sentry rollout.",
    "- Customer support and refund process.",
    "",
    ]
)

output_file.write_text("\n".join(lines), encoding="utf-8")
print(f"[saas-internal-artifact-report] wrote {output_file}")
PY
}

main "$@"
