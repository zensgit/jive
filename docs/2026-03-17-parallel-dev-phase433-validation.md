# Phase433 Validation

## Changed Files
- `/Users/huazhou/Downloads/Github/Jive/app/android/app/build.gradle.kts`
- `/Users/huazhou/Downloads/Github/Jive/app/scripts/build_release_candidate.sh`
- `/Users/huazhou/Downloads/Github/Jive/app/scripts/build_ios_release_candidate.sh`
- `/Users/huazhou/Downloads/Github/Jive/app/.github/workflows/flutter_ci.yml`
- `/Users/huazhou/Downloads/Github/Jive/app/ios/Podfile`
- `/Users/huazhou/Downloads/Github/Jive/app/ios/Podfile.lock`
- `/Users/huazhou/Downloads/Github/Jive/app/ios/Runner.xcodeproj/project.pbxproj`
- `/Users/huazhou/Downloads/Github/Jive/app/docs/android_prod_release_signing_mvp.md`
- `/Users/huazhou/Downloads/Github/Jive/app/docs/ios_release_candidate_fastfail_mvp.md`
- `/Users/huazhou/Downloads/Github/Jive/app/docs/2026-03-17-parallel-dev-phase433-design.md`
- `/Users/huazhou/Downloads/Github/Jive/app/docs/2026-03-17-parallel-dev-phase433-validation.md`

## Commands
### Script syntax
- `bash -n scripts/build_release_candidate.sh`
- `bash -n scripts/build_ios_release_candidate.sh`

Result: passed

### Workflow YAML parse
`ruby -e 'require "yaml"; YAML.load_file(".github/workflows/flutter_ci.yml")'`

Result: passed

### Android prod release candidate build
`bash scripts/build_release_candidate.sh`

Result: passed

### iOS release candidate preflight
`bash scripts/build_ios_release_candidate.sh`

Result: failed fast with clear environment blocker message

## Android output
- artifact: `/Users/huazhou/Downloads/Github/Jive/app/build/release-candidate/20260317-171531-prod/app-prod-release.aab`
- size: `115791770` bytes
- sha256: `4efe37d8da58a5cfb9b195204cc7013bf98adcd257f1b23b1e89e4e145766584`
- report: `/Users/huazhou/Downloads/Github/Jive/app/build/reports/release-candidate/release-candidate.json`
- signingMode: `debug`

## iOS blocker
### First blocker fixed
- `google_mlkit_commons` 要求的 deployment target 已从 `13.0` 提升到 `15.5`

### Current blocker
- `xcodebuild -workspace Runner.xcworkspace -scheme Runner -showdestinations` 返回：
  - `Any iOS Device` 不可用
  - `iOS 26.0 is not installed`
- 因此当前 iOS candidate 仍不能在本机完成 device release build

## Conclusion
- Android `prod` flavor 候选包已可生成
- Android 正式发布还差 signing secrets
- iOS 项目配置已基本收口，当前剩余的是本机 Xcode 组件/平台环境问题
