# SaaS Staging Device Smoke Self-Test 开发与验证记录

日期：2026-05-10

## 目标

为 `scripts/run_saas_staging_device_smoke.sh` 增加 host-only fake adb 自测，补齐 staging APK 安装之后的设备启动 smoke 安全网。目标是验证脚本 contract，而不依赖真实 Android 设备、模拟器、APK 安装、UI 会话或 app 数据。

## 改动

- `scripts/run_saas_staging_device_smoke.sh`
  - 修复 `run_adb` 在未指定 `--device` 时使用空数组展开导致 macOS bash + `set -u` 下提前退出的问题。
  - 改为有 `DEVICE` 时显式调用 `adb -s <serial>`，无 `DEVICE` 时直接调用 `adb`。
- `scripts/test_saas_staging_device_smoke.sh`
  - 新增 fake adb host-only 自测。
  - 模拟 launch screenshot、uiautomator XML、pid、logcat、install、seed prefs 等设备侧行为。
- `.github/workflows/flutter_ci.yml`
  - 将 device smoke 脚本和自测加入 `saas_production_readiness_self_check`。
- `scripts/should_run_saas_wave0_smoke.sh`
  - device smoke 或其自测脚本变更时触发 Wave0 SaaS smoke。
- `scripts/test_saas_wave0_smoke_trigger.sh`
  - 增加 device smoke 相关触发断言。

## 自测覆盖

- 非法 `--expect` 会在 adb 前失败。
- 非法 `--wait-seconds` 会在 adb 前失败。
- `--skip-install` 路径可以启动并识别 home 页面。
- 非 skip install 路径会把 APK 与 device serial 转发到 installer。
- `--seed-home-prefs` 会写入 Flutter SharedPreferences，并通过 `run-as` 拷贝到 app shared prefs。
- 期望页面与实际页面不一致时失败。
- app pid 缺失时失败。
- logcat 中出现 `Unhandled Exception` 等 fatal pattern 时失败，并写出 `app-fatal-log-lines.txt`。
- 成功路径会输出 `summary.md`、`launch.png`、`launch.xml`、`detected-screen.txt` 等 artifacts。

## 验证命令

```bash
chmod +x scripts/test_saas_staging_device_smoke.sh
bash -n scripts/run_saas_staging_device_smoke.sh scripts/test_saas_staging_device_smoke.sh scripts/should_run_saas_wave0_smoke.sh scripts/test_saas_wave0_smoke_trigger.sh
scripts/test_saas_staging_device_smoke.sh --help >/dev/null
scripts/test_saas_staging_device_smoke.sh
scripts/test_saas_wave0_smoke_trigger.sh
ruby -e 'require "yaml"; YAML.load_file(".github/workflows/flutter_ci.yml"); puts "yaml ok"'
scripts/test_saas_staging_apk_installer.sh
scripts/test_saas_staging_apk_builder.sh
scripts/test_saas_release_candidate_workflow.sh
scripts/test_saas_full_billing_staging_smoke_workflow.sh
scripts/test_saas_core_staging_lane.sh
scripts/test_saas_staging_rollout.sh
scripts/test_saas_deployment_readiness.sh
scripts/test_saas_production_release_readiness_report.sh
scripts/test_saas_report_artifact_guard.sh
scripts/test_release_android_smoke_artifact_verifier.sh
scripts/test_release_android_smoke_summary_renderer.sh
/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos
scripts/run_saas_wave0_smoke.sh
git diff --check
```

## 验证结果

- `scripts/test_saas_staging_device_smoke.sh`：通过。
- `scripts/test_saas_wave0_smoke_trigger.sh`：通过。
- `.github/workflows/flutter_ci.yml` YAML 解析：通过。
- 既有 staging APK builder / installer 自测：通过。
- 既有 SaaS release / billing / core lane / rollout / readiness / artifact guard 自测：通过。
- Android release smoke artifact verifier / summary renderer 自测：通过。
- `flutter analyze --no-fatal-infos`：退出码 0；当前仓库仍有既有 83 个 info lint，无 error/warning。
- `scripts/run_saas_wave0_smoke.sh`：通过。
- `git diff --check`：通过。

## 限制说明

- 本次是 host-only contract test，不连接真实 Android 设备或模拟器。
- 本次不安装真实 APK，不验证真实 Flutter UI 渲染。
- 真实 staging APK 安装、启动和设备端 smoke 仍需要后续在 emulator 或实体机上执行。
