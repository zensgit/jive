#!/usr/bin/env bash
set -euo pipefail

target="${1:-all}"

case "$target" in
  all|android|ios|core)
    ;;
  -h|--help|help)
    cat <<'USAGE'
Usage: scripts/print_moneythings_prebeta_smoke_checklist.sh [all|android|ios|core]

Prints the MoneyThings pre-beta manual smoke checklist.
USAGE
    exit 0
    ;;
  *)
    echo "Unknown target: $target" >&2
    echo "Expected one of: all, android, ios, core" >&2
    exit 2
    ;;
esac

repo_head="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
repo_branch="$(git branch --show-current 2>/dev/null || echo unknown)"

print_header() {
  cat <<EOF
# Jive MoneyThings Pre-Beta Manual Smoke

Target: $target
Branch: $repo_branch
Head: $repo_head

Record each result as PASS / FAIL / BLOCKED and attach screenshots or logs for
every FAIL or BLOCKED item.

EOF
}

print_core() {
  cat <<'EOF'
## Core Entry And Data Smoke

- [ ] MT-CORE-01 One-tap breakfast quick action saves directly.
      Expected: transaction is created with the saved amount, category, account,
      scene/book context, and quick-action usage count updates.

- [ ] MT-CORE-02 Lunch quick action opens confirm mode and saves after amount
      entry.
      Expected: amount is required, source banner is visible, save creates one
      transaction, and no silent failure occurs.

- [ ] MT-CORE-03 Complex transfer or incomplete external entry opens the
      structured editor.
      Expected: TransactionFormScreen shows source context and highlights the
      missing fields instead of saving automatically.

- [ ] MT-CORE-04 Third-level category remains opt-in.
      Expected: default category creation stays two-level; adding a child from
      a second-level category allows a third-level path and saves top + leaf
      compatible keys.

- [ ] MT-CORE-05 Account group display keeps concrete account identity.
      Expected: grouped paths are visible in picker/detail/report surfaces, but
      the saved transaction still points to the selected concrete account.

- [ ] MT-CORE-06 Shared-scene transaction warning appears.
      Expected: shared visibility hint is shown and private account usage is
      blocked or asks for replacement according to policy.

- [ ] MT-CORE-07 SmartList default view restores and stale default clears.
      Expected: entering bill list restores the default SmartList; deleting that
      view clears the stale default.

EOF
}

print_android() {
  cat <<'EOF'
## Android System Entry Smoke

- [ ] MT-ANDROID-01 Today widget default quick-add opens structured entry.
      Expected: widget button opens jive://transaction/new with widget source
      metadata and missing-field highlights.

- [ ] MT-ANDROID-02 Configured widget quick action opens quick-action entry.
      Expected: widget button opens jive://quick-action?id=... and reaches the
      same QuickActionExecutor path as in-app quick actions.

- [ ] MT-ANDROID-03 Android share entry routes to structured editor.
      Expected: shared text is preserved as note/raw text when parsing is
      incomplete and source metadata is visible.

EOF
}

print_ios() {
  cat <<'EOF'
## iOS System Entry Smoke

- [ ] MT-IOS-01 Shortcuts exposes Jive quick action intent.
      Expected: Shortcuts can launch a saved quick action and reaches the same
      execution path as in-app quick actions.

- [ ] MT-IOS-02 Scene switch URL opens the expected scene.
      Expected: jive://scene/switch by id, key, or name opens the scene/book
      context without changing the data model.

- [ ] MT-IOS-03 Transaction URL opens structured editor.
      Expected: jive://transaction/new opens TransactionFormScreen with source
      banner and missing-field highlights.

EOF
}

print_footer() {
  cat <<'EOF'
## Exit Criteria

- All core items pass on at least one runnable app target.
- Android widget items pass on Android before Android beta.
- iOS Shortcuts/AppIntent items pass on iOS before iOS beta.
- Any FAIL or BLOCKED item has an issue or PR linked before external beta.
EOF
}

print_header
print_core

if [[ "$target" == "all" || "$target" == "android" ]]; then
  print_android
fi

if [[ "$target" == "all" || "$target" == "ios" ]]; then
  print_ios
fi

print_footer
