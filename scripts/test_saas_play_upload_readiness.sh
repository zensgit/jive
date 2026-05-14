#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="$SCRIPT_DIR/check_saas_play_upload_readiness.sh"

usage() {
  cat <<'EOF'
Usage:
  scripts/test_saas_play_upload_readiness.sh [--keep-fixtures]

Runs host-only fixture tests for scripts/check_saas_play_upload_readiness.sh.
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
      printf '[saas-play-upload-readiness-test] unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

ROOT="$(mktemp -d /tmp/jive-saas-play-upload-readiness-test.XXXXXX)"

cleanup() {
  if [[ "$KEEP_FIXTURES" -eq 1 ]]; then
    printf '[saas-play-upload-readiness-test] kept fixtures: %s\n' "$ROOT"
  else
    rm -rf "$ROOT"
  fi
}

trap cleanup EXIT INT TERM

log() {
  printf '[saas-play-upload-readiness-test] %s\n' "$*"
}

fail() {
  printf '[saas-play-upload-readiness-test] FAIL: %s\n' "$*" >&2
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

  mkdir -p "$dir/reports/release-candidate" "$dir/release-candidate/20260514-prod"
  local aab="$dir/release-candidate/20260514-prod/app-prod-release.aab"
  printf 'fake-play-upload-readiness-aab\n' > "$aab"

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

create_manifest_dump() {
  local file="$1"
  local package_name="${2:-com.jivemoney.app}"

  cat > "$file" <<EOF
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="$package_name"
    android:versionCode="100"
    android:versionName="1.0.0-20260514">
</manifest>
EOF
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
run_case good \
  --artifact-dir "$good_dir"
assert_status good 0
assert_contains "$ROOT/good/stdout.txt" "passed"
assert_contains "$ROOT/good/stdout.txt" "package=com.jivemoney.app"
assert_contains "$ROOT/good/stdout.txt" "track=internal"
assert_contains "$ROOT/good/stdout.txt" "releaseStatus=draft"
log "good fixture ok: production AAB artifact is accepted without a service account in dry-run"

service_account="$ROOT/google-play-service-account.json"
printf '{"type":"service_account"}\n' > "$service_account"
with_secret_dir="$ROOT/with-secret-artifact"
create_good_artifact "$with_secret_dir"
run_case with-secret \
  --artifact-dir "$with_secret_dir" \
  --service-account-json "$service_account" \
  --require-service-account \
  --release-status completed
assert_status with-secret 0
assert_contains "$ROOT/with-secret/stdout.txt" "releaseStatus=completed"
log "with-secret fixture ok: apply-mode service account presence is checked without reading it"

missing_secret_dir="$ROOT/missing-secret-artifact"
create_good_artifact "$missing_secret_dir"
run_case missing-secret \
  --artifact-dir "$missing_secret_dir" \
  --require-service-account
assert_status missing-secret 1
assert_contains "$ROOT/missing-secret/stderr.txt" "--service-account-json is required"
log "missing-secret fixture ok: apply-mode blocks missing service account"

bad_track_dir="$ROOT/bad-track-artifact"
create_good_artifact "$bad_track_dir"
run_case bad-track \
  --artifact-dir "$bad_track_dir" \
  --track production
assert_status bad-track 1
assert_contains "$ROOT/bad-track/stderr.txt" "Play upload track must be 'internal'"
log "bad-track fixture ok: blocks non-internal track"

bad_package_dir="$ROOT/bad-package-artifact"
create_good_artifact "$bad_package_dir"
run_case bad-package \
  --artifact-dir "$bad_package_dir" \
  --package-name com.jivemoney.app.dev
assert_status bad-package 1
assert_contains "$ROOT/bad-package/stderr.txt" "package name expected"
log "bad-package fixture ok: blocks dev package ids"

bad_sha_dir="$ROOT/bad-sha-artifact"
create_good_artifact "$bad_sha_dir"
python3 - "$bad_sha_dir/reports/release-candidate/release-candidate.json" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
payload = json.loads(path.read_text(encoding="utf-8"))
payload["sha256"] = "0" * 64
path.write_text(json.dumps(payload, indent=2), encoding="utf-8")
PY
run_case bad-sha --artifact-dir "$bad_sha_dir"
assert_status bad-sha 1
assert_contains "$ROOT/bad-sha/stderr.txt" "sha256 expected"
log "bad-sha fixture ok: rejects mismatched AAB digest"

manifest_dir="$ROOT/manifest-artifact"
create_good_artifact "$manifest_dir"
manifest_file="$ROOT/manifest.xml"
create_manifest_dump "$manifest_file"
run_case manifest \
  --artifact-dir "$manifest_dir" \
  --manifest-dump "$manifest_file" \
  --require-manifest-check
assert_status manifest 0
assert_contains "$ROOT/manifest/stdout.txt" "manifest=passed"
assert_contains "$ROOT/manifest/stdout.txt" "manifestPackage=com.jivemoney.app"
log "manifest fixture ok: validates package from manifest dump"

bad_manifest_dir="$ROOT/bad-manifest-artifact"
create_good_artifact "$bad_manifest_dir"
bad_manifest_file="$ROOT/bad-manifest.xml"
create_manifest_dump "$bad_manifest_file" "com.example.bad"
run_case bad-manifest \
  --artifact-dir "$bad_manifest_dir" \
  --manifest-dump "$bad_manifest_file" \
  --require-manifest-check
assert_status bad-manifest 1
assert_contains "$ROOT/bad-manifest/stderr.txt" "manifest package expected"
log "bad-manifest fixture ok: rejects wrong manifest package"

leaky_dir="$ROOT/leaky-artifact"
create_good_artifact "$leaky_dir"
printf 'do-not-ship\n' > "$leaky_dir/service-account-secret.json"
run_case leaky --artifact-dir "$leaky_dir"
assert_status leaky 1
assert_contains "$ROOT/leaky/stderr.txt" "forbidden secret-like file names"
log "leaky fixture ok: blocks secret-like files inside artifact"

printf '[saas-play-upload-readiness-test] all checks passed\n'
