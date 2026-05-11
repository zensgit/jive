#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CHECK_TARGET="$SCRIPT_DIR/check_saas_github_secrets.sh"
PUSH_TARGET="$SCRIPT_DIR/push_saas_github_secrets.sh"

usage() {
  cat <<'EOF'
Usage:
  scripts/test_saas_github_secrets.sh [--keep-fixtures]

Runs host-only fixture tests for SaaS GitHub Actions secret helper scripts with
a fake gh CLI. No network, real GitHub repository, real secret values, or
GitHub credentials are required.
EOF
}

KEEP_FIXTURES=0
while (($#)); do
  case "$1" in
    --keep-fixtures)
      KEEP_FIXTURES=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      printf '[saas-github-secrets-test] unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

ROOT="$(mktemp -d /tmp/jive-saas-github-secrets-test.XXXXXX)"

cleanup() {
  if [[ "$KEEP_FIXTURES" -eq 1 ]]; then
    printf '[saas-github-secrets-test] kept fixtures: %s\n' "$ROOT"
  else
    rm -rf "$ROOT"
  fi
}

trap cleanup EXIT INT TERM

log() {
  printf '[saas-github-secrets-test] %s\n' "$*"
}

fail() {
  printf '[saas-github-secrets-test] FAIL: %s\n' "$*" >&2
  exit 1
}

assert_contains() {
  local file="$1"
  local expected="$2"
  grep -Fq -- "$expected" "$file" || fail "expected '$expected' in $file"
}

assert_not_contains() {
  local file="$1"
  local unexpected="$2"
  if [[ -f "$file" ]] && grep -Fq -- "$unexpected" "$file"; then
    fail "did not expect '$unexpected' in $file"
  fi
}

CORE_SECRET_NAMES=(
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

PRODUCTION_SECRET_NAMES=(
  PRODUCTION_SUPABASE_URL
  PRODUCTION_SUPABASE_ANON_KEY
  PRODUCTION_ADMOB_APP_ID
  PRODUCTION_ADMOB_BANNER_ID
)

create_fixture_app() {
  local fixture_dir="$1"
  local app_dir="$fixture_dir/app"
  local bin_dir="$fixture_dir/bin"

  mkdir -p "$app_dir/scripts" "$bin_dir"
  cp "$CHECK_TARGET" "$app_dir/scripts/check_saas_github_secrets.sh"
  cp "$PUSH_TARGET" "$app_dir/scripts/push_saas_github_secrets.sh"
  chmod +x \
    "$app_dir/scripts/check_saas_github_secrets.sh" \
    "$app_dir/scripts/push_saas_github_secrets.sh"

  cat > "$bin_dir/gh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

state_dir="${JIVE_FAKE_GH_STATE_DIR:?JIVE_FAKE_GH_STATE_DIR is required}"
log_file="$state_dir/gh.log"
secret_list="$state_dir/secrets.txt"
mkdir -p "$state_dir"
touch "$secret_list"

printf 'gh:%s\n' "$*" >> "$log_file"

if [[ "${1:-}" == "repo" && "${2:-}" == "view" ]]; then
  printf 'zensgit/jive\n'
  exit 0
fi

if [[ "${1:-}" == "secret" && "${2:-}" == "list" ]]; then
  if [[ -n "${JIVE_FAKE_GH_SECRET_NAMES:-}" ]]; then
    printf '%s\n' "$JIVE_FAKE_GH_SECRET_NAMES"
    exit 0
  fi
  cat "$secret_list"
  exit 0
fi

if [[ "${1:-}" == "secret" && "${2:-}" == "set" ]]; then
  secret_name="${3:-}"
  value="$(cat)"
  printf 'set:%s:length=%s\n' "$secret_name" "${#value}" >> "$log_file"
  if [[ -n "$secret_name" ]] && ! grep -Fxq "$secret_name" "$secret_list"; then
    printf '%s\n' "$secret_name" >> "$secret_list"
  fi
  exit 0
fi

printf 'fake gh unsupported command: %s\n' "$*" >&2
exit 2
EOF

  chmod +x "$bin_dir/gh"
}

write_core_env_file() {
  local file="$1"

  cat > "$file" <<'EOF'
SUPABASE_ACCESS_TOKEN=secret-value-that-must-not-leak
STAGING_PROJECT_REF=evnluvzvbqmsmypbchym
STAGING_DB_PASSWORD=db-password-that-must-not-leak
SUPABASE_URL=https://example.supabase.co
SUPABASE_ANON_KEY=anon-key-that-must-not-leak
SUPABASE_SERVICE_ROLE_KEY=service-role-that-must-not-leak
PUBSUB_BEARER_TOKEN=pubsub-token-that-must-not-leak
WEBHOOK_HMAC_SECRET=webhook-secret-that-must-not-leak
ADMIN_API_TOKEN=admin-token-that-must-not-leak
ADMIN_API_ALLOWED_ORIGINS=https://staging.example.com
ANALYTICS_ADMIN_TOKEN=analytics-token-that-must-not-leak
NOTIFICATION_ADMIN_TOKEN=notification-token-that-must-not-leak
SUPABASE_FUNCTIONS_URL=https://functions.example.com
EOF
}

write_production_env_file() {
  local file="$1"

  cat > "$file" <<'EOF'
SUPABASE_URL=https://prod.example.supabase.co
SUPABASE_ANON_KEY=prod-anon-that-must-not-leak
ADMOB_APP_ID=ca-app-pub-prod-app
ADMOB_BANNER_ID=ca-app-pub-prod-banner
EOF
}

run_fixture() {
  local label="$1"
  shift
  local -a extra_env=()

  while (($#)) && [[ "$1" == *=* ]]; do
    extra_env+=("$1")
    shift
  done

  local fixture_dir="$ROOT/$label"
  local state_dir="$fixture_dir/state"
  local app_dir="$fixture_dir/app"
  local bin_dir="$fixture_dir/bin"
  mkdir -p "$fixture_dir" "$state_dir"
  create_fixture_app "$fixture_dir"

  set +e
  if ((${#extra_env[@]})); then
    env \
      PATH="$bin_dir:$PATH" \
      JIVE_FAKE_GH_STATE_DIR="$state_dir" \
      "${extra_env[@]}" \
      "$@" \
      > "$fixture_dir/stdout.txt" 2> "$fixture_dir/stderr.txt"
  else
    env \
      PATH="$bin_dir:$PATH" \
      JIVE_FAKE_GH_STATE_DIR="$state_dir" \
      "$@" \
      > "$fixture_dir/stdout.txt" 2> "$fixture_dir/stderr.txt"
  fi
  local status=$?
  set -e

  printf '%s\n' "$status" > "$fixture_dir/status.txt"
  printf '%s\n' "$app_dir" > "$fixture_dir/app-dir.txt"
  printf '%s\n' "$state_dir" > "$fixture_dir/state-dir.txt"
}

assert_status() {
  local label="$1"
  local expected="$2"
  local actual
  actual="$(cat "$ROOT/$label/status.txt")"
  if [[ "$actual" != "$expected" ]]; then
    printf '%s\n' '--- stdout ---' >&2
    cat "$ROOT/$label/stdout.txt" >&2 || true
    printf '%s\n' '--- stderr ---' >&2
    cat "$ROOT/$label/stderr.txt" >&2 || true
    printf '%s\n' '--- fake gh ---' >&2
    cat "$(cat "$ROOT/$label/state-dir.txt")/gh.log" >&2 || true
    fail "$label expected exit $expected, got $actual"
  fi
}

"$CHECK_TARGET" --help >/dev/null
"$PUSH_TARGET" --help >/dev/null
log "help fixtures ok: scripts expose help without gh"

run_fixture check-template \
  "$(dirname "$CHECK_TARGET")/check_saas_github_secrets.sh" --profile production-release --include-signing --repo zensgit/jive --print-template
assert_status check-template 0
assert_contains "$ROOT/check-template/stdout.txt" "gh secret set PRODUCTION_SUPABASE_URL --repo zensgit/jive"
assert_contains "$ROOT/check-template/stdout.txt" "gh secret set ANDROID_RELEASE_KEYSTORE_BASE64 --repo zensgit/jive"
assert_not_contains "$(cat "$ROOT/check-template/state-dir.txt")/gh.log" "secret list"
log "check fixture ok: print-template is name-only and does not list secrets"

partial_core_names="$(printf '%s\n' "${CORE_SECRET_NAMES[@]:0:3}")"
run_fixture check-missing \
  JIVE_FAKE_GH_SECRET_NAMES="$partial_core_names" \
  "$CHECK_TARGET" --profile core --repo zensgit/jive
assert_status check-missing 1
assert_contains "$ROOT/check-missing/stderr.txt" "missing required secret: STAGING_SUPABASE_URL"
assert_not_contains "$ROOT/check-missing/stdout.txt" "secret-value-that-must-not-leak"
assert_not_contains "$ROOT/check-missing/stderr.txt" "secret-value-that-must-not-leak"
log "check fixture ok: missing required secrets fail without exposing values"

complete_core_names="$(printf '%s\n' "${CORE_SECRET_NAMES[@]}" STAGING_SUPABASE_FUNCTIONS_URL)"
run_fixture check-core \
  JIVE_FAKE_GH_SECRET_NAMES="$complete_core_names" \
  "$CHECK_TARGET" --profile core --repo zensgit/jive
assert_status check-core 0
assert_contains "$ROOT/check-core/stdout.txt" "all required GitHub Actions secrets are present"
log "check fixture ok: core profile accepts complete required matrix"

dry_env="$ROOT/dry-run.env"
write_core_env_file "$dry_env"
run_fixture push-dry-run \
  "$(dirname "$PUSH_TARGET")/push_saas_github_secrets.sh" --env-file "$dry_env" --profile core --repo zensgit/jive --include-optional
assert_status push-dry-run 0
assert_contains "$ROOT/push-dry-run/stdout.txt" "dry run complete"
assert_contains "$ROOT/push-dry-run/stdout.txt" "READY: value present for STAGING_SUPABASE_ACCESS_TOKEN"
assert_not_contains "$(cat "$ROOT/push-dry-run/state-dir.txt")/gh.log" "secret set"
assert_not_contains "$ROOT/push-dry-run/stdout.txt" "secret-value-that-must-not-leak"
assert_not_contains "$ROOT/push-dry-run/stderr.txt" "secret-value-that-must-not-leak"
log "push fixture ok: dry-run validates values without writing or leaking"

apply_env="$ROOT/apply.env"
write_core_env_file "$apply_env"
run_fixture push-apply \
  "$(dirname "$PUSH_TARGET")/push_saas_github_secrets.sh" --env-file "$apply_env" --profile core --repo zensgit/jive --include-optional --apply
assert_status push-apply 0
state_dir="$(cat "$ROOT/push-apply/state-dir.txt")"
assert_contains "$state_dir/gh.log" "set:STAGING_SUPABASE_ACCESS_TOKEN:"
assert_contains "$state_dir/secrets.txt" "STAGING_SUPABASE_FUNCTIONS_URL"
assert_contains "$ROOT/push-apply/stdout.txt" "GitHub Actions secrets uploaded"
assert_contains "$ROOT/push-apply/stdout.txt" "all required GitHub Actions secrets are present"
assert_not_contains "$state_dir/gh.log" "secret-value-that-must-not-leak"
assert_not_contains "$ROOT/push-apply/stdout.txt" "secret-value-that-must-not-leak"
assert_not_contains "$ROOT/push-apply/stderr.txt" "secret-value-that-must-not-leak"
log "push fixture ok: apply writes names only and post-checks via fake gh"

prod_env="$ROOT/production.env"
write_production_env_file "$prod_env"
run_fixture push-production \
  "$(dirname "$PUSH_TARGET")/push_saas_github_secrets.sh" --env-file "$prod_env" --profile production-release --repo zensgit/jive
assert_status push-production 0
assert_contains "$ROOT/push-production/stdout.txt" "READY: value present for PRODUCTION_SUPABASE_URL"
assert_contains "$ROOT/push-production/stdout.txt" "READY: value present for PRODUCTION_ADMOB_BANNER_ID"
assert_not_contains "$ROOT/push-production/stdout.txt" "prod-anon-that-must-not-leak"
log "push fixture ok: production-release profile validates production matrix"

log "all SaaS GitHub secrets self-tests passed"
