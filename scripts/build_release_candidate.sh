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
ENV_FILE="${PRODUCTION_ENV_FILE:-/tmp/jive-saas-production.env}"
STAMP="$(date +%Y%m%d-%H%M%S)"
STRICT_SIGNING="${JIVE_RELEASE_CANDIDATE_STRICT_SIGNING:-false}"
STRICT_SIGNING="$(echo "$STRICT_SIGNING" | tr '[:upper:]' '[:lower:]')"
RUN_PROD_READINESS="${JIVE_RELEASE_CANDIDATE_RUN_PROD_READINESS:-true}"
RUN_PROD_READINESS="$(echo "$RUN_PROD_READINESS" | tr '[:upper:]' '[:lower:]')"
DRY_RUN="${JIVE_RELEASE_CANDIDATE_DRY_RUN:-false}"
DRY_RUN="$(echo "$DRY_RUN" | tr '[:upper:]' '[:lower:]')"
SIGNING_MODE="debug"
signing_details=()
TEMP_FILES=()
DART_DEFINE_FILE=""
DART_DEFINES_CONFIGURED="false"

cleanup_temp_files() {
  if [[ "${#TEMP_FILES[@]}" -eq 0 ]]; then
    return 0
  fi

  local path
  for path in "${TEMP_FILES[@]}"; do
    [[ -n "$path" ]] || continue
    rm -rf -- "$path"
  done
}

trap cleanup_temp_files EXIT INT TERM

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

value_from_env_file() {
  local key="$1"
  local file="$2"
  [[ -f "$file" ]] || return 0

  awk -F '=' -v key="$key" '
    $0 ~ "^[[:space:]]*" key "=" {
      sub(/^[[:space:]]*/, "", $0)
      value = substr($0, length(key) + 2)
    }
    END { if (value != "") print value }
  ' "$file"
}

value_for_key() {
  local key="$1"
  local value="${!key:-}"

  if [[ -n "$value" ]]; then
    printf '%s\n' "$value"
    return 0
  fi

  value_from_env_file "$key" "$ENV_FILE"
}

export_if_present() {
  local key="$1"
  local value

  value="$(value_for_key "$key")"
  if [[ -n "$value" ]]; then
    export "$key=$value"
  fi
}

file_size_bytes() {
  local file="$1"

  if stat -c%s "$file" >/dev/null 2>&1; then
    stat -c%s "$file"
    return 0
  fi

  if stat -f%z "$file" >/dev/null 2>&1; then
    stat -f%z "$file"
    return 0
  fi

  wc -c < "$file" | tr -d '[:space:]'
}

build_dart_define_file() {
  local output_dir
  local output_file

  output_dir="$(mktemp -d "${TMPDIR:-/tmp}/jive-release-dart-defines.XXXXXX")"
  chmod 700 "$output_dir"
  TEMP_FILES+=("$output_dir")

  output_file="$output_dir/dart-defines.json"
  : > "$output_file"
  chmod 600 "$output_file"

  python3 - "$output_file" \
    "$(value_for_key SUPABASE_URL)" \
    "$(value_for_key SUPABASE_ANON_KEY)" \
    "$(value_for_key PAYMENT_CHANNEL)" \
    "$(value_for_key ENABLE_STORE_BILLING)" \
    "$(value_for_key ENABLE_WECHAT_PAY)" \
    "$(value_for_key ENABLE_ALIPAY)" \
    "$(value_for_key ADMOB_BANNER_ID)" <<'PY'
import json
import sys
from pathlib import Path

(
    output_file,
    supabase_url,
    supabase_anon_key,
    payment_channel,
    enable_store_billing,
    enable_wechat_pay,
    enable_alipay,
    admob_banner_id,
) = sys.argv[1:]

values = {
    "SUPABASE_URL": supabase_url,
    "SUPABASE_ANON_KEY": supabase_anon_key,
    "PAYMENT_CHANNEL": payment_channel,
    "ENABLE_STORE_BILLING": enable_store_billing,
    "ENABLE_WECHAT_PAY": enable_wechat_pay,
    "ENABLE_ALIPAY": enable_alipay,
    "ADMOB_BANNER_ID": admob_banner_id,
}

Path(output_file).write_text(
    json.dumps(
        {key: value for key, value in values.items() if value},
        ensure_ascii=False,
        indent=2,
    ),
    encoding="utf-8",
)
PY

  DART_DEFINE_FILE="$output_file"
  DART_DEFINES_CONFIGURED="true"
}

