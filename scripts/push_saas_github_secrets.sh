#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

ENV_FILE="${STAGING_ENV_FILE:-}"
PROFILE="${JIVE_SAAS_STAGING_PROFILE:-core}"
REPO="${GITHUB_REPOSITORY:-}"
APPLY=0
INCLUDE_OPTIONAL=0
INCLUDE_SIGNING=0

usage() {
  cat <<'EOF'
Usage:
  scripts/push_saas_github_secrets.sh [options]

Options:
  --env-file <path>       Local env file. Defaults to STAGING_ENV_FILE or /tmp/jive-saas-staging.env for staging profiles,
                          and PRODUCTION_ENV_FILE or /tmp/jive-saas-production.env for production-release.
  --repo <owner/repo>     GitHub repository. Defaults to GITHUB_REPOSITORY or the current gh repo.
  --profile <name>        core, full, or production-release. Defaults to JIVE_SAAS_STAGING_PROFILE or core.
  --include-optional      Also upload optional secrets when available.
  --include-signing       For production-release, upload Android release signing secrets too.
  --apply                 Actually write GitHub Actions secrets. Without this, only checks coverage.
  --help                  Show this help.

Required shell variables:
  SUPABASE_ACCESS_TOKEN or STAGING_SUPABASE_ACCESS_TOKEN
  STAGING_PROJECT_REF
  STAGING_DB_PASSWORD

Required env-file keys for core:
  SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY,
  PUBSUB_BEARER_TOKEN, WEBHOOK_HMAC_SECRET, ADMIN_API_TOKEN,
  ADMIN_API_ALLOWED_ORIGINS, ANALYTICS_ADMIN_TOKEN, NOTIFICATION_ADMIN_TOKEN

Required env-file keys for production-release:
  SUPABASE_URL, SUPABASE_ANON_KEY, ADMOB_APP_ID, ADMOB_BANNER_ID

Notes:
  This script never prints secret values.
  It uploads repository-level GitHub Actions secrets only when --apply is passed.
EOF
}

log() {
  printf '[saas-github-secret-push] %s\n' "$*"
}

die() {
  printf '[saas-github-secret-push] ERROR: %s\n' "$*" >&2
  exit 1
}

warn() {
  printf '[saas-github-secret-push] WARN: %s\n' "$*" >&2
}

parse_args() {
  while (( "$#" )); do
    case "$1" in
      --env-file)
        ENV_FILE="${2:-}"
        shift 2
        ;;
      --repo)
        REPO="${2:-}"
        shift 2
        ;;
      --profile)
        PROFILE="${2:-}"
        shift 2
        ;;
      --include-optional)
        INCLUDE_OPTIONAL=1
        shift
        ;;
      --include-signing)
        INCLUDE_SIGNING=1
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

  case "$PROFILE" in
    core|full|production-release)
      ;;
    *)
      die "unknown profile: $PROFILE"
      ;;
  esac
}

resolve_default_env_file() {
  if [[ -n "$ENV_FILE" ]]; then
    return 0
  fi

  if [[ "$PROFILE" == "production-release" ]]; then
    ENV_FILE="${PRODUCTION_ENV_FILE:-/tmp/jive-saas-production.env}"
  else
    ENV_FILE="${STAGING_ENV_FILE:-/tmp/jive-saas-staging.env}"
  fi
}

