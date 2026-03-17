# Phase434 Design

## Goal
把发布候选链路从“能构建”推进到“能明确告诉我们为什么还不能发版”。

## Scope
- `/Users/huazhou/Downloads/Github/Jive/app/scripts/build_release_candidate.sh`
- `/Users/huazhou/Downloads/Github/Jive/app/scripts/build_ios_release_candidate.sh`
- `/Users/huazhou/Downloads/Github/Jive/app/scripts/render_release_report_summary.sh`
- `/Users/huazhou/Downloads/Github/Jive/app/.github/workflows/flutter_ci.yml`
- `/Users/huazhou/Downloads/Github/Jive/app/android/key.properties.example`
- `/Users/huazhou/Downloads/Github/Jive/app/docs/release_candidate_build_mvp.md`
- `/Users/huazhou/Downloads/Github/Jive/app/docs/release_candidate_checklist_mvp.md`

## Decisions
- Android `prod` 候选构建支持 `JIVE_RELEASE_CANDIDATE_STRICT_SIGNING=true`。
- 严格模式下，缺失正式 keystore 直接 `block`，并写入 `release-candidate.json`。
- iOS 预检不再只给终端提示，统一沉淀到 `ios-release-candidate-preflight.json/.md`。
- `render_release_report_summary.sh` 扩展为读取 Android/iOS candidate 报告，直接在 CI summary 中呈现阻塞状态。

## Result
- Android 候选包现在可以区分“可继续评审”和“必须先补签名材料”。
- iOS 候选包现在可以区分“环境可用”和“Xcode 平台组件缺失”。
- 发布阻塞已从日志噪音收口为结构化报告。
