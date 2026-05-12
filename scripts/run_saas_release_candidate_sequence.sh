#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

REPO="${GITHUB_REPOSITORY:-}"
REF="${JIVE_SAAS_RELEASE_REF:-main}"
WORKFLOW="${JIVE_SAAS_RELEASE_WORKFLOW:-SaaS Release Candidate}"
GH_BIN="${JIVE_GH_BIN:-gh}"
SECRET_CHECK_SCRIPT="${JIVE_SAAS_GITHUB_SECRETS_CHECK_SCRIPT:-$APP_DIR/scripts/check_saas_github_secrets.sh}"
ARTIFACT_DIR="${JIVE_SAAS_RELEASE_ARTIFACT_DIR:-$APP_DIR/build/reports/saas-release-candidate-sequence}"
BUILD_NAME="${JIVE_SAAS_RELEASE_BUILD_NAME:-}"
BUILD_NUMBER="${JIVE_SAAS_RELEASE_BUILD_NUMBER:-}"
POLL_INTERVAL_SECONDS="${JIVE_SAAS_RELEASE_POLL_INTERVAL_SECONDS:-10}"
TIMEOUT_SECONDS="${JIVE_SAAS_RELEASE_TIMEOUT_SECONDS:-2700}"
CHECK_SECRETS=1
DOWNLOAD_ARTIFACT=1

RUN_LABELS=()
RUN_IDS=()

usage() {
  cat <<'EOF'
Usage:
  scripts/run_saas_release_candidate_sequence.sh [options]

Options:
  --repo <owner/repo>       GitHub repository. Defaults to GITHUB_REPOSITORY or gh repo view.
  --ref <git-ref>           Workflow ref. Defaults to main.
  --workflow <name>         Workflow name. Defaults to "SaaS Release Candidate".
  --artifact-dir <path>     Directory for downloaded final artifacts and sequence summary.
  --build-name <version>    Optional Flutter build-name override for all three runs.
  --build-number <number>   Optional Flutter build-number override for all three runs.
  --timeout-seconds <n>     Per-run timeout. Defaults to 2700.
  --poll-interval <n>       Poll interval in seconds. Defaults to 10.
  --skip-secret-check       Do not preflight GitHub Actions production-release secrets.
  --no-download             Do not download or validate the final AAB artifact.
  --help                    Show this help.

Sequence:
  1. build_appbundle=false, strict_signing=false
  2. build_appbundle=false, strict_signing=true
  3. build_appbundle=true, strict_signing=true

The script never reads or prints secret values. It checks only whether the
required GitHub Actions secret names exist before dispatching workflows.
EOF
}

log() {
  printf '[saas-release-sequence] %s\n' "$*" >&2
}

die() {
  printf '[saas-release-sequence] ERROR: %s\n' "$*" >&2
  exit 1
}

parse_args() {
  while (($#)); do
    case "$1" in
      --repo)
        REPO="${2:-}"
        shift 2
        ;;
      --ref)
        REF="${2:-}"
        shift 2
        ;;
      --workflow)
        WORKFLOW="${2:-}"
        shift 2
        ;;
      --artifact-dir)
        ARTIFACT_DIR="${2:-}"
        shift 2
        ;;
      --build-name)
        BUILD_NAME="${2:-}"
        shift 2
        ;;
      --build-number)
        BUILD_NUMBER="${2:-}"
        shift 2
        ;;
      --timeout-seconds)
        TIMEOUT_SECONDS="${2:-}"
        shift 2
        ;;
      --poll-interval)
        POLL_INTERVAL_SECONDS="${2:-}"
        shift 2
        ;;
      --skip-secret-check)
        CHECK_SECRETS=0
        shift
        ;;
      --no-download)
        DOWNLOAD_ARTIFACT=0
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
}

resolve_repo() {
  if [[ -n "$REPO" ]]; then
    printf '%s\n' "$REPO"
    return 0
  fi

  "$GH_BIN" repo view --json nameWithOwner --jq .nameWithOwner
}

run_secret_check() {
  [[ -f "$SECRET_CHECK_SCRIPT" ]] || die "secret check script not found: $SECRET_CHECK_SCRIPT"

  log "checking production-release GitHub Actions secrets"
  "$SECRET_CHECK_SCRIPT" --profile production-release --include-signing --repo "$REPO"
}

