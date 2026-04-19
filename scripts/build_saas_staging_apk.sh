#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

ENV_FILE="${STAGING_ENV_FILE:-/tmp/jive-saas-staging.env}"
FLAVOR="${JIVE_SAAS_BUILD_FLAVOR:-dev}"
MODE="${JIVE_SAAS_BUILD_MODE:-debug}"
BUILD_KIND="${JIVE_SAAS_BUILD_KIND:-apk}"
STAMP="$(date +%Y%m%d-%H%M%S)"
ARTIFACT_ROOT="${JIVE_SAAS_BUILD_ARTIFACT_DIR:-$APP_DIR/build/saas-staging/$STAMP-$FLAVOR-$MODE}"
REPORT_DIR="$APP_DIR/build/reports/saas-staging"

usage() {
  cat <<'EOF'
Usage:
  scripts/build_saas_staging_apk.sh [options]

Options:
  --env-file <path>  Staging env file. Defaults to STAGING_ENV_FILE or /tmp/jive-saas-staging.env.
  --flavor <name>    Flutter flavor. Defaults to JIVE_SAAS_BUILD_FLAVOR or dev.
  --mode <name>      debug or release. Defaults to JIVE_SAAS_BUILD_MODE or debug.
  --kind <name>      apk or appbundle. Defaults to JIVE_SAAS_BUILD_KIND or apk.
  --help             Show this help.

Required env-file keys:
  SUPABASE_URL
  SUPABASE_ANON_KEY

Notes:
  This script only passes client-safe Supabase values to Flutter.
  It never passes SUPABASE_SERVICE_ROLE_KEY into the app build.
EOF
}

log() {
  printf '[saas-staging-build] %s\n' "$*"
}

die() {
  printf '[saas-staging-build] ERROR: %s\n' "$*" >&2
  exit 1
}

value_from_env_file() {
  local key="$1"
  local file="$2"
  awk -F '=' -v key="$key" '
    $0 ~ "^[[:space:]]*" key "=" {
      sub(/^[[:space:]]*/, "", $0)
      value = substr($0, length(key) + 2)
    }
    END { if (value != "") print value }
  ' "$file"
}

resolve_flutter_bin() {
  if [[ -n "${FLUTTER_BIN:-}" && -x "${FLUTTER_BIN:-}" ]]; then
    printf '%s\n' "$FLUTTER_BIN"
    return 0
  fi

  local candidate
  for candidate in \
    "$APP_DIR/../../.flutter_sdk/bin/flutter" \
    "$APP_DIR/../.flutter_sdk/bin/flutter" \
    "$APP_DIR/.flutter_sdk/bin/flutter" \
    "$HOME/development/flutter/bin/flutter" \
    "$HOME/flutter/bin/flutter" \
    "/opt/homebrew/bin/flutter"; do
    if [[ -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  command -v flutter 2>/dev/null
}

parse_args() {
  while (( "$#" )); do
    case "$1" in
      --env-file)
        ENV_FILE="${2:-}"
        shift 2
        ;;
      --flavor)
        FLAVOR="${2:-}"
        shift 2
        ;;
      --mode)
        MODE="${2:-}"
        shift 2
        ;;
      --kind)
        BUILD_KIND="${2:-}"
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

  case "$MODE" in
    debug|release)
      ;;
    *)
      die "unsupported mode: $MODE"
      ;;
  esac

  case "$BUILD_KIND" in
    apk|appbundle)
      ;;
    *)
      die "unsupported kind: $BUILD_KIND"
      ;;
  esac

  if [[ "$BUILD_KIND" == "appbundle" && "$MODE" != "release" ]]; then
    die "appbundle builds must use --mode release"
  fi
}

find_artifact() {
  local build_type_segment="$1"
  local flavor_segment="$2"
  local expected=""

  if [[ "$BUILD_KIND" == "appbundle" ]]; then
    expected="$APP_DIR/build/app/outputs/bundle/${flavor_segment}Release/app-${flavor_segment}-release.aab"
    if [[ -f "$expected" ]]; then
      printf '%s\n' "$expected"
      return 0
    fi

    find "$APP_DIR/build/app/outputs/bundle" -name '*.aab' | sort | tail -n 1
    return 0
  fi

  expected="$APP_DIR/build/app/outputs/flutter-apk/app-${flavor_segment}-${build_type_segment}.apk"
  if [[ -f "$expected" ]]; then
    printf '%s\n' "$expected"
    return 0
  fi

  find "/build/app/outputs/flutter-apk" -name "*.apk" | sort | tail -n 1
}

file_size_bytes() {
  local file=""

  if stat -c%s "" >/dev/null 2>&1; then
    stat -c%s ""
    return 0
  fi

  if stat -f%z "" >/dev/null 2>&1; then
    stat -f%z ""
    return 0
  fi

  wc -c < "" | tr -d '[:space:]'
}

