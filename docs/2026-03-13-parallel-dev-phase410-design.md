# 2026-03-13 Parallel Dev Phase410 Design

## 目标

本轮从“继续增加治理页面”切换到“上线前测试车道建设”，补齐最薄弱的 3 个点：

1. release smoke 脚本与 CI 入口
2. ImportCenter 与 CategoryIconPicker 的 integration smoke
3. 数据备份/恢复 round-trip 回归

## 设计决策

### 1. 先做可稳定执行的 smoke，不强行扩大范围

当前仓库已经有大量治理 service/screen/test，但集成回归仍然偏薄。与其继续扩治理页，不如先补一条能反复执行的 release smoke lane。

### 2. 选“能真实闭环”的页面，而不是硬造假登录流

仓库当前没有真实认证业务页，只有认证治理页。因此本轮没有伪造 auth 表单流，而是选择已有真实业务页面：

- `ImportCenterScreen`
- `CategoryIconPickerScreen`
- `JiveDataBackupService`

### 3. CI 拆分 host smoke 与 Android emulator smoke

- host smoke：快速验证 analyze、backup round-trip、轻量 integration smoke
- Android emulator smoke：继续承接既有交易搜索、日历筛选，并纳入新增 smoke

## 产出

- `release_smoke_lane_mvp.md`
- `data_backup_roundtrip_regression_mvp.md`
- `import_center_failure_analytics_smoke_mvp.md`
- `category_icon_picker_smoke_mvp.md`
- `run_release_smoke.sh`
- `flutter_ci.yml` 扩充 release smoke / e2e 列表

## 暂缓项

- `Settings` 导航 smoke 在 macOS integration 环境下不稳定，本轮不纳入 release 车道。
