# Jive SaaS Staging Apply / Deploy Runbook

> 日期: 2026-04-10
> 更新: 2026-04-18
> 主线基线: `main`
> 部署测试入口: [#159](https://github.com/zensgit/jive/pull/159)
> 目标: 在 staging 环境完成 SaaS Beta 的数据库迁移、Edge Function secrets 注入、Functions deploy 与最小验收

## 适用前提

这份 runbook 假设 SaaS Beta 已经在 `main`，并且 [#159](https://github.com/zensgit/jive/pull/159) 的部署 readiness 脚本已合并。

当前代码侧已满足：
- `bash scripts/run_saas_wave0_smoke.sh` 可作为本地 SaaS Wave0 smoke
- `bash scripts/check_saas_deployment_readiness.sh --profile core` 可作为静态 readiness gate
- `bash scripts/run_saas_core_staging_lane.sh --env-file /tmp/jive-saas-staging.env` 可作为 core staging 一键 lane

当前环境侧仍需要你补齐：
- staging Supabase project ref
- staging deploy 凭据
- staging 所需 secrets 的真实值

## 已确认的 CLI 入口

本机可以直接使用：

```bash
npx -y supabase@latest --version
```

当前验证过的命令帮助：

```bash
npx -y supabase@latest help link
npx -y supabase@latest help db push
npx -y supabase@latest help secrets set
npx -y supabase@latest help functions deploy
```

当前仓库提供了两个执行入口：

```bash
bash scripts/run_saas_core_staging_lane.sh --help
bash scripts/run_saas_staging_rollout.sh help
```

在真正 apply/deploy 前，建议先跑：

```bash
bash scripts/check_saas_deployment_readiness.sh \
  --profile core \
  --strict \
  --online \
  --env-file /tmp/jive-saas-staging.env
```

说明：
- 这台机器没有预装 `supabase` 到 PATH
- 但可以用 `npx -y supabase@latest ...` 执行
- 本机 Docker 当前不可用，所以 Functions deploy 建议使用 `--use-api`

## 需要准备的变量

### 1. 连接与目标
- `SUPABASE_ACCESS_TOKEN`
- `STAGING_PROJECT_REF`
- `STAGING_DB_PASSWORD`

备注：如果已经换过 staging 项目，以 Supabase Dashboard 当前值为准。

### 2. Functions 运行时 secrets

这些是当前代码实际读取的环境变量。

共享基础：
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`

说明：
- 在 Supabase 托管的 Edge Functions 中，这 3 个 `SUPABASE_*` 变量由平台默认提供
- `run_saas_staging_rollout.sh deploy` 不再把它们通过 `supabase secrets set` 重复推送
- 如果需要本地 `supabase functions serve` 或构建客户端 APK，仍可以把它们保留在本地 env file

Billing / Google：
- `GOOGLE_SERVICE_ACCOUNT_EMAIL`
- `GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY`
- `GOOGLE_PLAY_PACKAGE_NAME`

Billing / Apple：
- `APPLE_APP_STORE_BUNDLE_ID`
- `APPLE_APP_STORE_SHARED_SECRET`
- `APPLE_APP_STORE_APPLE_ID`
- `APPLE_APP_STORE_ENVIRONMENT`

Webhook 安全：
- `PUBSUB_BEARER_TOKEN`
- `WEBHOOK_HMAC_SECRET`

Ops / Admin：
- `ADMIN_API_TOKEN`
- `ADMIN_API_ALLOWED_ORIGINS`
- `ANALYTICS_ADMIN_TOKEN`
- `NOTIFICATION_ADMIN_TOKEN`

### 2.1 Core SaaS 最小 secrets

如果当前只想先验证服务器上的登录、同步和运营后台，而不接商店订阅，可先只准备：

- `ADMIN_API_TOKEN`
- `ADMIN_API_ALLOWED_ORIGINS`
- `ANALYTICS_ADMIN_TOKEN`
- `NOTIFICATION_ADMIN_TOKEN`

这条路径会：
- 仍然 apply 全部数据库迁移
- 只推送 Core SaaS 所需 secrets
- 只部署 `analytics`、`send-notification`、`admin`
- 跳过 `subscription-webhook` 与 `verify-subscription`

如果还要继续执行客户端 APK 构建或真实 App 端联调，仍需要在 env file 中补齐客户端安全的 `SUPABASE_URL` 与 `SUPABASE_ANON_KEY`。

## 迁移顺序

本轮 staging apply 关注以下迁移：

1. `004_add_book_key.sql`
2. `006_add_sync_tombstones.sql`
3. `007_create_user_subscriptions.sql`
4. `008_add_sync_keys_for_core_sync.sql`
5. `009_webhook_idempotency.sql`
6. `010_create_analytics_events.sql`
7. `011_create_notification_queue.sql`
8. `012_allow_admin_subscription_override.sql`

当前仓库里这些文件都已经存在于：
- [supabase/migrations](/Users/chauhua/Documents/GitHub/Jive/app/supabase/migrations)

## 推荐执行顺序

### 一键脚本入口

如果你已经有 staging 凭据，推荐优先使用 core 一键 lane：

```bash
bash scripts/run_saas_core_staging_lane.sh \
  --env-file /tmp/jive-saas-staging.env
```

如果当前 staging 项目的 `supabase db push` 卡在远端数据库连接阶段，可以在分步入口启用 Postgres fallback：

```bash
bash scripts/run_saas_staging_rollout.sh all \
  --profile core \
  --pg-fallback-only \
  --project-ref "$STAGING_PROJECT_REF" \
  --db-password "$STAGING_DB_PASSWORD" \
  --access-token "$SUPABASE_ACCESS_TOKEN" \
  --db-url "$STAGING_DB_URL" \
  --env-file /tmp/jive-saas-staging.env
```

如果远端负载较高，也可以放宽 fallback 的锁和语句超时：

```bash
bash scripts/run_saas_staging_rollout.sh all \
  --profile core \
  --pg-fallback-only \
  --pg-lock-timeout 10s \
  --pg-statement-timeout 180s \
  --project-ref "$STAGING_PROJECT_REF" \
  --db-password "$STAGING_DB_PASSWORD" \
  --access-token "$SUPABASE_ACCESS_TOKEN" \
  --db-url "$STAGING_DB_URL" \
  --env-file /tmp/jive-saas-staging.env
```

如果你想分步执行，则继续按下面的手工步骤。

### Step 1. 进入主线工作树

```bash
cd /Users/chauhua/Documents/GitHub/Jive/app
```

### Step 2. 配置 staging 变量

```bash
export SUPABASE_ACCESS_TOKEN='你的_access_token'
export STAGING_PROJECT_REF='你的_project_ref'
export STAGING_DB_PASSWORD='你的_db_password'
```

### Step 3. link 到 staging 项目

```bash
npx -y supabase@latest link \
  --project-ref "$STAGING_PROJECT_REF" \
  --password "$STAGING_DB_PASSWORD" \
  --workdir /Users/chauhua/Documents/GitHub/Jive/app
```

### Step 4. 先 dry-run 看远端将应用哪些迁移

```bash
npx -y supabase@latest db push \
  --include-all \
  --dry-run \
  --workdir /Users/chauhua/Documents/GitHub/Jive/app
```

预期：
- 输出里应包含 `004 / 006 / 007 / 008 / 009 / 010 / 011 / 012`
- 如果远端已有一部分迁移，CLI 会只显示 pending 部分

如果 CLI 卡在 `Connecting to remote database`，改走 fallback dry-run：

```bash
bash scripts/run_saas_staging_rollout.sh dry-run \
  --profile core \
  --pg-fallback-only \
  --project-ref "$STAGING_PROJECT_REF" \
  --db-password "$STAGING_DB_PASSWORD" \
  --access-token "$SUPABASE_ACCESS_TOKEN" \
  --db-url "$STAGING_DB_URL"
```

预期：
- 输出 `remote_history_versions`
- 输出 `baseline_versions`
- 输出 `pending_versions`
- 具体 baseline / pending 组合以远端实时状态为准

### Step 5. 正式 apply 迁移

```bash
npx -y supabase@latest db push \
  --include-all \
  --workdir /Users/chauhua/Documents/GitHub/Jive/app
```

如果使用 fallback apply：

```bash
bash scripts/run_saas_staging_rollout.sh apply \
  --profile core \
  --pg-fallback-only \
  --project-ref "$STAGING_PROJECT_REF" \
  --db-password "$STAGING_DB_PASSWORD" \
  --access-token "$SUPABASE_ACCESS_TOKEN" \
  --db-url "$STAGING_DB_URL"
```

### Step 6. 准备 secrets 文件

建议直接复制模板文件再填值：

```bash
cp docs/jive-saas-staging.env.example /tmp/jive-saas-staging.env
```

然后编辑：

```bash
$EDITOR /tmp/jive-saas-staging.env
```

说明：
- [jive-saas-staging.env.example](/Users/chauhua/Documents/GitHub/Jive/app/docs/jive-saas-staging.env.example) 已包含当前 5 个 Edge Functions 需要的全部变量
- `GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY` 需要保持为单行，并将换行写成 `\\n`
- 如果想先检查变量和 secrets 是否齐，再执行 apply/deploy，先跑 `preflight`

### Step 7. 推送 secrets

```bash
npx -y supabase@latest secrets set \
  --env-file /tmp/jive-saas-staging.env \
  --project-ref "$STAGING_PROJECT_REF" \
  --workdir /Users/chauhua/Documents/GitHub/Jive/app
```

### Step 8. 部署 5 个 Edge Functions

由于这台机器 Docker 不可用，建议统一走 `--use-api`。

推荐优先使用脚本部署，因为它会自动区分鉴权模式：

- `verify-subscription` 保持 Supabase JWT verification，用于真实用户会话。
- `subscription-webhook` / `analytics` / `send-notification` / `admin` 使用函数内自定义 token 鉴权，因此部署时需要 `--no-verify-jwt`，否则 Supabase 网关会先拦截自定义 token。

```bash
bash scripts/run_saas_staging_rollout.sh deploy \
  --profile core \
  --project-ref "$STAGING_PROJECT_REF" \
  --access-token "$SUPABASE_ACCESS_TOKEN" \
  --env-file /tmp/jive-saas-staging.env
```

如果手工执行，命令如下：

```bash
npx -y supabase@latest functions deploy subscription-webhook \
  --project-ref "$STAGING_PROJECT_REF" \
  --use-api \
  --no-verify-jwt \
  --workdir /Users/chauhua/Documents/GitHub/Jive/app

npx -y supabase@latest functions deploy verify-subscription \
  --project-ref "$STAGING_PROJECT_REF" \
  --use-api \
  --workdir /Users/chauhua/Documents/GitHub/Jive/app

npx -y supabase@latest functions deploy analytics \
  --project-ref "$STAGING_PROJECT_REF" \
  --use-api \
  --no-verify-jwt \
  --workdir /Users/chauhua/Documents/GitHub/Jive/app

npx -y supabase@latest functions deploy send-notification \
  --project-ref "$STAGING_PROJECT_REF" \
  --use-api \
  --no-verify-jwt \
  --workdir /Users/chauhua/Documents/GitHub/Jive/app

npx -y supabase@latest functions deploy admin \
  --project-ref "$STAGING_PROJECT_REF" \
  --use-api \
  --no-verify-jwt \
  --workdir /Users/chauhua/Documents/GitHub/Jive/app
```

## 最小验收清单

### A. 数据库
- `user_subscriptions` 存在
- `sync_tombstones` 存在
- analytics / notification / webhook 相关表存在
- `shared_ledgers.workspace_key`、核心 sync key 字段存在

### B. Functions
- `subscription-webhook`
- `verify-subscription`
- `analytics`
- `send-notification`
- `admin`

都已部署成功，且 Dashboard 中可见最新版本

### C. 配置
- `ADMIN_API_ALLOWED_ORIGINS` 不为空
- Apple / Google / webhook / admin token 等 secrets 已注入
- staging 的 `SUPABASE_URL` / `SUPABASE_ANON_KEY` / `SERVICE_ROLE_KEY` 与目标项目匹配

### D. 代码基线
- 以 `main` 为准
- 部署 readiness 证据链参考：
  - [2026-04-18-saas-deployment-test-readiness.md](/Users/chauhua/Documents/GitHub/Jive/app/docs/2026-04-18-saas-deployment-test-readiness.md)
  - [2026-04-09-saas-beta-verification-closure.md](/Users/chauhua/Documents/GitHub/Jive/app/docs/2026-04-09-saas-beta-verification-closure.md)
  - [2026-04-10-saas-beta-mainline-merge-strategy.md](/Users/chauhua/Documents/GitHub/Jive/app/docs/2026-04-10-saas-beta-mainline-merge-strategy.md)

## 常见阻塞与处理

更完整的值班手册见：
- [2026-04-10-saas-staging-troubleshooting.md](/Users/chauhua/Documents/GitHub/Jive/app/docs/2026-04-10-saas-staging-troubleshooting.md)

### 1. `Cannot connect to the Docker daemon`
原因：
- 本机 Docker 当前不可用

处理：
- `functions deploy` 一律加 `--use-api`
- `db push` 是远端操作，不依赖本机 Docker

### 2. `project ref not linked`
原因：
- 仓库当前没有 staging link

处理：
- 先执行 `supabase link --project-ref ...`

### 3. `missing env` / `unauthorized`
原因：
- staging secrets 未注入完整
- `SUPABASE_ACCESS_TOKEN` 未设置或权限不足

处理：
- 先补齐 `/tmp/jive-saas-staging.env`
- 重新执行 `secrets set`

### 4. `db push` 显示远端历史异常
原因：
- 远端 migration history 与本地不一致

处理：
- 先保留 `--dry-run` 输出
- 不要手工跳过当前 004/006/007/008/009/010/011/012 这组编号
- 先比对远端已执行历史，再决定是否需要单独修复 migration history

## 结论

当前最快的 SaaS 化路径已经不是继续写代码，而是：

1. 合并 [#159](https://github.com/zensgit/jive/pull/159)
2. 用 `scripts/run_saas_core_staging_lane.sh` 在 staging 做一次完整 core apply / deploy / smoke / APK build
3. 以 staging 结果作为 Beta 主线的最终环境验收
