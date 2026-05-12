#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="$SCRIPT_DIR/run_saas_release_candidate_sequence.sh"

usage() {
  cat <<'EOF'
Usage:
  scripts/test_saas_release_candidate_sequence_runner.sh [--keep-fixtures]

Runs host-only fixture tests for scripts/run_saas_release_candidate_sequence.sh.
No real GitHub Actions workflow, secret store, Flutter build, Android signing,
artifact download, or network access is used.
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
      printf '[saas-release-sequence-test] unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

ROOT="$(mktemp -d /tmp/jive-saas-release-sequence-test.XXXXXX)"

cleanup() {
  if [[ "$KEEP_FIXTURES" -eq 1 ]]; then
    printf '[saas-release-sequence-test] kept fixtures: %s\n' "$ROOT"
  else
    rm -rf "$ROOT"
  fi
}

trap cleanup EXIT INT TERM

log() {
  printf '[saas-release-sequence-test] %s\n' "$*"
}

fail() {
  printf '[saas-release-sequence-test] FAIL: %s\n' "$*" >&2
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
  if grep -Fq -- "$unexpected" "$file"; then
    fail "did not expect '$unexpected' in $file"
  fi
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
    printf '%s\n' '--- calls ---' >&2
    cat "$ROOT/$label/calls.log" >&2 || true
    fail "$label expected exit $expected, got $actual"
  fi
}

create_fake_gh() {
  local dir="$1"
  local fake="$dir/fake-gh"

  cat > "$fake" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

state_dir="${JIVE_FAKE_GH_STATE_DIR:?JIVE_FAKE_GH_STATE_DIR is required}"
calls="$state_dir/calls.log"
counter="$state_dir/counter"
mkdir -p "$state_dir"
touch "$calls"
[[ -f "$counter" ]] || printf '1000\n' > "$counter"

log_call() {
  printf '%s\n' "$*" >> "$calls"
}

next_id() {
  local id
  id="$(cat "$counter")"
  id=$((id + 1))
  printf '%s\n' "$id" > "$counter"
  printf '%s\n' "$id"
}

emit_runs() {
  python3 - "$state_dir" <<'PY'
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
runs = []
for path in root.glob("run-*.json"):
    runs.append(json.loads(path.read_text(encoding="utf-8")))
runs.sort(key=lambda item: int(item["databaseId"]), reverse=True)
print(json.dumps(runs))
PY
}

case "${1:-}" in
  repo)
    if [[ "${2:-}" == "view" ]]; then
      log_call "repo view"
      printf 'zensgit/jive\n'
      exit 0
    fi
    ;;
  workflow)
    if [[ "${2:-}" == "run" ]]; then
      workflow="${3:-}"
      shift 3
      build_appbundle=""
      strict_signing=""
      while (($#)); do
        case "$1" in
          -f)
            value="${2:-}"
            case "$value" in
              build_appbundle=*) build_appbundle="${value#build_appbundle=}" ;;
              strict_signing=*) strict_signing="${value#strict_signing=}" ;;
            esac
            shift 2
            ;;
          *)
            shift
            ;;
        esac
      done

      id="$(next_id)"
      log_call "workflow run id=$id workflow=$workflow build_appbundle=$build_appbundle strict_signing=$strict_signing"
      cat > "$state_dir/run-$id.json" <<JSON
{"databaseId":$id,"status":"completed","conclusion":"success","url":"https://example.invalid/actions/runs/$id","createdAt":"2026-05-12T00:00:00Z","headSha":"fake-$id"}
JSON
      exit 0
    fi
    ;;
  run)
    case "${2:-}" in
      list)
        log_call "run list"
        emit_runs
        exit 0
        ;;
      view)
        id="${3:-}"
        log_call "run view id=$id"
        cat "$state_dir/run-$id.json"
        exit 0
        ;;
      download)
        id="${3:-}"
        shift 3
        dir=""
        while (($#)); do
          case "$1" in
            --dir)
              dir="${2:-}"
              shift 2
              ;;
            *)
              shift
              ;;
          esac
        done
        [[ -n "$dir" ]] || {
          printf 'missing --dir\n' >&2
          exit 2
        }

        log_call "run download id=$id dir=$dir"
        mkdir -p "$dir/reports/release-candidate" "$dir/release-candidate/20260512-prod"
        aab="$dir/release-candidate/20260512-prod/app-prod-release.aab"
        printf 'fake-aab-%s\n' "$id" > "$aab"
        bytes="$(wc -c < "$aab" | tr -d '[:space:]')"
        sha256="$(shasum -a 256 "$aab" | awk '{print $1}')"
        cat > "$dir/reports/release-candidate/release-candidate.json" <<JSON
{
  "generatedAt": "20260512-000000",
  "flavor": "prod",
  "buildName": "1.0.0",
  "buildNumber": "1",
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
  "gitCommit": "fake-$id"
}
JSON
        printf '# Release Candidate\n' > "$dir/reports/release-candidate/latest.md"
        exit 0
        ;;
    esac
    ;;
