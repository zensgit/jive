# SaaS Budget Category Keys Array 开发与验证

日期：2026-04-21

分支：`codex/saas-budget-category-keys-array`

## 目标

把预算同步字段 `budgets.category_keys` 收敛到 Supabase schema 预期的 jsonb array 口径，避免继续把单个分类 key 作为 scalar string 写入云端。

## 改动

- 新增 `lib/core/sync/sync_budget_payload.dart`，集中生成预算同步 payload 的 `category_keys`。
- `SyncEngine` 出站预算行与预算 tombstone 冲突快照统一写入 `List<String>`。
- `SyncDeleteMarkerService` 生成预算删除 tombstone 时统一写入 `List<String>`。
- staging sync smoke 的预算 payload 改为 `["cat_food"]`，并验证第二 session 拉回的 `category_keys` 也是数组。
- 更新上一个 staging core sync smoke 报告，注明旧 scalar string 口径已被本轮收敛替代。

## 兼容策略

出站：

- `categoryKey == null` 或空白字符串：写入 `[]`。
- 单个分类 key：写入 `[categoryKey]`。

入站：

- 保留 `SyncEngine` 既有兼容逻辑，仍可读取旧的 scalar string。
- 仍可读取 array，并取第一个元素映射回本地 `JiveBudget.categoryKey`。

当前这只是“单值本地模型到云端数组”的契约收敛，不引入多分类预算语义。

## 验证

已执行格式化：

```bash
/Users/chauhua/development/flutter/bin/dart format \
  lib/core/sync/sync_budget_payload.dart \
  lib/core/sync/sync_engine.dart \
  lib/core/sync/sync_delete_marker_service.dart \
  test/sync_budget_payload_test.dart \
  test/sync_delete_marker_service_test.dart
```

已通过聚焦测试：

```bash
/Users/chauhua/development/flutter/bin/flutter test \
  test/sync_budget_payload_test.dart \
  test/sync_delete_marker_service_test.dart \
  test/sync_engine_test.dart
```

结果：

```text
All tests passed!
```

已通过 analyze 口径：

```bash
/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos
```

结果：

```text
135 issues found. (ran in 7.3s)
```

说明：命令退出码为 0，全部为既有 info 级 lint；本轮没有新增 analyzer error/warning。

已通过脚本语法检查：

```bash
bash -n scripts/run_saas_staging_sync_smoke.sh
```

已通过嵌入 Python 编译检查：

```bash
awk '/^from __future__ import annotations$/{flag=1} /^PY$/{flag=0} flag{print}' \
  scripts/run_saas_staging_sync_smoke.sh > /tmp/jive_saas_sync_smoke_embedded.py
python3 -m py_compile /tmp/jive_saas_sync_smoke_embedded.py
```

已通过 diff 空白检查：

```bash
git diff --check
```

## 后续建议

- 恢复 `/tmp/jive-saas-staging.env` 后，复跑 `scripts/run_saas_staging_sync_smoke.sh`，让远端 Supabase 也验证数组口径。
- 如果未来产品需要“一个预算绑定多个分类”，再扩展本地 `JiveBudget` 模型；本轮不改变本地单分类语义。
