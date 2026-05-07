#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/guard_saas_report_artifacts.sh [options] [root ...]

Options:
  --root <path>          Report/artifact root to scan. May be repeated.
  --label <name>         Human-readable lane name for diagnostics.
  --secret-env <name>    Environment variable whose value must not appear in
                         scanned report files. May be repeated.
  -h, --help             Show this help.

Blocks sensitive-looking files before CI uploads release/SaaS report artifacts.
Missing roots are skipped. Secret values shorter than 8 characters are ignored
to avoid noisy matches from empty placeholders.
EOF
}

LABEL="SaaS report artifacts"
ROOTS=()
SECRET_ENVS=()

while (( "$#" )); do
  case "$1" in
    --root)
      [[ $# -ge 2 ]] || { printf 'Missing value for --root\n' >&2; exit 2; }
      ROOTS+=("$2")
      shift 2
      ;;
    --label)
      [[ $# -ge 2 ]] || { printf 'Missing value for --label\n' >&2; exit 2; }
      LABEL="$2"
      shift 2
      ;;
    --secret-env)
      [[ $# -ge 2 ]] || { printf 'Missing value for --secret-env\n' >&2; exit 2; }
      SECRET_ENVS+=("$2")
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    --)
      shift
      while (( "$#" )); do
        ROOTS+=("$1")
        shift
      done
      ;;
    -*)
      printf 'Unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
    *)
      ROOTS+=("$1")
      shift
      ;;
  esac
done

if (( ${#ROOTS[@]} == 0 )); then
  printf 'No artifact roots provided for %s.\n' "$LABEL"
  exit 0
fi

EXISTING_ROOTS=()
for root in "${ROOTS[@]}"; do
  if [[ -e "$root" ]]; then
    EXISTING_ROOTS+=("$root")
  fi
done

if (( ${#EXISTING_ROOTS[@]} == 0 )); then
  printf 'No existing artifact roots found for %s.\n' "$LABEL"
  exit 0
fi

blocked_file="$(mktemp)"
leaked_file="$(mktemp)"
trap 'rm -f "$blocked_file" "$leaked_file"' EXIT

find "${EXISTING_ROOTS[@]}" -type f \
    \( \
      -name '*.env' -o \
      -name '*.pem' -o \
      -name '*.key' -o \
      -name '*.keystore' -o \
      -name '*.jks' -o \
      -name '*.p12' -o \
      -name '*.pfx' -o \
      -iname '*secret*' -o \
      -iname '*secrets*' -o \
      -iname '*credential*' -o \
      -iname '*credentials*' -o \
      -iname '*dart-defines*' \
    \) | sort > "$blocked_file"

if [[ -s "$blocked_file" ]]; then
  printf '%s artifact guard blocked sensitive-looking files:\n' "$LABEL" >&2
  sed 's/^/ - /' "$blocked_file" >&2
  exit 1
fi

for key in "${SECRET_ENVS[@]}"; do
  value="${!key:-}"
  if [[ -z "$value" || "${#value}" -lt 8 ]]; then
    continue
  fi

  while IFS= read -r matched_file; do
    [[ -z "$matched_file" ]] && continue
    printf '%s: %s\n' "$key" "$matched_file" >> "$leaked_file"
  done < <(grep -R -I -F -l -- "$value" "${EXISTING_ROOTS[@]}" 2>/dev/null || true)
done

if [[ -s "$leaked_file" ]]; then
  printf '%s artifact guard found secret values in reports:\n' "$LABEL" >&2
  sort -u "$leaked_file" | sed 's/^/ - /' >&2
  exit 1
fi

printf '%s artifact guard passed for %s root(s).\n' "$LABEL" "${#EXISTING_ROOTS[@]}"
