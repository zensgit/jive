#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="$SCRIPT_DIR/report_saas_internal_test_release_artifact.sh"

usage() {
  cat <<'EOF'
Usage:
  scripts/test_saas_internal_test_release_artifact_report.sh [--keep-fixtures]

Runs host-only fixture tests for scripts/report_saas_internal_test_release_artifact.sh.
No real Play Console, GitHub Actions, Flutter build, Android SDK, or secret store is used.
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
      printf '[saas-internal-artifact-report-test] unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

ROOT="$(mktemp -d /tmp/jive-saas-internal-artifact-report-test.XXXXXX)"

cleanup() {
  if [[ "$KEEP_FIXTURES" -eq 1 ]]; then
    printf '[saas-internal-artifact-report-test] kept fixtures: %s\n' "$ROOT"
  else
    rm -rf "$ROOT"
  fi
}

trap cleanup EXIT INT TERM

log() {
  printf '[saas-internal-artifact-report-test] %s\n' "$*"
}

fail() {
  printf '[saas-internal-artifact-report-test] FAIL: %s\n' "$*" >&2
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
  local run_id="${2:-424242}"

  mkdir -p "$dir/reports/release-candidate" "$dir/release-candidate/20260512-prod"
  local aab="$dir/release-candidate/20260512-prod/app-prod-release.aab"
  printf 'fake-prod-aab-%s\n' "$run_id" > "$aab"

  local bytes
  local sha256
  bytes="$(wc -c < "$aab" | tr -d '[:space:]')"
  sha256="$(shasum -a 256 "$aab" | awk '{print $1}')"

  cat > "$dir/reports/release-candidate/release-candidate.json" <<JSON
{
  "generatedAt": "20260512-000000",
  "flavor": "prod",
  "buildName": "1.0.0",
  "buildNumber": "100",
  "signingMode": "release-configured",
  "signingPreflight": "release-configured (release signing ready)",
  "strictSigning": true,
  "productionReadinessGate": true,
  "dryRun": false,
  "dartDefinesConfigured": true,
  "status": "passed",
  "message": "Release candidate appbundle built and archived.",
  "artifactName": "app-prod-release.aab",
  "artifactBytes": $bytes,
  "sha256": "$sha256",
  "gitBranch": "main",
  "gitCommit": "abc123"
}
JSON

  cat > "$dir/saas-release-candidate-sequence-summary.md" <<EOF
# SaaS Release Candidate Sequence

- finalRunId: \`$run_id\`
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
create_good_artifact "$good_dir" 424242
run_case good \
  --artifact-dir "$good_dir" \
  --output "$ROOT/good.md" \
  --play-version "1.0.0+100"
assert_status good 0
assert_contains "$ROOT/good.md" "Status: \`ready-for-play-internal\`"
assert_contains "$ROOT/good.md" "Workflow run id: \`424242\`"
assert_contains "$ROOT/good.md" "AAB SHA-256:"
assert_contains "$ROOT/good.md" "status=passed"
assert_contains "$ROOT/good.md" "Google Play Internal Test Checklist"
log "good fixture ok: renders validated internal test report"

bad_sha_dir="$ROOT/bad-sha"
create_good_artifact "$bad_sha_dir" 777
python3 - "$bad_sha_dir/reports/release-candidate/release-candidate.json" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
payload = json.loads(path.read_text(encoding="utf-8"))
payload["sha256"] = "0" * 64
path.write_text(json.dumps(payload, indent=2), encoding="utf-8")
PY
run_case bad-sha --artifact-dir "$bad_sha_dir" --output "$ROOT/bad-sha.md"
assert_status bad-sha 1
assert_contains "$ROOT/bad-sha/stderr.txt" "sha256 expected"
log "bad-sha fixture ok: rejects mismatched digest"

leaky_dir="$ROOT/leaky"
create_good_artifact "$leaky_dir" 888
printf 'do-not-ship\n' > "$leaky_dir/production.env"
run_case leaky --artifact-dir "$leaky_dir" --output "$ROOT/leaky.md"
assert_status leaky 1
assert_contains "$ROOT/leaky/stderr.txt" "forbidden secret-like file names"
log "leaky fixture ok: rejects secret-like artifact filenames"

missing_dir="$ROOT/missing-report"
mkdir -p "$missing_dir"
run_case missing-report --artifact-dir "$missing_dir" --output "$ROOT/missing.md"
assert_status missing-report 1
assert_contains "$ROOT/missing-report/stderr.txt" "release-candidate.json not found"
log "missing-report fixture ok: requires release candidate JSON"

printf '[saas-internal-artifact-report-test] all checks passed\n'
