# SaaS Staging Sync Smoke Dev & Verify

Date: 2026-04-21 23:01 CST
Branch: `codex/saas-staging-sync-smoke`
Base commit: `f31061f`

## Goal

Close the next deployment-testing gap after staging APK/device smoke: verify that staging Supabase can accept and return a transaction-shaped sync payload for a real authenticated staging user.

This is intentionally not a full app two-device sync test. It is a remote schema/RLS smoke that validates the highest-risk backend pieces needed by the app sync engine:

- auth user creation and email/password sign-in
- user JWT RLS insert into `transactions`
- second-session pull by stable `sync_key`
- required `book_key` boundary
- `deleted_at` tombstone update
- cleanup of temporary staging data

## Development Changes

Added `scripts/run_saas_staging_sync_smoke.sh`.

The script:

- reads `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_SERVICE_ROLE_KEY` from a staging env file
- creates a temporary email-confirmed auth user through the Supabase Admin API
- signs in twice through anon auth to simulate two client sessions
- inserts one transaction-shaped sync payload through the first user JWT
- pulls the same row through the second user JWT
- verifies `sync_key`, `book_key`, and amount
- updates `deleted_at` through the user JWT to validate tombstone writes
- deletes the test transaction and temporary user by default
- writes only redacted artifacts; it does not print or persist Supabase keys/tokens

Supported options:

- `--env-file <path>`
- `--out-dir <path>`
- `--keep-user`
- `--skip-cleanup`
- `--python <path>`

## Staging Validation

Command:

```bash
scripts/run_saas_staging_sync_smoke.sh \
  --env-file /tmp/jive-saas-staging.env \
  --out-dir /tmp/jive-saas-sync-smoke-20260421
```

Result: `PASS`

Artifact summary:

- summary: `/tmp/jive-saas-sync-smoke-20260421/summary.md`
- metadata: `/tmp/jive-saas-sync-smoke-20260421/metadata.json`
- created user: `/tmp/jive-saas-sync-smoke-20260421/create-user.redacted.json`
- sessions: `/tmp/jive-saas-sync-smoke-20260421/sessions.redacted.json`
- inserted row: `/tmp/jive-saas-sync-smoke-20260421/inserted-transaction.redacted.json`
- pulled row: `/tmp/jive-saas-sync-smoke-20260421/pulled-transaction.redacted.json`
- tombstoned row: `/tmp/jive-saas-sync-smoke-20260421/tombstoned-transaction.redacted.json`

Validated stages:

- `admin_user_create`
- `anon_password_sign_in_session_1`
- `anon_password_sign_in_session_2`
- `rls_insert_transaction`
- `second_session_pull_by_sync_key`
- `rls_tombstone_update`
- `cleanup`

Staging row identity:

- `bookKey`: `book_default`
- `syncKey`: `jive_sync_smoke_tx_20260421150044_7z695sln`
- cleanup: `complete`

## Secret Safety Check

Ran a local artifact scan for common Supabase/JWT/token markers:

```bash
rg -n "eyJ|sbp_|SUPABASE|SERVICE_ROLE|ANON|access_token|refresh_token|password|Bearer|apikey" /tmp/jive-saas-sync-smoke-20260421 || true
```

No secret values were found in generated artifacts. The only matches were harmless validation labels containing the word `anon`.

## Local Validation

Passed:

```bash
chmod +x scripts/run_saas_staging_sync_smoke.sh
bash -n scripts/run_saas_staging_sync_smoke.sh
scripts/run_saas_staging_sync_smoke.sh --help
git diff --check
```

Not run:

- `flutter analyze`
- `flutter test`

Reason: this PR adds a shell/Python staging smoke wrapper and documentation only; it does not change Dart, Flutter build inputs, Android/iOS app code, or Supabase migrations.

## Limitations

This smoke validates the remote sync contract, not full app sync UX. It does not:

- drive the Flutter app UI
- create local Isar rows
- verify a second physical device
- test accounts/categories/budgets tables
- exercise the app-side entitlement gate; real App sync still requires a `subscriber` user because cloud sync is gated by tier

## Risk Notes

The smoke confirms the current remote path is deployable, but two sync design risks remain worth tracking:

- `sync_key` is now the intended stable upsert key, while legacy `unique(user_id, local_id)` constraints still exist. Cross-device rows can change local Isar IDs, so future app-side tests should verify that repeat push/pull cycles do not collide with old local IDs.
- Sync cursors are still client-time based in the app. A future hardening pass should consider advancing cursors from the max observed remote `updated_at` or another server-time source.

## Follow-Up

Recommended next deployment-testing step:

- Add an app-side staging sync runbook once a reusable staging test account and device interaction path are available.
- Extend this smoke to accounts/budgets after the transactions path remains stable across one more staging run.
