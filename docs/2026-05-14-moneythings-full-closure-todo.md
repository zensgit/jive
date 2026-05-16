# Jive MoneyThings Full Closure TODO

Date: 2026-05-14
Last updated: 2026-05-16
Baseline: `origin/main`
Branch: `codex/moneythings-full-closure-todo-20260514`

## Goal

Complete the Jive-adapted MoneyThings borrowing plan in phases: first merge
already-clean work, then close product loops, and only then evaluate risky data
model, sync, and permission migrations.

This TODO is the execution checklist for the full closure plan. It intentionally
keeps the first seven waves migration-free and treats Wave 8 as a separate
design gate.

## Guardrails

- [x] Keep the dirty primary worktree untouched.
- [x] Use fresh `origin/main` worktrees for all follow-up implementation work.
- [x] Do not change `supabase/migrations` before Wave 8.
- [x] Do not change `lib/core/sync` before Wave 8.
- [x] Do not change `.github/workflows` in MoneyThings closure PRs.
- [x] Do not change SaaS entitlement, payment, or sync truth logic in these PRs.
- [x] Default category UX remains two-level; third-level categories are opt-in.
- [x] Merchant support remains lightweight memory/search, not a complex merchant
      master-data system.
- [x] Object sharing remains a visibility and warning layer until the Wave 8
      permission gate.

## Wave 0: Merge Queue Closure

Status: ready clean PR queue completed on 2026-05-14. Draft and stacked PR
cleanup completed on 2026-05-16. `#266` was closed as superseded; all other
listed draft/stacked PRs were merged into `main`.

### Ready clean PRs to merge

- [x] Merge `#269` Preserve quick action editor params.
- [x] Merge `#271` Scene template contract tests.
- [x] Merge `#272` Scene template picker test.
- [x] Merge `#273` Deep link entry contract tests.
- [x] Merge `#275` Account group contract tests.
- [x] Merge `#276` Source banner contract tests.
- [x] Merge `#278` Transaction footer contract tests.
- [x] Merge `#281` Three-level category grid picker support.
- [x] Merge `#282` Account group UI contract.
- [x] Merge `#288` Scene candidates in transaction entry.
- [x] Merge `#289` Category third-level widget smoke.
- [x] Merge `#291` Third-level categories opt-in.
- [x] Merge `#294` Quick action entry link builder.
- [x] Merge `#295` Grouped account paths in filters.
- [x] Merge `#297` Shared transaction hint banner.
- [x] Merge `#298` Default bank asset groups to bank name.
- [x] Merge `#300` Account paths in report exports.
- [x] Merge `#301` Account paths in transaction details.
- [x] Merge `#303` MoneyThings TODO status calibration.
- [x] Merge `#304` Account paths in CSV exports.
- [x] Merge `#305` Account paths in capital flow.
- [x] Merge `#308` Account paths in credit analysis.
- [x] Merge `#309` Account paths in Excel exports.
- [x] Merge `#310` Speech account path aliases.
- [x] Merge `#311` Account paths in currency overview.
- [x] Merge `#312` Account paths in recurring rules.
- [x] Merge `#313` Account paths in investments.

### Draft or stacked PRs to restack or supersede

- [x] Merge `#220` Persistent quick action store.
- [x] Merge `#222` Quick action management.
- [x] Merge `#223` Quick action drag ordering.
- [x] Merge `#225` Quick action custom icons.
- [x] Merge `#227` Quick action search.
- [x] Merge `#229` Add-entry quick action save.
- [x] Merge `#230` Quick action core editing.
- [x] Merge `#232` Account group collapse.
- [x] Merge `#233` Quick action edit validation.
- [x] Merge `#235` Grouped account paths in pickers.
- [x] Merge `#236` Category share warnings.
- [x] Merge `#237` Tag share warnings.
- [x] Merge `#240` Grouped account paths in filters.
- [x] Merge `#241` Tag archive warnings.
- [x] Merge `#243` Tag merge warnings.
- [x] Merge `#244` Grouped account paths in automation.
- [x] Merge `#246` Shared account edit warnings.
- [x] Merge `#248` SmartList regression tests.
- [x] Merge `#249` Object share policy tests.
- [x] Merge `#251` Shared scene transaction warning.
- [x] Merge `#255` Form book context for structured entries.
- [x] Merge `#256` SmartList regression coverage.
- [x] Merge `#257` Transaction deep link source coverage.
- [x] Resolve and merge `#259` hidden parent category path conflicts; merge only
      if the final diff stays limited to category path preservation.
