# Jive SaaS Post-Merge 30-Minute Checklist

> 日期: 2026-04-10
> 主线 PR: [#144](https://github.com/zensgit/jive/pull/144)
> 当前 head: `a4bedeb`
> 目标: `#144` 合入 `main` 后 30 分钟内完成最小主线验收与 staging 落地

## 使用方式

这份清单不是替代完整 runbook，而是给操作当天直接照着执行的短版本。

完整细节仍参考：
- [2026-04-10-saas-fast-track-checklist.md](/Users/chauhua/Documents/GitHub/Jive/worktrees/codex-saas-mainline-next/docs/2026-04-10-saas-fast-track-checklist.md)
- [2026-04-10-saas-staging-apply-runbook.md](/Users/chauhua/Documents/GitHub/Jive/worktrees/codex-saas-mainline-next/docs/2026-04-10-saas-staging-apply-runbook.md)

## T+0 分钟：完成主线 merge

- [ ] 在 GitHub 将 [#144](https://github.com/zensgit/jive/pull/144) 从 `draft` 改成 `ready`
- [ ] 选择 `Create a merge commit`
- [ ] 确认 `main` 已包含 `#144`

## T+5 分钟：fresh main 验证

- [ ] 新开一个 fresh `main` worktree 或全新 clone
- [ ] 拉取最新 `origin/main`
- [ ] 运行：

```bash
bash scripts/run_saas_wave0_smoke.sh
```

- [ ] 结果必须为通过

失败即回退到：
- [ ] 先不要继续 staging deploy
- [ ] 保存失败日志
- [ ] 优先检查 sync / billing / auth / ops 哪一组失败

## T+10 分钟：staging 前置准备

- [ ] 已拿到 `SUPABASE_ACCESS_TOKEN`
- [ ] 已拿到 `STAGING_PROJECT_REF`
- [ ] 已拿到 `STAGING_DB_PASSWORD`
- [ ] 已准备 `/tmp/jive-saas-staging.env`
- [ ] 已从模板复制：

```bash
cp docs/jive-saas-staging.env.example /tmp/jive-saas-staging.env
```

- [ ] 先跑预检查：

```bash
scripts/run_saas_staging_rollout.sh preflight \
  --project-ref "$STAGING_PROJECT_REF" \
  --db-password "$STAGING_DB_PASSWORD" \
  --access-token "$SUPABASE_ACCESS_TOKEN" \
  --env-file /tmp/jive-saas-staging.env
```

运行时 secrets 至少要包含：
- [ ] `SUPABASE_URL`
- [ ] `SUPABASE_ANON_KEY`
- [ ] `SUPABASE_SERVICE_ROLE_KEY`
- [ ] `GOOGLE_SERVICE_ACCOUNT_EMAIL`
- [ ] `GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY`
- [ ] `GOOGLE_PLAY_PACKAGE_NAME`
- [ ] `APPLE_APP_STORE_BUNDLE_ID`
- [ ] `APPLE_APP_STORE_SHARED_SECRET`
- [ ] `APPLE_APP_STORE_APPLE_ID`
- [ ] `APPLE_APP_STORE_ENVIRONMENT`
- [ ] `PUBSUB_BEARER_TOKEN`
- [ ] `WEBHOOK_HMAC_SECRET`
- [ ] `ADMIN_API_TOKEN`
- [ ] `ADMIN_API_ALLOWED_ORIGINS`
- [ ] `ANALYTICS_ADMIN_TOKEN`
- [ ] `NOTIFICATION_ADMIN_TOKEN`

## T+15 分钟：staging 数据库 apply

- [ ] 进入工作树：

```bash
cd /Users/chauhua/Documents/GitHub/Jive/worktrees/codex-saas-mainline-next
```

- [ ] link staging：

```bash
scripts/run_saas_staging_rollout.sh dry-run \
  --project-ref "$STAGING_PROJECT_REF" \
  --db-password "$STAGING_DB_PASSWORD" \
  --access-token "$SUPABASE_ACCESS_TOKEN"
```

- [ ] 确认 dry-run 输出包含这组迁移：
- [ ] `004_add_book_key.sql`
- [ ] `006_add_sync_tombstones.sql`
- [ ] `007_create_user_subscriptions.sql`
- [ ] `008_add_sync_keys_for_core_sync.sql`
- [ ] `009_webhook_idempotency.sql`
- [ ] `010_create_analytics_events.sql`
- [ ] `011_create_notification_queue.sql`
- [ ] `012_allow_admin_subscription_override.sql`

- [ ] 再正式 apply：

```bash
scripts/run_saas_staging_rollout.sh apply \
  --project-ref "$STAGING_PROJECT_REF" \
  --db-password "$STAGING_DB_PASSWORD" \
  --access-token "$SUPABASE_ACCESS_TOKEN"
```

## T+20 分钟：staging secrets 与 functions deploy

- [ ] 推送 secrets 并部署 Functions：

```bash
scripts/run_saas_staging_rollout.sh deploy \
  --project-ref "$STAGING_PROJECT_REF" \
  --access-token "$SUPABASE_ACCESS_TOKEN" \
  --env-file /tmp/jive-saas-staging.env
```

- [ ] 确认 5 个 Functions 在 Dashboard 中可见并是最新版本

## T+30 分钟：最小业务验收

数据库层：
- [ ] `user_subscriptions` 存在
- [ ] `sync_tombstones` 存在
- [ ] analytics / notification 相关表存在
- [ ] `shared_ledgers.workspace_key` 存在

API / 配置层：
- [ ] `ADMIN_API_ALLOWED_ORIGINS` 不为空
- [ ] webhook / admin token 已注入
- [ ] Apple / Google 相关 secrets 已注入

功能层：
- [ ] Billing webhook 可部署
- [ ] verify-subscription 可部署
- [ ] analytics 可部署
- [ ] send-notification 可部署
- [ ] admin 可部署

## T+35 分钟：PR 收尾

- [ ] 用 [2026-04-10-saas-pr-cleanup-map.md](/Users/chauhua/Documents/GitHub/Jive/worktrees/codex-saas-mainline-next/docs/2026-04-10-saas-pr-cleanup-map.md) 确认每个旧 PR 的收尾类别
- [ ] 用 [print_saas_pr_cleanup_comments.sh](/Users/chauhua/Documents/GitHub/Jive/worktrees/codex-saas-mainline-next/scripts/print_saas_pr_cleanup_comments.sh) 生成评论模板
- [ ] 在旧 clean PR 上标注 `merged via #144`
- [ ] 在旧污染 / 已替代 PR 上标注 `superseded by #144`

## 完成标准

满足以下 3 条即可视为 SaaS Beta 已完成主线收口：

1. [#144](https://github.com/zensgit/jive/pull/144) 已 merge 到 `main`
2. fresh `main` 上 `bash scripts/run_saas_wave0_smoke.sh` 通过
3. staging 迁移和 5 个 Functions 已部署完成

## 当前真正阻塞

如果今天还不能完成，不是代码阻塞，而是这几项环境阻塞：
- GitHub UI 的 merge 还没执行
- staging project ref 还没提供
- staging DB password 还没提供
- staging access token / runtime secrets 还没提供
