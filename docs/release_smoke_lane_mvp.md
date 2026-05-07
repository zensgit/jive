# Release Smoke Lane MVP

## 目标

在进入上线测试前，建立一条可重复执行的基础 smoke 车道，覆盖：

1. 数据备份/恢复 round-trip 回归
2. ImportCenter 失败聚合与导出闭环
3. 分类图标搜索/选择/确认闭环
4. 备份迁移与 stale session release gate 回归
5. Android 本地部署前交互 smoke，包括首页、SaaS 门控、Settings 导航、快记入口、记账计算器

## 本轮落地

- Host 脚本：`scripts/run_release_smoke.sh`
- Android 本地脚本：`scripts/run_release_android_smoke.sh`
- Host smoke 车道：`.github/workflows/flutter_ci.yml`
- Android emulator integration 车道：`.github/workflows/flutter_ci.yml`

## Host 执行内容

- `flutter analyze`
- `flutter test test/data_backup_service_roundtrip_test.dart test/data_backup_service_migration_regression_test.dart test/auth_stale_session_release_gate_test.dart`
- `flutter test integration_test/import_center_failure_analytics_flow_test.dart --dart-define=JIVE_E2E=true`
- `flutter test integration_test/category_icon_picker_flow_test.dart --dart-define=JIVE_E2E=true`

执行：

```bash
scripts/run_release_smoke.sh
```

## Android 本地执行内容

`scripts/run_release_android_smoke.sh` 是部署前本地 Android smoke 的短入口，默认等价于：

```bash
scripts/run_android_local_feature_smoke.sh \
  --scenario all \
  --fresh-install \
  --allow-uninstall-on-signature-mismatch
```

覆盖：

- `guest-home`：冷启动、onboarding、游客首页
- `saas-gates`：免费用户订阅页入口、云同步订阅门控
- `settings-navigation`：设置页、语言弹层、隐私政策、返回首页
- `quick-entry-hub`：长按 FAB 打开快记中心、进入手动记账
- `transaction-entry`：记账页锚点、备注入口、`1+2×3=7.00` 计算验证

执行：

```bash
scripts/run_release_android_smoke.sh
```

默认会 fresh install，推荐在 emulator 上运行。若在实体机上运行且需要保留本地数据，请显式传入：

```bash
scripts/run_release_android_smoke.sh --preserve-data
```

复用已有 APK：

```bash
scripts/run_release_android_smoke.sh \
  --skip-build \
  --apk-path build/app/outputs/flutter-apk/app-dev-debug.apk
```

实体机上只有在确认可删除本地数据时，才建议使用默认 fresh install。

```bash
scripts/run_release_android_smoke.sh --device <serial>
```

产物默认写入：

```text
build/reports/release-android-smoke/<timestamp>/
```

## 暂缓项

- `Settings` 导航 smoke 已转入 Android 本地车道，由 `settings-navigation` 场景覆盖；不再放入不稳定的 host integration lane。
- `calendar_date_picker_flow_test.dart` 和 `transaction_search_flow_test.dart` 依赖平台流与插件实现，当前仅保留在 Android emulator 车道，不放进 host release smoke。
