#!/usr/bin/env bash
set -euo pipefail

PROFILE="${JIVE_SAAS_STAGING_PROFILE:-core}"
REPO="${GITHUB_REPOSITORY:-}"
PRINT_TEMPLATE=0

CORE_SECRETS=(
  STAGING_SUPABASE_ACCESS_TOKEN
  STAGING_PROJECT_REF
  STAGING_DB_PASSWORD
  STAGING_SUPABASE_URL
  STAGING_SUPABASE_ANON_KEY
  STAGING_SUPABASE_SERVICE_ROLE_KEY
  STAGING_PUBSUB_BEARER_TOKEN
  STAGING_WEBHOOK_HMAC_SECRET
  STAGING_ADMIN_API_TOKEN
  STAGING_ADMIN_API_ALLOWED_ORIGINS
  STAGING_ANALYTICS_ADMIN_TOKEN
  STAGING_NOTIFICATION_ADMIN_TOKEN
)

STORE_PROVIDER_SECRETS=(
  STAGING_GOOGLE_SERVICE_ACCOUNT_EMAIL
  STAGING_GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY
  STAGING_GOOGLE_PLAY_PACKAGE_NAME
  STAGING_APPLE_APP_STORE_BUNDLE_ID
  STAGING_APPLE_APP_STORE_SHARED_SECRET
  STAGING_APPLE_APP_STORE_APPLE_ID
  STAGING_APPLE_APP_STORE_ENVIRONMENT
  STAGING_DOMESTIC_PAYMENT_WEBHOOK_TOKEN
)

OPTIONAL_SECRETS=(
  STAGING_SUPABASE_FUNCTIONS_URL
)

usage() {
  cat <<'EOF'
Usage:
  scripts/check_saas_github_secrets.sh [options]

Options:
  --repo <owner/repo>  GitHub repository. Defaults to GITHUB_REPOSITORY or the current gh repo.
  --profile <name>    core or full. Defaults to JIVE_SAAS_STAGING_PROFILE or core.
  --print-template    Print safe gh secret set command templates instead of checking.
  --help              Show this help.

Examples:
  scripts/check_saas_github_secrets.sh --profile core
  scripts/check_saas_github_secrets.sh --profile full --repo zensgit/jive
  scripts/check_saas_github_secrets.sh --profile core --print-template

Notes:
  This script checks only whether GitHub Actions secret names exist.
  It never reads or prints secret values.
EOF
}

log() {
  printf '[saas-github-secrets] %s\n' "$*"
}

die() {
  printf '[saas-github-secrets] ERROR: %s\n' "$*" >&2
  exit 1
}

parse_args() {
  while (( "$#" )); do
    case "$1" in
      --repo)
        REPO="${2:-}"
        shift 2
        ;;
      --profile)
        PROFILE="${2:-}"
        shift 2
        ;;
      --print-template)
        PRINT_TEMPLATE=1
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
    core|full)
      ;;
    *)
      die "unknown profile: $PROFILE"
      ;;
  esac
}

resolve_repo() {
  if [[ -n "$REPO" ]]; then
    printf '%s\n' "$REPO"
    return 0
  fi

  gh repo view --json nameWithOwner --jq .nameWithOwner
}

required_secrets() {
  printf '%s\n' "${CORE_SECRETS[@]}"
  if [[ "$PROFILE" == "full" ]]; then
    printf '%s\n' "${STORE_PROVIDER_SECRETS[@]}"
  fi
}

print_template() {
  local repo="$1"
  local secret

  log "repo: $repo"
  log "profile: $PROFILE"
  log "copy these commands and enter values through stdin when prompted"
  printf '\n'

  while IFS= read -r secret; do
    [[ -n "$secret" ]] || continue
    printf 'gh secret set %s --repo %s\n' "$secret" "$repo"
  done < <(required_secrets)

  printf '\n'
  log "optional"
  for secret in "${OPTIONAL_SECRETS[@]}"; do
    printf 'gh secret set %s --repo %s\n' "$secret" "$repo"
  done
}

load_existing_secrets() {
  local repo="$1"
  gh secret list \
    --repo "$repo" \
    --app actions \
    --json name \
    --jq '.[].name'
}

contains_secret() {
  local needle="$1"

  grep -Fxq "$needle" <<< "$EXISTING_SECRET_NAMES"
}

main() {
  parse_args "$@"

  command -v gh >/dev/null 2>&1 || die "gh CLI is required"

  local repo
  repo="$(resolve_repo)"
  [[ -n "$repo" ]] || die "unable to resolve GitHub repository"

  if [[ "$PRINT_TEMPLATE" -eq 1 ]]; then
    print_template "$repo"
    return 0
  fi

  log "repo: $repo"
  log "profile: $PROFILE"

  local existing_secret_names=""
  while IFS= read -r secret; do
    [[ -n "$secret" ]] || continue
    existing_secret_names+="${secret}"$'\n'
  done < <(load_existing_secrets "$repo")
  EXISTING_SECRET_NAMES="$existing_secret_names"

  local missing=0
  local secret

  while IFS= read -r secret; do
    [[ -n "$secret" ]] || continue
    if contains_secret "$secret"; then
      log "PASS: secret exists: $secret"
    else
      missing=$((missing + 1))
      printf '[saas-github-secrets] MISS: missing required secret: %s\n' "$secret" >&2
    fi
  done < <(required_secrets)

  for secret in "${OPTIONAL_SECRETS[@]}"; do
    if contains_secret "$secret"; then
      log "PASS: optional secret exists: $secret"
    else
      log "WARN: optional secret is not set: $secret"
    fi
  done

  if [[ "$missing" -gt 0 ]]; then
    die "$missing required GitHub Actions secret(s) missing"
  fi

  log "all required GitHub Actions secrets are present"
}

main "$@"
