# MoneyThings 全方案 TODO 执行记录

## Summary

本轮基于 `origin/main` 合入 PR #193 后的协议层继续推进，主集成分支为 `feature/moneythings-full-todo`。目标是先落地不需要迁移的低风险能力，把 One Touch、交易编辑器、三层分类、账户组、场景/SmartList 和共享提示串到现有模型上。

## 主线状态

- 2026-04-29：完整 MoneyThings 非迁移波次已通过 PR #196 合入 `main`。
- 主线 merge commit：`562d3d92b0bffcae53666a7a8a14d153a4c3fcd6`。
- GitHub `main@562d3d92` 已通过 `analyze_and_test`、`detect_saas_wave0_smoke`、`saas_wave0_smoke`。
- 2026-05-05：本文件更新为 post-merge TODO closure，不再把已落地的 stacked PR 当作待执行入口。

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
- PR #197 已补齐 SmartList 当前视图保存、固定分类/子分类保存、场景/共享状态与删除风险提示。
- PR #200 已把截图 OCR、对话记账等外部入口统一到 `TransactionEntryParams -> TransactionFormScreen`。
- PR #201 已为 AutoDraft 增加结构化编辑器 fallback，并保留原确认路径。
- PR #202 已把三层分类导入/导出路径统一收口到 `CategoryPathService`。
- PR #205 已把 AI Assistant 语音与剪贴板识别接入结构化编辑器。
- PR #206 已把 Android `ACTION_SEND text/plain` 分享接入 `jive://transaction/new`。
- PR #207 已为 Android Today widget 增加 `+ 记一笔` 结构化编辑器入口。
- PR #209 已补齐入口体系 closure 与 Android 验证文档。
- 2026-05-05：`codex/moneythings-ios-shortcuts-entry` 补齐 iOS App Intent / Shortcuts 原生入口，继续复用 `jive://transaction/new` 与 `jive://quick-action` 协议。
- 2026-05-05：`codex/moneythings-ios-share-extension` 补齐 iOS 系统分享入口，`text/url` 分享统一进入 `jive://transaction/new`。
- 2026-05-05：`codex/moneythings-quick-action-store` 新增本地 `JiveQuickAction` shadow collection，模板自动回填为稳定 quick action，首页/快记中心/Deep Link 统一读取 `QuickActionService`。
- 2026-05-05：`codex/moneythings-quick-action-management` 将旧模板列表升级为快速动作管理页，支持首页显示/隐藏、置顶、图标颜色、本地排序与删除。

## 保持不变

- 未修改 `supabase/migrations`。
- 未修改 SaaS entitlement/payment/sync 逻辑。
- 未修改 `.github/workflows`。
- 未新增破坏性数据迁移。
- 交易仍保存到具体 `accountId`，账户组只做视图聚合。
- 对象级共享仍是提示层，不新增对象级权限真相。

## 当前波次已完成

- Quick Action / One Touch 兼容协议已覆盖模板、Deep Link、Android widget、Android share、iOS Shortcuts 与 iOS share 的低风险入口。
- 快速动作已具备本地管理能力：显示/隐藏、置顶、图标颜色、排序和删除。
- iOS Shortcuts / Siri 可通过 App Intent 打开结构化记账编辑器，或通过快速动作 ID 打开 One Touch 入口。
- iOS 系统分享可把文本或 URL 作为 `shareReceive/rawText` 打开结构化编辑器。
- 外部交易入口已统一到 `TransactionEntryParams`，复杂或缺字段场景进入 `TransactionFormScreen`。
- 三层分类在选择、展示、详情、导入、导出上使用兼容路径，不新增 `tertiaryCategoryKey`。
- 账户组以视图层表达，交易仍保存到具体 `accountId`。
- SmartList 支持默认视图、置顶、当前筛选/搜索保存，以及固定分类页面保存。
- 对象共享第一阶段保持提示层，覆盖场景、账户、分类、标签的共享状态与删除风险提示。

## Post-Beta / 迁移型待评估

- 跨端 quick action 同步、从模板兼容源迁到独立云端 quick action 源、拖拽排序和更完整图标库。
- `parentAccountKey` migration，用于真实父子账户。
- 对象级 sharing table、RLS、离线冲突处理和审计日志。
- E2EE / 密钥管理。
- SaaS entitlement/payment/sync 行为变更。

## 验证计划

- `flutter analyze --no-fatal-infos`
- `flutter test test/moneythings_alignment_services_test.dart`
- `flutter test test/add_transaction_screen_entry_ux_test.dart`
- `flutter test test/category_picker_user_categories_test.dart`
- `flutter test test/transaction_entry_widget_regression_test.dart`
- 手工 smoke：打开新增记账页，选择三层分类，保存后确认详情路径与统计聚合不回退。

最新 post-merge 验证记录见：

- `docs/2026-05-05-moneythings-postmerge-closure-dev-verify.md`
- `docs/2026-05-05-moneythings-ios-shortcuts-dev-verify.md`
- `docs/2026-05-05-moneythings-ios-share-extension-dev-verify.md`
- `docs/2026-05-05-moneythings-quick-action-store-dev-verify.md`
- `docs/2026-05-05-moneythings-quick-action-management-dev-verify.md`
- `docs/moneythings-entry-system-user-guide.md`
