# Data Backup Migration Regression MVP

## 目标

在进入上线测试前，把“旧版本备份导入后是否自动修复交易字段”从人工约定改成可执行回归：

1. legacy 备份缺少 `schemaVersion` 时按兼容版本导入
2. 旧交易缺少 `categoryKey` / `subCategoryKey` / `accountId` 时自动修复
3. 未来版本备份一律阻断，且不能清空当前本地数据

## 本轮落地

- 更新导入服务：`/Users/huazhou/Downloads/Github/Jive/app/lib/core/service/data_backup_service.dart`
- 新增回归测试：`/Users/huazhou/Downloads/Github/Jive/app/test/data_backup_service_migration_regression_test.dart`

## 关键策略

- 缺失 `schemaVersion` 的备份按 `legacySchemaVersion=1` 处理
- `schemaVersion > current` 的备份直接抛错阻断
- 导入完成后由服务层主动调用 transaction migration，而不是把修复责任留给外层调用方
- `BackupImportSummary` 补充 source schema 与修复计数，便于发布前验证
