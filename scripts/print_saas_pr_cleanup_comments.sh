#!/usr/bin/env bash
set -euo pipefail

MERGE_PR="${1:-144}"

merged_via=(
  139 142 136 140 141 122 131 124 133 138 134 135 127 128 129 130
)

superseded=(
  117 118 119 121 123 125 126 132 137
)

print_block() {
  local pr="$1"
  local kind="$2"

  printf 'PR #%s\n' "$pr"
  printf '%s\n' '---'

  if [[ "$kind" == "merged" ]]; then
    cat <<EOF
This work is now merged via #$MERGE_PR, which served as the single SaaS Beta mainline integration path into \`main\`.

Keeping this PR for audit context, but it is no longer the recommended merge path.
EOF
  else
    cat <<EOF
This PR is now superseded by #$MERGE_PR.

The SaaS Beta stack was integrated and advanced through \`#$MERGE_PR\` as the single mainline merge path, so this branch should be kept only for historical audit context and not merged independently.
EOF
  fi

  printf '\n\n'
}

printf '=== merged via #%s ===\n\n' "$MERGE_PR"
for pr in "${merged_via[@]}"; do
  print_block "$pr" merged
done

printf '=== superseded by #%s ===\n\n' "$MERGE_PR"
for pr in "${superseded[@]}"; do
  print_block "$pr" superseded
done
