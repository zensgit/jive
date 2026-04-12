# Jive SaaS Duty Handoff Summary

> 日期: 2026-04-10
> 主线状态: `main@6ea8b06`
> 原集成 PR: [#144](https://github.com/zensgit/jive/pull/144)
> 用途: 给下一位接手人一页看清当前 SaaS Beta 主线、执行入口与阻塞点

## 一句话结论

当前 SaaS Beta 的代码主线已经进入 `main`，代码侧收口完成；现在唯一剩余工作是 staging rollout 与最小业务验收。

代码侧已经具备：
- `origin/main@6ea8b06`
- fresh `main` worktree 复验通过
- `Wave 0 smoke` 已两次通过
- staging rollout 脚本、secrets 模板、排障文档、旧 PR 收尾模板都已准备好

当前真正阻塞只剩：
- staging 的 DB password / access token / runtime secrets 还没提供完整

## 当前主线

- 主线分支: `main`
- 当前主线 commit: `6ea8b06`
- 原集成分支: `codex/saas-beta-mainline@474a802`
- 原集成 PR: [#144](https://github.com/zensgit/jive/pull/144)

## 推荐执行顺序

1. 在 fresh `main` 上运行：

```bash
bash scripts/run_saas_wave0_smoke.sh
```

2. 复制并填写 staging secrets：

```bash
cp docs/jive-saas-staging.env.example /tmp/jive-saas-staging.env
$EDITOR /tmp/jive-saas-staging.env
```

3. 先跑预检查：

```bash
scripts/run_saas_staging_rollout.sh preflight \
  --project-ref "$STAGING_PROJECT_REF" \
  --db-password "$STAGING_DB_PASSWORD" \
  --access-token "$SUPABASE_ACCESS_TOKEN" \
  --env-file /tmp/jive-saas-staging.env
```

4. 预检查通过后执行 staging rollout：

```bash
scripts/run_saas_staging_rollout.sh all \
  --project-ref "$STAGING_PROJECT_REF" \
  --db-password "$STAGING_DB_PASSWORD" \
  --access-token "$SUPABASE_ACCESS_TOKEN" \
  --env-file /tmp/jive-saas-staging.env
```

5. 最小验收通过后，再把 staging 结果回写到相关文档

## 关键脚本

### 主线验证
- [run_saas_wave0_smoke.sh](/Users/chauhua/Documents/GitHub/Jive/worktrees/codex-saas-mainline-next/scripts/run_saas_wave0_smoke.sh)

### staging rollout
- [run_saas_staging_rollout.sh](/Users/chauhua/Documents/GitHub/Jive/worktrees/codex-saas-mainline-next/scripts/run_saas_staging_rollout.sh)
  - `preflight`
  - `dry-run`
  - `apply`
  - `deploy`
  - `all`

### 旧 PR 收尾
- [print_saas_pr_cleanup_comments.sh](/Users/chauhua/Documents/GitHub/Jive/worktrees/codex-saas-mainline-next/scripts/print_saas_pr_cleanup_comments.sh)

## 关键文档

### 主线设计与验证
- [2026-04-09-saas-beta-design-closure.md](/Users/chauhua/Documents/GitHub/Jive/worktrees/codex-saas-mainline-next/docs/2026-04-09-saas-beta-design-closure.md)
- [2026-04-09-saas-beta-verification-closure.md](/Users/chauhua/Documents/GitHub/Jive/worktrees/codex-saas-mainline-next/docs/2026-04-09-saas-beta-verification-closure.md)
- [2026-04-10-saas-beta-mainline-merge-strategy.md](/Users/chauhua/Documents/GitHub/Jive/worktrees/codex-saas-mainline-next/docs/2026-04-10-saas-beta-mainline-merge-strategy.md)

### staging 执行
- [2026-04-10-saas-fast-track-checklist.md](/Users/chauhua/Documents/GitHub/Jive/worktrees/codex-saas-mainline-next/docs/2026-04-10-saas-fast-track-checklist.md)
- [2026-04-10-saas-post-merge-30min-checklist.md](/Users/chauhua/Documents/GitHub/Jive/worktrees/codex-saas-mainline-next/docs/2026-04-10-saas-post-merge-30min-checklist.md)
- [2026-04-10-saas-staging-apply-runbook.md](/Users/chauhua/Documents/GitHub/Jive/worktrees/codex-saas-mainline-next/docs/2026-04-10-saas-staging-apply-runbook.md)
- [2026-04-10-saas-staging-troubleshooting.md](/Users/chauhua/Documents/GitHub/Jive/worktrees/codex-saas-mainline-next/docs/2026-04-10-saas-staging-troubleshooting.md)
- [jive-saas-staging.env.example](/Users/chauhua/Documents/GitHub/Jive/worktrees/codex-saas-mainline-next/docs/jive-saas-staging.env.example)

### GitHub 收尾
- [2026-04-10-saas-pr-cleanup-map.md](/Users/chauhua/Documents/GitHub/Jive/worktrees/codex-saas-mainline-next/docs/2026-04-10-saas-pr-cleanup-map.md)

## 当前真实阻塞

### 1. staging 环境阻塞
- staging project ref 已固定为 `evnluvzvbqmsmypbchym`
- `STAGING_DB_PASSWORD` 未提供
- `SUPABASE_ACCESS_TOKEN` 未提供
- `/tmp/jive-saas-staging.env` 已创建并填入基础 Supabase / package / bundle 信息，但还缺 10 个运行时变量：
  - `GOOGLE_SERVICE_ACCOUNT_EMAIL`
  - `GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY`
  - `APPLE_APP_STORE_SHARED_SECRET`
  - `APPLE_APP_STORE_APPLE_ID`
  - `PUBSUB_BEARER_TOKEN`
  - `WEBHOOK_HMAC_SECRET`
  - `ADMIN_API_TOKEN`
  - `ADMIN_API_ALLOWED_ORIGINS`
  - `ANALYTICS_ADMIN_TOKEN`
  - `NOTIFICATION_ADMIN_TOKEN`

### 1.1 2026-04-12 复验状态
- fresh detached `main@6ea8b06` 上再次运行 `bash scripts/run_saas_wave0_smoke.sh`，结果通过
- `scripts/run_saas_staging_rollout.sh preflight --project-ref evnluvzvbqmsmypbchym --env-file /tmp/jive-saas-staging.env` 返回 12 个阻塞项
- 远端 staging 的关键表与 5 个 Edge Functions 当前仍返回 `404`

### 2. 明确不在 Beta 当前收口范围内
- Apple JWS / 证书链更强校验
- RevenueCat
- admin dashboard UI
- analytics/report UI
- notification outbound delivery/provider
- E2EE / 密钥管理

## 接手人最低动作

如果只做最小推进，接手人只需要做这 3 件事：

1. 在 fresh `main` 上跑 `run_saas_wave0_smoke.sh`
2. 拿 staging 凭据并填好 `/tmp/jive-saas-staging.env`
3. 跑 `run_saas_staging_rollout.sh all`

做到这 3 步，就已经完成 SaaS Beta 主线收口。
