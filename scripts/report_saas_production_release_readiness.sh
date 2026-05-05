#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

REPO="${GITHUB_REPOSITORY:-}"
OUTPUT_FILE="$APP_DIR/build/reports/saas-production-release-readiness/latest.md"
STRICT=0

usage() {
  cat <<'EOF'
Usage:
  scripts/report_saas_production_release_readiness.sh [options]

Options:
  --repo <owner/repo>   GitHub repository. Defaults to GITHUB_REPOSITORY or the current gh repo.
  --output <path>       Markdown report path. Defaults to build/reports/saas-production-release-readiness/latest.md.
  --strict              Exit non-zero when production release secrets are incomplete.
  --help                Show this help.

Notes:
  This script writes a redacted Markdown readiness report. It checks only secret names,
  never reads or prints GitHub Actions secret values.
EOF
}

log() {
  printf '[saas-prod-release-report] %s\n' "$*"
}

die() {
  printf '[saas-prod-release-report] ERROR: %s\n' "$*" >&2
  exit 1
}

parse_args() {
  while (( "$#" )); do
    case "$1" in
      --repo)
        REPO="${2:-}"
        shift 2
        ;;
      --output)
        OUTPUT_FILE="${2:-}"
        shift 2
        ;;
      --strict)
        STRICT=1
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

  gh repo view --json nameWithOwner --jq .nameWithOwner
}

run_secret_check() {
  local output_file="$1"
  shift

  "$@" >"$output_file" 2>&1
}

main() {
  parse_args "$@"

  command -v gh >/dev/null 2>&1 || die "gh CLI is required"

  local repo
  repo="$(resolve_repo)"
  [[ -n "$repo" ]] || die "unable to resolve GitHub repository"

  local output_dir
  output_dir="$(dirname "$OUTPUT_FILE")"
  mkdir -p "$output_dir"

  local main_sha=""
  main_sha="$(git ls-remote origin refs/heads/main | awk '{print $1}')"

  local workflow_state="missing"
  workflow_state="$(gh workflow list --repo "$repo" --all | awk -F '\t' '$1 == "SaaS Release Candidate" { print $2; found=1 } END { if (!found) print "missing" }')"

  local latest_ci="unavailable"
  latest_ci="$(gh run list \
    --repo "$repo" \
    --workflow "Flutter CI" \
    --branch main \
    --limit 1 \
    --json databaseId,conclusion,status,headSha,url,createdAt \
    --jq 'if length == 0 then "unavailable" else "run=" + (.[0].databaseId|tostring) + " status=" + .[0].status + " conclusion=" + (.[0].conclusion // "") + " head=" + .[0].headSha + " url=" + .[0].url end')"

  local minimum_log
  local strict_log
  minimum_log="$(mktemp)"
  strict_log="$(mktemp)"
  trap "rm -f '$minimum_log' '$strict_log'" EXIT

  local minimum_status
  local strict_status

  set +e
  run_secret_check "$minimum_log" "$APP_DIR/scripts/check_saas_github_secrets.sh" --profile production-release --repo "$repo"
  minimum_status=$?
  run_secret_check "$strict_log" "$APP_DIR/scripts/check_saas_github_secrets.sh" --profile production-release --include-signing --repo "$repo"
  strict_status=$?
  set -e

  local ready_status="blocked"
  if [[ "$workflow_state" == "active" && "$minimum_status" -eq 0 ]]; then
    ready_status="dry-run-ready"
  fi
  if [[ "$workflow_state" == "active" && "$strict_status" -eq 0 ]]; then
    ready_status="signed-build-ready"
  fi

  {
    printf '# SaaS Production Release Readiness\n\n'
    printf 'Generated: %s\n\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf 'Repository: `%s`\n\n' "$repo"
    printf '## Summary\n\n'
    printf '%s\n' "- Status: \`$ready_status\`"
    printf '%s\n' "- \`main\`: \`${main_sha:-unknown}\`"
    printf '%s\n' "- \`SaaS Release Candidate\` workflow: \`$workflow_state\`"
    printf '%s\n\n' "- Latest main Flutter CI: \`$latest_ci\`"

    printf '## Required Secrets\n\n'
    printf 'Minimum dry-run secret check exit: `%s`\n\n' "$minimum_status"
    printf '```text\n'
    cat "$minimum_log"
    printf '```\n\n'

    printf 'Strict signing secret check exit: `%s`\n\n' "$strict_status"
    printf '```text\n'
    cat "$strict_log"
    printf '```\n\n'

    printf '## Next Commands\n\n'
    printf 'After the missing production secrets are configured:\n\n'
    printf '```bash\n'
    printf 'scripts/check_saas_github_secrets.sh --profile production-release --repo %s\n' "$repo"
    printf 'scripts/check_saas_github_secrets.sh --profile production-release --include-signing --repo %s\n' "$repo"
    printf '```\n\n'
    printf 'Then run GitHub Actions -> `SaaS Release Candidate` in this order:\n\n'
    printf '1. `build_appbundle=false`, `strict_signing=false`\n'
    printf '2. `build_appbundle=false`, `strict_signing=true`\n'
    printf '3. `build_appbundle=true`, `strict_signing=true`\n'
  } > "$OUTPUT_FILE"

  log "wrote $OUTPUT_FILE"

  if [[ "$STRICT" -eq 1 && "$ready_status" == "blocked" ]]; then
    die "production release readiness is blocked"
  fi
}

main "$@"
