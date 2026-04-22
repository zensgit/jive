# SaaS Function Smoke 失败日志脱敏开发与验证

日期：2026-04-22

分支：`codex/saas-function-smoke-redacted-errors`

## 目标

收紧 `scripts/run_saas_staging_function_smoke.sh` 的失败日志。该脚本会携带 staging anon key、admin token、analytics token、notification token，以及 full profile 下的 webhook token。旧实现遇到非预期 HTTP 状态时会打印响应体前 500 字节，若 Edge Function 或代理错误回显 token-like 字段，可能进入 GitHub Actions log。

## 改动

- 新增 `redact_text()`，用于清理 curl 失败错误中的 Bearer、JWT、Supabase personal token、token/key/password-like 文本。
- 新增 `response_summary()`，将非预期 HTTP 响应体转成结构摘要。
- `expect_status()` 不再打印 `head -c 500 "$body_file"` 的原始响应体。
- JSON 响应的敏感字段名折叠为 `<sensitive>`，保留对象/数组结构用于排障。
- curl 失败 stderr 先走脱敏再进入 warning log。

## 安全边界

- 成功路径行为不变，仍只输出 PASS 与 HTTP status。
- 失败路径保留 label、expected/got status 与响应结构摘要。
- 不再把 Function 原始响应体写入终端日志。
- 不改变任何 Supabase Function 请求、profile 范围或验收口径。

## 验证

静态检查通过：

```bash
bash -n scripts/run_saas_staging_function_smoke.sh
```

伪造恶意 500 响应验证通过：

- 本地 HTTP server 对 core profile 覆盖的 analytics/admin/send-notification 请求全部返回 500。
- 响应体中故意放入假 `access_token`、`refresh_token`、`purchase_token`、`password`、`authorization`、`apikey`、`admin_token`、JWT 形态字符串。
- 使用假 env 运行：

```bash
scripts/run_saas_staging_function_smoke.sh \
  --env-file /tmp/jive-function-redaction.env \
  --functions-url http://127.0.0.1:18767/functions/v1 \
  --profile core
```

结果：

```text
script_status=1
[saas-function-smoke] WARN: analytics rejects missing admin token response: object(keys=[<sensitive>, <sensitive>, <sensitive>, <sensitive>, <sensitive>, <sensitive>, <sensitive>, <sensitive>, ...])
[saas-function-smoke] ERROR: function smoke found 5 issue(s)
```

扫描 `/tmp/jive-function-redaction-smoke-fail` 未发现假 token/key/password/JWT 或敏感字段名。

curl 连接失败路径验证通过：

- 使用不可连接的本地端口触发 curl error。
- 日志只显示 curl 连接错误，没有输出假 env 里的 token 值。

## 后续验证建议

合并后可继续使用现有 core staging workflow 运行 function smoke：

```bash
gh workflow run saas_core_staging.yml \
  --ref main \
  -f run_local_smoke=false \
  -f run_sync_smoke=false \
  -f apply_migrations=false \
  -f deploy_functions=false \
  -f run_function_smoke=true \
  -f build_apk=false
```

预期：

- 正常 staging function smoke 仍然 PASS。
- 若任一 Function 返回非预期 body，Actions log 只显示结构摘要，不显示原始响应体。
