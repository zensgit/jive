# Phase432 Design

## Goal
把仓库从“可以跑回归”推进到“可以产出新版本候选包”。

## Changes
### 1. Version bump
- `/Users/huazhou/Downloads/Github/Jive/app/pubspec.yaml`
- 版本从 `1.0.0+1` 提升到 `1.0.1+2`

### 2. Android release candidate pipeline
- 新增 `/Users/huazhou/Downloads/Github/Jive/app/scripts/build_release_candidate.sh`
- 默认读取 `pubspec.yaml` 中的 `buildName/buildNumber`
- 执行 `flutter build appbundle --release --flavor dev`
- 复制产物到 `build/release-candidate/<stamp>-<flavor>/`
- 生成 `release-candidate.json` / `release-candidate.md`

### 3. CI manual entry
- `/Users/huazhou/Downloads/Github/Jive/app/.github/workflows/flutter_ci.yml`
- `workflow_dispatch` 新增 `build_release_candidate`
- 新增 `android_release_candidate` job
- job 结束后上传 release candidate artifact，并把 markdown 摘要写入 `GITHUB_STEP_SUMMARY`

### 4. Release blocker fix
- `/Users/huazhou/Downloads/Github/Jive/app/android/app/build.gradle.kts`
- 按 `google_mlkit_text_recognition` README 的 Android 说明补 app-level language package dependencies
- 解决 `bundleDevRelease` 时的 R8 missing classes

## Tradeoff
- 这轮先把 Android 候选包打通，不扩 iOS archive
- 这轮先保留 debug signing 的现状，只把真正的 blocker 明确写进 checklist
