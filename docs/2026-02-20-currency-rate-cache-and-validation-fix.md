# Jive 币种链路修复（汇率缓存一致性 + 非法汇率防护）

日期：2026-02-20
分支：`codex/fix-currency-rate-pipeline`

## 背景

在汇率链路中存在两个稳定性风险：

1. **缓存一致性问题**：
   - `getRate` 命中内存缓存后，`setManualRate` / `fetchAndUpdateRates` 更新数据库但未同步缓存，可能短时间内读到旧值。
2. **非法汇率风险**：
   - 当外部返回 `0` 或非法值时，反向汇率 `1/rate` 可能产生无穷值，污染数据。

## 本次改动

文件：`lib/core/service/currency_service.dart`

1. 增加缓存工具方法：
   - `_cacheKey`
   - `_isValidRate`
   - `_cacheRate`
2. `getRate` 统一按大写货币代码和规范化缓存键读取。
3. `fetchAndUpdateRates`：
   - 忽略非正数/非法汇率
   - 写库后同步正反向缓存
   - 更新已有记录时同步刷新 `effectiveDate`
4. `setManualRate`：
   - 非正数汇率直接抛 `ArgumentError`
   - 写库后同步正反向缓存
   - 更新已有记录时同步刷新 `effectiveDate`

## 测试

新增：`test/currency_service_test.dart`

覆盖点：
1. 手动设置汇率后，缓存立即反映正反向汇率。
2. 非法（<=0）手动汇率被拒绝。
3. 在线更新可覆盖旧缓存，并写入反向缓存。
4. 在线返回非正数汇率时被安全忽略。

## 验证

已执行并通过：

```bash
flutter analyze --no-fatal-infos
flutter test test/currency_service_test.dart test/budget_service_test.dart
flutter test
```

## 结论

本次修复确保“写入汇率 -> 读取汇率”链路在同一会话内一致，且对异常上游数据具备防护，降低了汇率相关页面的错读与脏数据风险。
