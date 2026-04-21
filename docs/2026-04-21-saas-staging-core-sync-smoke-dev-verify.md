# SaaS Staging Core Sync Smoke 开发与验证

日期：2026-04-21

分支：`codex/saas-staging-sync-core-smoke`

## 目标

把 staging Supabase smoke 从“只验证 transactions”升级为“核心同步小闭环”：

- 创建临时 Supabase Auth 用户并用 anon password flow 建立两个 session。
- 通过用户 JWT + RLS 插入 `accounts`、`transactions`、`budgets`。
- 用第二个 session 按 `sync_key` 拉回三类核心数据，验证 `book_key` 边界存在。
- 验证交易里的 `account_sync_key` 可以跨 session round-trip，避免只验证本地 `account_id`。
- 验证 `transactions` 和 `budgets` 的 `deleted_at` tombstone 更新。
- 默认清理临时交易、预算、账户和 auth user。

## 改动

修改脚本：

- `scripts/run_saas_staging_sync_smoke.sh`

新增验证点：

- `rls_insert_account`
- `second_session_pull_account_by_sync_key`
- `rls_insert_transaction`
- `second_session_pull_transaction_by_sync_key`
- `transaction_account_sync_key_round_trip`
- `rls_insert_budget`
- `second_session_pull_budget_by_sync_key`
- `rls_transaction_tombstone_update`
- `rls_budget_tombstone_update`
- `cleanup`

新增脱敏 artifacts：

- `inserted-account.redacted.json`
- `pulled-account.redacted.json`
- `inserted-budget.redacted.json`
- `pulled-budget.redacted.json`
- `tombstoned-budget.redacted.json`

## 契约说明

`accounts` / `budgets` 插入显式携带：

- `user_id`
- `local_id`
- `sync_key`
- `book_key`
- `updated_at`

`book_key` 当前既是数据边界字段，也是 RLS 条件之一，所以 smoke 不再把它当可选字段处理。

`transactions` 在有账户引用时显式携带：

- `account_id`
- `account_sync_key`

这样能验证 SaaS 同步真正使用跨设备稳定账户标识，而不是只依赖本机 Isar int ID。

后续更新：`budgets.category_keys` 已在 `2026-04-21-saas-budget-category-keys-array-dev-verify.md` 中收敛为数组口径；旧字符串读取仍保留兼容。

## 验证

已通过：

```bash
bash -n scripts/run_saas_staging_sync_smoke.sh
```

已通过：

```bash
scripts/run_saas_staging_sync_smoke.sh --help
```

已通过：

```bash
awk '/^from __future__ import annotations$/{flag=1} /^PY$/{flag=0} flag{print}' \
  scripts/run_saas_staging_sync_smoke.sh > /tmp/jive_saas_sync_smoke_embedded.py
python3 -m py_compile /tmp/jive_saas_sync_smoke_embedded.py
```

已通过：

```bash
git diff --check
```

真实 staging 复跑尝试：

```bash
scripts/run_saas_staging_sync_smoke.sh \
  --env-file /tmp/jive-saas-staging.env \
  --out-dir /tmp/jive-saas-sync-core-smoke-20260421
```

结果：

```text
[saas-sync-smoke] ERROR: env file not found: /tmp/jive-saas-staging.env
```

因此本次远端 Supabase 实测尚未完成，原因是本机临时 env 文件已不存在；脚本没有打印或写入任何密钥。

## 远端复跑命令

在本机恢复一个不入库的 env 文件后执行：

```bash
scripts/run_saas_staging_sync_smoke.sh \
  --env-file /tmp/jive-saas-staging.env \
  --out-dir /tmp/jive-saas-sync-core-smoke-$(date +%Y%m%d-%H%M%S)
```

env 文件需要包含：

```text
SUPABASE_URL=...
SUPABASE_ANON_KEY=...
SUPABASE_SERVICE_ROLE_KEY=...
```

安全检查建议：

```bash
rg -n "eyJ|sbp_|SERVICE_ROLE|access_token|refresh_token|password|Bearer|apikey" \
  /tmp/jive-saas-sync-core-smoke-*
```

期望产物里只有脱敏元数据和测试行标识，不应出现真实 token/key/password。

## 剩余风险

- 这是 PostgREST/RLS 级 smoke，不等价于 App 内订阅用户完整同步流程。
- `budgets.category_keys` 已后续收敛为数组口径；Dart 侧仍兼容读取旧 String/List。当前仍是本地 `categoryKey` 单值映射到云端单元素数组，不是多分类预算语义。
- `sync_key` 虽已作为 SaaS 稳定标识使用，但 legacy `unique(user_id, local_id)` 仍存在；后续跨设备冲突测试还需要覆盖重复 local ID 场景。
