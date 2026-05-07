# MoneyThings Account Edit Warnings Dev Verify

## Summary

This low-risk stacked slice extends the MoneyThings-style object sharing visibility layer to account create/edit saves. Shared-scene accounts already show visibility badges; this branch adds an explicit confirmation before a shared-scene account form writes changes.

- Branch: `codex/moneythings-account-edit-warnings`
- Base: `codex/moneythings-account-automation-paths`
- PR: TBD
- Worktree: `/Users/chauhua/Documents/GitHub/Jive/worktrees/moneythings-account-edit-warnings`

## Implementation

- `AccountsScreen` now checks the existing `ObjectSharePolicyService` before saving an account form.
- Private scenes continue to save immediately.
- Shared scenes show a confirmation for both account creation and account edits.
- The copy states that shared ledger/book remains the permission truth and that transactions still save to concrete accounts.
- Account badges continue to use the same account share policy helper.

## Guardrails

- Did not modify `supabase/migrations`.
- Did not modify `lib/core/sync`.
- Did not modify `.github/workflows`.
- Did not modify SaaS entitlement, payment, or sync logic.
- Did not introduce object-level sharing tables, RLS, or permission truth.
- Did not add account archive/delete behavior or `parentAccountKey`.

## Validation

- `/Users/chauhua/development/flutter/bin/dart format lib/feature/accounts/accounts_screen.dart test/moneythings_alignment_services_test.dart`
- `/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos lib/feature/accounts/accounts_screen.dart test/moneythings_alignment_services_test.dart`
- `/Users/chauhua/development/flutter/bin/flutter test test/moneythings_alignment_services_test.dart --plain-name ObjectSharePolicyService`
- `git diff --check`
- `git diff --name-only -- supabase/migrations lib/core/sync .github/workflows`

## Validation Notes

- Manual device smoke was not run in this worktree.

## Manual Smoke Checklist

- Open accounts in a private scene, edit an account, and confirm it saves without an extra shared warning.
- Open accounts in a shared scene, create an account, and confirm the shared-impact dialog appears before saving.
- Edit an existing account in a shared scene and confirm cancel keeps the form open without saving.
- Confirm the dialog and verify the account still saves through the existing `AccountService` path.