list_runs_json() {
  "$GH_BIN" run list \
    --repo "$REPO" \
    --workflow "$WORKFLOW" \
    --branch "$REF" \
    --event workflow_dispatch \
    --limit 30 \
    --json databaseId,status,conclusion,url,createdAt,headSha
}

write_run_ids() {
  local json_file="$1"
  local output_file="$2"

  python3 - "$json_file" "$output_file" <<'PY'
import json
import sys
from pathlib import Path

runs = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8") or "[]")
Path(sys.argv[2]).write_text(
    "".join(f"{run.get('databaseId')}\n" for run in runs if run.get("databaseId") is not None),
    encoding="utf-8",
)
PY
}

find_new_run_id() {
  local before_ids_file="$1"
  local runs_json_file="$2"

  python3 - "$before_ids_file" "$runs_json_file" <<'PY'
import json
import sys
from pathlib import Path

before = {
    line.strip()
    for line in Path(sys.argv[1]).read_text(encoding="utf-8").splitlines()
    if line.strip()
}
runs = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8") or "[]")
for run in runs:
    run_id = str(run.get("databaseId", ""))
    if run_id and run_id not in before:
        print(run_id)
        break
PY
}

json_value() {
  local json_file="$1"
  local key="$2"

  python3 - "$json_file" "$key" <<'PY'
import json
import sys
from pathlib import Path

payload = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8") or "{}")
value = payload.get(sys.argv[2], "")
print("" if value is None else value)
PY
}

dispatch_workflow() {
  local label="$1"
  local build_appbundle="$2"
  local strict_signing="$3"
  local before_json
  local before_ids
  local after_json
  local run_id=""
  local deadline
  local args

  before_json="$(mktemp)"
  before_ids="$(mktemp)"
  after_json="$(mktemp)"
  list_runs_json > "$before_json"
  write_run_ids "$before_json" "$before_ids"

  args=(
    workflow run "$WORKFLOW"
    --repo "$REPO"
    --ref "$REF"
    -f flavor=prod
    -f build_appbundle="$build_appbundle"
    -f strict_signing="$strict_signing"
  )
  if [[ -n "$BUILD_NAME" ]]; then
    args+=(-f build_name="$BUILD_NAME")
  fi
  if [[ -n "$BUILD_NUMBER" ]]; then
    args+=(-f build_number="$BUILD_NUMBER")
  fi

  log "dispatching $label"
  "$GH_BIN" "${args[@]}"

  deadline=$((SECONDS + TIMEOUT_SECONDS))
  while ((SECONDS < deadline)); do
    list_runs_json > "$after_json"
    run_id="$(find_new_run_id "$before_ids" "$after_json")"
    if [[ -n "$run_id" ]]; then
      rm -f "$before_json" "$before_ids" "$after_json"
      printf '%s\n' "$run_id"
      return 0
    fi
    sleep "$POLL_INTERVAL_SECONDS"
  done

  rm -f "$before_json" "$before_ids" "$after_json"
  die "timed out waiting for GitHub Actions run to appear for $label"
}

wait_for_run_success() {
  local label="$1"
  local run_id="$2"
  local view_json
  local status
  local conclusion
  local url
  local deadline

  view_json="$(mktemp)"
  deadline=$((SECONDS + TIMEOUT_SECONDS))

  while ((SECONDS < deadline)); do
    "$GH_BIN" run view "$run_id" --repo "$REPO" --json status,conclusion,url > "$view_json"
    status="$(json_value "$view_json" status)"
    conclusion="$(json_value "$view_json" conclusion)"
    url="$(json_value "$view_json" url)"

    log "$label run=$run_id status=$status conclusion=${conclusion:-pending}"
    if [[ "$status" == "completed" ]]; then
      rm -f "$view_json"
      if [[ "$conclusion" == "success" ]]; then
        log "$label succeeded: $url"
        return 0
      fi
      die "$label failed with conclusion=$conclusion: $url"
    fi

    sleep "$POLL_INTERVAL_SECONDS"
  done

  rm -f "$view_json"
  die "timed out waiting for $label run=$run_id"
}

record_run() {
  local label="$1"
  local run_id="$2"

  RUN_LABELS+=("$label")
  RUN_IDS+=("$run_id")
}

