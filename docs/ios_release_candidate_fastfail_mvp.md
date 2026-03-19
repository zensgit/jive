# iOS Release Candidate Fast-fail MVP

## Goal
把 iOS 候选构建从“跑很久后失败”改成“先做环境 preflight，再快速失败并给出明确修复提示”。

## Changes
- `/Users/huazhou/Downloads/Github/Jive/app/ios/Podfile`
  - iOS deployment target 升到 `15.5`
  - 按 ML Kit 要求补 `post_install` deployment target / arch 收口
- `/Users/huazhou/Downloads/Github/Jive/app/scripts/build_ios_release_candidate.sh`
  - 新增无签名 iOS candidate 构建脚本
  - 在 `flutter build ios` 前调用 `xcodebuild -workspace Runner.xcworkspace -scheme Runner -showdestinations`
  - 若 `Any iOS Device` 不可用，则直接报错退出
  - 将 xcode destination preflight 输出结构化为 JSON/MD 并写入 `build/reports/ios-release-candidate/`，失败也会保留报告供排查
- `/Users/huazhou/Downloads/Github/Jive/app/.github/workflows/flutter_ci.yml`
  - 新增手动触发的 `ios_release_candidate` job

## Result
- deployment target blocker 已修掉
- 当前剩余 blocker 已清晰收敛为本机 Xcode 缺少可用 iOS device destination
- 现在会在 `build/reports/ios-release-candidate/ios-release-candidate-preflight.{json,md}` 记录 preflight 结果，成功/失败都可直接通过报告判断原因
- 后续不需要再等完整 `flutter build ios` 才知道环境不满足
