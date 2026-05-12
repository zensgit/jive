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

create_manifest_dump() {
  local file="$1"
  local package_name="${2:-com.jivemoney.app}"

  cat > "$file" <<EOF
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="$package_name"
    android:versionCode="100"
    android:versionName="1.0.0-20260512">
</manifest>
EOF
}

create_fake_bundletool() {
  local file="$1"
  local manifest_file="$2"

  cat > "$file" <<EOF
#!/usr/bin/env bash
set -euo pipefail
if [[ "\${1:-}" != "dump" || "\${2:-}" != "manifest" || "\${3:-}" != --bundle=* ]]; then
  printf 'unexpected bundletool args: %s\\n' "\$*" >&2
  exit 2
fi
cat "$manifest_file"
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
assert_contains "$ROOT/good.md" "Manifest check: \`skipped\`"
assert_contains "$ROOT/good.md" "status=passed"
assert_contains "$ROOT/good.md" "Google Play Internal Test Checklist"
log "good fixture ok: renders validated internal test report"

manifest_dir="$ROOT/manifest-artifact"
create_good_artifact "$manifest_dir" 515151
manifest_file="$ROOT/manifest.xml"
fake_bundletool="$ROOT/fake-bundletool"
create_manifest_dump "$manifest_file"
create_fake_bundletool "$fake_bundletool" "$manifest_file"
run_case manifest \
  --artifact-dir "$manifest_dir" \
  --output "$ROOT/manifest.md" \
  --bundletool "$fake_bundletool" \
  --require-manifest-check
assert_status manifest 0
assert_contains "$ROOT/manifest.md" "Manifest check: \`passed\`"
assert_contains "$ROOT/manifest.md" "Manifest package: \`com.jivemoney.app\`"
assert_contains "$ROOT/manifest.md" "Manifest version name: \`1.0.0-20260512\`"
assert_contains "$ROOT/manifest.md" "Manifest version code: \`100\`"
assert_contains "$ROOT/manifest.md" "Android manifest package matches \`com.jivemoney.app\`."
log "manifest fixture ok: validates package and records manifest version details"

bad_manifest_dir="$ROOT/bad-manifest-artifact"
create_good_artifact "$bad_manifest_dir" 616161
bad_manifest_file="$ROOT/bad-manifest.xml"
create_manifest_dump "$bad_manifest_file" "com.example.bad"
run_case bad-manifest \
  --artifact-dir "$bad_manifest_dir" \
  --output "$ROOT/bad-manifest.md" \
  --manifest-dump "$bad_manifest_file" \
  --require-manifest-check
assert_status bad-manifest 1
assert_contains "$ROOT/bad-manifest/stderr.txt" "manifest package expected"
log "bad-manifest fixture ok: rejects unexpected package"

missing_bundletool_dir="$ROOT/missing-bundletool-artifact"
create_good_artifact "$missing_bundletool_dir" 717171
run_case missing-bundletool \
  --artifact-dir "$missing_bundletool_dir" \
  --output "$ROOT/missing-bundletool.md" \
  --bundletool "$ROOT/not-a-bundletool" \
  --require-manifest-check
assert_status missing-bundletool 1
assert_contains "$ROOT/missing-bundletool/stderr.txt" "bundletool not found"
log "missing-bundletool fixture ok: require-manifest-check blocks if bundletool is unavailable"

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
