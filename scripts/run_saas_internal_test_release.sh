#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

REPO="${GITHUB_REPOSITORY:-}"
ENV_FILE="${PRODUCTION_ENV_FILE:-/tmp/jive-saas-production.env}"
ARTIFACT_DIR="${JIVE_SAAS_RELEASE_ARTIFACT_DIR:-$APP_DIR/build/reports/saas-release-candidate-sequence}"
BUILD_NAME="${JIVE_SAAS_RELEASE_BUILD_NAME:-}"
BUILD_NUMBER="${JIVE_SAAS_RELEASE_BUILD_NUMBER:-}"
APPLY=0
INCLUDE_OPTIONAL=0
RUN_SEQUENCE=1

READINESS_SCRIPT="${JIVE_SAAS_PROD_READINESS_SCRIPT:-$APP_DIR/scripts/check_saas_production_readiness.sh}"
SECRET_PUSH_SCRIPT="${JIVE_SAAS_SECRET_PUSH_SCRIPT:-$APP_DIR/scripts/push_saas_github_secrets.sh}"
SECRET_CHECK_SCRIPT="${JIVE_SAAS_SECRET_CHECK_SCRIPT:-$APP_DIR/scripts/check_saas_github_secrets.sh}"
SEQUENCE_SCRIPT="${JIVE_SAAS_RELEASE_SEQUENCE_SCRIPT:-$APP_DIR/scripts/run_saas_release_candidate_sequence.sh}"

usage() {
  cat <<'EOF'
Usage:
  scripts/run_saas_internal_test_release.sh [options]

Options:
  --repo <owner/repo>      GitHub repository. Defaults to GITHUB_REPOSITORY or gh repo resolution in child scripts.
  --env-file <path>        Production env file. Defaults to PRODUCTION_ENV_FILE or /tmp/jive-saas-production.env.
  --artifact-dir <path>    Final release-candidate artifact download directory.
  --build-name <version>   Optional Flutter build-name override.
  --build-number <number>  Optional Flutter build-number override.
  --include-optional       Upload optional production-release secrets from the env file too.
  --skip-sequence          Upload and verify secrets, but do not run the release-candidate workflow sequence.
  --apply                  Upload GitHub secrets and run the sequence. Without this, only local dry-run checks run.
  --help                   Show this help.

This is the final local entrypoint for preparing a Google Play internal-test
production AAB. It validates the production env file, uploads production client
secrets when --apply is passed, checks GitHub Actions secrets including Android
release signing, and then delegates to scripts/run_saas_release_candidate_sequence.sh.

The script never prints secret values.
EOF
}

log() {
  printf '[saas-internal-release] %s\n' "$*"
}

die() {
  printf '[saas-internal-release] ERROR: %s\n' "$*" >&2
  exit 1
}

parse_args() {
  while (($#)); do
    case "$1" in
      --repo)
        REPO="${2:-}"
        shift 2
        ;;
      --env-file)
        ENV_FILE="${2:-}"
        shift 2
        ;;
      --artifact-dir)
        ARTIFACT_DIR="${2:-}"
        shift 2
        ;;
      --build-name)
        BUILD_NAME="${2:-}"
        shift 2
        ;;
      --build-number)
        BUILD_NUMBER="${2:-}"
        shift 2
        ;;
      --include-optional)
        INCLUDE_OPTIONAL=1
        shift
        ;;
      --skip-sequence)
        RUN_SEQUENCE=0
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

require_file() {
  local file="$1"
  local label="$2"

  [[ -f "$file" ]] || die "$label not found: $file"
}

repo_args() {
  if [[ -n "$REPO" ]]; then
    printf '%s\n' --repo "$REPO"
  fi
}

run_production_readiness() {
  require_file "$READINESS_SCRIPT" "production readiness script"
  require_file "$ENV_FILE" "production env file"

  log "validating production env file"
  "$READINESS_SCRIPT" \
    --env-file "$ENV_FILE" \
    --profile app \
    --store android
}

run_secret_upload_dry_run() {
  local args
  require_file "$SECRET_PUSH_SCRIPT" "GitHub secret push script"

  args=(
    --profile production-release
    --env-file "$ENV_FILE"
  )
  if [[ -n "$REPO" ]]; then
    args+=(--repo "$REPO")
  fi
  if [[ "$INCLUDE_OPTIONAL" -eq 1 ]]; then
    args+=(--include-optional)
  fi

  log "validating production-release secret values without upload"
  "$SECRET_PUSH_SCRIPT" "${args[@]}"
}

run_secret_upload_apply() {
  local args
  require_file "$SECRET_PUSH_SCRIPT" "GitHub secret push script"

  args=(
    --profile production-release
    --env-file "$ENV_FILE"
    --apply
  )
  if [[ -n "$REPO" ]]; then
    args+=(--repo "$REPO")
  fi
  if [[ "$INCLUDE_OPTIONAL" -eq 1 ]]; then
    args+=(--include-optional)
  fi

  log "uploading production-release GitHub Actions secrets"
  "$SECRET_PUSH_SCRIPT" "${args[@]}"
}

run_secret_check() {
  local args
  require_file "$SECRET_CHECK_SCRIPT" "GitHub secret check script"

  args=(--profile production-release --include-signing)
  if [[ -n "$REPO" ]]; then
    args+=(--repo "$REPO")
  fi

  log "checking production-release GitHub Actions secrets including signing"
  "$SECRET_CHECK_SCRIPT" "${args[@]}"
}

run_release_sequence() {
  local args
  require_file "$SEQUENCE_SCRIPT" "release candidate sequence script"

  args=(--artifact-dir "$ARTIFACT_DIR")
  if [[ -n "$REPO" ]]; then
    args+=(--repo "$REPO")
  fi
  if [[ -n "$BUILD_NAME" ]]; then
    args+=(--build-name "$BUILD_NAME")
  fi
  if [[ -n "$BUILD_NUMBER" ]]; then
    args+=(--build-number "$BUILD_NUMBER")
  fi

  log "running SaaS release-candidate sequence"
  "$SEQUENCE_SCRIPT" "${args[@]}"
}

main() {
  parse_args "$@"

  run_production_readiness

  if [[ "$APPLY" -ne 1 ]]; then
    run_secret_upload_dry_run
    log "dry run complete; pass --apply to upload secrets and run the release sequence"
    return 0
  fi

  run_secret_upload_apply
  run_secret_check

  if [[ "$RUN_SEQUENCE" -eq 1 ]]; then
    run_release_sequence
  else
    log "release sequence skipped"
  fi
}

main "$@"
