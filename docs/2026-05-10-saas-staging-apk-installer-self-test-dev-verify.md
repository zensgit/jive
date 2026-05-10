# SaaS Staging APK Installer Self-Test 开发与验证记录

日期：2026-05-10

## 目标

为 `scripts/install_saas_staging_apk.sh` 增加 host-only fixture 自测，重点覆盖 staging APK 安装链路的数据安全边界：签名不一致时默认不卸载，只有显式允许时才可卸载，并且配置备份时必须先成功备份再删除本地数据。

## 改动

- `scripts/install_saas_staging_apk.sh`
  - 修复 `run_adb` 在未指定 `--device` 时使用空数组展开导致 macOS bash + `set -u` 下提前退出的问题。
  - 改为有 `DEVICE` 时显式调用 `adb -s <serial>`，无 `DEVICE` 时直接调用 `adb`。
- `scripts/test_saas_staging_apk_installer.sh`
  - 新增 fake `adb` host-only 自测。
  - 不连接真实设备、不安装真实 APK、不读取真实 app data。
- `.github/workflows/flutter_ci.yml`
  - 将 installer 脚本和自测加入 `saas_production_readiness_self_check`。
- `scripts/should_run_saas_wave0_smoke.sh`
  - installer 或其自测脚本变更时触发 Wave0 SaaS smoke。
- `scripts/test_saas_wave0_smoke_trigger.sh`
  - 增加 installer 相关触发断言。

## 自测覆盖

- APK 路径不存在时，在 adb install 前失败。
- 正常签名兼容安装时，只执行一次 `adb install -r`，不会卸载。
- 签名不一致且未显式允许卸载时，脚本失败并且不会执行 `adb uninstall`。
- 签名不一致且显式 `--allow-uninstall-on-signature-mismatch` 时，脚本先卸载再重试安装。
- 配置 `--backup-before-uninstall` 时，脚本会先通过 `run-as ... tar` 生成备份并验证 tar listing。
- 备份失败时，脚本中止并保留本地 app 数据，不执行卸载。
- 指定 `--device` 时，fake adb 捕获到 `-s <serial>` 参数。

## 验证命令

```bash
chmod +x scripts/test_saas_staging_apk_installer.sh
bash -n scripts/install_saas_staging_apk.sh scripts/test_saas_staging_apk_installer.sh scripts/should_run_saas_wave0_smoke.sh scripts/test_saas_wave0_smoke_trigger.sh
scripts/test_saas_staging_apk_installer.sh --help >/dev/null
scripts/test_saas_staging_apk_installer.sh
scripts/test_saas_wave0_smoke_trigger.sh
scripts/test_saas_staging_apk_builder.sh
ruby -e 'require "yaml"; YAML.load_file(".github/workflows/flutter_ci.yml"); puts "yaml ok"'
scripts/test_saas_deployment_readiness.sh
scripts/test_saas_production_release_readiness_report.sh
scripts/test_saas_report_artifact_guard.sh
scripts/test_saas_release_candidate_workflow.sh
scripts/test_saas_full_billing_staging_smoke_workflow.sh
scripts/test_saas_core_staging_lane.sh
scripts/test_saas_staging_rollout.sh
/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos
scripts/run_saas_wave0_smoke.sh
git diff --check
```

## 验证结果

- `scripts/test_saas_staging_apk_installer.sh`：通过。
- `scripts/test_saas_staging_apk_builder.sh`：通过。
- `scripts/test_saas_wave0_smoke_trigger.sh`：通过。
- `.github/workflows/flutter_ci.yml` YAML 解析：通过。
- 既有 SaaS deployment / release / artifact guard / rollout / core lane 自测：通过。
- `flutter analyze --no-fatal-infos`：退出码 0；当前仓库仍有既有 83 个 info lint，无 error/warning。
- `scripts/run_saas_wave0_smoke.sh`：通过。
- `git diff --check`：通过。

## 限制说明

- 本次是 host-only contract test，不连接真实 Android 设备或模拟器。
- 本次不安装真实 APK，不验证真实设备 UI。
- 真实 staging APK 安装、启动和设备端 smoke 仍需要后续在 emulator 或实体机上执行。
