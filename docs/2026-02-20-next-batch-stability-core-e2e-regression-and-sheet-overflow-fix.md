# Jive 稳定性续推进：筛选弹层溢出修复与 Integration 全量回归

日期：2026-02-20  
分支：`codex/next-batch-stability-core`  
PR：`https://github.com/zensgit/jive/pull/43`

## 背景

在真机执行集成测试时，`transaction_search_flow_test` 曾出现运行期 UI 异常：

- `A RenderFlex overflowed by 107 pixels on the bottom.`
- 位置：`lib/core/widgets/transaction_filter_sheet.dart:218`

同时，为降低 UI 文案变化带来的 E2E 波动，需要将关键点击点从文本匹配切换为 key 匹配。

## 本次实现

1. 修复筛选弹层溢出
   - 文件：`lib/core/widgets/transaction_filter_sheet.dart`
   - 变更：将弹层主体由直接 `Column` 改为 `SingleChildScrollView` + `Column`。
   - 效果：在小屏或内容较多场景下可滚动，不再触发底部溢出。

2. 强化 integration 选择器稳定性
   - 文件：`lib/main.dart`
     - 新增 `home_view_all_button` key（首页 `View All` 入口）。
   - 文件：`lib/core/widgets/transaction_filter_sheet.dart`
     - `全部清除` 按钮新增 `transaction_filter_clear_all_button` key。
   - 文件：`integration_test/transaction_search_flow_test.dart`
     - `View All` 与 `全部清除` 改为 `find.byKey(...)`。
   - 文件：`integration_test/calendar_date_picker_flow_test.dart`
     - `View All` 改为 `find.byKey(...)`。

## 提交记录

- `9e62d3b` `fix(integration): stabilize filter sheet and key-based selectors`

## 验证记录（2026-02-20）

1. 静态检查

```bash
flutter analyze
```

结果：通过（No issues found）。

2. 定向 integration（真机）

```bash
flutter test integration_test/transaction_search_flow_test.dart -d EP0110MZ0BC110087W
flutter test integration_test/calendar_date_picker_flow_test.dart -d EP0110MZ0BC110087W
```

结果：两条用例均通过（All tests passed）。

3. 全量 integration（真机）

```bash
flutter test integration_test -d EP0110MZ0BC110087W
```

结果：通过（2/2 用例通过，All tests passed）。

## 结论

本轮 `1+2` 已闭环完成：

1. 完整 integration_test 回归通过。  
2. 变更与验证文档已落盘，且与当前分支/PR 对齐。
