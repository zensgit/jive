#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPORT_DIR="$APP_DIR/build/reports"
CONTEXT="${1:-release}"
SUMMARY_TARGET="${GITHUB_STEP_SUMMARY:-}"

tmp_file="$(mktemp)"
trap 'rm -f "$tmp_file"' EXIT

python3 - "$REPORT_DIR" "$CONTEXT" >"$tmp_file" <<'PY'
import json
import os
import sys

report_dir = sys.argv[1]
context = sys.argv[2]

sections = [
    ("release-candidate", "Android Release Candidate"),
    ("ios-release-candidate", "iOS Release Candidate"),
    ("sync-runtime", "Sync Runtime Reports"),
    ("account-book-import-sync", "Account Book / Import / Sync Reports"),
    ("import-column-mapping", "Import Column Mapping Reports"),
]

print(f"## {context.capitalize()} Release Report Summary")
printed = False

for folder, title in sections:
    folder_path = os.path.join(report_dir, folder)
    files = []
    if os.path.isdir(folder_path):
        for name in sorted(os.listdir(folder_path)):
            if name.endswith(".json"):
                files.append(os.path.join(folder_path, name))
    if not files:
        continue
    printed = True
    print()
    print(f"### {title}")
    for path in files:
        with open(path, "r", encoding="utf-8") as handle:
            data = json.load(handle)
        name = os.path.basename(path)
        status = data.get("status", "unknown")
        level = data.get("telemetryLevel") or data.get("mode") or "n/a"
        artifact_name = str(data.get("artifactName", "")).strip()
        flavor = str(data.get("flavor", "")).strip()
        signing_mode = str(data.get("signingMode", "")).strip()
        codesign = str(data.get("codesign", "")).strip()
        message = str(data.get("message", "")).strip()
        reason = str(data.get("reason", "")).strip()
        action = str(data.get("action", "")).strip()
        recommendation = str(data.get("recommendation", "")).strip()
        print(f"- `{name}`: `{status}` / `{level}`")
        if artifact_name:
            print(f"  - artifact: {artifact_name}")
        if flavor:
            print(f"  - flavor: {flavor}")
        if signing_mode:
            print(f"  - signingMode: {signing_mode}")
        if codesign:
            print(f"  - codesign: {codesign}")
        if message:
            print(f"  - message: {message}")
        if reason:
            print(f"  - reason: {reason}")
        if action:
            print(f"  - action: {action}")
        if recommendation:
            print(f"  - recommendation: {recommendation}")

if not printed:
    print()
    print("- No JSON reports found under `build/reports`.")
PY

cat "$tmp_file"

if [[ -n "$SUMMARY_TARGET" ]]; then
  cat "$tmp_file" >> "$SUMMARY_TARGET"
fi
