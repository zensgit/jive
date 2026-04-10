# Jive SaaS Fast-Track Checklist

> 日期: 2026-04-10
> 推荐主线: [#144](https://github.com/zensgit/jive/pull/144)
> 当前 head: `83ecd5d`

## 目标

把 Jive SaaS Beta 以最快路径收口到主线并落到 staging。

## 快执行计划

1. 在 GitHub 把 [#144](https://github.com/zensgit/jive/pull/144) 从 `draft` 改成 `ready`
2. 使用 `Create a merge commit` 合并 [#144](https://github.com/zensgit/jive/pull/144) 到 `main`
3. 在 fresh `main` worktree 上运行：

```bash
bash scripts/run_saas_wave0_smoke.sh
```

4. 准备 staging 变量：
- `SUPABASE_ACCESS_TOKEN`
- `STAGING_PROJECT_REF`
- `STAGING_DB_PASSWORD`

5. 准备 staging secrets：
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
- `GOOGLE_SERVICE_ACCOUNT_EMAIL`
- `GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY`
- `GOOGLE_PLAY_PACKAGE_NAME`
- `APPLE_APP_STORE_BUNDLE_ID`
- `APPLE_APP_STORE_SHARED_SECRET`
- `APPLE_APP_STORE_APPLE_ID`
- `APPLE_APP_STORE_ENVIRONMENT`
- `PUBSUB_BEARER_TOKEN`
- `WEBHOOK_HMAC_SECRET`
- `ADMIN_API_TOKEN`
- `ADMIN_API_ALLOWED_ORIGINS`
- `ANALYTICS_ADMIN_TOKEN`
- `NOTIFICATION_ADMIN_TOKEN`

6. 在主线工作树执行：

```bash
cd /Users/chauhua/Documents/GitHub/Jive/worktrees/codex-saas-mainline-next
```

7. link + dry-run + apply migrations：

```bash
npx -y supabase@latest link --project-ref "$STAGING_PROJECT_REF" --password "$STAGING_DB_PASSWORD"
npx -y supabase@latest db push --include-all --dry-run
npx -y supabase@latest db push --include-all
```

8. 注入 secrets：

```bash
npx -y supabase@latest secrets set --env-file /tmp/jive-saas-staging.env --project-ref "$STAGING_PROJECT_REF"
```

9. 部署 5 个 Edge Functions：

```bash
npx -y supabase@latest functions deploy subscription-webhook --project-ref "$STAGING_PROJECT_REF" --use-api
npx -y supabase@latest functions deploy verify-subscription --project-ref "$STAGING_PROJECT_REF" --use-api
npx -y supabase@latest functions deploy analytics --project-ref "$STAGING_PROJECT_REF" --use-api
npx -y supabase@latest functions deploy send-notification --project-ref "$STAGING_PROJECT_REF" --use-api
npx -y supabase@latest functions deploy admin --project-ref "$STAGING_PROJECT_REF" --use-api
```

10. 做最小验收：
- `user_subscriptions` / `sync_tombstones` / analytics / notification 相关表存在
- 5 个 Functions 都已部署成功
- `ADMIN_API_ALLOWED_ORIGINS` 不为空
- main 上 `Wave 0 smoke` 通过

## 当前真实阻塞

不是代码阻塞，而是环境阻塞：
- `#144` 还需要 GitHub UI 手工 merge
- staging project ref 还未在仓库里显式 linked
- staging access token / DB password / runtime secrets 还未提供

## 参考文档

- [2026-04-10-saas-staging-apply-runbook.md](/Users/chauhua/Documents/GitHub/Jive/worktrees/codex-saas-mainline-next/docs/2026-04-10-saas-staging-apply-runbook.md)
- [2026-04-10-saas-beta-mainline-merge-strategy.md](/Users/chauhua/Documents/GitHub/Jive/worktrees/codex-saas-mainline-next/docs/2026-04-10-saas-beta-mainline-merge-strategy.md)
- [2026-04-09-saas-beta-verification-closure.md](/Users/chauhua/Documents/GitHub/Jive/worktrees/codex-saas-mainline-next/docs/2026-04-09-saas-beta-verification-closure.md)
