# MoneyThings 全方案 TODO 执行记录

## Summary

本轮基于 `origin/main` 合入 PR #193 后的协议层继续推进，分支为 `feature/moneythings-full-todo`。目标是先落地不需要迁移的低风险能力，把 One Touch、交易编辑器、三层分类、账户组、场景/SmartList 和共享提示串到现有模型上。

## 已完成

- 合并 #193 并以 fresh `origin/main@400852ed` 建立新 worktree。
- `TemplateListScreen` 的“使用模板”改为统一调用 `QuickActionExecutor`。
- 新增 `QuickActionDeepLinkService`，支持 `jive://quick-action?id=template:<id>` 和 `jive://transaction/new?...`。
- 首页 `MainScreen` 接入 `app_links`，外部 quick action 与 transaction deep link 统一进入执行器或 `TransactionFormScreen`。
- Android manifest 补齐 `jive://quick-action` 与 `jive://transaction` scheme host；iOS 已存在 `jive` URL scheme。
- `AddTransactionScreen` 分类选择接入三层路径：首屏可显示大类下所有后代分类，保存仍保持 `categoryKey=顶层`、`subCategoryKey=叶子`。
- `CategorySearchResult` 支持完整分类路径搜索，中间层名称也能命中。
- 分类管理页允许对子分类继续“添加下级分类”，并在父卡片下展示后代路径。
- `AccountGroupService` 忽略旧 broad groupName，避免把“资金账户/信用账户”误当子账户组。
- 资产页接入账户组展示，多账户同组时展示“账户组 + 子账户”。
- 账户类型模板补充银行卡活期、外币/定期、ETC。
- 首页账本切换文案升级为“场景切换”，底层仍使用 `JiveBook`。
- 账单列表入口接入默认 SmartList，存在默认视图时自动恢复筛选并显示提示。
- 账户卡片在共享场景下显示共享状态提示，权限真相仍沿用 shared ledger/book。

## 保持不变

- 未修改 `supabase/migrations`。
- 未修改 SaaS entitlement/payment/sync 逻辑。
- 未修改 `.github/workflows`。
- 未新增破坏性数据迁移。
- 交易仍保存到具体 `accountId`，账户组只做视图聚合。
- 对象级共享仍是提示层，不新增对象级权限真相。

## 待继续

- Widget/App Intent 的 QuickAction 入口还需接入同一执行器。
- 分享、截图、语音入口需逐步统一构造 `TransactionEntryParams`。
- 三层分类的统计、导出、导入路径还需继续走 `CategoryPathService` 收口。
- SmartList 从当前筛选一键保存、置顶、默认视图的入口还可继续增强。
- 分类、标签、场景对象卡片的共享状态提示还需继续补齐。

## 验证计划

- `flutter analyze --no-fatal-infos`
- `flutter test test/moneythings_alignment_services_test.dart`
- `flutter test test/add_transaction_screen_entry_ux_test.dart`
- `flutter test test/category_picker_user_categories_test.dart`
- `flutter test test/transaction_entry_widget_regression_test.dart`
- 手工 smoke：打开新增记账页，选择三层分类，保存后确认详情路径与统计聚合不回退。
