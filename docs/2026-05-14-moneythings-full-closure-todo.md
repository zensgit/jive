# Jive MoneyThings Full Closure TODO

Date: 2026-05-14
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

- [ ] Keep the dirty primary worktree untouched.
- [ ] Use fresh `origin/main` worktrees for all follow-up implementation work.
- [ ] Do not change `supabase/migrations` before Wave 8.
- [ ] Do not change `lib/core/sync` before Wave 8.
- [ ] Do not change `.github/workflows` in MoneyThings closure PRs.
- [ ] Do not change SaaS entitlement, payment, or sync truth logic in these PRs.
- [ ] Default category UX remains two-level; third-level categories are opt-in.
- [ ] Merchant support remains lightweight memory/search, not a complex merchant
      master-data system.
- [ ] Object sharing remains a visibility and warning layer until the Wave 8
      permission gate.

## Wave 0: Merge Queue Closure

### Ready clean PRs to merge

- [ ] Merge `#269` Preserve quick action editor params.
- [ ] Merge `#271` Scene template contract tests.
- [ ] Merge `#272` Scene template picker test.
- [ ] Merge `#273` Deep link entry contract tests.
- [ ] Merge `#275` Account group contract tests.
- [ ] Merge `#276` Source banner contract tests.
- [ ] Merge `#278` Transaction footer contract tests.
- [ ] Merge `#281` Three-level category grid picker support.
- [ ] Merge `#282` Account group UI contract.
- [ ] Merge `#288` Scene candidates in transaction entry.
- [ ] Merge `#289` Category third-level widget smoke.
- [ ] Merge `#291` Third-level categories opt-in.
- [ ] Merge `#294` Quick action entry link builder.
- [ ] Merge `#295` Grouped account paths in filters.
- [ ] Merge `#297` Shared transaction hint banner.
- [ ] Merge `#298` Default bank asset groups to bank name.
- [ ] Merge `#300` Account paths in report exports.
- [ ] Merge `#301` Account paths in transaction details.
- [ ] Merge `#303` MoneyThings TODO status calibration.
- [ ] Merge `#304` Account paths in CSV exports.
- [ ] Merge `#305` Account paths in capital flow.
- [ ] Merge `#308` Account paths in credit analysis.
- [ ] Merge `#309` Account paths in Excel exports.
- [ ] Merge `#310` Speech account path aliases.
- [ ] Merge `#311` Account paths in currency overview.
- [ ] Merge `#312` Account paths in recurring rules.
- [ ] Merge `#313` Account paths in investments.

### Draft or stacked PRs to restack or supersede

- [ ] Restack or supersede `#220` Persistent quick action store.
- [ ] Restack or supersede `#222` Quick action management.
- [ ] Restack or supersede `#223` Quick action drag ordering.
- [ ] Restack or supersede `#225` Quick action custom icons.
- [ ] Restack or supersede `#227` Quick action search.
- [ ] Restack or supersede `#229` Add-entry quick action save.
- [ ] Restack or supersede `#230` Quick action core editing.
- [ ] Restack or supersede `#232` Account group collapse.
- [ ] Restack or supersede `#233` Quick action edit validation.
- [ ] Restack or supersede `#235` Grouped account paths in pickers.
- [ ] Restack or supersede `#236` Category share warnings.
- [ ] Restack or supersede `#237` Tag share warnings.
- [ ] Restack or supersede `#240` Grouped account paths in filters.
- [ ] Restack or supersede `#241` Tag archive warnings.
- [ ] Restack or supersede `#243` Tag merge warnings.
- [ ] Restack or supersede `#244` Grouped account paths in automation.
- [ ] Restack or supersede `#246` Shared account edit warnings.
- [ ] Restack or supersede `#248` SmartList regression tests.
- [ ] Restack or supersede `#249` Object share policy tests.
- [ ] Restack or supersede `#251` Shared scene transaction warning.
- [ ] Restack or supersede `#255` Form book context for structured entries.
- [ ] Restack or supersede `#256` SmartList regression coverage.
- [ ] Restack or supersede `#257` Transaction deep link source coverage.
- [ ] Resolve `#259` hidden parent category path conflicts; merge only if the
      final diff stays limited to category path preservation.
- [ ] Restack or supersede `#260` Account group display path dedupe.
- [ ] Restack or supersede `#262` Stale SmartList default cleanup.
- [ ] Restack or supersede `#264` Category import path segments.
- [ ] Restack or supersede `#265` Category share preview paths.
- [ ] Restack or supersede `#266` Transaction entry protocol tests.
- [ ] Restack or supersede `#268` Shared-ledger object share boundary.

### Wave 0 acceptance

- [ ] All ready clean PRs are merged or explicitly superseded.
- [ ] All draft/stacked PRs are either restacked on fresh `main`, superseded, or
      documented as deferred.
- [ ] Fresh `main` passes `flutter analyze --no-fatal-infos`.
- [ ] Fresh `main` passes the merged MoneyThings-related test set.

## Wave 1: One Touch / Quick Action Closure

- [ ] Make `QuickActionExecutor` the only app-level quick-entry executor.
- [ ] Route templates, quick-entry hub, Widget bridge, AppIntent, and Deep Link
      through `QuickActionExecutor`.
- [ ] Preserve direct, confirm, and edit execution modes.
- [ ] Add or finish "save as quick action" after successful manual transaction
      save.
- [ ] Complete quick action search.
- [ ] Complete quick action drag ordering.
- [ ] Complete quick action custom icons.
- [ ] Complete quick action edit validation.
- [ ] Complete quick action usage statistics and recommendation surfaces.
- [ ] Keep template compatibility until the high-risk persistence gate decides
      whether a standalone synced quick-action store is needed.
