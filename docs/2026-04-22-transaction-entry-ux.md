# Transaction Entry UX Development And Validation

Date: 2026-04-22
Branch: `feature/transaction-entry-ux`
Base: `origin/main@6ea8b06`

## Scope

This change optimizes the add transaction flow without changing transaction persistence, SaaS entitlement/payment/sync logic, Supabase migrations, or CI workflows.

## Design

### Amount Entry

- The amount header now has a stable two-line display.
- The first line shows the current formula in small text and keeps the tail when the formula is long.
- The second line shows the live calculated result in the original large amount style.
- The display area uses a fixed height so entering digits/operators does not visibly jump between one-line and two-line states.
- `AmountExpression` evaluates `+`, `-`, `×`, and `÷` with multiplication/division precedence.
- Incomplete formulas keep the last valid result, for example `1+2×` displays the formula while the result remains `3`.

### Keyboard

- Short tap on number/operator keys updates the formula and result immediately.
- Long press on `+` toggles that key between `+` and `×`.
- Long press on `-` toggles that key between `-` and `÷`.
- `OK` still calls the existing save path, and save still reads the computed numeric amount from `_amountStr`.

### Inline Note

- The note entry is now directly under the amount display.
- It starts as a compact inline "备注（可选）" control.
- Tapping it expands the existing `NoteFieldWithChips` inline, preserving note chips and note save behavior.
- No modal dialog is introduced for notes.

### Categories

- Add transaction subcategories now filter out hidden subcategories.
- `CategoryPickerScreen` now handles the user-only category case where a user-created child belongs to a system parent.
- In user-only mode, system parents with user children remain visible as grouping rows, and their custom children are included in search/list data.

### Guided Setup

- In the welcome guided setup "记一笔" step, tapping a category now dismisses the keyboard so the bottom "下一步" button is reachable.
- Validation now shows clear snackbars for missing category or missing amount instead of silently doing nothing.

## Files

- `lib/feature/transactions/add_transaction_screen.dart`
- `lib/feature/transactions/amount_expression.dart`
- `lib/feature/transactions/note_field_with_chips.dart`
- `lib/feature/category/category_picker_screen.dart`
- `lib/feature/onboarding/guided_setup_screen.dart`
- `test/amount_expression_test.dart`
- `test/category_picker_user_categories_test.dart`

## Validation

### Passed

- `/Users/chauhua/development/flutter/bin/dart format ...`
- `/Users/chauhua/development/flutter/bin/flutter test test/amount_expression_test.dart test/note_field_with_chips_test.dart test/account_category_sync_repository_test.dart`
- `/Users/chauhua/development/flutter/bin/flutter test test/transaction_query_service_test.dart`
- `/Users/chauhua/development/flutter/bin/flutter test test/transaction_query_spec_test.dart`
- `/Users/chauhua/development/flutter/bin/flutter test test/category_picker_user_categories_test.dart`

### Analyze

Command:

```bash
/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos
```

Result: completed with no compile errors, but returned exit code 1 because the current `origin/main` tree already has warning-level analyzer findings. Examples include:

- `lib/feature/budget/project_budget_screen.dart`: unused local variable `budgetService`
- `test/pdf_report_service_test.dart`: unused import and unnecessary type check
- `lib/feature/transactions/add_transaction_screen.dart`: existing unused `_dateTimeFormat` field and existing async `BuildContext` lint warnings

These were not changed in this task to avoid unrelated cleanup scope.

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

## Out Of Scope

- No changes to `supabase/migrations`.
- No changes to `lib/core/sync`.
- No changes to `.github/workflows`.
- No SaaS entitlement/payment/sync behavior changes.
