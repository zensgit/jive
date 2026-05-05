#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

ENV_FILE="${PRODUCTION_ENV_FILE:-/tmp/jive-saas-production.env}"
PROFILE="app"
STORE_TARGET="android"
STRICT=0
REQUIRE_RELEASE_SIGNING=0
ALLOW_ADMOB_TEST_IDS=0
ALLOW_STAGING_SUPABASE=0
ALLOW_DOMESTIC_SHARED_TOKEN=0
FAILURES=0
WARNINGS=0

KNOWN_STAGING_SUPABASE_REF="evnluvzvbqmsmypbchym"
ADMOB_TEST_APP_ID="ca-app-pub-3940256099942544~3347511713"
ADMOB_TEST_BANNER_ID="ca-app-pub-3940256099942544/6300978111"

usage() {
  cat <<'EOF'
Usage:
  scripts/check_saas_production_readiness.sh [options]

Options:
  --env-file <path>              Production env file. Defaults to PRODUCTION_ENV_FILE or /tmp/jive-saas-production.env.
  --profile <name>               app, billing, or full. Defaults to app.
  --store <name>                 android, ios, all, or none. Defaults to android.
  --strict                       Treat optional production gaps as failures.
  --require-release-signing      Fail when Android release signing is not configured.
  --allow-admob-test-ids         Allow AdMob test IDs. Useful only for staging/dev dry runs.
  --allow-staging-supabase       Allow the known staging Supabase project URL.
  --allow-domestic-shared-token  Allow domestic payment shared-token webhook auth.
  --help                         Show this help.

Examples:
  scripts/check_saas_production_readiness.sh
  scripts/check_saas_production_readiness.sh --profile full --store android --strict --require-release-signing
  scripts/check_saas_production_readiness.sh --env-file /tmp/jive-saas-production.env --profile app

Notes:
  This script is a production release guard. It never prints secret values.
  It intentionally fails on known staging/mock/test configuration unless an explicit allow flag is provided.
EOF
}

log() {
  printf '[saas-prod-readiness] %s\n' "$*"
}

pass() {
  log "PASS: $*"
}

warn() {
  WARNINGS=$((WARNINGS + 1))
  printf '[saas-prod-readiness] WARN: %s\n' "$*" >&2
}

fail() {
  FAILURES=$((FAILURES + 1))
  printf '[saas-prod-readiness] FAIL: %s\n' "$*" >&2
}

warn_or_fail() {
  if [[ "$STRICT" -eq 1 ]]; then
    fail "$*"
  else
    warn "$*"
  fi
}

parse_args() {
  while (( "$#" )); do
    case "$1" in
      --env-file)
        ENV_FILE="${2:-}"
        shift 2
        ;;
      --profile)
        PROFILE="${2:-}"
        shift 2
        ;;
      --store)
        STORE_TARGET="${2:-}"
        shift 2
        ;;
      --strict)
        STRICT=1
        shift
        ;;
      --require-release-signing)
        REQUIRE_RELEASE_SIGNING=1
        shift
        ;;
      --allow-admob-test-ids)
        ALLOW_ADMOB_TEST_IDS=1
        shift
        ;;
      --allow-staging-supabase)
        ALLOW_STAGING_SUPABASE=1
        shift
        ;;
      --allow-domestic-shared-token)
        ALLOW_DOMESTIC_SHARED_TOKEN=1
        shift
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        fail "unknown argument: $1"
        usage
        exit 2
        ;;
    esac
  done

  case "$PROFILE" in
    app|billing|full)
      ;;
    *)
      fail "unknown profile: $PROFILE"
      usage
      exit 2
      ;;
  esac

  case "$STORE_TARGET" in
    android|ios|all|none)
      ;;
    *)
      fail "unknown store target: $STORE_TARGET"
      usage
      exit 2
      ;;
  esac
}

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

is_truthy() {
  case "${1:-}" in
    1|true|TRUE|yes|YES|on|ON)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

is_falsey() {
  case "${1:-}" in
    0|false|FALSE|no|NO|off|OFF)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

lowercase() {
  printf '%s' "${1:-}" | tr '[:upper:]' '[:lower:]'
}

