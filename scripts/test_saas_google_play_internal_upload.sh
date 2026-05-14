#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="$SCRIPT_DIR/upload_saas_google_play_internal_test.sh"

usage() {
  cat <<'EOF'
Usage:
  scripts/test_saas_google_play_internal_upload.sh [--keep-fixtures]

Runs host-only fixture tests for scripts/upload_saas_google_play_internal_test.sh.
No real Google Play service account, Play Console upload, Android SDK, or network access is used.
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
      printf '[saas-google-play-upload-test] unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

ROOT="$(mktemp -d /tmp/jive-saas-google-play-upload-test.XXXXXX)"

cleanup() {
  if [[ "$KEEP_FIXTURES" -eq 1 ]]; then
    printf '[saas-google-play-upload-test] kept fixtures: %s\n' "$ROOT"
  else
    rm -rf "$ROOT"
  fi
}

trap cleanup EXIT INT TERM

log() {
  printf '[saas-google-play-upload-test] %s\n' "$*"
}

fail() {
  printf '[saas-google-play-upload-test] FAIL: %s\n' "$*" >&2
  exit 1
}

assert_contains() {
  local file="$1"
  local expected="$2"
  grep -Fq -- "$expected" "$file" || fail "expected '$expected' in $file"
}

assert_not_exists() {
  local file="$1"
  [[ ! -e "$file" ]] || fail "expected $file to be absent"
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
    fail "$label expected exit $expected, got $actual"
  fi
}

create_good_artifact() {
  local dir="$1"
  local status="${2:-passed}"

  mkdir -p "$dir/reports/release-candidate" "$dir/release-candidate/20260514-prod"
  local aab="$dir/release-candidate/20260514-prod/app-prod-release.aab"
  printf 'fake-google-play-upload-aab\n' > "$aab"

  local bytes
  local sha256
  bytes="$(wc -c < "$aab" | tr -d '[:space:]')"
  sha256="$(shasum -a 256 "$aab" | awk '{print $1}')"

  cat > "$dir/reports/release-candidate/release-candidate.json" <<JSON
{
  "generatedAt": "20260514-000000",
  "flavor": "prod",
  "buildName": "1.0.0",
  "buildNumber": "100",
  "signingMode": "release-configured",
  "signingPreflight": "release-configured (release signing ready)",
  "strictSigning": true,
  "productionReadinessGate": true,
  "dryRun": false,
  "dartDefinesConfigured": true,
  "status": "$status",
  "message": "Release candidate appbundle built and archived.",
  "artifactName": "app-prod-release.aab",
  "artifactBytes": $bytes,
  "sha256": "$sha256",
  "gitBranch": "main",
  "gitCommit": "abc123"
}
JSON
}

create_fake_supply() {
  local file="$1"
  local log_file="$2"

  cat > "$file" <<EOF
#!/usr/bin/env bash
set -euo pipefail
printf '%s\\n' "\$*" > "$log_file"
EOF
  chmod +x "$file"
}

run_case() {
  local label="$1"
  shift
  local fixture="$ROOT/$label"
  mkdir -p "$fixture"

  set +e
  "$TARGET" "$@" > "$fixture/stdout.txt" 2> "$fixture/stderr.txt"
  local status=$?
  set -e

  printf '%s\n' "$status" > "$fixture/status.txt"
}

dry_run_dir="$ROOT/dry-run-artifact"
create_good_artifact "$dry_run_dir"
fake_supply_log="$ROOT/fake-supply.log"
fake_supply="$ROOT/fake-fastlane"
create_fake_supply "$fake_supply" "$fake_supply_log"
run_case dry-run \
  --artifact-dir "$dry_run_dir" \
  --supply-bin "$fake_supply" \
  --output "$ROOT/dry-run-handoff.md"
assert_status dry-run 0
assert_contains "$ROOT/dry-run/stdout.txt" "dry-run only"
assert_contains "$ROOT/dry-run/stdout.txt" "command shape"
assert_contains "$ROOT/dry-run-handoff.md" "SaaS Play Internal Test Upload Handoff"
assert_contains "$ROOT/dry-run-handoff.md" "\$GOOGLE_PLAY_SERVICE_ACCOUNT_JSON_PATH"
assert_not_exists "$fake_supply_log"
log "dry-run fixture ok: validates artifact and renders handoff without upload"

apply_dir="$ROOT/apply-artifact"
create_good_artifact "$apply_dir"
service_account="$ROOT/google-play-service-account.json"
printf '{"type":"service_account"}\n' > "$service_account"
apply_supply_log="$ROOT/apply-supply.log"
apply_supply="$ROOT/apply-fastlane"
create_fake_supply "$apply_supply" "$apply_supply_log"
run_case apply \
  --artifact-dir "$apply_dir" \
  --supply-bin "$apply_supply" \
  --service-account-json "$service_account" \
  --release-status completed \
  --output "$ROOT/apply-handoff.md" \
  --apply
assert_status apply 0
apply_aab="$(cd "$apply_dir/release-candidate/20260514-prod" && pwd -P)/app-prod-release.aab"
assert_contains "$apply_supply_log" "supply --json_key $service_account --package_name com.jivemoney.app --track internal"
assert_contains "$apply_supply_log" "--aab $apply_aab"
assert_contains "$apply_supply_log" "--release_status completed"
assert_contains "$ROOT/apply-handoff.md" "Release status: \`completed\`"
assert_contains "$ROOT/apply-handoff.md" "$service_account"
log "apply fixture ok: fake fastlane receives expected supply arguments"

missing_secret_dir="$ROOT/missing-secret-artifact"
create_good_artifact "$missing_secret_dir"
missing_supply_log="$ROOT/missing-supply.log"
missing_supply="$ROOT/missing-fastlane"
create_fake_supply "$missing_supply" "$missing_supply_log"
run_case missing-secret \
  --artifact-dir "$missing_secret_dir" \
  --supply-bin "$missing_supply" \
  --apply
assert_status missing-secret 1
assert_contains "$ROOT/missing-secret/stderr.txt" "--service-account-json is required"
assert_not_exists "$missing_supply_log"
log "missing-secret fixture ok: apply blocks before upload when service account is missing"

bad_status_dir="$ROOT/bad-status-artifact"
create_good_artifact "$bad_status_dir" "failed"
bad_supply_log="$ROOT/bad-supply.log"
bad_supply="$ROOT/bad-fastlane"
create_fake_supply "$bad_supply" "$bad_supply_log"
run_case bad-status \
  --artifact-dir "$bad_status_dir" \
  --supply-bin "$bad_supply" \
  --output "$ROOT/bad-status-handoff.md"
assert_status bad-status 1
assert_contains "$ROOT/bad-status/stderr.txt" "status expected 'passed'"
assert_not_exists "$bad_supply_log"
log "bad-status fixture ok: readiness failure prevents upload"

printf '[saas-google-play-upload-test] all checks passed\n'
