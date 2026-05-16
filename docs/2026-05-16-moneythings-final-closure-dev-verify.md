# MoneyThings Final Closure Dev Verify

Date: 2026-05-16

Branch: `codex/moneythings-final-closure`

Base: `origin/main@30ecef63`

## Scope

This documentation slice closes the migration-free MoneyThings borrowing plan
after `#320` merged into `main`. It records the final product boundary,
validation commands, remaining high-risk decisions, and the manual smoke
checklist for pre-beta device verification.

No app logic, migrations, sync internals, SaaS entitlement/payment/sync logic,
Supabase functions, or GitHub workflow files were changed.

## Implemented Product Surface

- One Touch / Quick Action: direct, confirm, and edit modes share
  `QuickActionExecutor`; templates, quick-entry hub, deep links, App Intents,
  Shortcuts, and widget quick-action links now converge on the same execution
  protocol.
- Transaction editor: external and incomplete entries construct
  `TransactionEntryParams`, show source context, highlight missing fields, and
  fall back to the structured editor instead of attempting silent saves.
- Categories: the default experience stays two-level; third-level categories
  are opt-in from an existing second-level category, while display, import,
  export, detail, reports, templates, and share previews use
  `CategoryPathService`.
- Account groups: subaccount-style display is implemented as a view layer
  through `AccountGroupService`; transactions still save concrete
  `JiveAccount.id` values.
- Scenes and SmartLists: scene switching wraps the existing book model,
  guided templates provide scenario defaults, candidate ordering uses scene
  context, and SmartLists support saved filters, pinning, default restoration,
  and stale-default cleanup.
- Sharing hints and family limits: `ObjectSharePolicyService` labels objects
  and warns on shared-scene risks, while shared-ledger creation/join/invite
  entry points enforce Free, Pro, and Family copy and limits from the sprint
  design.
- System entry linkage: URL schemes cover `jive://quick-action`,
  `jive://transaction/new`, and `jive://scene/switch`; Android widget quick
  add defaults to structured transaction entry and can be configured to open a
  saved quick action.

## Deferred Wave 8 Decisions

Wave 8 remains intentionally deferred because it would change data, sync, or
permission semantics:

- Decide whether Quick Actions need a first-class synced persistence model
  beyond the current compatibility layer.
- Decide whether account groups require a real `parentAccountKey` migration.
- Decide whether object-level sharing needs server-side tables, RLS,
  conflict handling, and audit logs.
- Design each accepted Wave 8 item as a separate migration and verification
  plan; do not combine these migrations with UI closure PRs.

## Verification

Commands to run from this fresh `main` worktree:

```bash
git diff --check
/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos
/Users/chauhua/development/flutter/bin/flutter test \
  test/quick_action_executor_params_test.dart \
  test/quick_action_store_service_test.dart \
  test/quick_action_filter_service_test.dart \
  test/quick_action_icon_render_test.dart \
  test/quick_action_deep_link_entry_contract_test.dart \
  test/quick_action_entry_link_builder_test.dart \
  test/transaction_entry_params_protocol_test.dart \
  test/transaction_entry_widget_regression_test.dart \
  test/transaction_source_banner_contract_test.dart \
  test/category_service_three_level_create_test.dart \
  test/category_grid_picker_three_level_test.dart \
  test/category_manager_three_level_widget_smoke_test.dart \
  test/account_group_service_contract_test.dart \
  test/account_group_summary_header_test.dart \
  test/scene_templates_contract_test.dart \
  test/scene_template_picker_test.dart \
  test/smart_list_service_test.dart \
  test/smart_list_service_regression_test.dart \
  test/object_share_policy_service_test.dart \
  test/transaction_share_hint_banner_test.dart \
  test/shared_ledger_limit_policy_test.dart \
  test/shared_ledger_service_test.dart \
  test/moneythings_alignment_services_test.dart \
  test/widget_data_service_test.dart
```

Results:

- `git diff --check`: passed.
- Restricted path check: passed; only `docs/` files were changed.
- `flutter analyze --no-fatal-infos`: passed with existing repo info-level
  analyzer findings.
- MoneyThings closure focused tests: passed, 137 tests.

## Manual Smoke Checklist

Run on a real device or simulator before external beta:

1. One-tap breakfast quick action saves directly.
2. Lunch quick action opens confirm mode, accepts amount, and saves.
3. Complex transfer or incomplete external entry opens the structured editor
   with source banner and highlighted missing fields.
4. Third-level category can be created from a second-level category and saved
   on a transaction while old two-level categories still behave normally.
5. Account group display shows grouped paths while transactions still save a
   concrete account.
6. Shared-scene transaction shows the shared visibility hint and blocks private
   account usage when required.
7. Bill list restores the default SmartList and clears stale defaults after
   deletion.
8. Widget default quick-add opens structured transaction entry.
9. Configured widget quick action opens `jive://quick-action?id=...`.
10. Deep Link and Shortcuts/AppIntent entries reach the same execution path as
    in-app quick actions.
