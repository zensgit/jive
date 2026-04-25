# Transaction Entry UX Development And Validation

Date: 2026-04-22
Updated: 2026-04-25
Branch: `feature/transaction-entry-ux`
Base: `origin/main@6311cd8`

## Scope

This change optimizes the add transaction flow without changing transaction persistence, SaaS entitlement/payment/sync logic, Supabase migrations, or CI workflows.

## Design

### Amount Entry

- The latest mainline transaction editor already uses the split component architecture (`CompactAmountBar`, `TransactionCalculatorKey`, field chips, and category panels); this PR ports the entry UX and tests onto that architecture instead of restoring the older monolithic layout.
- The amount header has a stable two-line display.
- The first line shows the current formula in small text and keeps the tail when the formula is long.
- The second line shows the live calculated result in the original large amount style.
- The display area uses a fixed height so entering digits/operators does not visibly jump between one-line and two-line states.
- `TransactionAmountExpression` evaluates `+`, `-`, `×`, and `÷` with multiplication/division precedence.
- Incomplete formulas keep the last valid result, for example `1+2×` displays the formula while the result remains `3`.
- Invalid formulas such as division by zero no longer display a valid-looking `0`; tapping save shows an explicit invalid-formula message.
- Invalid formulas continue to use the same two-line header: the formula remains on the first line and the result line switches to an explicit `无效` state instead of collapsing back to a single raw-expression line.

### Keyboard

- Short tap on number/operator keys updates the formula and result immediately.
- Long press on `+` toggles that key between `+` and `×`.
- Long press on `-` toggles that key between `-` and `÷`.
- Continuous-entry reset restores the operator keys to `+` and `-`, so a long-press mode from the previous transaction does not leak into the next entry.
- `OK` evaluates and saves a valid formula in the same tap, preserving the fast-entry flow.
- The route pop guard now only intercepts category search mode, so normal save/close actions can return their existing boolean result instead of being blocked by `PopScope(canPop: false)`.

### Inline Note

- The note entry is now directly under the amount display.
- It is rendered inside `CompactAmountBar` as an inline text field.
- Tapping the expand control grows the note field in place instead of opening a modal.
- The current mainline quick-field chips stay outside this note field, so the note area no longer depends on the older `NoteFieldWithChips` component.
- No modal dialog is introduced for notes.

### Categories

- Add transaction subcategories now filter out hidden subcategories.
- `CategoryPickerScreen` now handles the user-only category case where a user-created child belongs to a system parent.
- In user-only mode, system parents with user children remain visible as grouping rows, even if the parent itself is hidden.
- Hidden/system grouping parents are not selectable search results, while their visible custom children are included in search/list data.
- `CategoryPickerScreen` keeps production loading from Isar, while accepting prebuilt picker data for stable widget-level regression tests.

### Guided Setup

- In the welcome guided setup "记一笔" step, tapping a category now dismisses the keyboard so the bottom "下一步" button is reachable.
- Validation now shows clear snackbars for missing category or missing amount instead of silently doing nothing.
- `GuidedSetupScreen` keeps production defaults unchanged, while exposing small test seams for injected categories and first-transaction saving so the onboarding transaction flow can be covered by a stable widget test.

### Transaction Entry Testability

- `AddTransactionScreen`, `CompactAmountBar`, `TransactionCalculatorKey`, and `SubCategoryGrid` now expose stable widget keys for amount formula/result, amount keys, parent/subcategory rows, inline note controls, and the save button.
- Production data loading and save behavior remain the default.
- Widget tests can inject Isar, initial categories/accounts/tags/projects, a transaction saver, and a smart-tag resolver to verify the entry UX without bootstrapping the full app database.
- The full add-transaction widget regression now covers `1+2×3`, long-press operator switching, custom category selection, inline note entry, save return value, and the generated `JiveTransaction` payload.
- A follow-up widget regression also covers long-press `-` to `÷`, `1÷0` invalid-state rendering, and save blocking with the existing snackbar feedback.
- A second follow-up widget regression covers continuous-entry mode, proving that a saved transaction resets `+/-` operator toggles before the next entry starts.
- The test seams are annotated as testing-only and production call sites continue to use the default Isar repository, smart-tag, tag-usage, account-usage, and merchant-memory save path.

## Files

- `lib/feature/transactions/add_transaction_screen.dart`
- `lib/feature/transactions/transaction_amount_expression.dart`
- `lib/feature/transactions/widgets/compact_amount_bar.dart`
- `lib/feature/transactions/widgets/transaction_field_chips.dart`
- `lib/feature/category/category_picker_screen.dart`
- `lib/feature/onboarding/guided_setup_screen.dart`
- `lib/feature/budget/project_budget_screen.dart`
- `test/pdf_report_service_test.dart`
- `test/amount_expression_test.dart`
- `test/transaction_amount_expression_test.dart`
- `test/add_transaction_screen_entry_ux_test.dart`
- `test/category_picker_user_categories_test.dart`
- `test/guided_setup_screen_test.dart`

## Follow-Up Hardening

