# SaaS Legacy PR Cleanup Dev Verify

Date: 2026-05-18

Branch: `codex/saas-legacy-pr-cleanup-docs`

Base: `main@10228185` remotely; local branch created from the already-merged
`#322` head because local `git fetch` was intermittently failing against
GitHub HTTP transport.

## Scope

This documentation slice records the final cleanup of legacy SaaS PRs that
remained open after the `#144` SaaS Beta mainline merge.

No runtime app code, migrations, sync internals, SaaS entitlement/payment/sync
logic, Supabase functions, or GitHub workflow files were changed.

## GitHub Cleanup Performed

`#144` is the canonical SaaS Beta mainline merge:

- PR: https://github.com/zensgit/jive/pull/144
- Merged at: 2026-04-10
- Merge commit: `6ea8b06669b25ef052f21483eec142c79387ecd5`

The following legacy PRs were commented and closed as superseded by `#144` and
the current mainline closure:

- `#125`
- `#126`
- `#130`
- `#131`
- `#132`
- `#133`
- `#135`
- `#137`
- `#138`
- `#140`
- `#141`

Clarification comments were added after closure to preserve audit context and
avoid shell-rendering ambiguity from the first comment batch.

## Verification

Commands run:

```bash
gh pr view 144 --repo zensgit/jive --json number,state,mergedAt,mergeCommit,title,url
gh pr list --repo zensgit/jive --state open --json number,title,isDraft,headRefName,baseRefName,updatedAt,url --limit 100
gh api repos/zensgit/jive/branches/main --jq .commit.sha
gh run list --repo zensgit/jive --branch main --limit 3 --json databaseId,headSha,status,conclusion,name,createdAt,updatedAt
```

Results:

- `#144`: merged.
- Current remote `main`: `10228185aff3d9f383b15421733c49aad542a734`.
- Latest `main` Flutter CI: success.
- Open PR queue after cleanup: `[]`.

## Follow-Up Rule

- Do not reopen or merge the closed legacy SaaS stack PRs.
- Treat those PRs as historical audit/review material.
- Any new SaaS work must branch fresh from `main`, include scoped design and
  verification notes, and avoid mixing unrelated deferred work.