esac

printf 'fake gh unknown command: %s\n' "$*" >&2
exit 2
EOF

  chmod +x "$fake"
  printf '%s\n' "$fake"
}

create_fake_secret_check() {
  local dir="$1"
  local mode="$2"
  local fake="$dir/fake-secret-check"

  cat > "$fake" <<EOF
#!/usr/bin/env bash
set -euo pipefail
printf '[fake-secret-check] %s\\n' "\$*" >> "$dir/calls.log"
if [[ "$mode" == "pass" ]]; then
  exit 0
fi
printf '[fake-secret-check] missing production secrets\\n' >&2
exit 1
EOF

  chmod +x "$fake"
  printf '%s\n' "$fake"
}

run_case() {
  local label="$1"
  local secret_mode="$2"
  shift 2

  local fixture="$ROOT/$label"
  local fake_gh
  local fake_secret_check

  mkdir -p "$fixture"
  fake_gh="$(create_fake_gh "$fixture")"
  fake_secret_check="$(create_fake_secret_check "$fixture" "$secret_mode")"

  set +e
  env \
    JIVE_GH_BIN="$fake_gh" \
    JIVE_FAKE_GH_STATE_DIR="$fixture" \
    JIVE_SAAS_GITHUB_SECRETS_CHECK_SCRIPT="$fake_secret_check" \
    JIVE_SAAS_RELEASE_POLL_INTERVAL_SECONDS=0 \
    JIVE_SAAS_RELEASE_TIMEOUT_SECONDS=5 \
    "$TARGET" \
      --repo zensgit/jive \
      --artifact-dir "$fixture/artifacts" \
      "$@" \
      > "$fixture/stdout.txt" \
      2> "$fixture/stderr.txt"
  local status=$?
  set -e

  printf '%s\n' "$status" > "$fixture/status.txt"
}

run_case success pass
assert_status success 0
assert_contains "$ROOT/success/calls.log" "[fake-secret-check] --profile production-release --include-signing --repo zensgit/jive"
assert_contains "$ROOT/success/calls.log" "workflow run id=1001 workflow=SaaS Release Candidate build_appbundle=false strict_signing=false"
assert_contains "$ROOT/success/calls.log" "workflow run id=1002 workflow=SaaS Release Candidate build_appbundle=false strict_signing=true"
assert_contains "$ROOT/success/calls.log" "workflow run id=1003 workflow=SaaS Release Candidate build_appbundle=true strict_signing=true"
assert_contains "$ROOT/success/calls.log" "run download id=1003"
assert_contains "$ROOT/success/artifacts/saas-release-candidate-sequence-summary.md" "finalRunId: \`1003\`"
assert_contains "$ROOT/success/artifacts/saas-release-candidate-sequence-summary.md" "sha256:"
log "success fixture ok: dispatches three runs and validates final artifact"

run_case missing-secrets fail
assert_status missing-secrets 1
assert_contains "$ROOT/missing-secrets/stderr.txt" "[fake-secret-check] missing production secrets"
assert_not_contains "$ROOT/missing-secrets/calls.log" "workflow run"
log "missing-secrets fixture ok: blocks before dispatch"

printf '[saas-release-sequence-test] all checks passed\n'
