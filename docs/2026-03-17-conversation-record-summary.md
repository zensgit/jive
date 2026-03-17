# Conversation Record Summary

> 说明：这不是逐字聊天导出，而是按开发接续需要整理的 Markdown 纪要。重点保留里程碑、关键决策、同步状态、遗留本地状态和下一步。

## Repository Baseline
- Repository: `https://github.com/zensgit/jive.git`
- Workspace: `/Users/huazhou/Downloads/Github/Jive/app`
- Active branch when recorded: `codex/post-merge-verify`
- Latest pushed commit when recorded: `978cd4730acaadb8f0e9d0c095a51514d631d7d6`

## High-level Thread Goal
用户长期目标是：
- 持续并行开发
- 对标并超越 `/Users/huazhou/Downloads/Github/Jive/references/yimu_apk_6_2_5_jadx`
- 把项目从功能堆叠推进到可上线测试，再推进到可发布新版本
- 支持后续跨电脑接续开发

## Main Phases Covered In This Thread

### 1. Governance / Feature Parity Expansion
阶段大致覆盖 `phase385` 到 `phase409`。

主要工作：
- 大量 settings/governance service + screen + test + docs 落地
- 覆盖导入导出、认证安全、分类共享、梦想流程、图标搜索、主题与 widget 等多条支线
- 通过大量 service/widget test 验证，并持续写入设计/验证文档

特点：
- 这一段主要是“对标 yimu 的业务治理层”
- 产出很多本地未跟踪的 `docs/*.md` 与 `test/*` 文件
- 并不是所有历史 phase 文件都已经提交到 GitHub

### 2. Release / Regression / Integration Lane Construction
阶段大致覆盖 `phase410` 到 `phase425`。

主要工作：
- 建立 host release smoke lane
- 建立 Android emulator E2E lane
- 打通 `ImportCenter`、`CategoryIconPicker`、`transaction_search`、`calendar_date_picker` 等集成回归
- 补 `backup/restore + stale session + sync runtime` 回归
- 建立 runtime telemetry / report / CI summary

关键脚本与文件：
- `/Users/huazhou/Downloads/Github/Jive/app/scripts/run_release_smoke.sh`
- `/Users/huazhou/Downloads/Github/Jive/app/scripts/run_release_regression_suite.sh`
- `/Users/huazhou/Downloads/Github/Jive/app/scripts/run_android_e2e_smoke.sh`
- `/Users/huazhou/Downloads/Github/Jive/app/.github/workflows/flutter_ci.yml`

### 3. Import Pipeline Hardening
阶段大致覆盖 `phase426` 到 `phase430`。

主要工作：
- `ImportCenter` 的列映射 fail-fast / preview repair / duplicate resolution
- import history repository 边界抽离
- transfer import metadata bridge / preview / guard
- 更稳定的 Android integration smoke

代表提交：
- `e0b8992 feat(import): add repairable preview and transfer guard`
- `6b5cce5 feat(import): harden transfer account resolution gate`

### 4. Release Candidate Preparation
阶段大致覆盖 `phase431` 到 `phase435`。

主要工作：
- `auto_draft` transfer confirm 最终兜底
- Android release candidate 构建脚本
- Android `prod` flavor 与 strict signing preflight
- iOS release candidate preflight / reporting
- cross-machine handoff 文档
- conversation / handoff / release checklist 收口

代表提交：
- `6244bab chore(release): add candidate gating and verification`
- `b0c48b8 docs: add cross-machine handoff`
- `978cd47 docs: refresh cross-machine handoff`

## Important Synced Commits
- `e0b8992` `feat(import): add repairable preview and transfer guard`
- `850f1ef` `feat(sync): add runtime foundation and android release lane`
- `6b5cce5` `feat(import): harden transfer account resolution gate`
- `6244bab` `chore(release): add candidate gating and verification`
- `b0c48b8` `docs: add cross-machine handoff`
- `978cd47` `docs: refresh cross-machine handoff`

## Current Release State

### Android
- 代码层面已经支持 strict signing release candidate。
- 当前阻塞不是脚本，而是 **没有 production keystore / secrets**。
- 示例文件：
  - `/Users/huazhou/Downloads/Github/Jive/app/android/key.properties.example`
- 当前系统里只有：
  - `/Users/huazhou/.android/debug.keystore`
- 这个不能当正式发布签名材料。

### iOS
- 期间先遇到 `Any iOS Device` 不可用 / `iOS 26.0 is not installed`
- 之后通过清理空间重新执行了 `xcodebuild -downloadPlatform iOS`
- 当前线程结束时，iOS platform 下载已完成
- 但 `iOS release candidate build` 还没有在“platform 已安装”后的干净状态下再次完整重跑并验收

## Cross-machine Development Conclusion
- 你现在**可以**在另一台电脑上继续主线开发
- 推荐直接使用 GitHub 上的 `codex/post-merge-verify`
- 先看：
  - `/Users/huazhou/Downloads/Github/Jive/app/docs/2026-03-17-cross-machine-handoff.md`

建议启动步骤：
```bash
git clone https://github.com/zensgit/jive.git
cd jive/app
git switch codex/post-merge-verify
flutter pub get
bash scripts/run_release_regression_suite.sh
```

## Important Local-only State Not Fully Synced
以下内容仍然只在当前机器本地：
- `/Users/huazhou/Downloads/Github/Jive/app/lib/feature/settings/settings_screen.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/macos/Podfile.lock`
- 以及大量未跟踪的历史 `docs/`、`test/` 文件

这意味着：
- 换电脑继续主线开发：可以
- 完整继承当前机器所有本地脏工作区：还不可以，除非后续再做一次选择性同步

## Space / Environment Notes
本线程里做过一次本机空间回收：
- 删除 `/Users/huazhou/Downloads/Github/Jive/app/build`
- 删除 `/Users/huazhou/.android/avd`

之后重新拉起了 iOS platform 下载。

## Recommended Next Steps
1. 在另一台电脑 checkout `codex/post-merge-verify`
2. 先跑 host regression，确认环境干净
3. 验证 iOS device platform 在另一台电脑上的可用性
4. 如果要继续 Android 正式候选包，先准备 production keystore / secrets
5. 如果要把当前机器本地残留也迁走，再单独做第二轮选择性同步
