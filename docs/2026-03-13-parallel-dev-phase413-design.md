# 2026-03-13 Parallel Dev Phase413 Design

## 目标

本轮继续沿着“上线测试 + SaaS 演进底座”推进，补两类能力：

1. repository/sync cursor 基础抽象
2. Android E2E 失败诊断与重试机制

## 设计决策

### 1. 先做最小 sync foundation，不搞大重构

当前仓库还在 release readiness 阶段，不适合直接把所有 service 全量改仓储层。

因此本轮只补：

- `SyncCursor`
- `SyncRepository<T>`
- `AccountSyncRepository`
- `CategorySyncRepository`

### 2. cursor 采用 `updatedAt + lastId` 双键

只用时间戳会在同一时刻多行更新时丢记录，因此这轮直接用双键稳定分页。

### 3. Android E2E 不只要能跑，还要能定位失败

上一轮已经把 Android 车道脚本化，这轮继续补：

- per-test retry
- logcat
- dumpsys activity
- screenshot
- force-stop recovery

## 产出

- `sync_repository_foundation_mvp.md`
- `android_e2e_diagnostics_mvp.md`
- `sync_cursor.dart`
- `sync_repository_contract.dart`
- `account_sync_repository.dart`
- `category_sync_repository.dart`
- `account_category_sync_repository_test.dart`
- `run_android_e2e_smoke.sh` 增强版
- `2026-03-13-parallel-dev-phase413-design.md`
- `2026-03-13-parallel-dev-phase413-validation.md`

## 已识别约束

- `transaction` 目前没有统一 sync version / `updatedAt`，不能安全接入同一套 cursor 语义。
- Android emulator 车道本轮只做脚本与诊断增强，未在本地启动 emulator 直接执行。
