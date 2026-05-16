# MoneyThings Account Automation Paths Dev Verify

## Summary

This branch extends MoneyThings-style account group paths into automation-adjacent account selectors. It keeps account grouping as presentation only and does not change matching, save, filter, or transaction identity semantics.

- Branch: `codex/moneythings-account-automation-paths`
- Base: `codex/moneythings-account-filter-paths`
- PR: #244
- Worktree: `/Users/chauhua/Documents/GitHub/Jive/worktrees/moneythings-account-automation-paths`

## Implementation

- `AutoDraftsScreen` account dropdowns now display `AccountGroupService.displayPath(account)` for normal drafts and transfer drafts.
- AutoDraft transfer prompt dropdowns now show grouped paths while raw-text hint matching still uses the original account names.
- `RecurringRuleFormScreen` account and transfer-account dropdowns now show grouped paths.
- `TagRuleScreen` account filter chips now show grouped paths.
- Existing selected values remain concrete `JiveAccount.id` values.

## Guardrails

- Did not modify `supabase/migrations`.
- Did not modify `lib/core/sync`.
- Did not modify `.github/workflows`.
- Did not modify SaaS entitlement, payment, or sync logic.
- Did not change AutoDraft account matching or recurring rule persistence semantics.
- Did not add `parentAccountKey` or any account migration.

## Validation

- `/Users/chauhua/development/flutter/bin/dart format lib/feature/auto/auto_drafts_screen.dart lib/feature/recurring/recurring_rule_form_screen.dart lib/feature/tag/tag_rule_screen.dart`
- `/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos lib/feature/auto/auto_drafts_screen.dart lib/feature/recurring/recurring_rule_form_screen.dart lib/feature/tag/tag_rule_screen.dart`
- `/Users/chauhua/development/flutter/bin/flutter test test/moneythings_alignment_services_test.dart --plain-name AccountGroupService`
- `/Users/chauhua/development/flutter/bin/flutter test test/moneythings_alignment_services_test.dart test/transaction_entry_widget_regression_test.dart`
- `/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos`
- `git diff --check`
- `git diff --name-only -- supabase/migrations lib/core/sync .github/workflows`

## Validation Notes

- Full `flutter analyze --no-fatal-infos` exits successfully with 83 existing info-level findings in unrelated files.
- Manual device smoke was not run in this worktree.

## Manual Smoke Checklist

- Create grouped accounts such as `中国银行 / 活期 / CNY`.
- Open AutoDraft review and confirm account dropdowns show grouped paths.
- Open AutoDraft transfer account selection and confirm transfer-out/transfer-in dropdowns show grouped paths.
- Create or edit a recurring rule and confirm account dropdowns show grouped paths.
- Open tag rule account conditions and confirm account chips show grouped paths.
- Save or confirm each flow and verify the stored account ID remains the selected child account.
