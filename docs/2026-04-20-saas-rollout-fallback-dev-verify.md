# SaaS Staging Rollout Fallback 开发与验证报告

> 日期: 2026-04-20  
> 分支: `codex/saas-staging-rollout-fallback-restack`  
> 目标 PR: `#148` 前移到当前 `main` 基线  
> 范围: staging rollout fallback、core profile 精简部署、部署验证链路修复、旧 PR 队列清理

## 1. 背景

原 `#148` 分支与当前 `main` 是 unrelated histories，不能直接 merge 或常规 rebase。为避免把旧历史和旧 CI 基线带回主线，本次采用“按价值前移”的方式，只保留仍有部署价值的部分：

- Supabase CLI `db push` 失败时的 direct Postgres fallback。
- Core SaaS 首轮部署只推送最小 secrets。
- Core SaaS 首轮部署只部署非商店依赖函数。
- 避免通过 `supabase secrets set` 重复推送 Supabase 托管平台默认提供的 `SUPABASE_*` 变量。
- 修复 SaaS Wave0 smoke 在本机找不到 Flutter SDK 的问题。

## 2. 已清理的旧 PR

以下 PR 已关闭为 superseded，避免继续消耗 CI/Review 额度：

- `#146` `feat: support core-only SaaS staging rollout`
- `#145` `docs(saas): update post-merge rollout status`
- `#123` `docs(saas): audit sync safety wording`
- `#121` `feat(saas): forward-port B1.3 sync tombstones`
- `#119` `feat(B1.3): sync tombstones for delete conflicts`
- `#118` `feat(B1.2): reduce sync dependence on local account ids`
- `#117` `feat(B1.1): scope sync data by book key`

## 3. 开发内容

### 3.1 `scripts/run_saas_staging_rollout.sh`

- 新增 `--db-url`、`--pg-fallback`、`--pg-fallback-only`、`--pg-lock-timeout`、`--pg-statement-timeout`。
- 保留当前 `main` 的 `--profile core|full` 模型。
- 兼容旧参数 `--core-only`，作为 `--profile core` 的别名。
- `core` profile 只要求并推送 4 个核心 secrets：
  - `ADMIN_API_TOKEN`
  - `ADMIN_API_ALLOWED_ORIGINS`
  - `ANALYTICS_ADMIN_TOKEN`
  - `NOTIFICATION_ADMIN_TOKEN`
- `core` profile 只部署 3 个核心函数：
  - `analytics`
  - `send-notification`
  - `admin`
- `full` profile 仍部署 5 个 SaaS 函数：
  - `subscription-webhook`
  - `verify-subscription`
  - `analytics`
  - `send-notification`
  - `admin`
- `verify-subscription` 保持 Supabase JWT verification。
- `subscription-webhook`、`analytics`、`send-notification`、`admin` 继续使用 `--no-verify-jwt`，由函数内 token 逻辑鉴权。
- secrets 推送前生成临时 subset env file，避免把托管平台默认的 `SUPABASE_URL`、`SUPABASE_ANON_KEY`、`SUPABASE_SERVICE_ROLE_KEY` 再次写入项目 secrets。

### 3.2 `scripts/supabase_db_fallback.py`

- 新增 direct Postgres fallback helper。
- 支持 `plan` 和 `apply` 两种模式。
- 读取远端 schema 与 `supabase_migrations.schema_migrations`。
- 对已经存在但未记录的迁移做 baseline。
- 对缺失迁移按顺序 apply。
- 只允许显式审核过的迁移版本，遇到未知迁移会失败退出，避免误执行未审 SQL。

### 3.3 `scripts/run_saas_core_staging_lane.sh`

- 新增 passthrough 参数：
  - `--db-url`
  - `--pg-fallback`
  - `--pg-fallback-only`
  - `--pg-lock-timeout`
  - `--pg-statement-timeout`
- Core 一键 lane 可以直接进入 fallback 路径，不需要用户绕到底层 rollout 脚本。

### 3.4 `scripts/run_saas_wave0_smoke.sh`

- Flutter SDK 探测路径与 readiness/build 脚本对齐。
- 新增候选路径：
  - `$HOME/development/flutter/bin/flutter`
  - `$HOME/flutter/bin/flutter`
  - `/opt/homebrew/bin/flutter`

### 3.5 文档

- `docs/jive-saas-staging.env.example` 标明：
  - Supabase 托管环境默认提供 `SUPABASE_*`。
  - Core SaaS 最小 rollout 只需要 4 个 admin/ops secrets。
  - `SUPABASE_URL` 与 `SUPABASE_ANON_KEY` 仍用于本地 serve 或客户端 APK 构建。
