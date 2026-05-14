#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

ARTIFACT_DIR="${JIVE_SAAS_PLAY_UPLOAD_ARTIFACT_DIR:-}"
PACKAGE_NAME="${JIVE_SAAS_PLAY_PACKAGE_NAME:-com.jivemoney.app}"
EXPECTED_PACKAGE="${JIVE_SAAS_PLAY_EXPECTED_PACKAGE:-com.jivemoney.app}"
PLAY_TRACK="${JIVE_SAAS_PLAY_TRACK:-internal}"
RELEASE_STATUS="${JIVE_SAAS_PLAY_RELEASE_STATUS:-draft}"
SERVICE_ACCOUNT_JSON_PATH="${JIVE_GOOGLE_PLAY_SERVICE_ACCOUNT_JSON_PATH:-${GOOGLE_PLAY_SERVICE_ACCOUNT_JSON_PATH:-}}"
REQUIRE_SERVICE_ACCOUNT="${JIVE_SAAS_PLAY_REQUIRE_SERVICE_ACCOUNT:-false}"
BUNDLETOOL_BIN="${JIVE_BUNDLETOOL_BIN:-bundletool}"
MANIFEST_DUMP_FILE="${JIVE_SAAS_PLAY_MANIFEST_DUMP_FILE:-}"
REQUIRE_MANIFEST_CHECK="${JIVE_SAAS_PLAY_REQUIRE_MANIFEST_CHECK:-false}"

usage() {
  cat <<'EOF'
Usage:
  scripts/check_saas_play_upload_readiness.sh [options]

Options:
  --artifact-dir <path>          Downloaded saas-release-candidate artifact directory.
  --package-name <id>            Google Play package name. Defaults to com.jivemoney.app.
  --expected-package <id>        Expected Android package id. Defaults to com.jivemoney.app.
  --track <name>                 Google Play track. Defaults to internal.
  --release-status <status>      Play release status. Defaults to draft.
  --service-account-json <path>  Google Play service account JSON path. The file content is never read.
  --require-service-account      Require --service-account-json to exist. Intended for upload --apply.
  --bundletool <path>            bundletool executable for optional AAB manifest inspection.
  --manifest-dump <path>         Pre-rendered manifest XML/text dump for offline verification.
  --require-manifest-check       Fail if the AAB manifest cannot be inspected.
  --skip-manifest-check          Do not inspect the AAB manifest.
  --help                         Show this help.

This script performs host-only readiness checks before a Google Play internal
test upload. It validates the downloaded prod AAB artifact, release report,
track/status/package guardrails, optional manifest package, and optional service
account file presence. It never prints or reads secret values.
EOF
}

log() {
  printf '[saas-play-upload-readiness] %s\n' "$*"
}

die() {
  printf '[saas-play-upload-readiness] ERROR: %s\n' "$*" >&2
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
      --expected-package)
        EXPECTED_PACKAGE="${2:-}"
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
      --require-service-account)
        REQUIRE_SERVICE_ACCOUNT=true
        shift
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

  if [[ -n "$SERVICE_ACCOUNT_JSON_PATH" && ! -f "$SERVICE_ACCOUNT_JSON_PATH" ]]; then
    die "service account JSON file not found"
  fi
  case "$REQUIRE_SERVICE_ACCOUNT" in
    1|true|TRUE|yes|YES|required|REQUIRED)
      [[ -n "$SERVICE_ACCOUNT_JSON_PATH" ]] || die "--service-account-json is required when --require-service-account is set"
      ;;
  esac

  python3 - \
    "$ARTIFACT_DIR" \
    "$PACKAGE_NAME" \
    "$EXPECTED_PACKAGE" \
    "$PLAY_TRACK" \
    "$RELEASE_STATUS" \
    "$BUNDLETOOL_BIN" \
    "$MANIFEST_DUMP_FILE" \
    "$REQUIRE_MANIFEST_CHECK" <<'PY'
import hashlib
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

artifact_dir = Path(sys.argv[1]).expanduser().resolve()
package_name = sys.argv[2] or "com.jivemoney.app"
expected_package = sys.argv[3] or "com.jivemoney.app"
play_track = sys.argv[4] or "internal"
release_status = sys.argv[5] or "draft"
bundletool_bin = sys.argv[6] or "bundletool"
manifest_dump_file = Path(sys.argv[7]).expanduser().resolve() if sys.argv[7] else None
manifest_mode = sys.argv[8].strip().lower()
require_manifest_check = manifest_mode in {"1", "true", "yes", "required"}
skip_manifest_check = manifest_mode == "skip"

valid_statuses = {"draft", "completed", "inProgress", "halted"}
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


def is_dev_package(value: str) -> bool:
    lowered = value.lower()
    return (
        lowered.endswith(".dev")
        or lowered.endswith(".debug")
        or ".staging" in lowered
        or ".debug" in lowered
        or lowered.startswith("com.example.")
    )


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

    manifest_package = parse_manifest_value(manifest_text, "package")
    version_name = parse_manifest_value(manifest_text, "versionName")
    version_code = parse_manifest_value(manifest_text, "versionCode")
    if not manifest_package:
        if require_manifest_check:
            fail("manifest package was not found")
        return {"status": "skipped", "reason": "manifest package was not found"}
    if manifest_package != expected_package:
        fail(f"manifest package expected {expected_package!r}, got {manifest_package!r}")
    if is_dev_package(manifest_package):
        fail(f"manifest package must not be a dev/staging id: {manifest_package!r}")
    return {
        "status": "passed",
        "source": source,
        "package": manifest_package,
        "versionName": version_name or "not-recorded",
        "versionCode": version_code or "not-recorded",
    }


if play_track != "internal":
    fail(f"Play upload track must be 'internal' for this lane, got {play_track!r}")
if release_status not in valid_statuses:
    fail(f"release status must be one of {sorted(valid_statuses)}, got {release_status!r}")
if package_name != expected_package:
    fail(f"package name expected {expected_package!r}, got {package_name!r}")
if is_dev_package(package_name):
    fail(f"package name must not be a dev/staging id: {package_name!r}")

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
if payload.get("artifactName") and payload["artifactName"] != aab_path.name:
    errors.append(f"artifactName expected {aab_path.name!r}, got {payload['artifactName']!r}")
if payload.get("artifactBytes") != actual_bytes:
    errors.append(f"artifactBytes expected {actual_bytes!r}, got {payload.get('artifactBytes')!r}")
if payload.get("sha256") != actual_sha256:
    errors.append(f"sha256 expected {actual_sha256!r}, got {payload.get('sha256')!r}")

manifest_check = inspect_manifest(aab_path)

if errors:
    fail("\n".join(errors))

print("[saas-play-upload-readiness] passed")
print(f"[saas-play-upload-readiness] package={package_name}")
print(f"[saas-play-upload-readiness] track={play_track}")
print(f"[saas-play-upload-readiness] releaseStatus={release_status}")
print(f"[saas-play-upload-readiness] aab={aab_path.name}")
print(f"[saas-play-upload-readiness] sha256={actual_sha256}")
print(f"[saas-play-upload-readiness] manifest={manifest_check['status']}")
if manifest_check["status"] == "passed":
    print(f"[saas-play-upload-readiness] manifestPackage={manifest_check['package']}")
    print(f"[saas-play-upload-readiness] manifestVersionCode={manifest_check['versionCode']}")
PY
}

main "$@"
