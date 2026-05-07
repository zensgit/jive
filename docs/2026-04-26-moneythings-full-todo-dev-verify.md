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
- 2026-05-05：PR #223 / `codex/moneythings-quick-action-dnd` 补齐快速动作可见/隐藏分区拖拽排序，并复用分类图标库扩充图标候选。
- 2026-05-06：PR #225 / `codex/moneythings-quick-action-custom-icons` 补齐快速动作自定义图标，复用分类图标源选择器，支持系统图标、表情、文字和本机图片。
- 2026-05-06：PR #227 / `codex/moneythings-quick-action-search` 补齐快速动作管理页搜索/过滤，支持按名称、分类、备注、金额、模式、类型、首页/隐藏和置顶状态查找；搜索期间禁用拖拽，避免过滤子集误改全局排序。
- 2026-05-06：`codex/moneythings-add-entry-save-action` 让新增记账页在金额、账户、分类完整后显示“保存为快速动作”，并把当前金额算式结果、账户、三层分类叶子、备注、时间、账本和标签反向生成快速动作 seed，生产仍复用模板兼容存储。
- 2026-05-06：`codex/moneythings-quick-action-core-edit` 为快速动作管理页补齐“编辑内容”，可修改名称、类型、默认金额、账户/转入账户、三层分类叶子和备注，并同步回 template-backed 兼容源。
- 2026-05-07：`codex/moneythings-account-group-collapse` 为资产页账户组补齐折叠/展开、本地偏好持久化和组内余额摘要，继续保持交易保存到具体子账户。
- 2026-05-10：`codex/moneythings-quick-action-editor-params` 补齐 Quick Action edit fallback 参数映射测试，并保留 `bookId` 作为结构化编辑器的场景/账本预填上下文。
- 2026-05-10：`codex/moneythings-scene-template-contracts` 固定日常、旅行、装修、家庭、宠物、自由职业 6 个场景模板的 ID 顺序与核心分类/标签语义，避免场景产品化后续回退。
- 2026-05-10：`codex/moneythings-transaction-entry-protocol` 补齐 `TransactionEntryParams` 协议回归测试，固定来源横幅、提交按钮、缺字段高亮和复杂转账预填合同。
- 2026-05-10：`codex/moneythings-category-import-segments` 补齐三层分类导入路径保真，CSV / 映射导入可保留完整 `大类 / 中类 / 小类` segments，并在同名叶子分类时按完整路径解析到正确叶子。
- 2026-05-10：`codex/moneythings-category-share-path-preview` 补齐分类分享预览的三层路径显示，导入前可看到 `大类 / 中类 / 小类`，并用 roundtrip 测试确认 `parentKey` 不丢失。
- 2026-05-10：`codex/moneythings-object-share-shared-ledger-boundary` 补齐对象共享提示在 sharedLedger-only 场景下的私有对象风险提示，仍保持提示层语义。

## 保持不变

- 未修改 `supabase/migrations`。
- 未修改 SaaS entitlement/payment/sync 逻辑。
- 未修改 `.github/workflows`。
- 未新增破坏性数据迁移。
- 交易仍保存到具体 `accountId`，账户组只做视图聚合。
- 对象级共享仍是提示层，不新增对象级权限真相。

## 继续收口记录

- 2026-05-07：PR #248 / `codex/moneythings-smartlist-regression-tests` 补齐 SmartList 服务级回归测试，覆盖筛选状态映射、置顶排序和默认视图删除清理。
- 2026-05-07：`codex/moneythings-object-share-policy-tests` 补齐对象共享提示策略测试，覆盖 shared ledger key、显式共享、私有对象阻止和空影响删除提示。
- 2026-05-07：`codex/moneythings-form-book-context` 补齐结构化交易编辑器的账本上下文展示与共享场景保存前提示，外部入口带 `prefillBookId` 时保存语义保持一致。
- 2026-05-10：`codex/moneythings-deeplink-source-coverage` 补齐 `jive://transaction/new` 的 `entrySource` 覆盖，支持 quickAction / voice / conversation / autoDraft / OCR 等结构化入口来源。
- 2026-05-07：`codex/moneythings-smartlist-regression` 增加 SmartList 默认视图、删除清理、置顶排序与筛选快照往返回归测试，不改变产品逻辑。
- 2026-05-10：`codex/moneythings-account-display-paths` 优化账户组路径展示，避免子账户名称已含类型/币种时重复显示。
- 2026-05-10：`codex/moneythings-smartlist-stale-default` 增加 SmartList 默认视图 stale id 清理，避免默认视图指向已删除记录。
- 2026-05-10：`codex/moneythings-category-hidden-paths` 修正三层分类可见路径解析，隐藏父级不再导致可见叶子丢失完整路径上下文。
- 2026-05-07：`codex/moneythings-shared-transaction-warning` 补齐共享场景手动新增交易保存前提示，取消不保存、继续后保持原交易保存路径。

