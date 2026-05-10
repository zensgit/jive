# MoneyThings Transaction Footer Contracts 开发与验证记录

日期：2026-05-10

## 目标

为 `TransactionFooterBar` 补充低风险 widget 合同测试，锁定交易编辑器底部操作区在不同入口 source 与交易类型下的按钮语义。范围保持在 `test/` 与 `docs/`，不改产品逻辑。

## 覆盖

- `manual` source 显示主按钮 `保存`，并在非 edit 模式保留 `保存并新建` 与 `连续记账`。
- 外部入口保持统一语义：`quickAction` 显示 `立即记录`，`voice` / `conversation` / `autoDraft` / `ocrScreenshot` / `shareReceive` / `deepLink` 显示 `确认入账`。
- `edit` source 显示 `保存修改`，并隐藏 `保存并新建` 与 `连续记账`。
- `expense` / `income` / `transfer` 只断言按钮存在，不做像素或颜色断言，避免脆弱测试。

## 验证命令

```bash
/Users/chauhua/development/flutter/bin/flutter test test/transaction_footer_bar_contract_test.dart
/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos test/transaction_footer_bar_contract_test.dart lib/feature/transactions/widgets/transaction_footer_bar.dart
git diff --check
git diff --name-only origin/main...HEAD -- supabase/migrations lib/core/sync .github/workflows
git diff --name-only origin/main...HEAD | grep -E '(^lib/(core/(sync|payment|entitlement)|feature/(subscription|payment|entitlement))|^supabase/migrations|^\\.github/workflows)' || true
```

## 验证结果

- 通过。测试断言使用文本语义而非按钮内部祖先结构，避免 Flutter
  `FilledButton.icon` / `OutlinedButton.icon` 的内部实现变化造成脆弱失败。

## PR

- Draft PR：待创建后回填。
