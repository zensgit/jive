# CI 增量推进与验证报告（2026-02-12）

## 1. 目标
- 将 `flutter analyze` 与 `flutter test` 固化到 GitHub Actions，保证每个 PR 都会跑静态检查与单测，避免 analyzer 噪音回归。

## 2. 方案与实现
- 新增 GitHub Actions 工作流：`.github/workflows/flutter_ci.yml`
- 触发：`pull_request`（所有 PR）
- 触发：`push` 到 `main`
- Job：`analyze_and_test`（`ubuntu-latest`）
- 步骤：安装 Flutter `3.35.5`（stable）
- 步骤：`flutter pub get`
- 步骤：`flutter analyze`（默认开启 fatal-infos/fatal-warnings，要求 0 issue）
- 步骤：`flutter test`

## 3. 本地验证
在仓库根目录执行：
```bash
flutter analyze
flutter test
```

## 4. 预期效果
- PR 页面会出现 `Flutter CI / analyze_and_test` 检查。
- 若引入任意 analyzer 问题或测试失败，将阻止合入（按仓库分支保护策略为准）。
