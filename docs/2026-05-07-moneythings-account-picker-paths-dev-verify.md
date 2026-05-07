# MoneyThings Account Picker Paths Dev / Verify

## Summary

This slice continues the MoneyThings account-group TODO by carrying grouped account display paths through transaction entry pickers.

The first-stage account-group model remains unchanged:

- Each subaccount is still a normal `JiveAccount`.
- Transactions still save to the concrete `accountId`.
- `groupName` only affects display, search, and selection clarity.
- No parent-account migration is introduced.

## Branch

- Branch: `codex/moneythings-account-picker-paths`
- Base: `codex/moneythings-quick-action-edit-validation`
- Worktree: `/Users/chauhua/Documents/GitHub/Jive/worktrees/moneythings-account-picker-paths`
- PR: TBD

## Implementation

### Manual Add Transaction

`AddTransactionScreen` now uses `AccountGroupService.displayPath(...)` for:

- The compact amount bar account label.
- The account picker grid display label.
- Account picker search, so users can search by group name such as `中国银行` as well as child account name.

### Structured Transaction Editor

`TransactionFormScreen` now uses the same display path for:

- Main account picker rows.
- Transfer target picker rows.
- Core fields account display.
- Transfer target display card.

### Shared Account Chip

`AccountChip` now displays the account path for grouped subaccounts. This keeps the high-frequency calculator-style transaction page consistent with the full editor.

## Guardrails

- No `supabase/migrations` changes.
- No `lib/core/sync` changes.
- No `.github/workflows` changes.
- No SaaS entitlement, payment, or sync behavior changes.
- No account or transaction schema migration.
- No change to transaction save semantics.

## Validation

Automated checks run locally:

```bash
/Users/chauhua/development/flutter/bin/dart format lib/feature/transactions/add_transaction_screen.dart lib/feature/transactions/transaction_form_screen.dart lib/feature/transactions/widgets/account_selector_section.dart test/transaction_entry_widget_regression_test.dart
/Users/chauhua/development/flutter/bin/flutter test test/transaction_entry_widget_regression_test.dart
/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos lib/feature/transactions/add_transaction_screen.dart lib/feature/transactions/transaction_form_screen.dart lib/feature/transactions/widgets/account_selector_section.dart test/transaction_entry_widget_regression_test.dart
/Users/chauhua/development/flutter/bin/flutter test test/transaction_entry_widget_regression_test.dart test/add_transaction_screen_entry_ux_test.dart test/category_picker_user_categories_test.dart
/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos
git diff --check
git diff --name-only -- supabase/migrations lib/core/sync .github/workflows
```

Results:

- Transaction entry widget regression tests: passed.
- Targeted analyze: passed with no issues.
- Transaction entry and category picker regression tests: passed.
- Full `flutter analyze --no-fatal-infos`: passed with existing info-level warnings.
- `git diff --check`: passed.
- Restricted path diff check: empty.

## Manual Smoke

Recommended manual verification:

1. Create two accounts with the same meaningful `groupName`, such as `中国银行 / 活期 CNY` and `中国银行 / 定期 USD`.
2. Open manual add transaction and confirm the account chip shows the grouped path.
3. Open account picker and search `中国银行`; confirm grouped child accounts are found.
4. Open structured editor and confirm account and transfer target pickers show grouped paths.
5. Save a transaction and confirm it still saves to the selected child account.
