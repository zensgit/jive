#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$APP_DIR"

VERSION_LINE="$(grep '^version:' pubspec.yaml | awk '{print $2}')"
DEFAULT_BUILD_NAME="${VERSION_LINE%%+*}"
DEFAULT_BUILD_NUMBER="${VERSION_LINE##*+}"

FLAVOR="${JIVE_RELEASE_CANDIDATE_FLAVOR:-prod}"
BUILD_NAME="${JIVE_RELEASE_CANDIDATE_BUILD_NAME:-$DEFAULT_BUILD_NAME}"
BUILD_NUMBER="${JIVE_RELEASE_CANDIDATE_BUILD_NUMBER:-$DEFAULT_BUILD_NUMBER}"
STAMP="$(date +%Y%m%d-%H%M%S)"
STRICT_SIGNING="${JIVE_RELEASE_CANDIDATE_STRICT_SIGNING:-false}"
STRICT_SIGNING="$(echo "$STRICT_SIGNING" | tr '[:upper:]' '[:lower:]')"
SIGNING_MODE="debug"
signing_details=()

KEY_PROPERTIES_FILE=""
if [[ -f "$APP_DIR/key.properties" ]]; then
  KEY_PROPERTIES_FILE="$APP_DIR/key.properties"
elif [[ -f "$APP_DIR/android/key.properties" ]]; then
  KEY_PROPERTIES_FILE="$APP_DIR/android/key.properties"
fi