- [x] Merge `#260` Account group display path dedupe.
- [x] Merge `#262` Stale SmartList default cleanup.
- [x] Merge `#264` Category import path segments.
- [x] Merge `#265` Category share preview paths.
- [x] Close `#266` Transaction entry protocol tests as superseded by merged
      transaction entry protocol coverage.
- [x] Merge `#268` Shared-ledger object share boundary.

### Wave 0 acceptance

- [x] All ready clean PRs are merged or explicitly superseded.
- [x] All draft/stacked PRs are either restacked on fresh `main`, superseded, or
      documented as deferred.
- [x] Fresh `main` passes GitHub Flutter CI analyze/test at
      `main@4109c589` (run `25958116674`).
- [x] Fresh `main` passes the merged MoneyThings-related test set through the
      same GitHub Flutter CI run.

Local note: Flutter is not available in the shell PATH for this agent session,
so final Wave 0 analyzer/test evidence is the GitHub `main` Flutter CI run.

## Wave 1: One Touch / Quick Action Closure

- [x] Make `QuickActionExecutor` the only app-level quick-entry executor.
- [x] Route templates, quick-entry hub, AppIntent, and Deep Link
      through `QuickActionExecutor`.
- [x] Preserve direct, confirm, and edit execution modes.
- [x] Add or finish "save as quick action" after successful manual transaction
      save.
- [x] Complete quick action search.
- [x] Complete quick action drag ordering.
- [x] Complete quick action custom icons.
- [x] Complete quick action edit validation.
- [x] Complete quick action usage statistics and recommendation surfaces.
- [x] Keep template compatibility until the high-risk persistence gate decides
      whether a standalone synced quick-action store is needed.
- [x] Add tests for direct, confirm, edit, save-as-action, usage count,
      `lastUsedAt`, Deep Link, and AppIntent routing.

Status note: Android's current home widget quick-add uses the shared
`jive://transaction/new` structured-editor path. A future widget that exposes
saved quick actions should reuse `jive://quick-action?id=...`.

## Wave 2: Transaction Editor Unified Entry

- [x] Ensure voice, screenshot, share, Deep Link, Widget, Quick Action, and auto
      draft entries all construct `TransactionEntryParams`.
- [x] Ensure incomplete external entries open `TransactionFormScreen` instead of
      silently attempting a save.
- [x] Keep `AddTransactionScreen` as the high-frequency calculator-first manual
      entry page.
- [x] Keep `TransactionFormScreen` as the structured editor for external,
      incomplete, or complex entries.
- [x] Support source banners for quick action, voice, screenshot, share, deep
      link, widget, and auto draft.
- [x] Support `highlightFields` for amount, category, account,
      transferAccount, time, note, and tags.
- [x] Preserve continuous-entry behavior, existing save semantics, and test
      anchors.

## Wave 3: Three-Level Category Completion

- [x] Keep default category creation and entry UX at two levels.
- [x] Allow third-level creation only when the user chooses "add child" from an
      existing second-level category.
- [x] Store transactions compatibly: top-level in `categoryKey`, selected leaf
      in `subCategoryKey`.
- [x] Use `CategoryPathService` for transaction detail category paths.
- [x] Use `CategoryPathService` for filters and reports.
- [x] Use `CategoryPathService` for CSV and Excel export category paths.
- [x] Use `CategoryPathService` for import path segments.
- [x] Use `CategoryPathService` for template and quick-action category labels.
- [x] Use `CategoryPathService` for category share previews.
- [x] Cover old two-level categories, new three-level categories, hidden parent
      paths, import/export, reports, and transaction detail display in tests.

## Wave 4: Account Group / Subaccount View Completion

- [x] Keep transactions saving to concrete `JiveAccount.id`.
- [x] Use `AccountGroupService` in account picker labels.
- [x] Use `AccountGroupService` in account filters.
- [x] Use `AccountGroupService` in transaction details.
- [x] Use `AccountGroupService` in report exports.
- [x] Use `AccountGroupService` in CSV and Excel exports.
- [x] Use `AccountGroupService` in capital flow and credit analysis.
- [x] Use `AccountGroupService` in multi-currency overview.
- [x] Use `AccountGroupService` in recurring rules.
- [x] Use `AccountGroupService` in investments.
- [x] Use `AccountGroupService` in speech and automation candidates.
- [x] Add account templates for bank multi-currency, credit card, Huabei,
      Baitiao, meal card, transit card, and ETC.