require_present() {
  local key="$1"
  local label="${2:-$key}"
  local value

  value="$(value_for_key "$key")"
  if [[ -n "$value" ]]; then
    pass "$label present"
  else
    fail "$label missing"
  fi
}

warn_if_missing() {
  local key="$1"
  local label="${2:-$key}"
  local value

  value="$(value_for_key "$key")"
  if [[ -n "$value" ]]; then
    pass "$label present"
  else
    warn_or_fail "$label missing"
  fi
}

check_env_file() {
  if [[ -f "$ENV_FILE" ]]; then
    pass "env file exists: $ENV_FILE"
  else
    warn_or_fail "env file missing: $ENV_FILE"
  fi
}

check_supabase_client_config() {
  local supabase_url
  local anon_key

  supabase_url="$(value_for_key SUPABASE_URL)"
  anon_key="$(value_for_key SUPABASE_ANON_KEY)"

  require_present SUPABASE_URL "client SUPABASE_URL"
  require_present SUPABASE_ANON_KEY "client SUPABASE_ANON_KEY"

  if [[ -n "$supabase_url" ]]; then
    if [[ "$supabase_url" != https://* ]]; then
      fail "SUPABASE_URL must use https for production"
    elif [[ "$supabase_url" == *localhost* || "$supabase_url" == *127.0.0.1* ]]; then
      fail "SUPABASE_URL points to local development"
    elif [[ "$supabase_url" == *"$KNOWN_STAGING_SUPABASE_REF"* && "$ALLOW_STAGING_SUPABASE" -ne 1 ]]; then
      fail "SUPABASE_URL points to the known staging project"
    else
      pass "SUPABASE_URL shape is production-safe"
    fi
  fi

  if [[ -n "$anon_key" ]]; then
    if [[ "$anon_key" == sbp_* ]]; then
      fail "SUPABASE_ANON_KEY looks like a Supabase access token"
    elif [[ "$anon_key" != *.*.* ]]; then
      warn_or_fail "SUPABASE_ANON_KEY does not look like a JWT anon key"
    else
      pass "SUPABASE_ANON_KEY shape looks client-safe"
    fi
  fi
}

check_admin_origins() {
  local origins
  origins="$(value_for_key ADMIN_API_ALLOWED_ORIGINS)"

  if [[ -z "$origins" ]]; then
    warn_or_fail "ADMIN_API_ALLOWED_ORIGINS missing"
    return 0
  fi

  if [[ "$origins" == "*" || "$origins" == *",*"* || "$origins" == *"*, "* ]]; then
    fail "ADMIN_API_ALLOWED_ORIGINS must not allow wildcard origins in production"
  elif [[ "$origins" == *localhost* || "$origins" == *127.0.0.1* ]]; then
    fail "ADMIN_API_ALLOWED_ORIGINS contains local development origins"
  else
    pass "ADMIN_API_ALLOWED_ORIGINS is constrained"
  fi
}

check_admob_ids() {
  local ad_config="$APP_DIR/lib/core/ads/ad_config.dart"
  local manifest="$APP_DIR/android/app/src/main/AndroidManifest.xml"
  local app_id
  local banner_id
  local found_test=0

  app_id="$(value_for_key ADMOB_APP_ID)"
  banner_id="$(value_for_key ADMOB_BANNER_ID)"

  require_present ADMOB_APP_ID "AdMob app id"
  require_present ADMOB_BANNER_ID "AdMob banner id"

  if [[ "$app_id" == "$ADMOB_TEST_APP_ID" ]]; then
    found_test=1
    warn "ADMOB_APP_ID is the AdMob test app id"
  elif [[ -n "$app_id" ]]; then
    pass "ADMOB_APP_ID is not the test app id"
  fi

  if [[ "$banner_id" == "$ADMOB_TEST_BANNER_ID" ]]; then
    found_test=1
    warn "ADMOB_BANNER_ID is the AdMob test banner id"
  elif [[ -n "$banner_id" ]]; then
    pass "ADMOB_BANNER_ID is not the test banner id"
  fi

  if [[ -f "$ad_config" ]] &&
    grep -F -q "bannerUnitId = testBannerId" "$ad_config"; then
    found_test=1
    warn "AdConfig hardwires bannerUnitId to the AdMob test banner id"
  fi

  if [[ -f "$manifest" ]] &&
    grep -F -q "$ADMOB_TEST_APP_ID" "$manifest"; then
    found_test=1
    warn "AndroidManifest references the AdMob test app id"
  fi

  if [[ "$found_test" -eq 1 ]]; then
    if [[ "$ALLOW_ADMOB_TEST_IDS" -eq 1 ]]; then
      warn "AdMob test IDs allowed by explicit flag"
    else
      fail "AdMob test IDs must be replaced before production release"
    fi
  else
    pass "AdMob test IDs not found in production app config"
  fi
}

check_android_release_signing() {
  local key_properties_file=""
  local store_file="${JIVE_ANDROID_STORE_FILE:-}"
  local store_password="${JIVE_ANDROID_STORE_PASSWORD:-}"
  local key_alias="${JIVE_ANDROID_KEY_ALIAS:-}"
  local key_password="${JIVE_ANDROID_KEY_PASSWORD:-}"

  if [[ -f "$APP_DIR/key.properties" ]]; then
    key_properties_file="$APP_DIR/key.properties"
  elif [[ -f "$APP_DIR/android/key.properties" ]]; then
    key_properties_file="$APP_DIR/android/key.properties"
  fi

  if [[ -n "$key_properties_file" ]]; then
    # shellcheck disable=SC1090
    source "$key_properties_file"
    store_file="${storeFile:-$store_file}"
    store_password="${storePassword:-$store_password}"
    key_alias="${keyAlias:-$key_alias}"
    key_password="${keyPassword:-$key_password}"
  fi

  if [[ -n "$store_file" && ! -f "$store_file" && -f "$APP_DIR/$store_file" ]]; then
    store_file="$APP_DIR/$store_file"
  fi

  if [[ -n "$store_file" && -f "$store_file" && -n "$store_password" && -n "$key_alias" && -n "$key_password" ]]; then
    pass "Android release signing appears configured"
  elif [[ "$REQUIRE_RELEASE_SIGNING" -eq 1 || "$STRICT" -eq 1 ]]; then
    fail "Android release signing is not fully configured"
  else
    warn "Android release signing is not fully configured"
  fi
}

check_payment_runtime_flags() {
  local payment_channel
  local enable_store_billing
  local enable_wechat_pay
  local enable_alipay
  local mock_base_url
  local domestic_enabled=0

  payment_channel="$(value_for_key PAYMENT_CHANNEL)"
  enable_store_billing="$(value_for_key ENABLE_STORE_BILLING)"
  enable_wechat_pay="$(value_for_key ENABLE_WECHAT_PAY)"
  enable_alipay="$(value_for_key ENABLE_ALIPAY)"
  mock_base_url="$(value_for_key DOMESTIC_PAYMENT_MOCK_BASE_URL)"

  if [[ -n "$mock_base_url" ]]; then
    fail "DOMESTIC_PAYMENT_MOCK_BASE_URL must be empty for production"
  else
    pass "DOMESTIC_PAYMENT_MOCK_BASE_URL is not configured"
  fi

  case "$(lowercase "$payment_channel")" in
    selfhostedweb|self_hosted_web|directandroid|direct_android|desktopweb|desktop_web)
      domestic_enabled=1
      ;;
  esac

  if is_truthy "$enable_wechat_pay" || is_truthy "$enable_alipay"; then
    domestic_enabled=1
  fi

  if [[ "$domestic_enabled" -eq 1 ]]; then
    if [[ "$ALLOW_DOMESTIC_SHARED_TOKEN" -eq 1 ]]; then
      warn "domestic payment shared-token webhook auth allowed by explicit flag"
    else
      fail "domestic payment is enabled but production provider signature verification is not implemented"
    fi
  else
    pass "domestic payment providers are not enabled for production"
  fi

  if is_falsey "$enable_store_billing"; then
    warn_or_fail "ENABLE_STORE_BILLING is disabled"
  else
    pass "store billing is not explicitly disabled"
  fi
}

check_google_play_billing() {
  if [[ "$STORE_TARGET" != "android" && "$STORE_TARGET" != "all" ]]; then
    return 0
  fi

  warn_if_missing GOOGLE_SERVICE_ACCOUNT_EMAIL "Google service account email"
  warn_if_missing GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY "Google service account private key"
  warn_if_missing GOOGLE_PLAY_PACKAGE_NAME "Google Play package name"

  local package_name
  package_name="$(value_for_key GOOGLE_PLAY_PACKAGE_NAME)"
  if [[ -n "$package_name" ]]; then
    if [[ "$package_name" == *".dev"* || "$package_name" == *"debug"* || "$package_name" == "com.jivemoney.app.dev" ]]; then
      fail "GOOGLE_PLAY_PACKAGE_NAME points to a dev/debug package"
    else
      pass "Google Play package name is not the dev package"
    fi
  fi
}

check_apple_billing() {
  if [[ "$STORE_TARGET" != "ios" && "$STORE_TARGET" != "all" ]]; then
    return 0
  fi

  warn_if_missing APPLE_APP_STORE_BUNDLE_ID "Apple App Store bundle id"
  warn_if_missing APPLE_APP_STORE_SHARED_SECRET "Apple shared secret"
  warn_if_missing APPLE_APP_STORE_APPLE_ID "Apple app id"
  warn_if_missing APPLE_APP_STORE_ENVIRONMENT "Apple App Store environment"

  local environment
  environment="$(value_for_key APPLE_APP_STORE_ENVIRONMENT)"
  case "$(lowercase "$environment")" in
    production)
      pass "Apple App Store environment is production"
      ;;
    sandbox)
      fail "APPLE_APP_STORE_ENVIRONMENT is Sandbox"
      ;;
    "")
      ;;
    *)
      warn_or_fail "APPLE_APP_STORE_ENVIRONMENT is not explicitly production"
      ;;
  esac
}

