# Jive SaaS Fast-Track Checklist

> 日期: 2026-04-10
> 更新: 2026-04-18
> 推荐主线: `main`
> 当前部署测试入口: [#159](https://github.com/zensgit/jive/pull/159)

## 目标

把 Jive SaaS Beta 以最快路径落到 staging，并保留可重复验证的部署证据链。

## 快执行计划

1. 合并 [#159](https://github.com/zensgit/jive/pull/159) 到 `main`
2. 在 fresh `main` worktree 上运行：

```bash
bash scripts/run_saas_wave0_smoke.sh
```

3. 初始化本地 staging env 文件：

```bash
bash scripts/init_saas_staging_env.sh \
  --env-file /tmp/jive-saas-staging.env
```

4. 准备 shell 级 staging 变量：
- `SUPABASE_ACCESS_TOKEN`
- `STAGING_PROJECT_REF`
- `STAGING_DB_PASSWORD`

5. 在 `/tmp/jive-saas-staging.env` 中准备 core staging secrets：
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
- `PUBSUB_BEARER_TOKEN`
- `WEBHOOK_HMAC_SECRET`
- `ADMIN_API_TOKEN`
- `ADMIN_API_ALLOWED_ORIGINS`
- `ANALYTICS_ADMIN_TOKEN`
- `NOTIFICATION_ADMIN_TOKEN`

```bash
$EDITOR /tmp/jive-saas-staging.env
```

6. 检查本地部署准备：

```bash
bash scripts/check_saas_deployment_readiness.sh \
  --profile core \
  --strict \
  --online \
  --env-file /tmp/jive-saas-staging.env
```

7. 检查 GitHub Actions secrets 是否齐全：

```bash
bash scripts/check_saas_github_secrets.sh \
  --profile core \
  --repo zensgit/jive
```

8. 如果本地 env 和 shell 变量已经准备好，可一条命令上传 GitHub Actions secrets：

```bash
bash scripts/push_saas_github_secrets.sh \
  --profile core \
  --repo zensgit/jive \
  --env-file /tmp/jive-saas-staging.env \
  --apply
```

9. 一条命令跑完 core staging lane：

```bash
bash scripts/run_saas_core_staging_lane.sh \
  --env-file /tmp/jive-saas-staging.env
```

10. 如果先只想做安全预演，不 apply / deploy：

```bash
bash scripts/run_saas_core_staging_lane.sh \
  --env-file /tmp/jive-saas-staging.env \
  --skip-apply \
  --skip-deploy \
  --skip-function-smoke \
  --skip-apk
```

11. 做最小验收：
- `user_subscriptions` / `sync_tombstones` / analytics / notification 相关表存在
- 5 个 Functions 都已部署成功
- `ADMIN_API_ALLOWED_ORIGINS` 不为空
- main 上 `Wave 0 smoke` 通过
- dev debug staging APK 可构建

## 当前真实阻塞

不是代码阻塞，而是环境阻塞：
- [#159](https://github.com/zensgit/jive/pull/159) 合并前，GitHub Actions 手动 staging lane 还不能从 `main` 触发
- GitHub Actions repository secrets 还未配置完整，可用 `scripts/check_saas_github_secrets.sh --profile core --repo zensgit/jive` 检查
- staging `SUPABASE_ACCESS_TOKEN` / `STAGING_PROJECT_REF` / `STAGING_DB_PASSWORD` 还需要以安全方式注入执行环境
- Supabase Dashboard 里曾经粘贴到聊天的 token/key 建议先 rotate 后再进入真实测试

## 参考文档

- [2026-04-18-saas-deployment-test-readiness.md](/Users/chauhua/Documents/GitHub/Jive/app/docs/2026-04-18-saas-deployment-test-readiness.md)
- [2026-04-10-saas-staging-apply-runbook.md](/Users/chauhua/Documents/GitHub/Jive/app/docs/2026-04-10-saas-staging-apply-runbook.md)
- [2026-04-10-saas-staging-troubleshooting.md](/Users/chauhua/Documents/GitHub/Jive/app/docs/2026-04-10-saas-staging-troubleshooting.md)
- [jive-saas-staging.env.example](/Users/chauhua/Documents/GitHub/Jive/app/docs/jive-saas-staging.env.example)
- [run_saas_core_staging_lane.sh](/Users/chauhua/Documents/GitHub/Jive/app/scripts/run_saas_core_staging_lane.sh)
- [check_saas_github_secrets.sh](/Users/chauhua/Documents/GitHub/Jive/app/scripts/check_saas_github_secrets.sh)
- [push_saas_github_secrets.sh](/Users/chauhua/Documents/GitHub/Jive/app/scripts/push_saas_github_secrets.sh)
- [run_saas_staging_rollout.sh](/Users/chauhua/Documents/GitHub/Jive/app/scripts/run_saas_staging_rollout.sh)