if [[ -n "$KEY_PROPERTIES_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$KEY_PROPERTIES_FILE"
fi

RELEASE_STORE_FILE="${storeFile:-${JIVE_ANDROID_STORE_FILE:-}}"
RELEASE_STORE_PASSWORD="${storePassword:-${JIVE_ANDROID_STORE_PASSWORD:-}}"
RELEASE_KEY_ALIAS="${keyAlias:-${JIVE_ANDROID_KEY_ALIAS:-}}"
RELEASE_KEY_PASSWORD="${keyPassword:-${JIVE_ANDROID_KEY_PASSWORD:-}}"

if [[ -n "$RELEASE_STORE_FILE" ]]; then
  signing_details+=("storeFile=$RELEASE_STORE_FILE")
  if [[ ! -f "$RELEASE_STORE_FILE" && -f "$APP_DIR/$RELEASE_STORE_FILE" ]]; then
    RELEASE_STORE_FILE="$APP_DIR/$RELEASE_STORE_FILE"
  fi
fi

[[ -z "$RELEASE_STORE_FILE" ]] && signing_details+=("storeFile-unset")
[[ -z "$RELEASE_STORE_PASSWORD" ]] && signing_details+=("storePassword-unset")
[[ -z "$RELEASE_KEY_ALIAS" ]] && signing_details+=("keyAlias-unset")
[[ -z "$RELEASE_KEY_PASSWORD" ]] && signing_details+=("keyPassword-unset")

if [[ -n "$RELEASE_STORE_FILE" && -n "$RELEASE_STORE_PASSWORD" && -n "$RELEASE_KEY_ALIAS" && -n "$RELEASE_KEY_PASSWORD" && -f "$RELEASE_STORE_FILE" ]]; then
  SIGNING_MODE="release-configured"
else
  [[ -n "$RELEASE_STORE_FILE" && ! -f "$RELEASE_STORE_FILE" ]] && signing_details+=("storeFile-missing")
fi

PRE_FLIGHT="${SIGNING_MODE}"
if [[ "$SIGNING_MODE" != "release-configured" ]]; then
  PRE_FLIGHT+=" (${signing_details[*]})"
else
  PRE_FLIGHT+=" (release signing ready)"
fi

if [[ "$STRICT_SIGNING" == "true" && "$FLAVOR" == "prod" && "$SIGNING_MODE" != "release-configured" ]]; then
  PRE_FLIGHT_STATUS="block"
  PRE_FLIGHT_MESSAGE="Strict signing is enabled for prod flavor but release signing is not configured."
else
  PRE_FLIGHT_STATUS=$([[ "$SIGNING_MODE" == "release-configured" ]] && echo "ready" || echo "review")
  PRE_FLIGHT_MESSAGE=$([[ "$SIGNING_MODE" == "release-configured" ]] && echo "Release signing is configured." || echo "Release signing is missing; build will fall back to debug signing.")
fi

ARTIFACT_ROOT="${JIVE_RELEASE_CANDIDATE_ARTIFACT_DIR:-$APP_DIR/build/release-candidate/$STAMP-$FLAVOR}"
REPORT_DIR="$APP_DIR/build/reports/release-candidate"
mkdir -p "$ARTIFACT_ROOT" "$REPORT_DIR"

write_report() {
  python3 - "$REPORT_DIR" "$STAMP" "$FLAVOR" "$BUILD_NAME" "$BUILD_NUMBER" "$SIGNING_MODE" "$PRE_FLIGHT" "$STRICT_SIGNING" "$PRE_FLIGHT_STATUS" "$PRE_FLIGHT_MESSAGE" "${1:-}" "${2:-}" "${3:-}" "${4:-}" "${5:-}" <<'PY'
import json
import sys
from pathlib import Path

(report_dir, stamp, flavor, build_name, build_number, signing_mode, signing_preflight,
 strict_signing, status, message, artifact_path, artifact_bytes, sha256, git_branch,
 git_commit) = sys.argv[1:]

report_root = Path(report_dir)
report_root.mkdir(parents=True, exist_ok=True)
payload = {
    "generatedAt": stamp,
    "flavor": flavor,
    "buildName": build_name,
    "buildNumber": build_number,
    "signingMode": signing_mode,
    "signingPreflight": signing_preflight,
    "strictSigning": strict_signing == "true",
    "status": status,
    "message": message,
}

if artifact_path:
    artifact = Path(artifact_path)
    payload.update(
        {
            "artifactPath": str(artifact),
            "artifactName": artifact.name,
            "artifactBytes": int(artifact_bytes),
            "sha256": sha256,
            "gitBranch": git_branch,
            "gitCommit": git_commit,
        }
    )

json_path = report_root / "release-candidate.json"
md_path = report_root / "release-candidate.md"
latest_md_path = report_root / "latest.md"

json_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")

lines = [
    "# Release Candidate",
    "",
    f"- generatedAt: {stamp}",
    f"- flavor: {flavor}",
    f"- buildName: {build_name}",
    f"- buildNumber: {build_number}",
    f"- status: {status}",
    f"- message: {message}",
    f"- signingMode: {signing_mode}",
    f"- signingPreflight: {signing_preflight}",
    f"- strictSigning: {strict_signing}",
]
if artifact_path:
    lines.extend(
        [
            f"- artifactName: {payload['artifactName']}",
            f"- artifactBytes: {payload['artifactBytes']}",
            f"- sha256: {sha256}",
            f"- gitBranch: {git_branch}",
            f"- gitCommit: {git_commit}",
            f"- artifactPath: {artifact_path}",
        ]
    )

content = "\n".join(lines) + "\n"
md_path.write_text(content, encoding="utf-8")
latest_md_path.write_text(content, encoding="utf-8")
PY
}

log() {
  echo "[release-candidate] $*"
}

log "flavor=$FLAVOR buildName=$BUILD_NAME buildNumber=$BUILD_NUMBER signing=$SIGNING_MODE"
log "signingPreflight=$PRE_FLIGHT strict=$STRICT_SIGNING"

write_report

if [[ "$PRE_FLIGHT_STATUS" == "block" ]]; then
  echo "$PRE_FLIGHT_MESSAGE" >&2
  echo "Provide ${KEY_PROPERTIES_FILE:-key.properties} or export the required keystore environment variables." >&2
  exit 1
fi

flutter pub get
flutter build appbundle \
  --release \
  --flavor "$FLAVOR" \
  --build-name "$BUILD_NAME" \
  --build-number "$BUILD_NUMBER"

EXPECTED_AAB="$APP_DIR/build/app/outputs/bundle/${FLAVOR}Release/app-${FLAVOR}-release.aab"
if [[ -f "$EXPECTED_AAB" ]]; then
  AAB_PATH="$EXPECTED_AAB"
else
  AAB_PATH="$(find "$APP_DIR/build/app/outputs/bundle" -name '*.aab' | sort | tail -n 1)"
fi

if [[ -z "${AAB_PATH:-}" || ! -f "$AAB_PATH" ]]; then
  echo "AAB artifact not found after build." >&2
  exit 1
fi

AAB_NAME="$(basename "$AAB_PATH")"
TARGET_AAB="$ARTIFACT_ROOT/$AAB_NAME"
cp "$AAB_PATH" "$TARGET_AAB"

SHA256="$(shasum -a 256 "$TARGET_AAB" | awk '{print $1}')"
GIT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
GIT_COMMIT="$(git rev-parse HEAD)"
write_report "$TARGET_AAB" "$(stat -f%z "$TARGET_AAB")" "$SHA256" "$GIT_BRANCH" "$GIT_COMMIT"

log "artifact=$TARGET_AAB"
log "report=$REPORT_DIR/release-candidate.json"