- [ ] Add tests for direct, confirm, edit, save-as-action, usage count,
      `lastUsedAt`, Widget, Deep Link, and AppIntent routing.

## Wave 2: Transaction Editor Unified Entry

- [ ] Ensure voice, screenshot, share, Deep Link, Widget, Quick Action, and auto
      draft entries all construct `TransactionEntryParams`.
- [ ] Ensure incomplete external entries open `TransactionFormScreen` instead of
      silently attempting a save.
- [ ] Keep `AddTransactionScreen` as the high-frequency calculator-first manual
      entry page.
- [ ] Keep `TransactionFormScreen` as the structured editor for external,
      incomplete, or complex entries.
- [ ] Support source banners for quick action, voice, screenshot, share, deep
      link, widget, and auto draft.
- [ ] Support `highlightFields` for amount, category, account,
      transferAccount, time, note, and tags.
- [ ] Preserve continuous-entry behavior, existing save semantics, and test
      anchors.

## Wave 3: Three-Level Category Completion

- [ ] Keep default category creation and entry UX at two levels.
- [ ] Allow third-level creation only when the user chooses "add child" from an
      existing second-level category.
- [ ] Store transactions compatibly: top-level in `categoryKey`, selected leaf
      in `subCategoryKey`.
- [ ] Use `CategoryPathService` for transaction detail category paths.
- [ ] Use `CategoryPathService` for filters and reports.
- [ ] Use `CategoryPathService` for CSV and Excel export category paths.
- [ ] Use `CategoryPathService` for import path segments.
- [ ] Use `CategoryPathService` for template and quick-action category labels.
- [ ] Use `CategoryPathService` for category share previews.
- [ ] Cover old two-level categories, new three-level categories, hidden parent
      paths, import/export, reports, and transaction detail display in tests.

## Wave 4: Account Group / Subaccount View Completion

- [ ] Keep transactions saving to concrete `JiveAccount.id`.
- [ ] Use `AccountGroupService` in account picker labels.
- [ ] Use `AccountGroupService` in account filters.
- [ ] Use `AccountGroupService` in transaction details.
- [ ] Use `AccountGroupService` in report exports.
- [ ] Use `AccountGroupService` in CSV and Excel exports.
- [ ] Use `AccountGroupService` in capital flow and credit analysis.
- [ ] Use `AccountGroupService` in multi-currency overview.
- [ ] Use `AccountGroupService` in recurring rules.
- [ ] Use `AccountGroupService` in investments.
- [ ] Use `AccountGroupService` in speech and automation candidates.
- [ ] Add account templates for bank multi-currency, credit card, Huabei,
      Baitiao, meal card, transit card, and ETC.
- [ ] Add tests for grouped display, concrete-account transaction save,
      multi-currency display, exports, speech alias resolution, and recurring
      rules.

## Wave 5: Scene And SmartList Productization

- [ ] Add a home scene switcher that wraps the current book-switching behavior.
- [ ] Keep the underlying data model as `JiveBook` during this phase.
- [ ] Add guided setup scene templates: Daily, Travel, Family, Pet, Renovation,
      and Freelance.
- [ ] Applying a scene template creates or suggests default categories, tags,
      accounts, and budget suggestions.
- [ ] Use `SceneCandidateService` to prioritize transaction-entry category and
      account candidates.
- [ ] Make scene context affect list filters, stats, and candidate ordering.
- [ ] Support saving current bill-list filters as a SmartList.
- [ ] Support pinning SmartLists.
- [ ] Support setting one SmartList as the default bill-list view.
- [ ] Restore the default SmartList when entering the bill list.
- [ ] Clear stale default SmartLists when the referenced view is removed.
- [ ] Cover travel scene initialization, scene switching, candidate ordering,
      saved-current-filter, pinning, default restoration, and stale cleanup in
      tests.

## Wave 6: Object Sharing Hints And Family Limits

- [ ] Keep shared ledger/book as the only permission truth in this phase.
- [ ] Use `ObjectSharePolicyService` to label accounts as private, inherited
      shared, or shared.
- [ ] Use `ObjectSharePolicyService` to label categories as private, inherited
      shared, or shared.
- [ ] Use `ObjectSharePolicyService` to label tags as private, inherited shared,
      or shared.
- [ ] Use `ObjectSharePolicyService` to label scenes/books as private or shared.
- [ ] Show a shared-transaction hint when creating transactions in shared scenes.
- [ ] Warn or block when a private account is used in a shared-scene
      transaction.
- [ ] Warn before editing or deleting shared accounts.
- [ ] Warn before editing or deleting shared categories.
- [ ] Warn before archiving or merging shared tags.
- [ ] Implement Free/Pro/Family shared-ledger entry states, member limits, and
      ledger limits from `SPRINT_DESIGN_AND_VALIDATION.md`.
- [ ] Cover labels, warnings, private-object blocking, and tier-limit messaging
      in tests.

## Wave 7: System-Level Entry Linkage

- [ ] Fix URL scheme contract for `jive://quick-action`.
- [ ] Fix URL scheme contract for `jive://transaction/new`.
- [ ] Fix URL scheme contract for `jive://scene/switch`.
- [ ] Ensure Deep Link entries include source metadata and missing-field
      highlights.
- [ ] Ensure Widget actions use the same quick-action execution path as in-app
      actions.
- [ ] Ensure AppIntent/Shortcuts actions use the same quick-action execution
      path as in-app actions.
- [ ] Add real-device smoke notes for Widget, Shortcuts/AppIntent, and Deep Link.
- [ ] Cover system entry contracts in tests where local automation is possible.

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
