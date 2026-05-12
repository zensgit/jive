#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="$SCRIPT_DIR/render_saas_play_internal_upload_handoff.sh"

usage() {
  cat <<'EOF'
Usage:
  scripts/test_saas_play_internal_upload_handoff.sh [--keep-fixtures]

Runs host-only fixture tests for scripts/render_saas_play_internal_upload_handoff.sh.
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
      printf '[saas-play-upload-handoff-test] unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

ROOT="$(mktemp -d /tmp/jive-saas-play-upload-handoff-test.XXXXXX)"

cleanup() {
  if [[ "$KEEP_FIXTURES" -eq 1 ]]; then
    printf '[saas-play-upload-handoff-test] kept fixtures: %s\n' "$ROOT"
  else
    rm -rf "$ROOT"
  fi
}

trap cleanup EXIT INT TERM

log() {
  printf '[saas-play-upload-handoff-test] %s\n' "$*"
}

fail() {
  printf '[saas-play-upload-handoff-test] FAIL: %s\n' "$*" >&2
  exit 1
}

assert_contains() {
  local file="$1"
  local expected="$2"
  grep -Fq -- "$expected" "$file" || fail "expected '$expected' in $file"
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

  mkdir -p "$dir/reports/release-candidate" "$dir/release-candidate/20260513-prod"
  local aab="$dir/release-candidate/20260513-prod/app-prod-release.aab"
  printf 'fake-play-upload-aab\n' > "$aab"

  local bytes
  local sha256
  bytes="$(wc -c < "$aab" | tr -d '[:space:]')"
  sha256="$(shasum -a 256 "$aab" | awk '{print $1}')"

  cat > "$dir/reports/release-candidate/release-candidate.json" <<JSON
{
  "generatedAt": "20260513-000000",
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

good_dir="$ROOT/good-artifact"
create_good_artifact "$good_dir"
completion_report="$ROOT/completion.md"
printf '# completion\n' > "$completion_report"
run_case good \
  --artifact-dir "$good_dir" \
  --completion-report "$completion_report" \
  --output "$ROOT/good.md" \
  --service-account-json "/secure/google-play-service-account.json" \
  --release-status completed \
  --play-version "1.0.0+100" \
  --play-release-id "release-123" \
  --tester-link "https://play.google.com/apps/internaltest/example" \
  --rollout-status "internal-available"
assert_status good 0
assert_contains "$ROOT/good.md" "Package name: \`com.jivemoney.app\`"
assert_contains "$ROOT/good.md" "Play track: \`internal\`"
assert_contains "$ROOT/good.md" "Release status: \`completed\`"
assert_contains "$ROOT/good.md" "AAB SHA-256:"
assert_contains "$ROOT/good.md" "fastlane \\"
assert_contains "$ROOT/good.md" "--json_key \\"
assert_contains "$ROOT/good.md" "/secure/google-play-service-account.json"
assert_contains "$ROOT/good.md" "--package_name \\"
assert_contains "$ROOT/good.md" "com.jivemoney.app"
assert_contains "$ROOT/good.md" "Play release id: \`release-123\`"
assert_contains "$ROOT/good.md" "Tester link: \`https://play.google.com/apps/internaltest/example\`"
assert_contains "$ROOT/good.md" "Rollout status: \`internal-available\`"
log "good fixture ok: renders upload handoff and post-upload fields"

placeholder_dir="$ROOT/placeholder-artifact"
create_good_artifact "$placeholder_dir"
run_case placeholder \
  --artifact-dir "$placeholder_dir" \
  --output "$ROOT/placeholder.md"
assert_status placeholder 0
assert_contains "$ROOT/placeholder.md" "\$GOOGLE_PLAY_SERVICE_ACCOUNT_JSON_PATH"
assert_contains "$ROOT/placeholder.md" "Release status: \`draft\`"
log "placeholder fixture ok: avoids requiring local service account path"

bad_status_dir="$ROOT/bad-status-artifact"
create_good_artifact "$bad_status_dir" "failed"
run_case bad-status \
  --artifact-dir "$bad_status_dir" \
  --output "$ROOT/bad-status.md"
assert_status bad-status 1
assert_contains "$ROOT/bad-status/stderr.txt" "status expected 'passed'"
log "bad-status fixture ok: rejects non-passed release candidate"

missing_report_dir="$ROOT/missing-completion-artifact"
create_good_artifact "$missing_report_dir"
run_case missing-completion \
  --artifact-dir "$missing_report_dir" \
  --completion-report "$ROOT/missing.md" \
  --output "$ROOT/missing-completion.md"
assert_status missing-completion 1
assert_contains "$ROOT/missing-completion/stderr.txt" "completion report not found"
log "missing-completion fixture ok: rejects missing referenced completion report"

printf '[saas-play-upload-handoff-test] all checks passed\n'
