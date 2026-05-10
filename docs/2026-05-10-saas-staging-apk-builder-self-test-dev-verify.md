# SaaS Staging APK Builder Self-Test 开发与验证记录

日期：2026-05-10

## 目标

为 `scripts/build_saas_staging_apk.sh` 增加 host-only fixture 自测，并接入现有 SaaS CI 脚本自检链路。目标是验证 staging APK/AAB 构建入口的关键安全 contract，而不依赖真实 Flutter 构建、Android SDK、Supabase 项目、设备、网络或密钥。

## 改动

- `scripts/build_saas_staging_apk.sh`
  - 新增 `JIVE_SAAS_BUILD_REPORT_DIR` 覆盖能力，方便测试把报告写入临时 fixture 目录。
  - 默认报告路径保持 `build/reports/saas-staging` 不变。
- `scripts/test_saas_staging_apk_builder.sh`
  - 新增 fake `flutter` host-only 自测。
  - 覆盖 `apk debug` 与 `appbundle release` 两类产物路由。
  - 验证 `SUPABASE_SERVICE_ROLE_KEY` 不会进入 client dart-define 文件或报告。
  - 验证构建报告 `saas-staging-build.json` 与 `latest.md` 产出。
- `.github/workflows/flutter_ci.yml`
  - 将新脚本加入 `saas_production_readiness_self_check` 的 `bash -n` 与实际自测。
- `scripts/should_run_saas_wave0_smoke.sh`
  - staging APK builder 或其自测脚本变更时触发 Wave0 SaaS smoke。
- `scripts/test_saas_wave0_smoke_trigger.sh`
  - 增加 APK builder 相关触发断言。

## 自测覆盖

- 缺 env 文件会在调用 Flutter 前失败。
- 缺 `SUPABASE_ANON_KEY` 会在调用 Flutter 前失败。
- 缺 `SUPABASE_URL` 会在调用 Flutter 前失败。
- 默认拒绝 `--flavor prod`，避免 staging 构建被误认为生产 release candidate。
- `--kind appbundle --mode debug` 会失败，避免无效 AAB 模式。
- `apk debug` 可以写入 artifact、JSON 报告和 Markdown 报告。
- `appbundle release` 可以写入 artifact、JSON 报告和 Markdown 报告。
- 显式 `--allow-prod-flavor` 时才允许 prod flavor 诊断构建。
- fake Flutter 捕获到的 dart-define 只包含 `SUPABASE_URL` 与 `SUPABASE_ANON_KEY`，不包含 service role key。

## 验证命令

```bash
chmod +x scripts/test_saas_staging_apk_builder.sh
bash -n scripts/build_saas_staging_apk.sh scripts/test_saas_staging_apk_builder.sh scripts/should_run_saas_wave0_smoke.sh scripts/test_saas_wave0_smoke_trigger.sh
scripts/test_saas_staging_apk_builder.sh --help >/dev/null
scripts/test_saas_staging_apk_builder.sh
scripts/test_saas_wave0_smoke_trigger.sh
ruby -e 'require "yaml"; YAML.load_file(".github/workflows/flutter_ci.yml"); puts "yaml ok"'
scripts/test_saas_release_candidate_workflow.sh
scripts/test_saas_full_billing_staging_smoke_workflow.sh
scripts/test_saas_core_staging_lane.sh
scripts/test_saas_staging_rollout.sh
scripts/test_saas_deployment_readiness.sh
scripts/test_saas_production_release_readiness_report.sh
scripts/test_saas_report_artifact_guard.sh
scripts/test_release_report_summary_renderer.sh
scripts/test_ios_release_candidate_builder.sh
scripts/test_release_android_smoke_artifact_verifier.sh
scripts/test_release_android_smoke_summary_renderer.sh
/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos
scripts/run_saas_wave0_smoke.sh
git diff --check
```

## 验证结果

- `scripts/test_saas_staging_apk_builder.sh`：通过。
- `scripts/test_saas_wave0_smoke_trigger.sh`：通过。
- `.github/workflows/flutter_ci.yml` YAML 解析：通过。
- 既有 SaaS workflow / deployment / release / artifact guard / iOS / Android smoke 自测：通过。
- `flutter analyze --no-fatal-infos`：退出码 0；当前仓库仍有既有 83 个 info lint，无 error/warning。
- `scripts/run_saas_wave0_smoke.sh`：通过。
- `git diff --check`：通过。

## 限制说明

- 本次是 host-only contract test，不构建真实 APK/AAB。
- 本次不访问真实 Supabase、不读取真实 secrets、不启动 emulator、不安装到设备。
- 真实 staging APK 产物、安装验证、设备端 smoke 仍由 GitHub Actions staging/release workflow 或后续设备验证完成。
