# MoneyThings Full Closure TODO Development And Verification

Date: 2026-05-14
Branch: `codex/moneythings-full-closure-todo-20260514`

## Development

- Added `docs/2026-05-14-moneythings-full-closure-todo.md` as the execution
  checklist for the full Jive-adapted MoneyThings closure plan.
- Converted the plan into eight waves with explicit acceptance criteria:
  merge queue closure, One Touch, transaction editor, category paths, account
  groups, scenes and SmartLists, sharing hints and family limits, system entry
  linkage, and high-risk migration gates.
- Captured the current known ready PR merge queue and draft/stacked PR cleanup
  queue so future work can proceed without reopening old design debates.
- Preserved guardrails that keep this phase away from migrations, sync internals,
  GitHub workflows, and SaaS entitlement/payment/sync truth logic.

## Verification

Commands run:

```sh
git status --short --branch
git diff --check
```

Expected result:

- The branch contains documentation-only changes.
- No whitespace errors are reported.
- No restricted directories are modified.

## Follow-Up Execution Notes

- Wave 0 should start by merging or superseding the ready clean PRs listed in
  the TODO file.
- Draft or stacked PRs should be restacked onto fresh `origin/main` after the
  ready queue has been compressed.
- Wave 8 must remain a separate migration and permission design gate.
