# 2026-03-13 Parallel Dev Phase411 Design

## 目标

本轮继续沿着 release readiness 车道推进，不再增加新的治理页面，重点补 3 个上线前薄弱点：

1. 备份导入的 schema 兼容与 migration 回归
2. 陈旧会话 / 陈旧凭据的 release gate 回归
3. release smoke 车道把新增回归纳入常规执行

## 设计决策

### 1. 备份导入改成服务层自带兼容门禁

过去 `importFromFile()` 只负责写库，不负责判断未来版本备份，也不负责 legacy 交易修复。这个设计容易把关键迁移逻辑散落到 UI 层。

本轮改为：

- 缺失 `schemaVersion` 视为 legacy v1
- 高于当前 `schemaVersion=4` 的备份直接阻断
- 导入后由服务层主动调用 `TransactionService` 两条真实迁移函数

### 2. 把认证治理 service 提升为 release gate

仓库已经有多条认证治理 service，但之前缺少“发布前怎样组合判定”的回归。

本轮把下列风险固化成 release gate：

- stale callback write 未阻断
- stale bundle 未失效
- token rotation 缺失
- email/token/credential/user bundle 不完整

### 3. release smoke 继续偏向稳定、可重复执行

这轮不去新增不稳定的桌面 UI smoke，而是把新增 regression test 直接接进 `run_release_smoke.sh`，保证每轮都能跑到。

## 产出

- `data_backup_migration_regression_mvp.md`
- `auth_stale_session_release_gate_mvp.md`
- `data_backup_service_migration_regression_test.dart`
- `auth_stale_session_release_gate_test.dart`
- `data_backup_service.dart` 兼容/迁移增强
- `run_release_smoke.sh` 扩充验证列表

## 暂缓项

- 真正的多端会话广播、云端 token revoke、后端租户隔离仍属于 SaaS/服务端阶段，不在本轮 Flutter 本地 release gate 范围内。