resolve_repo() {
  if [[ -n "$REPO" ]]; then
    printf '%s\n' "$REPO"
    return 0
  fi

  gh repo view --json nameWithOwner --jq .nameWithOwner
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

lookup_value() {
  local env_key="$1"
  local file_key="${2:-$env_key}"
  local value="${!env_key:-}"

  if [[ -z "$value" && "$file_key" != "$env_key" ]]; then
    value="${!file_key:-}"
  fi

  if [[ -z "$value" && -f "$ENV_FILE" ]]; then
    value="$(value_from_env_file "$file_key" "$ENV_FILE")"
  fi

  printf '%s\n' "$value"
}

add_secret_mapping() {
  local secret_name="$1"
  local env_key="$2"
  local file_key="${3:-$env_key}"

  SECRET_NAMES+=("$secret_name")
  SECRET_ENV_KEYS+=("$env_key")
  SECRET_FILE_KEYS+=("$file_key")
}

build_secret_mappings() {
  SECRET_NAMES=()
  SECRET_ENV_KEYS=()
  SECRET_FILE_KEYS=()

  if [[ "$PROFILE" == "production-release" ]]; then
    add_secret_mapping PRODUCTION_SUPABASE_URL SUPABASE_URL SUPABASE_URL
    add_secret_mapping PRODUCTION_SUPABASE_ANON_KEY SUPABASE_ANON_KEY SUPABASE_ANON_KEY
    add_secret_mapping PRODUCTION_ADMOB_APP_ID ADMOB_APP_ID ADMOB_APP_ID
    add_secret_mapping PRODUCTION_ADMOB_BANNER_ID ADMOB_BANNER_ID ADMOB_BANNER_ID

    if [[ "$INCLUDE_OPTIONAL" -eq 1 ]]; then
      add_secret_mapping PRODUCTION_ADMIN_API_ALLOWED_ORIGINS ADMIN_API_ALLOWED_ORIGINS ADMIN_API_ALLOWED_ORIGINS
      add_secret_mapping PRODUCTION_PAYMENT_CHANNEL PAYMENT_CHANNEL PAYMENT_CHANNEL
    fi

    if [[ "$INCLUDE_SIGNING" -eq 1 ]]; then
      add_secret_mapping ANDROID_RELEASE_KEYSTORE_BASE64 ANDROID_RELEASE_KEYSTORE_BASE64 ANDROID_RELEASE_KEYSTORE_BASE64
      add_secret_mapping ANDROID_RELEASE_STORE_PASSWORD ANDROID_RELEASE_STORE_PASSWORD ANDROID_RELEASE_STORE_PASSWORD
      add_secret_mapping ANDROID_RELEASE_KEY_ALIAS ANDROID_RELEASE_KEY_ALIAS ANDROID_RELEASE_KEY_ALIAS
      add_secret_mapping ANDROID_RELEASE_KEY_PASSWORD ANDROID_RELEASE_KEY_PASSWORD ANDROID_RELEASE_KEY_PASSWORD
    fi

    return 0
  fi

  add_secret_mapping STAGING_SUPABASE_ACCESS_TOKEN STAGING_SUPABASE_ACCESS_TOKEN SUPABASE_ACCESS_TOKEN
  add_secret_mapping STAGING_PROJECT_REF STAGING_PROJECT_REF STAGING_PROJECT_REF
  add_secret_mapping STAGING_DB_PASSWORD STAGING_DB_PASSWORD STAGING_DB_PASSWORD
  add_secret_mapping STAGING_SUPABASE_URL SUPABASE_URL SUPABASE_URL
  add_secret_mapping STAGING_SUPABASE_ANON_KEY SUPABASE_ANON_KEY SUPABASE_ANON_KEY
  add_secret_mapping STAGING_SUPABASE_SERVICE_ROLE_KEY SUPABASE_SERVICE_ROLE_KEY SUPABASE_SERVICE_ROLE_KEY
  add_secret_mapping STAGING_PUBSUB_BEARER_TOKEN PUBSUB_BEARER_TOKEN PUBSUB_BEARER_TOKEN
  add_secret_mapping STAGING_WEBHOOK_HMAC_SECRET WEBHOOK_HMAC_SECRET WEBHOOK_HMAC_SECRET
  add_secret_mapping STAGING_ADMIN_API_TOKEN ADMIN_API_TOKEN ADMIN_API_TOKEN
  add_secret_mapping STAGING_ADMIN_API_ALLOWED_ORIGINS ADMIN_API_ALLOWED_ORIGINS ADMIN_API_ALLOWED_ORIGINS
  add_secret_mapping STAGING_ANALYTICS_ADMIN_TOKEN ANALYTICS_ADMIN_TOKEN ANALYTICS_ADMIN_TOKEN
  add_secret_mapping STAGING_NOTIFICATION_ADMIN_TOKEN NOTIFICATION_ADMIN_TOKEN NOTIFICATION_ADMIN_TOKEN

  if [[ "$PROFILE" == "full" ]]; then
    add_secret_mapping STAGING_GOOGLE_SERVICE_ACCOUNT_EMAIL GOOGLE_SERVICE_ACCOUNT_EMAIL GOOGLE_SERVICE_ACCOUNT_EMAIL
    add_secret_mapping STAGING_GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY
    add_secret_mapping STAGING_GOOGLE_PLAY_PACKAGE_NAME GOOGLE_PLAY_PACKAGE_NAME GOOGLE_PLAY_PACKAGE_NAME
    add_secret_mapping STAGING_APPLE_APP_STORE_BUNDLE_ID APPLE_APP_STORE_BUNDLE_ID APPLE_APP_STORE_BUNDLE_ID
    add_secret_mapping STAGING_APPLE_APP_STORE_SHARED_SECRET APPLE_APP_STORE_SHARED_SECRET APPLE_APP_STORE_SHARED_SECRET
    add_secret_mapping STAGING_APPLE_APP_STORE_APPLE_ID APPLE_APP_STORE_APPLE_ID APPLE_APP_STORE_APPLE_ID
    add_secret_mapping STAGING_APPLE_APP_STORE_ENVIRONMENT APPLE_APP_STORE_ENVIRONMENT APPLE_APP_STORE_ENVIRONMENT
    add_secret_mapping STAGING_DOMESTIC_PAYMENT_WEBHOOK_TOKEN DOMESTIC_PAYMENT_WEBHOOK_TOKEN DOMESTIC_PAYMENT_WEBHOOK_TOKEN
  fi

  if [[ "$INCLUDE_OPTIONAL" -eq 1 ]]; then
    add_secret_mapping STAGING_SUPABASE_FUNCTIONS_URL SUPABASE_FUNCTIONS_URL SUPABASE_FUNCTIONS_URL
  fi
}

validate_values() {
  local missing=0
  local i
  local xtrace_was_on=0

  case "$-" in
    *x*)
      xtrace_was_on=1
      set +x
      ;;
  esac

  for i in "${!SECRET_NAMES[@]}"; do
    local secret_name="${SECRET_NAMES[$i]}"
    local env_key="${SECRET_ENV_KEYS[$i]}"
    local file_key="${SECRET_FILE_KEYS[$i]}"
    local value

    value="$(lookup_value "$env_key" "$file_key")"
    if [[ -n "$value" ]]; then
      log "READY: value present for $secret_name"
    else
      missing=$((missing + 1))
      printf '[saas-github-secret-push] MISS: missing value for %s (env %s or env-file key %s)\n' \
        "$secret_name" "$env_key" "$file_key" >&2
    fi
  done

  if [[ "$missing" -gt 0 ]]; then
    die "$missing required secret value(s) missing"
  fi

  if [[ "$xtrace_was_on" -eq 1 ]]; then
    set -x
  fi
}

