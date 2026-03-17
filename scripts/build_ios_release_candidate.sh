#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$APP_DIR"

VERSION_LINE="$(grep '^version:' pubspec.yaml | awk '{print $2}')"
DEFAULT_BUILD_NAME="${VERSION_LINE%%+*}"
DEFAULT_BUILD_NUMBER="${VERSION_LINE##*+}"

BUILD_NAME="${JIVE_IOS_RELEASE_BUILD_NAME:-$DEFAULT_BUILD_NAME}"
BUILD_NUMBER="${JIVE_IOS_RELEASE_BUILD_NUMBER:-$DEFAULT_BUILD_NUMBER}"
STAMP="$(date +%Y%m%d-%H%M%S)"
ARTIFACT_ROOT="${JIVE_IOS_RELEASE_ARTIFACT_DIR:-$APP_DIR/build/ios-release-candidate/$STAMP}"
REPORT_DIR="$APP_DIR/build/reports/ios-release-candidate"

mkdir -p "$ARTIFACT_ROOT" "$REPORT_DIR"

log() {
  echo "[ios-release-candidate] $*"
}

log "buildName=$BUILD_NAME buildNumber=$BUILD_NUMBER codesign=disabled"
flutter pub get
DESTINATIONS_OUTPUT="$(cd "$APP_DIR/ios" && xcodebuild -workspace Runner.xcworkspace -scheme Runner -showdestinations 2>&1 || true)"
PREFLIGHT_STATUS="ready"
PREFLIGHT_MESSAGE="Xcode destinations are available"
if [[ -z "$DESTINATIONS_OUTPUT" ]]; then
  PREFLIGHT_STATUS="review"
  PREFLIGHT_MESSAGE="xcodebuild -showdestinations returned empty output; proceeding to build for deeper diagnostics"
elif [[ "$DESTINATIONS_OUTPUT" == *"Any iOS Device"* && "$DESTINATIONS_OUTPUT" == *"not installed"* ]]; then
  PREFLIGHT_STATUS="missingPlatform"
  PREFLIGHT_MESSAGE="iOS device platform is not available in the current Xcode installation"
fi

PREFLIGHT_JSON="$REPORT_DIR/ios-release-candidate-preflight.json"
PREFLIGHT_MD="$REPORT_DIR/ios-release-candidate-preflight.md"
PREFLIGHT_LATEST="$REPORT_DIR/ios-release-candidate-preflight-latest.md"
PREFLIGHT_RAW="$REPORT_DIR/ios-release-candidate-preflight.raw.txt"

log "preflight status=$PREFLIGHT_STATUS"
printf '%s\n' "$DESTINATIONS_OUTPUT" > "$PREFLIGHT_RAW"
python3 - "$PREFLIGHT_STATUS" "$PREFLIGHT_MESSAGE" "$STAMP" "$PREFLIGHT_JSON" "$PREFLIGHT_MD" "$PREFLIGHT_LATEST" "$PREFLIGHT_RAW" <<'PY'
import json
import sys
from pathlib import Path

status, message, stamp, json_path, md_path, latest_path, raw_path = sys.argv[1:]
raw_output = Path(raw_path).read_text(encoding="utf-8").strip()
report = {
    "generatedAt": stamp,
    "status": status,
    "message": message,
    "rawOutput": raw_output,
}

json_path = Path(json_path)
md_path = Path(md_path)
latest_path = Path(latest_path)
for path in (json_path.parent, md_path.parent, latest_path.parent):
    path.mkdir(parents=True, exist_ok=True)

json_path.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
content = "\n".join([
    "# iOS Release Candidate Preflight",
    "",
    f"- generatedAt: {stamp}",
    f"- status: {status}",
    f"- message: {message}",
    "",
    "## Raw Output",
    "",
    raw_output,
]) + "\n"
md_path.write_text(content, encoding="utf-8")
latest_path.write_text(content, encoding="utf-8")
PY

if [[ "$PREFLIGHT_STATUS" == "missingPlatform" ]]; then
  echo "$DESTINATIONS_OUTPUT" >&2
  echo "iOS device platform is not available in the current Xcode installation." >&2
  echo "Install the required iOS platform from Xcode > Settings > Components before building a device release candidate." >&2
  exit 2