run_production_readiness_gate() {
  if [[ "$FLAVOR" != "prod" || "$RUN_PROD_READINESS" != "true" ]]; then
    return 0
  fi

  local args=(
    --profile app
    --store android
    --env-file "$ENV_FILE"
  )

  if [[ "$STRICT_SIGNING" == "true" ]]; then
    args+=(--require-release-signing)
  fi

  if [[ "${JIVE_RELEASE_CANDIDATE_ALLOW_ADMOB_TEST_IDS:-false}" == "true" ]]; then
    args+=(--allow-admob-test-ids)
  fi

  if [[ "${JIVE_RELEASE_CANDIDATE_ALLOW_STAGING_SUPABASE:-false}" == "true" ]]; then
    args+=(--allow-staging-supabase)
  fi

  if [[ "${JIVE_RELEASE_CANDIDATE_ALLOW_DOMESTIC_SHARED_TOKEN:-false}" == "true" ]]; then
    args+=(--allow-domestic-shared-token)
  fi

  log "running SaaS production readiness gate"
  bash "$APP_DIR/scripts/check_saas_production_readiness.sh" "${args[@]}"
}

write_report() {
  python3 - "$REPORT_DIR" "$STAMP" "$FLAVOR" "$BUILD_NAME" "$BUILD_NUMBER" "$SIGNING_MODE" "$PRE_FLIGHT" "$STRICT_SIGNING" "$RUN_PROD_READINESS" "$DRY_RUN" "$DART_DEFINES_CONFIGURED" "$PRE_FLIGHT_STATUS" "$PRE_FLIGHT_MESSAGE" "${1:-}" "${2:-}" "${3:-}" "${4:-}" "${5:-}" <<'PY'
import json
import sys
from pathlib import Path

(report_dir, stamp, flavor, build_name, build_number, signing_mode, signing_preflight,
 strict_signing, run_prod_readiness, dry_run, dart_defines_configured, status, message,
 artifact_path, artifact_bytes, sha256, git_branch, git_commit) = sys.argv[1:]

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
    "productionReadinessGate": run_prod_readiness == "true",
    "dryRun": dry_run == "true",
    "dartDefinesConfigured": dart_defines_configured == "true",
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
    f"- productionReadinessGate: {run_prod_readiness}",
    f"- dryRun: {dry_run}",
    f"- dartDefinesConfigured: {dart_defines_configured}",
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
log "envFile=$ENV_FILE productionReadinessGate=$RUN_PROD_READINESS dryRun=$DRY_RUN"

if [[ "$FLAVOR" == "prod" ]]; then
  build_dart_define_file
  export_if_present ADMOB_APP_ID
fi

write_report

if [[ "$PRE_FLIGHT_STATUS" == "block" ]]; then
  echo "$PRE_FLIGHT_MESSAGE" >&2
  echo "Provide ${KEY_PROPERTIES_FILE:-key.properties} or export the required keystore environment variables." >&2
  exit 1
fi

run_production_readiness_gate

if [[ "$DRY_RUN" == "true" ]]; then
  log "dry run requested; skipping Flutter build"
  exit 0
fi

flutter pub get

build_args=(
  build
  appbundle
  --release
  --flavor "$FLAVOR"
  --build-name "$BUILD_NAME"
  --build-number "$BUILD_NUMBER"
)
if [[ -n "$DART_DEFINE_FILE" ]]; then
  build_args+=(--dart-define-from-file="$DART_DEFINE_FILE")
fi

flutter "${build_args[@]}"

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
write_report "$TARGET_AAB" "$(file_size_bytes "$TARGET_AAB")" "$SHA256" "$GIT_BRANCH" "$GIT_COMMIT"

log "artifact=$TARGET_AAB"
log "report=$REPORT_DIR/release-candidate.json"