validate_final_artifact() {
  local run_id="$1"
  local report_json
  local aab_file

  mkdir -p "$ARTIFACT_DIR"
  log "downloading final artifact for run=$run_id into $ARTIFACT_DIR"
  "$GH_BIN" run download "$run_id" \
    --repo "$REPO" \
    --name "saas-release-candidate-$run_id" \
    --dir "$ARTIFACT_DIR"

  report_json="$(find "$ARTIFACT_DIR" -name release-candidate.json -print | sort | head -n 1)"
  [[ -n "$report_json" && -f "$report_json" ]] || die "release-candidate.json not found in $ARTIFACT_DIR"

  aab_file="$(find "$ARTIFACT_DIR" -name '*.aab' -print | sort | head -n 1)"
  [[ -n "$aab_file" && -f "$aab_file" ]] || die "AAB artifact not found in $ARTIFACT_DIR"

  python3 - "$report_json" "$aab_file" <<'PY'
import hashlib
import json
import sys
from pathlib import Path

report_path = Path(sys.argv[1])
aab_path = Path(sys.argv[2])
payload = json.loads(report_path.read_text(encoding="utf-8"))

expected = {
    "status": "passed",
    "dryRun": False,
    "strictSigning": True,
    "signingMode": "release-configured",
    "dartDefinesConfigured": True,
}
errors = []
for key, value in expected.items():
    if payload.get(key) != value:
        errors.append(f"{key} expected {value!r}, got {payload.get(key)!r}")

artifact_bytes = payload.get("artifactBytes")
if not isinstance(artifact_bytes, int) or artifact_bytes <= 0:
    errors.append(f"artifactBytes expected positive integer, got {artifact_bytes!r}")

sha256 = payload.get("sha256", "")
actual_sha256 = hashlib.sha256(aab_path.read_bytes()).hexdigest()
if sha256 != actual_sha256:
    errors.append(f"sha256 mismatch: report={sha256!r} actual={actual_sha256!r}")

if errors:
    raise SystemExit("\n".join(errors))
PY

  write_sequence_summary "$run_id" "$report_json" "$aab_file"
}

write_sequence_summary() {
  local final_run_id="$1"
  local report_json="$2"
  local aab_file="$3"
  local summary_file="$ARTIFACT_DIR/saas-release-candidate-sequence-summary.md"
  local sha256

  sha256="$(shasum -a 256 "$aab_file" | awk '{print $1}')"

  {
    printf '# SaaS Release Candidate Sequence\n\n'
    printf '%s\n' "- repo: \`$REPO\`"
    printf '%s\n' "- ref: \`$REF\`"
    printf '%s\n' "- workflow: \`$WORKFLOW\`"
    printf '%s\n' "- finalRunId: \`$final_run_id\`"
    printf '%s\n' "- report: \`$report_json\`"
    printf '%s\n' "- aab: \`$aab_file\`"
    printf '%s\n\n' "- sha256: \`$sha256\`"
    printf '## Runs\n\n'
    local i
    for i in "${!RUN_IDS[@]}"; do
      printf '%s\n' "- \`${RUN_LABELS[$i]}\`: \`${RUN_IDS[$i]}\`"
    done
  } > "$summary_file"

  log "wrote $summary_file"
}

run_step() {
  local label="$1"
  local build_appbundle="$2"
  local strict_signing="$3"
  local run_id

  run_id="$(dispatch_workflow "$label" "$build_appbundle" "$strict_signing")"
  record_run "$label" "$run_id"
  wait_for_run_success "$label" "$run_id"
  printf '%s\n' "$run_id"
}

main() {
  parse_args "$@"

  command -v "$GH_BIN" >/dev/null 2>&1 || die "gh CLI is required"
  [[ "$POLL_INTERVAL_SECONDS" =~ ^[0-9]+$ ]] || die "--poll-interval must be an integer"
  [[ "$TIMEOUT_SECONDS" =~ ^[0-9]+$ ]] || die "--timeout-seconds must be an integer"

  REPO="$(resolve_repo)"
  [[ -n "$REPO" ]] || die "unable to resolve GitHub repository"

  if [[ "$CHECK_SECRETS" -eq 1 ]]; then
    run_secret_check
  else
    log "secret preflight skipped"
  fi

  run_step "minimum-dry-run" false false >/dev/null
  run_step "strict-signing-dry-run" false true >/dev/null
  local final_run_id
  final_run_id="$(run_step "signed-prod-appbundle" true true)"

  if [[ "$DOWNLOAD_ARTIFACT" -eq 1 ]]; then
    validate_final_artifact "$final_run_id"
  else
    log "artifact download skipped"
  fi

  log "sequence complete"
}

main "$@"
