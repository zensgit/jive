# MoneyThings Wave 8 Decision Gate

Date: 2026-05-18

Branch: `codex/moneythings-smoke-wave8-gate`

Base: `origin/main@db294304`

## Purpose

Wave 8 is intentionally separate from the MoneyThings UI/product closure. It
covers changes that may alter persistence, sync, server permissions, or
cross-device conflict semantics. Those changes require explicit design review,
migration plans, and rollback plans before implementation.

## Non-Goals

- Do not add migrations in a UI closure PR.
- Do not change `lib/core/sync` as a side effect of product polish.
- Do not add object-level RLS while shared-ledger/book remains the permission
  truth.
- Do not change SaaS entitlement, payment, or subscription truth as part of
  MoneyThings borrowing work.

## Decision Matrix

| Topic | Current Safe State | Enter Wave 8 Only If | Required Design Output |
| --- | --- | --- | --- |
| QuickAction synced persistence | `JiveQuickAction` and template compatibility support local quick actions and system entry routing. | Users need cross-device quick-action ordering, widget shortcut sync, or shared quick actions that cannot be expressed by compatibility storage. | Sync model, conflict rules, stable ids, ordering semantics, migration, import/export, rollback. |
| Parent account relationship | `AccountGroupService` uses view-layer grouping from existing account fields while transactions save concrete account ids. | `groupName` cannot express stable parent-child relationships, nested balances, cross-device hierarchy edits, or import/export identity. | `parentAccountKey` schema, migration, sync protocol, statistics impact, import/export mapping, rollback. |
| Object-level sharing | `ObjectSharePolicyService` shows visibility and risk hints while shared ledger/book remains permission truth. | Users need sharing a category/account/tag without sharing the whole scene/book, or need per-object audit and revocation. | Server tables, RLS, role model, offline edits, conflict resolution, audit log, UX recovery, rollback. |

## Required Readiness Checks

Before any Wave 8 implementation PR:

- Fresh `main` passes `flutter analyze --no-fatal-infos`.
- MoneyThings closure focused tests pass.
- Pre-beta manual smoke has run on the target platform for the affected area.
- Migration plan includes forward migration, rollback or mitigation, and
  existing-data compatibility.
- Sync plan covers offline creation, update, delete, conflict resolution, and
  tombstone behavior where relevant.
- Permission plan identifies the single source of truth and how clients recover
  from stale permissions.
- Product copy clearly distinguishes private, inherited, and shared states.

## Recommended Order

1. Decide QuickAction synced persistence first if users expect widget and
   shortcut setups to roam across devices.
2. Decide `parentAccountKey` second if account group view-layer behavior is not
   enough for balance and import/export requirements.
3. Decide object-level sharing last, after SaaS sync and shared-ledger
   permission behavior are stable under real beta usage.

## Stop Conditions

Stop and open a design review instead of coding when:

- A change requires modifying `supabase/migrations`.
- A change requires modifying `lib/core/sync`.
- A change requires new RLS or server-side authorization truth.
- A change changes exported data semantics.
- A change makes existing local data ambiguous without a migration path.

## Initial Recommendation

Do not start Wave 8 implementation yet. The current Jive-adapted MoneyThings
surface is complete enough for pre-beta validation without changing data or
permission semantics. Use beta evidence from manual smoke and real user
feedback to decide which, if any, Wave 8 track should proceed.
