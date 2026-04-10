# Jive SaaS Duty Handoff Summary

> 日期: 2026-04-10
> 主线 PR: [#144](https://github.com/zensgit/jive/pull/144)
> 当前 head: `9bf8dcd`
> 用途: 给下一位接手人一页看清当前 SaaS Beta 主线、执行入口与阻塞点

## 一句话结论

当前 SaaS Beta 的代码主线已经收口完成，唯一推荐 merge 路径是 [#144](https://github.com/zensgit/jive/pull/144)。

代码侧已经具备：
- 集成分支 `codex/saas-beta-mainline`
- fresh `origin/main` merge 演练通过
- `Wave 0 smoke` 通过
- staging rollout 脚本、secrets 模板、排障文档、旧 PR 收尾模板都已准备好

当前真正阻塞只剩：
- GitHub UI 还没把 [#144](https://github.com/zensgit/jive/pull/144) merge
- staging 的 project ref / DB password / access token / secrets 还没提供

## 当前主线

- 主线分支: `codex/saas-beta-mainline`
- 当前 head: `9bf8dcd`
- 主线 PR: [#144](https://github.com/zensgit/jive/pull/144)
- 当前状态: `open + draft + mergeable + base=main`

## 推荐执行顺序

1. 把 [#144](https://github.com/zensgit/jive/pull/144) 从 `draft` 改成 `ready`
2. 使用 `Create a merge commit` 合并到 `main`
3. 在 fresh `main` 上运行：

```bash
bash scripts/run_saas_wave0_smoke.sh
```

4. 复制并填写 staging secrets：

```bash
cp docs/jive-saas-staging.env.example /tmp/jive-saas-staging.env
$EDITOR /tmp/jive-saas-staging.env
```

5. 先跑预检查：

```bash
scripts/run_saas_staging_rollout.sh preflight \
  --project-ref "$STAGING_PROJECT_REF" \
  --db-password "$STAGING_DB_PASSWORD" \
  --access-token "$SUPABASE_ACCESS_TOKEN" \
  --env-file /tmp/jive-saas-staging.env
```

6. 预检查通过后执行 staging rollout：

```bash
scripts/run_saas_staging_rollout.sh all \
  --project-ref "$STAGING_PROJECT_REF" \
  --db-password "$STAGING_DB_PASSWORD" \
  --access-token "$SUPABASE_ACCESS_TOKEN" \
  --env-file /tmp/jive-saas-staging.env
```

7. `#144` merge 后，用：

```bash
scripts/print_saas_pr_cleanup_comments.sh 144
```

给旧 PR 留 `merged via #144` / `superseded by #144` 评论

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

### 1. GitHub UI 阻塞
- [#144](https://github.com/zensgit/jive/pull/144) 还没从 `draft` 改成 `ready`
- 还没执行 merge commit

### 2. staging 环境阻塞
- `STAGING_PROJECT_REF` 未提供
- `STAGING_DB_PASSWORD` 未提供
- `SUPABASE_ACCESS_TOKEN` 未提供
- `/tmp/jive-saas-staging.env` 的真实值未提供

### 3. 明确不在 Beta 当前收口范围内
- Apple JWS / 证书链更强校验
- RevenueCat
- admin dashboard UI
- analytics/report UI
- notification outbound delivery/provider
- E2EE / 密钥管理

## 接手人最低动作

如果只做最小推进，接手人只需要做这 3 件事：

1. merge [#144](https://github.com/zensgit/jive/pull/144)
2. 跑 `run_saas_wave0_smoke.sh`
3. 拿 staging 凭据后跑 `run_saas_staging_rollout.sh all`

做到这 3 步，就已经完成 SaaS Beta 主线收口。
