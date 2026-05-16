# MoneyThings Full Closure TODO Development And Verification

Date: 2026-05-14
Last updated: 2026-05-16
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
- Updated the TODO after Wave 0 ready queue execution to mark `#269`, `#271`,
  `#272`, `#273`, `#275`, `#276`, `#278`, `#281`, `#282`, `#288`, `#289`,
  `#291`, `#294`, `#295`, `#297`, `#298`, `#300`, `#301`, `#303`, `#304`,
  `#305`, `#308`, `#309`, `#310`, `#311`, `#312`, and `#313` as merged.
- Updated the TODO after Wave 0 draft/stacked queue execution to mark `#220`,
  `#222`, `#223`, `#225`, `#227`, `#229`, `#230`, `#232`, `#233`, `#235`,
  `#236`, `#237`, `#240`, `#241`, `#243`, `#244`, `#246`, `#248`, `#249`,
  `#251`, `#255`, `#256`, `#257`, `#259`, `#260`, `#262`, `#264`, `#265`,
  and `#268` as merged.
- Recorded `#266` as closed and superseded by merged transaction entry protocol
  coverage instead of claiming it was merged.
- Recorded final Wave 0 evidence from the latest successful `main` Flutter CI
  run at `4109c589` (run `25958116674`).

## Verification

Commands run:

```sh
git status --short --branch
git diff --check
gh pr list --repo zensgit/jive --state open --json number,headRefName,title
gh pr view <number> --repo zensgit/jive --json number,state,mergedAt,mergeCommit,headRefName
gh run list --repo zensgit/jive --branch main --limit 10 --json databaseId,status,conclusion,headSha,createdAt,updatedAt,name
```

Expected result:

- The branch contains documentation-only changes.
- No whitespace errors are reported.
- No restricted directories are modified.
- The open MoneyThings PR queue is empty after Wave 0 cleanup.
- The latest `main` Flutter CI run succeeds at the last MoneyThings cleanup
  merge commit.

Additional execution notes:

- `flutter` is not available in the local shell PATH, so Flutter tests were not
  run locally from this documentation branch.
- The ready PRs were individually rebased or verified against fresh `main`,
  pushed with `--force-with-lease` where needed, and merged via GitHub.
- The draft and stacked PRs were merged or closed as superseded via GitHub.
- The latest `main` GitHub Actions run is the final Wave 0 CI signal after the
  last draft/stacked cleanup merge: Flutter CI run `25958116674`, head
  `4109c589495df533754db708fcbd8eca7fca4432`, conclusion `success`.

## Follow-Up Execution Notes

- Wave 0 is closed as of 2026-05-16.
- Wave 1-7 checklist items remain product execution items and should be
  calibrated against code before being marked complete.
- Wave 8 must remain a separate migration and permission design gate.
