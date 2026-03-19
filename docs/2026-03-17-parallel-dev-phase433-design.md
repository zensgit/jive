# Phase433 Design

## Goal
把 release candidate 从“Android dev 可构建”继续推进到：
1. Android `prod` flavor 可构建
2. Android release signing 可切换
3. iOS 候选构建具备脚本入口和 fast-fail preflight

## Changes
### 1. Android prod + signing-aware build
- `/Users/huazhou/Downloads/Github/Jive/app/android/app/build.gradle.kts`
- 新增 `prod` flavor
- 新增 `release` signingConfig 读取 `key.properties` / 环境变量
- 没有正式签名时仍允许回退 debug signing 构建候选包

### 2. Android release candidate script enhancement
- `/Users/huazhou/Downloads/Github/Jive/app/scripts/build_release_candidate.sh`
- 默认 flavor 改为 `prod`
- 报告中新增 `signingMode`

### 3. iOS candidate path
- `/Users/huazhou/Downloads/Github/Jive/app/ios/Podfile`
- deployment target 提升到 `15.5`
- `/Users/huazhou/Downloads/Github/Jive/app/scripts/build_ios_release_candidate.sh`
- `/Users/huazhou/Downloads/Github/Jive/app/.github/workflows/flutter_ci.yml`
- 新增 iOS release candidate manual job

## Findings
- Android 侧现在已能构建最终 flavor 的候选包，但还缺正式签名材料
- iOS 侧项目配置已满足 ML Kit 要求，当前失败点已缩到本机 Xcode device destination 环境问题
