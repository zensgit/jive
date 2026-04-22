# SaaS Core Staging Sync Smoke Action 开发与验证

日期：2026-04-22

分支：`codex/saas-core-staging-sync-smoke-action`

## 目标

把真实 Supabase staging 核心同步 smoke 接到现有 `SaaS Core Staging` 手动 workflow 中，减少对本机 `/tmp/jive-saas-staging.env` 的依赖。

## 改动

- `.github/workflows/saas_core_staging.yml`
  - 新增 `workflow_dispatch` 输入 `run_sync_smoke`，默认 `false`。
  - 勾选后向 core staging lane 传入 `--run-sync-smoke`。
- `scripts/run_saas_core_staging_lane.sh`
  - 新增 `--run-sync-smoke` 参数。
  - 在 migration apply 阶段之后运行 `scripts/run_saas_staging_sync_smoke.sh`。
  - smoke artifact 写入 `build/reports/saas-staging/sync-smoke-<timestamp>`，沿用既有 workflow artifact 上传路径。

## 安全边界

- 默认不改变现有 core staging workflow 行为，必须手动勾选 `run_sync_smoke=true` 才会访问 staging 数据库。
- workflow 继续使用 `STAGING_SUPABASE_URL`、`STAGING_SUPABASE_ANON_KEY`、`STAGING_SUPABASE_SERVICE_ROLE_KEY` 三个 GitHub Actions secrets 创建临时 env 文件。
- `run_saas_staging_sync_smoke.sh` 不打印 token/key/password，只写脱敏 metadata 与测试行标识。
- smoke 默认清理临时 auth user、account、transaction、budget 测试行。

## 运行方式

GitHub UI：

- Actions → SaaS Core Staging → Run workflow
- `run_sync_smoke=true`
- 若只想跑同步 smoke，建议：
  - `run_local_smoke=false`
  - `apply_migrations=false`
  - `deploy_functions=false`
  - `run_function_smoke=false`
  - `build_apk=false`

CLI：

```bash
gh workflow run saas_core_staging.yml \
  --ref main \
  -f run_local_smoke=false \
  -f run_sync_smoke=true \
  -f apply_migrations=false \
  -f deploy_functions=false \
  -f run_function_smoke=false \
  -f build_apk=false
```

说明：现有 workflow 仍会执行 migration dry-run，这是 core staging lane 的既有行为。

## 验证

已通过 Bash 语法检查：

```bash
bash -n scripts/run_saas_core_staging_lane.sh scripts/run_saas_staging_sync_smoke.sh
```

已通过 lane help 检查：

```bash
scripts/run_saas_core_staging_lane.sh --help
```

已通过 workflow YAML 解析：

```bash
ruby -e 'require "yaml"; YAML.load_file(".github/workflows/saas_core_staging.yml"); puts "yaml ok"'
```

已通过 diff 空白检查：

```bash
git diff --check
```

## 后续验证

合并后触发一次 `SaaS Core Staging` 手动 workflow，并设置 `run_sync_smoke=true`。预期结果：

- `Guard core staging secrets` 通过。
- `Run core staging lane` 中出现 `running staging core sync smoke`。
- artifact `saas-staging-reports-<run_id>` 包含 `sync-smoke-*/summary.md` 与脱敏 JSON。
- core sync smoke summary 为 `PASS`。

## Post-Merge 实测

已在 main 上触发手动 workflow：

```bash
gh workflow run saas_core_staging.yml \
  --ref main \
  -f run_local_smoke=false \
  -f run_sync_smoke=true \
  -f apply_migrations=false \
  -f deploy_functions=false \
  -f run_function_smoke=false \
  -f build_apk=false
```

结果：

- Workflow run: `24783963356`
- URL: `https://github.com/zensgit/jive/actions/runs/24783963356`
- Head SHA: `236764686ce0710913626514799a6a60b407f045`
- Status: `success`
- Job: `core_staging` passed
- `Guard core staging secrets`: passed
- `Run core staging lane`: passed
- `Upload SaaS staging reports`: passed

日志确认：

```text
[saas-core-lane] running staging core sync smoke
[saas-sync-smoke] PASS
[saas-core-lane] core staging lane completed
```

Artifact 确认：

- `saas-staging-reports-24783963356`
- `reports/saas-staging/sync-smoke-20260422-142825/summary.md`
- `reports/saas-staging/sync-smoke-20260422-142825/summary.json`
- `reports/saas-staging/sync-smoke-20260422-142825/*.redacted.json`

Summary 确认：

```text
status: PASS
cleanup: complete
bookKey: book_default
```

Validated checks:

- `admin_user_create`
- `anon_password_sign_in_session_1`
- `anon_password_sign_in_session_2`
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

Secret scan against downloaded artifacts found no token/key/password values; only validation labels such as `anon_password_sign_in_session_1` matched the broad search pattern.
