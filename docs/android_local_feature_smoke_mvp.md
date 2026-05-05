# Android Local Feature Smoke MVP

## Goal

`scripts/run_android_local_feature_smoke.sh` provides a repeatable local Android smoke lane for quick product checks before handing work to CI or staging. It focuses on emulator-friendly flows that can be driven with `adb`:

- build or reuse a debug APK
- install on an adb target
- cold launch the app
- drive onboarding to guest mode
- verify the guest home renders
- collect screenshots, UI XML, crash buffer, alert logs, and a Markdown summary

This lane is intentionally local-only. It does not upload secrets, does not trigger GitHub Actions, and does not use production Supabase or service-role keys.

## Recommended Usage

Fresh emulator run:

```bash
scripts/run_android_local_feature_smoke.sh \
  --fresh-install \
  --allow-uninstall-on-signature-mismatch
```

Reuse an existing APK:

```bash
scripts/run_android_local_feature_smoke.sh \
  --skip-build \
  --fresh-install \
  --allow-uninstall-on-signature-mismatch \
  --artifact-dir /tmp/jive-android-local-feature-smoke
```

Launch/capture only, without driving onboarding:

```bash
scripts/run_android_local_feature_smoke.sh \
  --skip-build \
  --skip-install \
  --skip-onboarding
```

## Safety Defaults

- The script preserves app data by default.
- App data is reset only when `--fresh-install` is passed.
- Signature-mismatch recovery uninstalls the app only when `--allow-uninstall-on-signature-mismatch` is passed.
- Default dart-defines are fake local smoke values and must not be treated as production connectivity proof.

## Outputs

By default, artifacts are written under:

```text
build/reports/local-android-feature-smoke/<timestamp>/
```

Each run emits:

- `summary.md`
- `launch.*`
- `onboarding_*.*`
- `auth*.*`
- `guest_confirm.*`
- `final_home.*`
- `install.log`
- `flutter-build.log` when building

## Current Scenario

The MVP scenario covers:

1. Welcome screen opens.
2. User skips welcome.
3. `记一笔` onboarding category grid appears.
4. `餐饮` can be selected.
5. `下一步` advances to category settings.
6. Remaining onboarding steps can be skipped.
7. Login page guest entry can be reached by scrolling.
8. Guest mode confirmation appears.
9. Guest home renders with `访客` and `净资产`.

## Known Limits

- Physical devices may block adb input injection depending on trust, focus, or OEM restrictions.
- This lane is not a replacement for integration tests or staging backend smoke.
- It validates local startup and UI navigation, not real payments, real cloud sync, or production release signing.
