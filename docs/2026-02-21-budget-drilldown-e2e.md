# Budget Drilldown E2E（2026-02-21）

## 实现范围
- 预算洞察钻取行增加稳定 Key：
  - `budget_top_category_<categoryKey>`
  - `budget_anomaly_day_<yyyyMMdd>`
- 保持 `__uncategorized__` 点击后提示：`未分类暂不支持快捷钻取`。
- 新增 Widget Test：
  - Top 分类行点击后进入账单页。
  - 异常日行点击后进入账单页且标题包含“异常日”。
  - 未分类行点击后出现 Snackbar。
- 新增 Integration Test：`integration_test/budget_insight_drilldown_flow_test.dart`
  - 首页进入预算管理。
  - 点击 Top 分类行进入交易页。
  - 打开筛选面板并断言日期范围不是“不限”。
  - 返回预算页后点击异常日行进入交易页并校验标题。
- 扩展 `scripts/verify_dev_flow.sh`：
  - 在预算页点击第一条 Top 分类并断言进入 `账单 ·`。
  - 返回后点击第一条异常日并断言进入 `账单 ·`。

## 验证命令

```bash
# 格式化
 dart format lib/feature/budget/budget_manager_screen.dart \
   test/budget_manager_screen_test.dart \
   integration_test/budget_insight_drilldown_flow_test.dart

# 静态检查
 flutter analyze --no-fatal-infos

# Widget Test
 flutter test test/budget_manager_screen_test.dart

# Integration Test（dev + E2E）
 flutter test integration_test/budget_insight_drilldown_flow_test.dart \
   --flavor dev \
   --dart-define=JIVE_E2E=true

# 设备流脚本（可选）
 bash scripts/verify_dev_flow.sh com.jivemoney.app.dev
```

## 结果记录（占位）
- `dart format ...`：PASS（3 files unchanged）。
- `flutter analyze --no-fatal-infos`：PASS（No issues found）。
- `flutter test test/budget_manager_screen_test.dart`：PASS（3 tests passed）。
- `flutter test integration_test/budget_insight_drilldown_flow_test.dart --flavor dev --dart-define=JIVE_E2E=true -d EP0110MZ0BC110087W`：PASS（1 integration test passed）。
- `bash scripts/verify_dev_flow.sh`：PASS（产物目录：`/tmp/jive-verify-20260221-214755`）。

## 备注
- 脚本默认包名改为 `com.jivemoney.app.auto.dev`，并在未传参时自动回退检测 `com.jivemoney.app.dev` / `com.jivemoney.app.auto`。
- 若预算页面无可钻取数据（首次空库场景），脚本会记录 `budget drilldown skipped` 并继续完成其他断言。
