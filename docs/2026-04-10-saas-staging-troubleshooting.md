# Jive SaaS Staging Troubleshooting

> 日期: 2026-04-10
> 主线 PR: [#144](https://github.com/zensgit/jive/pull/144)
> 当前 head: `a4bedeb`
> 用途: staging apply / deploy 失败时的值班式快速排查单

## 先做这一步

先跑预检查，不要直接盲目重试：

```bash
scripts/run_saas_staging_rollout.sh preflight \
  --project-ref "$STAGING_PROJECT_REF" \
  --db-password "$STAGING_DB_PASSWORD" \
  --access-token "$SUPABASE_ACCESS_TOKEN" \
  --env-file /tmp/jive-saas-staging.env
```

这一步会检查：
- Supabase CLI 是否可运行
- `STAGING_PROJECT_REF`
- `STAGING_DB_PASSWORD`
- `SUPABASE_ACCESS_TOKEN`
- `/tmp/jive-saas-staging.env` 是否存在
- secrets 文件里 16 个必需键是否都有值

## 值班顺序

1. 先看 `preflight`
2. 再看 `dry-run`
3. 再看 `apply`
4. 再看 `deploy`
5. 最后再看业务验收

不要跳过这个顺序，否则很容易把“缺凭据”和“真迁移问题”混在一起。

## 故障对照表

### 1. `missing required value`
症状：
- 脚本直接报 `missing required value`

原因：
- `STAGING_PROJECT_REF`
- `STAGING_DB_PASSWORD`
- `SUPABASE_ACCESS_TOKEN`
  其中至少一个没传

处理：
- 先 export 变量，或在命令后带 `--project-ref / --db-password / --access-token`

### 2. `env file not found`
症状：
- `preflight` 或 `deploy` 报 `env file not found`

原因：
- `/tmp/jive-saas-staging.env` 不存在

处理：

```bash
cp docs/jive-saas-staging.env.example /tmp/jive-saas-staging.env
$EDITOR /tmp/jive-saas-staging.env
```

### 3. `env:KEY: missing or empty`
症状：
- `preflight` 输出某个 `env:... missing or empty`

原因：
- secrets 文件里有键名但没值
- 或键根本没填

处理：
- 先补齐 `/tmp/jive-saas-staging.env`
- 特别注意 `GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY` 要保持单行，换行写成 `\\n`

### 4. `Cannot connect to the Docker daemon`
症状：
- `supabase functions deploy` 报 Docker daemon 连接错误

原因：
- 本机 Docker 不可用

处理：
- 使用脚本内置的 `--use-api`
- 不要把 deploy 改回本地 Docker bundle

### 5. `project ref not linked`
症状：
- `db push` 提示项目未 link

原因：
- staging project 还没 link
- 或 link 状态失效

处理：

```bash
scripts/run_saas_staging_rollout.sh dry-run \
  --project-ref "$STAGING_PROJECT_REF" \
  --db-password "$STAGING_DB_PASSWORD" \
  --access-token "$SUPABASE_ACCESS_TOKEN"
```

### 6. `unauthorized` / `forbidden`
症状：
- `link`
- `db push`
- `secrets set`
- `functions deploy`
  任一步返回 401/403

原因：
- `SUPABASE_ACCESS_TOKEN` 无效或权限不足
- `STAGING_PROJECT_REF` 指向错误项目

处理：
- 先核对 access token 是否属于目标组织/项目
- 再核对 project ref 是否正确

### 7. `db push --dry-run` 输出不包含 004/006/007/008/009/010/011/012
症状：
- dry-run 没出现预期迁移编号

原因：
- 远端已经应用过一部分迁移
- 或远端 migration history 不一致

处理：
- 如果只是“少了部分编号”，先确认是不是远端已应用
- 如果 history 明显错乱，先不要继续 apply
- 保留 dry-run 输出，单独处理 migration history

### 8. `functions deploy` 成功但 Dashboard 看不到最新版本
症状：
- CLI 看起来成功，但 Dashboard 不是最新代码

原因：
- project ref 指错
- deploy 到了错误项目

处理：
- 重新核对 `STAGING_PROJECT_REF`
- 重新执行单个 function deploy 验证

### 9. fresh `main` smoke 失败
症状：
- `bash scripts/run_saas_wave0_smoke.sh` 失败

原因：
- 主线合并后存在真实回归

处理：
- 先不要继续 staging rollout
- 先记录失败组别：
  - sync
  - billing webhook
  - billing verify / client truth
  - auth
  - ops analytics
  - ops notification
  - ops admin
- 失败组别定位完成前，不要硬推 staging

## 最快止血策略

如果 staging rollout 当天只想先把阻塞压缩到最小：

1. 跑 `preflight`
2. 跑 `dry-run`
3. 只在 `dry-run` 正常后再 `apply`
4. `apply` 成功后再 `deploy`
5. 任何一步失败都先停，不要连续盲重试

## 配套入口

- [run_saas_staging_rollout.sh](/Users/chauhua/Documents/GitHub/Jive/worktrees/codex-saas-mainline-next/scripts/run_saas_staging_rollout.sh)
- [jive-saas-staging.env.example](/Users/chauhua/Documents/GitHub/Jive/worktrees/codex-saas-mainline-next/docs/jive-saas-staging.env.example)
- [2026-04-10-saas-staging-apply-runbook.md](/Users/chauhua/Documents/GitHub/Jive/worktrees/codex-saas-mainline-next/docs/2026-04-10-saas-staging-apply-runbook.md)
- [2026-04-10-saas-post-merge-30min-checklist.md](/Users/chauhua/Documents/GitHub/Jive/worktrees/codex-saas-mainline-next/docs/2026-04-10-saas-post-merge-30min-checklist.md)
