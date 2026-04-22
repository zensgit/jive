# SaaS Staging Secret Handling 硬化开发与验证

日期：2026-04-22

分支：`codex/saas-build-dart-define-file`

## 目标

继续收紧 SaaS staging 发布链路里的 secret 处理边界，重点减少 secret 出现在命令行参数、xtrace 日志、CI 未显式 mask 的输出、以及 staging artifact 目录中的概率。

## 改动

- `scripts/build_saas_staging_apk.sh`
  - 将 `SUPABASE_URL` / `SUPABASE_ANON_KEY` 从两个 `--dart-define=...` 命令行参数改为临时 `--dart-define-from-file=<temp>/dart-defines.json`。
  - 临时目录权限为 `700`，define 文件权限为 `600`。
  - 退出、失败、INT/TERM 时统一清理临时目录。
  - 修复 shell command substitution 导致 `TEMP_FILES` 清理列表在 subshell 中丢失的问题。
- `scripts/push_saas_github_secrets.sh`
  - `gh secret set` 不再使用 `--body "$value"`，改为从 stdin 读取 secret。
  - `validate_values()` / `push_values()` 读取 secret 时临时关闭 xtrace，避免外层误用 `bash -x` 时打印 secret literal。
- `.github/workflows/saas_core_staging.yml`
  - 新增 `Mask staging secret values` step，对 staging 相关 secrets 显式执行 `::add-mask::`。
  - 新增 `Guard SaaS staging report artifacts` step，上传 artifact 前阻止 `.env`、`.pem`、`.key`、`*secret*`、`*credential*`、`*dart-defines*` 等敏感形态文件进入 staging report artifact。

## 安全边界

- `SUPABASE_ANON_KEY` 仍是客户端可见值，但在 CI 中来自 GitHub Secret，因此不再直接放进 Flutter build argv。
- `SUPABASE_SERVICE_ROLE_KEY` 仍不会传入 Flutter build。
- GitHub secret 上传仍会把值交给 `gh secret set`，但不再通过 argv 的 `--body` 传递。
- staging env 文件仍只存在于 runner temp 目录，artifact 上传前增加 denylist guard。

## 验证

静态检查通过：

```bash
bash -n scripts/build_saas_staging_apk.sh
bash -n scripts/push_saas_github_secrets.sh
```

help 输出检查通过：

```bash
scripts/build_saas_staging_apk.sh --help
scripts/push_saas_github_secrets.sh --help
```

假 Flutter 构建验证通过：

- 使用假的 `FLUTTER_BIN` 执行 `pub get` 与 `build apk`。
- 生成假的 `app-dev-debug.apk`，验证 artifact/report 仍生成。
- Flutter argv 只包含 `--dart-define-from-file=<temp>/dart-defines.json`。
- argv 和脚本日志中未出现假 `SUPABASE_ANON_KEY` 或 `SUPABASE_SERVICE_ROLE_KEY`。
- 脚本退出后未残留 `jive-saas-dart-defines.*` 临时目录。

GitHub secret 上传脚本验证通过：

- 使用假的 `gh` CLI 和假的 core profile env file。
- 以 `bash -x` 运行 `scripts/push_saas_github_secrets.sh --apply`。
- `gh secret set` argv 未出现 `--body`，fake secret literal 未出现在 stdout/stderr/xtrace。
- fake `gh` 确认 secret 值通过 stdin 传入。

Workflow YAML 解析通过：

```bash
ruby -e 'require "yaml"; YAML.load_file(".github/workflows/saas_core_staging.yml"); puts "yaml ok"'
```

Artifact guard 逻辑验证通过：

- 构造仅包含正常 report 的 staging artifact 根目录，guard 通过。
- 放入 `.env` / `*secret*` / `*dart-defines*` 形态文件时，guard 按预期失败。

## 后续建议

- `run_saas_staging_rollout.sh` 中 `supabase link --password` 仍受 Supabase CLI 参数接口限制；后续若 CLI 支持 stdin/env password，应继续改掉 argv 传递。
- 如果后续扩大 artifact 上传 glob，必须保留或同步扩大 `Guard SaaS staging report artifacts`。