- `docs/2026-04-10-saas-staging-apply-runbook.md` 增加 fallback dry-run/apply/all 示例。
- `docs/2026-04-10-saas-staging-troubleshooting.md` 增加 `db push` 卡连接、`psycopg` 缺失、fallback 白名单限制说明。

## 4. 本地验证

### 4.1 Shell / Python 静态验证

```bash
bash -n scripts/run_saas_staging_rollout.sh scripts/run_saas_core_staging_lane.sh scripts/run_saas_wave0_smoke.sh
python3 -m py_compile scripts/supabase_db_fallback.py
git diff --check
```

结果：

- 通过。

### 4.2 帮助文案验证

```bash
bash scripts/run_saas_staging_rollout.sh help
bash scripts/run_saas_core_staging_lane.sh --help
```

结果：

- `--profile core|full` 可见。
- `--core-only` 兼容别名可见。
- `--pg-fallback` / `--pg-fallback-only` / timeout 参数可见。

### 4.3 Core profile 行为验证

使用 fake Supabase CLI 验证 `deploy --profile core`。

结果：

- 只推送 4 个 secrets：
  - `ADMIN_API_TOKEN`
  - `ADMIN_API_ALLOWED_ORIGINS`
  - `ANALYTICS_ADMIN_TOKEN`
  - `NOTIFICATION_ADMIN_TOKEN`
- 只部署 3 个函数：
  - `analytics`
  - `send-notification`
  - `admin`
- 3 个函数均带 `--no-verify-jwt`。
- 未推送 `SUPABASE_URL`、`SUPABASE_ANON_KEY`、`SUPABASE_SERVICE_ROLE_KEY`。

### 4.4 Full profile 行为验证

使用 fake Supabase CLI 验证 `deploy --profile full`。

结果：

- 推送 Google / Apple / webhook / admin / ops secrets subset。
- 部署 5 个函数。
- `verify-subscription` 不带 `--no-verify-jwt`。
- 其他 4 个函数带 `--no-verify-jwt`。
- 未推送 `SUPABASE_URL`、`SUPABASE_ANON_KEY`、`SUPABASE_SERVICE_ROLE_KEY`。

### 4.5 Readiness 验证

```bash
STAGING_PROJECT_REF=projectref \
STAGING_DB_PASSWORD=password \
SUPABASE_ACCESS_TOKEN=token \
bash scripts/check_saas_deployment_readiness.sh \
  --profile core \
  --strict \
  --env-file "$TEMP_ENV_FILE" \
  --skip-github
```

结果：

- 通过。
- `failures=0 warnings=0 profile=core strict=1 online=0 run_smoke=0`。

### 4.6 Flutter Analyze

```bash
/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos
```

结果：

- 通过，退出码 0。
- 当前仍有既有 info 级 lint，未新增 analyzer error。
- 本次输出为 `80 issues found`，全部为 info 级。

### 4.7 SaaS Wave0 Smoke

```bash
bash scripts/run_saas_wave0_smoke.sh
```

结果：

- 通过。
- sync smoke 通过。
- billing webhook Deno check/test 通过。
- billing client/server-truth analyze 通过。
- subscription status / lifecycle / App Store payment Flutter tests 通过。
- verify-subscription Deno check/test 通过。
- auth analyze / Flutter tests 通过。
- analytics / send-notification / admin Deno check/test 通过。

## 5. 环境处理

本机安装了 fallback 所需 Python 依赖：

```bash
python3 -m pip install --user 'psycopg[binary]'
```

安装结果：

- `psycopg==3.2.13`
- `psycopg-binary==3.2.13`

## 6. 未执行项

- 未对真实 Supabase staging 数据库执行 `plan/apply`，因为本次本地验证没有使用真实 `STAGING_DB_URL`。
- 未推送真实 Supabase secrets，验证使用 fake Supabase CLI，避免误写线上或 staging 配置。
- 未合并 `#147` 国内支付设计 PR；它仍有价值，但属于独立较大 PR，建议下一步单独 restack。

## 7. 下一步建议

1. 将本分支 force-push 到 `codex/saas-staging-rollout-fallback`，更新 `#148`。
2. 等待 `#148` CI 通过后合并。
3. 单独处理 `#147` 国内支付设计与 provider resolver。
4. 对 stacked SaaS PR 按依赖顺序继续 restack：
   - `#140`
   - `#137`
   - `#133`
   - `#131`
   - `#130`