write_report() {
  local artifact_path="$1"
  local artifact_bytes="$2"
  local sha256="$3"
  local git_branch="$4"
  local git_commit="$5"

  python3 - "$REPORT_DIR" "$STAMP" "$FLAVOR" "$MODE" "$BUILD_KIND" "$artifact_path" "$artifact_bytes" "$sha256" "$git_branch" "$git_commit" <<'PY'
import json
import sys
from pathlib import Path

(
    report_dir,
    stamp,
    flavor,
    mode,
    build_kind,
    artifact_path,
    artifact_bytes,
    sha256,
    git_branch,
    git_commit,
) = sys.argv[1:]

report_root = Path(report_dir)
report_root.mkdir(parents=True, exist_ok=True)
artifact = Path(artifact_path)
payload = {
    "generatedAt": stamp,
    "flavor": flavor,
    "mode": mode,
    "buildKind": build_kind,
    "artifactPath": str(artifact),
    "artifactName": artifact.name,
    "artifactBytes": int(artifact_bytes),
    "sha256": sha256,
    "gitBranch": git_branch,
    "gitCommit": git_commit,
    "supabaseUrlConfigured": True,
    "supabaseAnonKeyConfigured": True,
    "serviceRolePassedToClient": False,
}

(report_root / "saas-staging-build.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2),
    encoding="utf-8",
)

lines = [
    "# SaaS Staging Build",
    "",
    f"- generatedAt: {stamp}",
    f"- flavor: {flavor}",
    f"- mode: {mode}",
    f"- buildKind: {build_kind}",
    f"- artifactName: {artifact.name}",
    f"- artifactBytes: {artifact_bytes}",
    f"- sha256: {sha256}",
    f"- gitBranch: {git_branch}",
    f"- gitCommit: {git_commit}",
    "- supabaseUrlConfigured: true",
    "- supabaseAnonKeyConfigured: true",
    "- serviceRolePassedToClient: false",
    f"- artifactPath: {artifact}",
]
(report_root / "latest.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
PY
}

main() {
  parse_args "$@"

  [[ -f "$ENV_FILE" ]] || die "env file not found: $ENV_FILE"

  local supabase_url
  local supabase_anon_key
  local flutter_bin
  local mode_flag
  local artifact_path
  local target_path
  local sha256

  supabase_url="$(value_from_env_file "SUPABASE_URL" "$ENV_FILE")"
  supabase_anon_key="$(value_from_env_file "SUPABASE_ANON_KEY" "$ENV_FILE")"
  [[ -n "$supabase_url" ]] || die "SUPABASE_URL is missing in $ENV_FILE"
  [[ -n "$supabase_anon_key" ]] || die "SUPABASE_ANON_KEY is missing in $ENV_FILE"

  flutter_bin="$(resolve_flutter_bin || true)"
  [[ -n "$flutter_bin" ]] || die "Flutter not found; set FLUTTER_BIN or install Flutter"

  mkdir -p "$ARTIFACT_ROOT" "$REPORT_DIR"

  log "flavor=$FLAVOR mode=$MODE kind=$BUILD_KIND"
  log "env file=$ENV_FILE"
  log "service role is intentionally not passed to Flutter"

  if [[ "$MODE" == "release" ]]; then
    mode_flag="--release"
  else
    mode_flag="--debug"
  fi

  (cd "$APP_DIR" && "$flutter_bin" pub get)

  if [[ "$BUILD_KIND" == "appbundle" ]]; then
    (cd "$APP_DIR" && "$flutter_bin" build appbundle \
      "$mode_flag" \
      --flavor "$FLAVOR" \
      --dart-define="SUPABASE_URL=$supabase_url" \
      --dart-define="SUPABASE_ANON_KEY=$supabase_anon_key")
  else
    (cd "$APP_DIR" && "$flutter_bin" build apk \
      "$mode_flag" \
      --flavor "$FLAVOR" \
      --dart-define="SUPABASE_URL=$supabase_url" \
      --dart-define="SUPABASE_ANON_KEY=$supabase_anon_key")
  fi

  artifact_path="$(find_artifact "$MODE" "$FLAVOR")"
  [[ -n "$artifact_path" && -f "$artifact_path" ]] || die "build artifact not found"

  target_path="$ARTIFACT_ROOT/$(basename "$artifact_path")"
  cp "$artifact_path" "$target_path"
  sha256="$(shasum -a 256 "$target_path" | awk '{print $1}')"

  write_report \
    "$target_path" \
    "20 20 12 61 79 80 81 33 98 100 204 250 395 398 399 400 701 702file_size_bytes "")" \
    "$sha256" \
    "$(cd "$APP_DIR" && git rev-parse --abbrev-ref HEAD)" \
    "$(cd "$APP_DIR" && git rev-parse HEAD)"

  log "artifact=$target_path"
  log "sha256=$sha256"
  log "report=$REPORT_DIR/saas-staging-build.json"
}

main "$@"