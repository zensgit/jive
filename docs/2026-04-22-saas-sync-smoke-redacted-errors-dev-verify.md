# SaaS Sync Smoke 失败日志脱敏开发与验证

日期：2026-04-22

分支：`codex/saas-sync-smoke-redacted-errors`

## 目标

收紧 `scripts/run_saas_staging_sync_smoke.sh` 的失败路径日志，避免真实 Supabase staging smoke 在 HTTP 4xx/5xx、清理失败或异常退出时，把原始响应体、token/key/password、JWT 或 URL query 值写入 CI logs 与 artifacts。

## 改动

- 新增 `redact_sensitive_text()` 与 `safe_error()`，在 summary 写盘前统一清理敏感文本。
- 新增 `safe_url()`，失败日志保留 method、host、path、status、expected，但把 query value 替换为 `<redacted>`。
- 新增 `payload_shape()` / `response_summary()`，HTTP 非预期状态只输出响应结构摘要，不再拼接 `raw[:500]`。
- `unexpected payload` 类错误不再输出 `{payload!r}`，改为输出数组长度、对象 key 摘要。
- 对敏感字段名如 token、password、apikey、authorization、jwt、service role 也折叠为 `<sensitive>`。
- 顶层失败路径不再重新抛 Python traceback，改为输出脱敏后的单行错误并以非 0 退出。
- 清理阶段的 `cleanupErrors` 同样走脱敏错误文本。

## 安全边界

- 成功路径仍只写 `.redacted.json`、`summary.json` 与 `summary.md`。
- 失败路径只写脱敏后的错误摘要，不写原始 HTTP body。
- URL query value 一律脱敏，避免 PostgREST 条件值或 token endpoint query 被带入 artifact。
- 真实 secret 不应进入 `summary.md`、`summary.json` 或命令日志。

## 验证

静态检查通过：

```bash
bash -n scripts/run_saas_staging_sync_smoke.sh
```

嵌入 Python 语法检查通过：

```bash
awk '/^from __future__ import annotations$/{flag=1} /^PY$/{flag=0} flag{print}' \
  scripts/run_saas_staging_sync_smoke.sh > /tmp/jive_saas_sync_smoke_embedded.py
python3 -m py_compile /tmp/jive_saas_sync_smoke_embedded.py
```

help 输出检查通过：

```bash
scripts/run_saas_staging_sync_smoke.sh --help
```

伪造恶意 500 响应验证通过：

- 本地 HTTP server 对 admin user create 和 cleanup DELETE 返回 500。
- 响应体中故意放入假 `access_token`、`refresh_token`、`password`、`authorization`、`apikey`、`service_role_key`、JWT、Supabase personal token 形态字符串。
- 脚本按预期失败并写入 `/tmp/jive-redaction-smoke-fail`。
- artifact 与命令日志扫描未发现这些假敏感值或敏感字段名。
- 输出只包含：

```text
response=object(keys=[<sensitive>, <sensitive>, <sensitive>, <sensitive>, <sensitive>, <sensitive>, <sensitive>, message])
```

本机真实 staging smoke 未运行：

```text
SKIP: /tmp/jive-saas-staging.env not found
```

## 后续验证建议

合并后可复用 GitHub Actions 手动 workflow：

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

预期：

- `Run core staging lane` 仍显示 `[saas-sync-smoke] PASS`。
- 下载 artifact 后扫描不应出现真实 token/key/password/JWT。
- 若 staging API 返回失败，summary 只应出现状态码、脱敏 URL 和响应结构摘要。
