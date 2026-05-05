# Android Local Feature Smoke Dev Verify

- Date: 2026-05-05
- Branch: `codex/local-android-feature-smoke-runner`
- Base: `main` @ `ebabb645`
- Device: Android Emulator `Jive_Staging_API35` / `emulator-5554`
- Package: `com.jivemoney.app.dev`
- Artifact dir: `/tmp/jive-android-local-feature-smoke-20260505-rerun`

## Changes

- Added `scripts/run_android_local_feature_smoke.sh`.
- Added `docs/android_local_feature_smoke_mvp.md`.
- Added this verification report.

## Why

Manual local smoke had to be repeated with several adb commands. The new script makes the local emulator path reusable:

- build or reuse the debug APK
- install safely
- cold launch
- drive onboarding to guest home
- collect UI and crash evidence
- write `summary.md`

The script preserves app data by default. Destructive local reset requires `--fresh-install`, and signature-mismatch uninstall requires `--allow-uninstall-on-signature-mismatch`.

## Commands

Syntax and help:

```bash
bash -n scripts/run_android_local_feature_smoke.sh
scripts/run_android_local_feature_smoke.sh --help
```

Full local emulator smoke:

```bash
scripts/run_android_local_feature_smoke.sh \
  --fresh-install \
  --allow-uninstall-on-signature-mismatch \
  --artifact-dir /tmp/jive-android-local-feature-smoke-20260505-rerun
```

Non-destructive launch-only smoke:

```bash
scripts/run_android_local_feature_smoke.sh \
  --skip-build \
  --skip-install \
  --artifact-dir /tmp/jive-android-local-feature-smoke-20260505-preserve
```

## Results

The full local emulator smoke passed.

Summary:

```text
status: passed
gitCommit: ebabb6451ef1805e1096c49f9acf56944230e5d9
device: emulator-5554
flavor: dev
package: com.jivemoney.app.dev
apkSha256: b48c6414750bbe4a008acb66101ac028427cf1a7128bb7237d590b213c7fd48d
finalCrashBytes: 0
```

Final home UI summary included:

```text
晚上好,
访客
净资产
¥0.00
收入
支出
转账
汇率
最近交易
还没有交易记录
记一笔
Home / Stats / Assets
```

Final artifacts:

```text
/tmp/jive-android-local-feature-smoke-20260505-rerun/summary.md
/tmp/jive-android-local-feature-smoke-20260505-rerun/final_home.png
/tmp/jive-android-local-feature-smoke-20260505-rerun/final_home.xml
/tmp/jive-android-local-feature-smoke-20260505-rerun/final_home.summary.txt
/tmp/jive-android-local-feature-smoke-20260505-rerun/final_home.crash.log
/tmp/jive-android-local-feature-smoke-20260505-rerun/final_home.alerts.log
```

Crash/alert evidence:

```text
final_home.crash.log: 0 bytes
final_home.alerts.log: 0 bytes
```

The non-destructive launch-only smoke also passed and detected that the guest home was already visible.

## Notes

- The script uses fake local smoke dart-defines by default. This validates local startup and config injection shape, not real production connectivity.
- This run intentionally reset only the emulator dev package because `--fresh-install` was passed.
- No GitHub secrets were read or written.
- No production workflow was triggered.
