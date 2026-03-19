# Release Candidate Build MVP

## Goal
为 Android 新版本提供一条可重复执行的候选构建路径，并把构建产物、版本号、校验和、commit 信息沉淀成 artifact report。

## Scope
- 版本号从 `1.0.0+1` 升到 `1.0.1+2`
- 新增 `/Users/huazhou/Downloads/Github/Jive/app/scripts/build_release_candidate.sh`
- workflow 增加手动触发的 Android release candidate job
- 构建后输出：
  - `build/release-candidate/**`
  - `build/reports/release-candidate/release-candidate.json`
  - `build/reports/release-candidate/release-candidate.md`
- `prod` flavor 支持 `JIVE_RELEASE_CANDIDATE_STRICT_SIGNING=true` 的严格签名模式

## Android blocker fixed
`google_mlkit_text_recognition` 在 Android release 混淆下会因为 language packages 只声明为 `compileOnly` 而触发 R8 缺类。

修复：在 `/Users/huazhou/Downloads/Github/Jive/app/android/app/build.gradle.kts` 显式补：
- `com.google.mlkit:text-recognition-chinese:16.0.1`
- `com.google.mlkit:text-recognition-devanagari:16.0.1`
- `com.google.mlkit:text-recognition-japanese:16.0.1`
- `com.google.mlkit:text-recognition-korean:16.0.1`

## Result
- 本地已成功产出 `dev` 与 `prod` flavor AAB
- CI 现在可通过 `workflow_dispatch` 手动触发 Android release candidate build
- 报告中已包含 `status` / `message` / `signingPreflight` / `strictSigning`
- 构建成功时报告中仍包含 artifact path / size / sha256 / branch / commit / buildName / buildNumber / signingMode