## 当前波次已完成

- Quick Action / One Touch 兼容协议已覆盖模板、Deep Link、Android widget、Android share、iOS Shortcuts 与 iOS share 的低风险入口。
- 快速动作已具备本地管理能力：显示/隐藏、置顶、图标颜色、拖拽排序、上/下移动和删除。
- 快速动作样式选择器复用分类图标库和图标源选择器，并保留转账、信用卡、收款等 One Touch 专属图标。
- 快速动作本地 presentation 已支持系统图标、表情、文字图标和本机图片图标；本机图片跨端同步/备份仍不在当前阶段处理。
- 快速动作管理页已支持本地搜索过滤；过滤只作用于当前列表展示，不改变 quick action store 顺序和执行协议。
- 新增记账页已支持从当前完整手动输入保存为快速动作，补上 One Touch 从“真实记账行为”反向沉淀快捷入口的闭环。
- 快速动作管理页已支持编辑核心字段，用户可以在不重建动作、不更换 stable id 的情况下调整 One Touch 内容。
- 账户组已支持按账本和资产分区记住折叠状态，收起时保留子账户数量、币种和组内余额摘要。
- iOS Shortcuts / Siri 可通过 App Intent 打开结构化记账编辑器，或通过快速动作 ID 打开 One Touch 入口。
- iOS 系统分享可把文本或 URL 作为 `shareReceive/rawText` 打开结构化编辑器。
- 外部交易入口已统一到 `TransactionEntryParams`，复杂或缺字段场景进入 `TransactionFormScreen`；结构化编辑器可展示传入账本/共享场景上下文，并在共享场景保存前确认。
- 三层分类在选择、展示、详情、导入、导出上使用兼容路径，不新增 `tertiaryCategoryKey`。
- 账户组以视图层表达，交易仍保存到具体 `accountId`。
- SmartList 支持默认视图、置顶、当前筛选/搜索保存，以及固定分类页面保存；服务级测试已覆盖保存视图映射、置顶排序和默认视图清理。
- 对象共享第一阶段保持提示层，覆盖场景、账户、分类、标签的共享状态、共享场景交易保存提示与删除风险提示。

## Post-Beta / 迁移型待评估

- 跨端 quick action 同步、从模板兼容源迁到独立云端 quick action 源、`file:` 自定义图标的跨端同步/备份语义。
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
- `docs/2026-05-05-moneythings-quick-action-dnd-dev-verify.md`
- `docs/2026-05-06-moneythings-quick-action-custom-icons-dev-verify.md`
- `docs/2026-05-06-moneythings-quick-action-search-dev-verify.md`
- `docs/2026-05-06-moneythings-add-entry-save-action-dev-verify.md`
- `docs/2026-05-06-moneythings-quick-action-core-edit-dev-verify.md`
- `docs/2026-05-07-moneythings-account-group-collapse-dev-verify.md`
- `docs/2026-05-10-moneythings-quick-action-editor-params-dev-verify.md`
- `docs/2026-05-10-moneythings-scene-template-contracts-dev-verify.md`
- `docs/2026-05-10-moneythings-transaction-entry-protocol-dev-verify.md`
- `docs/2026-05-07-moneythings-smartlist-regression-tests-dev-verify.md`
- `docs/2026-05-07-moneythings-object-share-policy-tests-dev-verify.md`
- `docs/2026-05-07-moneythings-form-book-context-dev-verify.md`
- `docs/2026-05-10-moneythings-deeplink-source-coverage-dev-verify.md`
- `docs/2026-05-07-moneythings-smartlist-regression-dev-verify.md`
- `docs/2026-05-10-moneythings-account-display-paths-dev-verify.md`
- `docs/2026-05-10-moneythings-smartlist-stale-default-dev-verify.md`
- `docs/2026-05-10-moneythings-category-hidden-paths-dev-verify.md`
- `docs/2026-05-07-moneythings-shared-transaction-warning-dev-verify.md`
- `docs/2026-05-10-moneythings-category-import-segments-dev-verify.md`
- `docs/2026-05-10-moneythings-category-share-path-preview-dev-verify.md`
- `docs/2026-05-10-moneythings-object-share-shared-ledger-boundary-dev-verify.md`
- `docs/moneythings-entry-system-user-guide.md`
