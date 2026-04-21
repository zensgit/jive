# SaaS Staging APK Build Verification

Date: 2026-04-21

## Summary

Built a fresh staging dev-debug APK from current `main` after the SaaS core staging backend was validated.

This run was scoped to artifact generation only:

- Did not apply database migrations.
- Did not deploy Supabase Edge Functions.
- Did not run deployed function smoke.
- Did build and upload a staging APK artifact.

## Source State

- Branch: `main`
- Commit: `8ce14ee7a7aa5bba156520f443af3029a35e3610`
- Previous backend validation report: `docs/2026-04-21-saas-staging-functions-deploy-smoke-dev-verify.md`

## GitHub Actions Run

Run: https://github.com/zensgit/jive/actions/runs/24724133714

Inputs:

```text
run_local_smoke=false
apply_migrations=false
deploy_functions=false
run_function_smoke=false
build_apk=true
```

Result: success

Duration: 7m 46s

## Confirmed Behavior

- Strict readiness passed.
- Main CI was green at `8ce14ee7a7aa5bba156520f443af3029a35e3610`.
- Local Wave0 SaaS smoke was intentionally skipped.
- Migration dry-run reported the remote database was up to date.
- Migration apply was skipped.
- Edge Functions deploy was skipped.
- Deployed function smoke was skipped.
- Dev-debug staging APK was built and uploaded as a workflow artifact.

Relevant log evidence:

```text
[saas-readiness] PASS: main CI is green at 8ce14ee7a7aa5bba156520f443af3029a35e3610: https://github.com/zensgit/jive/actions/runs/24724005636
[saas-readiness] summary: failures=0 warnings=0 profile=core strict=1 online=1 run_smoke=0
[saas-core-lane] skipping local Wave0 SaaS smoke
[saas-core-lane] previewing staging migrations
Remote database is up to date.
[saas-core-lane] skipping migration apply
[saas-core-lane] skipping Edge Functions deploy
[saas-core-lane] skipping deployed Functions smoke
[saas-core-lane] building dev debug staging APK
[saas-staging-build] flavor=dev mode=debug kind=apk
Built build/app/outputs/flutter-apk/app-dev-debug.apk
[saas-staging-build] artifact=/home/runner/work/jive/jive/build/saas-staging/20260421-130923-dev-debug/app-dev-debug.apk
[saas-staging-build] sha256=b9ed5ddc03733a14c65f1a302ecd5450bea3be4779c55772b9855f2d878fa96a
[saas-core-lane] core staging lane completed
```

## Artifact

GitHub artifact:

- Name: `saas-staging-reports-24724133714`
- Artifact ID: `6555500572`
- Artifact URL: https://github.com/zensgit/jive/actions/runs/24724133714/artifacts/6555500572
- Uploaded artifact zip digest: `9227b8dcdb77075594e47f1107c8cf704bacac3bbc1162c3bd235f4887d0d00f`
- Uploaded artifact zip size: `156258195` bytes

Downloaded local artifact path:

```text
/tmp/jive-saas-staging-apk-run-24724133714/saas-staging-reports-24724133714/saas-staging/20260421-130923-dev-debug/app-dev-debug.apk
```

APK metadata from `saas-staging-build.json`:

```json
{
  "generatedAt": "20260421-130923",
  "flavor": "dev",
  "mode": "debug",
  "buildKind": "apk",
  "artifactName": "app-dev-debug.apk",
  "artifactBytes": 253777249,
  "sha256": "b9ed5ddc03733a14c65f1a302ecd5450bea3be4779c55772b9855f2d878fa96a",
  "gitBranch": "main",
  "gitCommit": "8ce14ee7a7aa5bba156520f443af3029a35e3610",
  "supabaseUrlConfigured": true,
  "supabaseAnonKeyConfigured": true,
  "serviceRolePassedToClient": false
}
```

Local checksum verification:

```text
b9ed5ddc03733a14c65f1a302ecd5450bea3be4779c55772b9855f2d878fa96a  /tmp/jive-saas-staging-apk-run-24724133714/saas-staging-reports-24724133714/saas-staging/20260421-130923-dev-debug/app-dev-debug.apk
```

Local file size:

```text
253777249 bytes
```

## Readiness Result

The current staging stack is ready for device-side deploy testing:

- Staging database migrations are aligned.
- Core Supabase Edge Functions are deployed.
- Core deployed function smoke passed.
- Current `main` has a fresh staging dev-debug APK artifact.
- The APK was built with Supabase URL and anon key configured.
- The service role key was not passed to the client build.

## Recommended Device Test

Install the downloaded APK on the Android test phone, then verify:

- App launches cleanly.
- Login/auth entry points do not crash.
- SaaS subscription screen renders with the expected gated features.
- Cloud sync settings can read staging configuration.
- A basic local transaction flow still works.
- If a staging user is available, verify sync push/pull against Supabase.
