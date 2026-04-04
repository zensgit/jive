# Codex Task: B0.2 — 定义稳定云端标识

## 任务入口
请先阅读 `/Users/chauhua/Documents/GitHub/Jive/app/docs/codex-saas-tasks.md` 了解整体计划。
再阅读 `/Users/chauhua/Documents/GitHub/Jive/app/docs/saas-beta-boundaries.md` 了解边界决策。

## Git 工作流
```bash
cd /Users/chauhua/Documents/GitHub/Jive/app
git checkout main && git pull origin main
git checkout -b saas/b0.2-stable-cloud-ids
```

## 目标
不再长期依赖本地 Isar `int` 自增 ID 作为同步标识。为所有核心同步对象定义稳定的业务 key。

## 当前现状
以下模型**已有**稳定 key：
- `JiveBook.key` (String, unique index)
- `JiveAccount.key` (String, unique index)
- `JiveCategory.key` (String, unique index)
- `JiveTag.key` (String, unique index)
- `JiveSharedLedger.key` (String, unique index)

以下模型**缺少**稳定 key：
- `JiveTransaction` — 只有 Isar 自增 `Id id`
- `JiveBudget` — 只有 Isar 自增 `Id id`
- `JiveRecurringRule` — 只有 Isar 自增 `Id id`
- `JiveSavingsGoal` — 只有 Isar 自增 `Id id`

## 具体任务

### 1. 为缺失 key 的模型新增 `syncKey` 字段

修改以下文件，每个模型新增：
```dart
@Index(unique: true)
String syncKey = '';
```

文件清单：
- `lib/core/database/transaction_model.dart` — 新增 `syncKey`
- `lib/core/database/budget_model.dart` — 新增 `syncKey`
- `lib/core/database/recurring_rule_model.dart` — 新增 `syncKey`
- `lib/core/database/savings_goal_model.dart` — 新增 `syncKey`

### 2. 创建 SyncKey 生成工具

创建 `lib/core/sync/sync_key_generator.dart`：
```dart
/// 生成稳定的同步标识
class SyncKeyGenerator {
  /// 生成格式: {prefix}_{timestamp}_{random4}
  /// 例如: tx_1712345678901_a3f2
  static String generate(String prefix) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rand = Random.secure().nextInt(0xFFFF).toRadixString(16).padLeft(4, '0');
    return '${prefix}_${ts}_$rand';
  }
}
```

### 3. 回填逻辑

创建 `lib/core/sync/sync_key_migration.dart`：
- `migrateTransactionSyncKeys()` — 遍历所有 syncKey 为空的 transaction，生成并写入
- `migrateBudgetSyncKeys()` — 同上
- `migrateRecurringSyncKeys()` — 同上
- `migrateSavingsGoalSyncKeys()` — 同上
- `migrateAllSyncKeys()` — 调用以上所有

### 4. 在启动时触发迁移

在 `lib/main.dart` 的 `main()` 中，在 `DatabaseService.getInstance()` 之后调用：
```dart
await SyncKeyMigration.migrateAllSyncKeys();
```

### 5. 重新生成 Isar schema

```bash
export PATH="$PATH:/Users/chauhua/development/flutter/bin/cache/dart-sdk/bin"
dart run build_runner build --delete-conflicting-outputs
```

## 验收标准
- [ ] `flutter analyze lib/` — 0 errors
- [ ] `flutter test` — 所有测试通过
- [ ] 4 个模型都有 `syncKey` 字段
- [ ] SyncKeyGenerator 生成唯一标识
- [ ] 迁移逻辑可为已有数据回填 syncKey
- [ ] 不破坏任何现有功能

## 完成后
```bash
git add -A
git commit -m "feat(B0.2): add syncKey to transaction/budget/recurring/savings models

- SyncKeyGenerator for stable cloud identifiers
- SyncKeyMigration for backfilling existing data
- Triggered on app startup after database init

Co-Authored-By: Codex <noreply@openai.com>"

git push origin saas/b0.2-stable-cloud-ids
gh pr create --base main --title "B0.2: 定义稳定云端标识" --body "$(cat <<'PREOF'
## Summary
为 4 个缺少稳定标识的模型新增 syncKey 字段，不再长期依赖 local_id。

## Changes
- transaction_model.dart: +syncKey
- budget_model.dart: +syncKey
- recurring_rule_model.dart: +syncKey
- savings_goal_model.dart: +syncKey
- sync_key_generator.dart: 新建
- sync_key_migration.dart: 新建
- main.dart: 启动时触发迁移

## Checklist
- [ ] flutter analyze 0 errors
- [ ] flutter test 全部通过
- [ ] 向后兼容（不破坏现有本地数据）
- [ ] SQL 迁移不涉及（本次只改本地模型）
PREOF
)"
```

## 禁止
- 不要修改 SyncEngine（那是 B1.2 的任务）
- 不要修改 SQL migration（那是 B1.1 的任务）
- 不要修改测试文件
- 不要跨 scope
