# Android Prod Release Signing MVP

## Goal
把 Android 候选包从 `dev` 推进到 `prod`，并把 release signing 从写死 debug key 改成“有正式签名就用正式签名，没有就显式回退”。

## Changes
- `/Users/huazhou/Downloads/Github/Jive/app/android/app/build.gradle.kts`
- `/Users/huazhou/Downloads/Github/Jive/app/scripts/build_release_candidate.sh`
- 新增 `prod` flavor：
  - `applicationId = com.jivemoney.app`
  - `appLabel = Jive`
- 新增 keystore 配置读取：
  - `key.properties`
  - `JIVE_ANDROID_STORE_FILE`
  - `JIVE_ANDROID_STORE_PASSWORD`
  - `JIVE_ANDROID_KEY_ALIAS`
  - `JIVE_ANDROID_KEY_PASSWORD`
- `release` buildType 现在：
  - 有正式签名配置时使用 `release` signingConfig
  - 没有时回退 `debug` signingConfig
- `scripts/build_release_candidate.sh` 追加了 signing preflight，report 里新增 `signingPreflight`/`strictSigning` 字段，且对 `prod` flavor 可以通过 `JIVE_RELEASE_CANDIDATE_STRICT_SIGNING=true` 强制要求正式签名
- 新增 `android/key.properties.example`，直接复制可构成 `key.properties`

## Result
- `prod` flavor 已成功构建出 `app-prod-release.aab`
- release candidate report 已包含 `signingMode` + `signingPreflight` + `strictSigning`
- `scripts/build_release_candidate.sh` 会在 log/CI step 立刻反馈正式签名缺失，并且 `prod` flavor 可选地 fail-fast
- `android/key.properties.example` 让团队更容易生成 `key.properties` 并同步 secrets