push_values() {
  local repo="$1"
  local i
  local xtrace_was_on=0

  case "$-" in
    *x*)
      xtrace_was_on=1
      set +x
      ;;
  esac

  for i in "${!SECRET_NAMES[@]}"; do
    local secret_name="${SECRET_NAMES[$i]}"
    local env_key="${SECRET_ENV_KEYS[$i]}"
    local file_key="${SECRET_FILE_KEYS[$i]}"
    local value

    value="$(lookup_value "$env_key" "$file_key")"
    log "uploading $secret_name"
    if ! printf '%s' "$value" | gh secret set "$secret_name" \
      --repo "$repo" \
      --app actions >/dev/null; then
      if [[ "$xtrace_was_on" -eq 1 ]]; then
        set -x
      fi
      return 1
    fi
  done

  if [[ "$xtrace_was_on" -eq 1 ]]; then
    set -x
  fi
}

main() {
  parse_args "$@"
  resolve_default_env_file

  command -v gh >/dev/null 2>&1 || die "gh CLI is required"
  [[ -f "$ENV_FILE" ]] || warn "env file not found: $ENV_FILE; shell variables will still be checked"

  local repo
  repo="$(resolve_repo)"
  [[ -n "$repo" ]] || die "unable to resolve GitHub repository"

  build_secret_mappings

  log "repo: $repo"
  log "profile: $PROFILE"
  log "env file: $ENV_FILE"

  validate_values

  if [[ "$APPLY" -ne 1 ]]; then
    log "dry run complete; pass --apply to write GitHub Actions secrets"
    return 0
  fi

  push_values "$repo"
  log "GitHub Actions secrets uploaded"

  local check_args=(--profile "$PROFILE" --repo "$repo")
  if [[ "$INCLUDE_SIGNING" -eq 1 ]]; then
    check_args+=(--include-signing)
  fi

  bash "$APP_DIR/scripts/check_saas_github_secrets.sh" "${check_args[@]}"
}

main "$@"