check_billing_server_keys() {
  warn_if_missing PUBSUB_BEARER_TOKEN "Google RTDN Pub/Sub bearer token"
  warn_if_missing WEBHOOK_HMAC_SECRET "subscription webhook HMAC secret"
  warn_if_missing ADMIN_API_TOKEN "admin API token"
  warn_if_missing ANALYTICS_ADMIN_TOKEN "analytics admin token"
  warn_if_missing NOTIFICATION_ADMIN_TOKEN "notification admin token"
}

print_next_steps() {
  cat <<EOF
[saas-prod-readiness] next:
[saas-prod-readiness]   1. Replace AdMob test IDs before production release.
[saas-prod-readiness]   2. Use a production Supabase project and production anon key.
[saas-prod-readiness]   3. Keep domestic payment disabled until provider signature verification replaces shared-token staging auth.
[saas-prod-readiness]   4. Run this gate in strict mode before release:
[saas-prod-readiness]      scripts/check_saas_production_readiness.sh --profile full --store android --strict --require-release-signing --env-file $ENV_FILE
EOF
}

main() {
  parse_args "$@"

  log "repo root: $APP_DIR"
  log "profile=$PROFILE store=$STORE_TARGET strict=$STRICT env_file=$ENV_FILE"

  check_env_file

  if [[ "$PROFILE" == "app" || "$PROFILE" == "full" ]]; then
    check_supabase_client_config
    check_admob_ids
    check_payment_runtime_flags
    if [[ "$STORE_TARGET" == "android" || "$STORE_TARGET" == "all" ]]; then
      check_android_release_signing
    fi
  fi

  if [[ "$PROFILE" == "billing" || "$PROFILE" == "full" ]]; then
    check_admin_origins
    check_billing_server_keys
    check_google_play_billing
    check_apple_billing
  fi

  print_next_steps
  log "summary: failures=$FAILURES warnings=$WARNINGS profile=$PROFILE store=$STORE_TARGET strict=$STRICT"

  if [[ "$FAILURES" -gt 0 ]]; then
    exit 1
  fi
}

main "$@"
