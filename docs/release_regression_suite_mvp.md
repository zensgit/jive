# Release Regression Suite MVP

## 目标

把上线前回归从“几条 smoke 命令”收口成可复用的 regression suite，覆盖 sync foundation、backup/import 和 stale session gate。

## 本轮落地

- `scripts/run_release_regression_suite.sh`
- `scripts/run_release_smoke.sh` 先跑 regression，再跑 integration smoke
- `.github/workflows/flutter_ci.yml` 的 Android emulator lane 在进 E2E 前先跑 regression suite

## 覆盖范围

### 1. sync foundation

- `account/category/transaction/tag/project` sync repository
- `SyncCursorStore`
- `SyncLeaseStore`

### 2. backup/import

- round-trip
- legacy migration repair
- future schema reject
- sync checkpoint restore
- stale lease clear
- project backup/restore

### 3. auth release gate

- stale callback write
- stale bundle invalidate
- token rotation
- healthy bundle ready path

## 设计取舍

### 1. regression suite 和 smoke 分层

- `run_release_regression_suite.sh`：稳定、快速、适合 host 和 Android lane 前置校验
- `run_release_smoke.sh`：在 regression 通过后再跑集成 smoke

### 2. Android lane 不直接把所有单测改成设备测

当前更稳的做法是：

- 先在 runner 上跑 regression suite
- 再用 emulator 跑插件/平台依赖更重的 `integration_test`

## 下一步

1. 增加 backup/restore 的 Android 端集成回归
2. 把 stale session 场景接入更接近真实认证流的 integration test
3. 为 regression suite 增加 artifact 汇总和失败分桶