- [x] Add tests for grouped display, concrete-account transaction save,
      multi-currency display, exports, speech alias resolution, and recurring
      rules.

## Wave 5: Scene And SmartList Productization

- [x] Add a home scene switcher that wraps the current book-switching behavior.
- [x] Keep the underlying data model as `JiveBook` during this phase.
- [x] Add guided setup scene templates: Daily, Travel, Family, Pet, Renovation,
      and Freelance.
- [x] Applying a scene template creates or suggests default categories, tags,
      accounts, and budget suggestions.
- [x] Use `SceneCandidateService` to prioritize transaction-entry category and
      account candidates.
- [x] Make scene context affect list filters, stats, and candidate ordering.
- [x] Support saving current bill-list filters as a SmartList.
- [x] Support pinning SmartLists.
- [x] Support setting one SmartList as the default bill-list view.
- [x] Restore the default SmartList when entering the bill list.
- [x] Clear stale default SmartLists when the referenced view is removed.
- [x] Cover travel scene initialization, scene switching, candidate ordering,
      saved-current-filter, pinning, default restoration, and stale cleanup in
      tests.

## Wave 6: Object Sharing Hints And Family Limits

- [x] Keep shared ledger/book as the only permission truth in this phase.
- [x] Use `ObjectSharePolicyService` to label accounts as private, inherited
      shared, or shared.
- [x] Use `ObjectSharePolicyService` to label categories as private, inherited
      shared, or shared.
- [x] Use `ObjectSharePolicyService` to label tags as private, inherited shared,
      or shared.
- [x] Use `ObjectSharePolicyService` to label scenes/books as private or shared.
- [x] Show a shared-transaction hint when creating transactions in shared scenes.
- [x] Warn or block when a private account is used in a shared-scene
      transaction.
- [x] Warn before editing or deleting shared accounts.
- [x] Warn before editing or deleting shared categories.
- [x] Warn before archiving or merging shared tags.
- [ ] Implement Free/Pro/Family shared-ledger entry states, member limits, and
      ledger limits from `SPRINT_DESIGN_AND_VALIDATION.md`.
- [ ] Cover labels, warnings, private-object blocking, and tier-limit messaging
      in tests.

## Wave 7: System-Level Entry Linkage

- [x] Fix URL scheme contract for `jive://quick-action`.
- [x] Fix URL scheme contract for `jive://transaction/new`.
- [x] Fix URL scheme contract for `jive://scene/switch`.
- [x] Ensure Deep Link entries include source metadata and missing-field
      highlights.
- [ ] Ensure Widget actions use the same quick-action execution path as in-app
      actions.
- [x] Ensure AppIntent/Shortcuts actions use the same quick-action execution
      path as in-app actions.
- [x] Add real-device smoke notes for Widget, Shortcuts/AppIntent, and Deep Link.
- [x] Cover system entry contracts in tests where local automation is possible.

Status note: Android widget quick-add currently opens `jive://transaction/new`
with a widget source label. The remaining widget-specific item is only for a
future widget surface that exposes saved quick actions directly.

## Wave 8: High-Risk Migration Gate

Only start this wave after Waves 0-7 are merged and verified on fresh `main`.

- [ ] Decide whether quick actions need first-class synced persistence beyond
      the current compatibility layer.
- [ ] If needed, design QuickAction sync and migration separately.
- [ ] Decide whether account groups need `parentAccountKey`.
- [ ] If needed, design parent-account migration, import/export, statistics, and
      sync changes separately.
- [ ] Decide whether object-level sharing needs server-side tables and RLS.
- [ ] If needed, design object sharing tables, permissions, offline conflict
      handling, audit logs, and sync semantics separately.
- [ ] Do not combine Wave 8 migrations with UI closure PRs.

## Final Acceptance

- [ ] All non-risky MoneyThings borrowing features are merged into `main`.
- [ ] Fresh `main` passes `flutter analyze --no-fatal-infos`.
- [ ] Fresh `main` passes MoneyThings closure unit/widget tests.
- [ ] Manual smoke passes: one-tap breakfast, lunch confirm, complex transfer
      editor fallback, third-level category save, account group display, shared
      transaction warning, SmartList default restore, Widget/Deep Link entry.
- [ ] A final development and verification document summarizes implemented
      features, remaining Wave 8 decisions, and validation evidence.