fi

BUILD_LOG="$REPORT_DIR/ios-release-candidate-build.log"
set +e
flutter build ios \
  --release \
  --no-codesign \
  --build-name "$BUILD_NAME" \
  --build-number "$BUILD_NUMBER" 2>&1 | tee "$BUILD_LOG"
BUILD_EXIT=${PIPESTATUS[0]}
set -e

if [[ "$BUILD_EXIT" -ne 0 ]]; then
  python3 - "$REPORT_DIR" "$STAMP" "$BUILD_NAME" "$BUILD_NUMBER" "$BUILD_LOG" <<'PY'
import json
import sys
from pathlib import Path

report_dir, stamp, build_name, build_number, build_log = sys.argv[1:]
report_root = Path(report_dir)
report_root.mkdir(parents=True, exist_ok=True)
raw_output = Path(build_log).read_text(encoding="utf-8")

if "Any iOS Device" in raw_output and "not installed" in raw_output:
    status = "block"
    message = "iOS device platform is not available in the current Xcode installation"
else:
    status = "block"
    message = "flutter build ios failed before producing Runner.app"

payload = {
    "generatedAt": stamp,
    "status": status,
    "message": message,
    "buildName": build_name,
    "buildNumber": build_number,
    "codesign": "disabled",
    "rawOutput": raw_output,
}

json_path = report_root / "ios-release-candidate.json"
md_path = report_root / "ios-release-candidate.md"
latest_md_path = report_root / "latest.md"

json_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
content = "\n".join([
    "# iOS Release Candidate",
    "",
    f"- generatedAt: {stamp}",
    f"- status: {status}",
    f"- message: {message}",
    f"- buildName: {build_name}",
    f"- buildNumber: {build_number}",
    f"- codesign: disabled",
    "",
    "## Raw Output",
    "",
    raw_output,
]) + "\n"
md_path.write_text(content, encoding="utf-8")
latest_md_path.write_text(content, encoding="utf-8")
PY
  exit "$BUILD_EXIT"
fi

APP_PATH="$APP_DIR/build/ios/iphoneos/Runner.app"
if [[ ! -d "$APP_PATH" ]]; then
  echo "Runner.app not found after iOS release build." >&2
  exit 1
fi

python3 - "$APP_PATH" "$BUILD_NAME" "$BUILD_NUMBER" "$STAMP" "$REPORT_DIR" "$ARTIFACT_ROOT" <<'PY'
import json
import shutil
import sys
from pathlib import Path

app_path, build_name, build_number, stamp, report_dir, artifact_root = sys.argv[1:]
app = Path(app_path)
report_root = Path(report_dir)
artifact_root = Path(artifact_root)
report_root.mkdir(parents=True, exist_ok=True)
artifact_root.mkdir(parents=True, exist_ok=True)

target_app = artifact_root / app.name
if target_app.exists():
    shutil.rmtree(target_app)
shutil.copytree(app, target_app)

payload = {
    "generatedAt": stamp,
    "status": "review",
    "message": "Unsigned iOS release candidate built successfully; manual codesign/archive is still required.",
    "artifactPath": str(target_app),
    "artifactName": target_app.name,
    "buildName": build_name,
    "buildNumber": build_number,
    "codesign": "disabled",
}

json_path = report_root / "ios-release-candidate.json"
md_path = report_root / "ios-release-candidate.md"
latest_md_path = report_root / "latest.md"

json_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
content = "\n".join([
    "# iOS Release Candidate",
    "",
    f"- generatedAt: {stamp}",
    f"- buildName: {build_name}",
    f"- buildNumber: {build_number}",
    f"- codesign: disabled",
    f"- artifactName: {target_app.name}",
    f"- artifactPath: {target_app}",
]) + "\n"
md_path.write_text(content, encoding="utf-8")
latest_md_path.write_text(content, encoding="utf-8")
PY

log "artifact=$ARTIFACT_ROOT/Runner.app"
log "report=$REPORT_DIR/ios-release-candidate.json"