- Removed a stale unused `DateFormat` field from the transaction entry screen.
- Removed unused local budget-service construction in the project budget screen.
- Tightened `PdfReportService.generateAnnualReport` signature coverage so the test no longer relies on an always-true function type check.
- Added expression coverage for negative prefix input, trailing operators, chained incomplete formulas, and decimals.
- Preserved the existing non-negative amount guard by clamping negative expression results to `0`, while still treating zero/negative saves as invalid in the entry flow.
- Removed the duplicated `AmountExpression` helper after rebasing onto latest main; expression behavior now lives in `TransactionAmountExpression`.
- Extracted amount expression length into a named constant and removed the old hardcoded limit from keypad input.
- Added category coverage for hidden system parents that still own visible custom child categories.
- Added category picker UI coverage that verifies a hidden system parent behaves as a group row only, while tapping the custom child returns the selected result.
- Stabilized note suggestion chips to reduce layout movement when inline notes are expanded.
- Added a guided-setup widget regression test for selecting a category, tapping "下一步", saving the first expense payload, and advancing to the "设分类" step.
- Added an add-transaction widget regression for expression entry, custom category selection, inline note entry, save callback payload, and save route result.
- Added a second add-transaction widget regression that locks in `- -> ÷`, explicit invalid-result rendering, and the divide-by-zero save guard.
- Added a continuous-entry widget regression that verifies operator toggle state is reset after a successful save in `连续记账` mode.
- Rebasing onto latest `origin/main` kept the new componentized transaction platform and re-applied only the transaction-entry UX anchors/seams on top.
- These follow-up changes do not change transaction persistence, project budget behavior, or PDF generation behavior.

## Validation

### Passed

- `/Users/chauhua/development/flutter/bin/dart format ...`
- `/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos`
- `/Users/chauhua/development/flutter/bin/flutter test test/amount_expression_test.dart test/note_field_with_chips_test.dart test/account_category_sync_repository_test.dart`
- `/Users/chauhua/development/flutter/bin/flutter test test/transaction_query_service_test.dart`
- `/Users/chauhua/development/flutter/bin/flutter test test/transaction_query_spec_test.dart`
- `/Users/chauhua/development/flutter/bin/flutter test test/category_picker_user_categories_test.dart`
- `/Users/chauhua/development/flutter/bin/flutter test test/amount_expression_test.dart test/category_picker_user_categories_test.dart test/note_field_with_chips_test.dart test/account_category_sync_repository_test.dart test/transaction_query_service_test.dart test/transaction_query_spec_test.dart test/pdf_report_service_test.dart`
- `/Users/chauhua/development/flutter/bin/flutter test test/guided_setup_screen_test.dart`
- `/Users/chauhua/development/flutter/bin/flutter test test/add_transaction_screen_entry_ux_test.dart`
- `/Users/chauhua/development/flutter/bin/flutter test test/amount_expression_test.dart test/add_transaction_screen_entry_ux_test.dart`
- `/Users/chauhua/development/flutter/bin/flutter test test/transaction_amount_expression_test.dart test/amount_expression_test.dart test/add_transaction_screen_entry_ux_test.dart`
- `/Users/chauhua/development/flutter/bin/flutter test test/add_transaction_screen_entry_ux_test.dart test/guided_setup_screen_test.dart test/transaction_amount_expression_test.dart test/amount_expression_test.dart test/category_picker_user_categories_test.dart test/note_field_with_chips_test.dart test/account_category_sync_repository_test.dart test/transaction_query_service_test.dart test/transaction_query_spec_test.dart test/pdf_report_service_test.dart`
- `git diff --name-only -- supabase/migrations lib/core/sync .github/workflows`

### Parallel Review Notes

- A parallel read-only pass recommended an `AddTransactionScreen` end-to-end widget test for amount expression, inline note, custom category, and save behavior.
- The current implementation follows that recommendation with stable widget keys plus narrow test seams for initial data, smart-tag resolution, and transaction saving.
- The test intentionally captures the generated `JiveTransaction` through the saver seam; production default saving still writes through the existing Isar, tag usage, and merchant-memory path.

### Analyze

Command:

```bash
/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos
```

Result: passed with exit code 0. The command still reports existing info-level lints from the broader tree, but there are no warning/error-level blockers.

### Manual Smoke

- `flutter devices` found macOS, Chrome, and a connected iPhone.
- First `flutter run -d macos` was blocked by local codesign extended attributes.
- After clearing build/source extended attributes, `flutter run -d macos` built and launched the app.
- Runtime logs showed existing macOS plugin limitations for `google_mobile_ads` and `com.jive.app/stream`, but the app process started.
- UI click-through smoke could not be completed because Computer Use access to `com.jive.app.jive` was denied by local authorization.

Manual scenario still recommended on a developer machine with UI automation or direct interaction:

1. Open add transaction page.
2. Enter `1+2×3` and verify result `7`.
3. Long-press `+` and `-` to switch operators.
4. Select a custom category.
5. Tap note, enter inline note text, and save.

## Merge Readiness

- PR: `#186 Improve transaction entry UX`
- Status snapshot date: `2026-04-25`
- Latest GitHub-verified green head before the final documentation-only refreshes: `61b5ca44`
- Latest functional head before the documentation-only refresh commits: `ef59cca2`
- GitHub checks passed:
  - `analyze_and_test`
  - `detect_saas_wave0_smoke`
- Workflow-skipped checks:
  - `android_integration_test`
  - `saas_wave0_smoke`
- All previously outdated AI review threads were resolved after the follow-up fixes landed.
- PR remains `OPEN + MERGEABLE + ready for review`; there are no unresolved review threads and no requested changes.
- The first `2026-04-25` documentation refresh commit also reran GitHub CI successfully, so the merge-ready status is confirmed at the PR level rather than only inferred from the previous functional head.
- This `2026-04-25` update is documentation-only and does not introduce new runtime behavior.
- The remaining merge gate is process-only: if repository protection requires human approval, that approval still needs to come from GitHub review flow rather than additional code changes.

## Out Of Scope

- No changes to `supabase/migrations`.
- No changes to `lib/core/sync`.
- No changes to `.github/workflows`.
- No SaaS entitlement/payment/sync behavior changes.
