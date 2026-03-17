# Release Candidate Checklist MVP

## Already ready
- Host release regression suite 可执行
- Android emulator smoke 可执行
- Android `prod` release candidate AAB 可构建
- release candidate report 可落盘并可上传 CI artifact
- 版本号已提升到 `1.0.1+2`

## Still required before store release
1. 生产签名配置
   - 当前 `/Users/huazhou/Downloads/Github/Jive/app/android/app/build.gradle.kts` 的 `release` 仍会在无材料时回退 debug signing
   - 严格模式下可用 `JIVE_RELEASE_CANDIDATE_STRICT_SIGNING=true`
   - 参照 `/Users/huazhou/Downloads/Github/Jive/app/android/key.properties.example`
2. iOS 设备平台组件
   - 当前本机 `xcodebuild -showdestinations` 对 `Runner` 仍报 `Any iOS Device` 不可用
   - 诊断报告已落盘到 `/Users/huazhou/Downloads/Github/Jive/app/build/reports/ios-release-candidate/ios-release-candidate-preflight.json`
   - 已尝试 `xcodebuild -downloadPlatform iOS`，但当前机器仅剩约 `129Mi` 可用空间，下载直接失败，提示需要 `8.04 GB`
3. iOS 候选包签名/归档
   - 本轮只打通了无签名 preflight，还没到可分发 IPA
4. 脏工作区收口
   - `/Users/huazhou/Downloads/Github/Jive/app/lib/feature/settings/settings_screen.dart`
   - `/Users/huazhou/Downloads/Github/Jive/app/macos/Podfile.lock`
   仍需从发布切片中隔离

## Recommended release order
1. 准备 Android signing materials，并校验 `android/key.properties.example` 对应字段
2. 运行 host regression suite
3. 运行 Android smoke lane
4. 运行 `JIVE_RELEASE_CANDIDATE_STRICT_SIGNING=true bash /Users/huazhou/Downloads/Github/Jive/app/scripts/build_release_candidate.sh`
5. 校验 `/Users/huazhou/Downloads/Github/Jive/app/build/reports/release-candidate/release-candidate.json` 中的 `status` / `sha256` / `commit`
6. 运行 `/Users/huazhou/Downloads/Github/Jive/app/scripts/build_ios_release_candidate.sh` 并查看 preflight 报告
7. 再决定是否推送发布分支/打 tag
