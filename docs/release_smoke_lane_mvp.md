# Release Smoke Lane MVP

## 目标

在进入上线测试前，建立一条可重复执行的基础 smoke 车道，覆盖：

1. 数据备份/恢复 round-trip 回归
2. ImportCenter 失败聚合与导出闭环
3. 分类图标搜索/选择/确认闭环
4. 备份迁移与 stale session release gate 回归

## 本轮落地

- 新增脚本：`/Users/huazhou/Downloads/Github/Jive/app/scripts/run_release_smoke.sh`
- 新增 host smoke 车道：`/Users/huazhou/Downloads/Github/Jive/app/.github/workflows/flutter_ci.yml`
- Android emulator integration 列表补入新增 smoke：`/Users/huazhou/Downloads/Github/Jive/app/.github/workflows/flutter_ci.yml`

## 执行内容

- `flutter analyze`
- `flutter test test/data_backup_service_roundtrip_test.dart test/data_backup_service_migration_regression_test.dart test/auth_stale_session_release_gate_test.dart`
- `flutter test integration_test/import_center_failure_analytics_flow_test.dart --dart-define=JIVE_E2E=true`
- `flutter test integration_test/category_icon_picker_flow_test.dart --dart-define=JIVE_E2E=true`

## 暂缓项

- `Settings` 导航 smoke 已尝试，但当前桌面 integration 环境下不稳定，未纳入 release smoke 车道。
- 后续应优先在 Android emulator 车道补这条，而不是把不稳定用例塞进 host lane。
- `calendar_date_picker_flow_test.dart` 和 `transaction_search_flow_test.dart` 依赖平台流与插件实现，当前仅保留在 Android emulator 车道，不放进 host release smoke。
