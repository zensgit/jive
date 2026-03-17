# Phase435 Design

## Goal
把 `1+2+3` 这轮执行结果收口成可操作结论：
- Android 是否已有正式签名材料
- iOS 是否能自动补齐 device platform
- 哪些发布准备改动需要优先同步到 GitHub

## Scope
- `/Users/huazhou/Downloads/Github/Jive/app/docs/release_candidate_checklist_mvp.md`
- `/Users/huazhou/Downloads/Github/Jive/app/docs/2026-03-17-parallel-dev-phase435-design.md`
- `/Users/huazhou/Downloads/Github/Jive/app/docs/2026-03-17-parallel-dev-phase435-validation.md`

## Decisions
- 不使用系统 `debug.keystore` 伪装正式发布签名。
- 不在当前空间不足的机器上强行继续 iOS platform 下载重试。
- 先把 phase431-434 的发布准备切片选择性提交并同步到 `origin/codex/post-merge-verify`。

## Result
- Android blocker 收敛为“缺正式 keystore / secrets”
- iOS blocker 收敛为“缺 device platform 且磁盘仅剩约 3.9Gi，不足以下载 8.04GB 组件”
- GitHub 将先同步可复用的发布准备与验证能力
