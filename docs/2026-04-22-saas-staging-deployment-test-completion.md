# SaaS Staging Deployment Test Completion

Date: 2026-04-22

Documented: 2026-04-29

Status: complete for staging deployment testing.

## Scope

This report closes the SaaS staging deployment-test lane. It covers the current core SaaS staging path:

- GitHub Actions driven staging readiness.
- Supabase migration preview and apply.
- Supabase Edge Function deployment and smoke checks.
- Core sync push/pull smoke.
- Dev debug staging APK build and artifact guard.
- Android staging APK install/smoke evidence from the same staging lane family.

This is not a production store-release sign-off. Production Google Play billing, Apple production receipt verification, domestic payment production signature verification, notification delivery providers, and release signing remain separate release-readiness items.

## Baselines

- Staging workflow baseline: `main@cede4903a649288373d1359e93ced0e3208c6666`.
- Latest checked main CI after later merges: `main@562d3d92b0bffcae53666a7a8a14d153a4c3fcd6`, Flutter CI run `25116703685`, conclusion `success`.
- Staging APK device-install baseline: `main@8ce14ee7a7aa5bba156520f443af3029a35e3610`.

## GitHub Actions Evidence

| Run | Purpose | Result | Notes |
|---|---|---|---|
| [24786684182](https://github.com/zensgit/jive/actions/runs/24786684182) | Core staging dry run | success | Strict readiness passed; migration preview reported remote DB up to date; apply/deploy/sync/APK intentionally skipped. |
| [24786733056](https://github.com/zensgit/jive/actions/runs/24786733056) | Migration apply | success | Apply path ran; remote DB reported up to date; lane completed. |
| [24786787918](https://github.com/zensgit/jive/actions/runs/24786787918) | Functions deploy + function smoke | success | Deployed `analytics`, `send-notification`, and `admin`; smoke checks passed for auth failures and admin-token success paths. |
| [24786855136](https://github.com/zensgit/jive/actions/runs/24786855136) | Core sync smoke | success | `run_saas_staging_sync_smoke.sh` completed with `PASS`. |
| [24786990813](https://github.com/zensgit/jive/actions/runs/24786990813) | Staging APK build | success | Built `app-dev-debug.apk`; artifact reports uploaded; sensitive artifact guard passed. |
| [24724133714](https://github.com/zensgit/jive/actions/runs/24724133714) | Earlier staging APK build used for device smoke | success | Produced installable staging APK used by device-side validation docs. |

## APK Artifact Evidence

Latest staging APK artifact from run `24786990813`:

- Artifact group: `saas-staging-reports-24786990813`.
- APK path inside artifact: `saas-staging/20260422-152735-dev-debug/app-dev-debug.apk`.
- Report path inside artifact: `reports/saas-staging/saas-staging-build.json`.
- Summary path inside artifact: `reports/saas-staging/latest.md`.
- APK bytes: `253776681`.
- SHA-256: `16aff55dbed7b1cffa9b83467f67930359e4f1fb8746195fdde3d26b4dcecad9`.
- `SUPABASE_URL` configured: yes.
- `SUPABASE_ANON_KEY` configured: yes.
- Service-role key passed to client: no.

Device-smoke APK artifact from run `24724133714`:

- Artifact group: `saas-staging-reports-24724133714`.
- APK path inside artifact: `saas-staging/20260421-130923-dev-debug/app-dev-debug.apk`.
- APK bytes: `253777249`.
- SHA-256: `b9ed5ddc03733a14c65f1a302ecd5450bea3be4779c55772b9855f2d878fa96a`.

## App-Side Smoke Coverage

Covered by existing device validation and staging reports:

- Staging APK is buildable and installable.
- App cold launch completed during device-side smoke.
- Guest/onboarding path remained usable.
- Subscription and sync entry gates were reachable.
- Basic local transaction flow was validated in the staging APK smoke documentation.
- Staging sync smoke verified temporary core rows can be pushed/pulled and cleaned up.

## Intentional Skips

These are not blockers for staging deployment-test completion:

- Google Play production purchase validation.
- Apple production receipt validation.
- Domestic payment production provider signature verification.
- Production release signing and Play Console upload.
- Admin dashboard UI.
- Notification provider delivery outside the staging dry-run/server queue path.
- End-to-end encryption; current sync claims must remain conservative unless a real E2EE implementation is added.

## Follow-Up

Production/release-candidate readiness continues in the separate production gate and release-candidate workflow work:

- PR `#212`: production readiness gate.
- PR `#213`: stacked release-candidate workflow and production release secret helpers.

Recommended merge order:

1. Merge PR `#212`.
2. Rebase or retarget PR `#213` onto `main`.
3. Configure production release secrets.
4. Run `SaaS Release Candidate` first with `build_appbundle=false`.
5. Run strict-signing dry run, then signed production AAB build only when store signing material is ready.

## Conclusion

The staging deployment-test lane is complete for the SaaS core path. The repo has repeatable GitHub Actions evidence for readiness, migration apply, function deployment, function smoke, sync smoke, APK artifact generation, and device-install smoke. Remaining items are production release and store/provider readiness, not blockers for staging deployment-test completion.
