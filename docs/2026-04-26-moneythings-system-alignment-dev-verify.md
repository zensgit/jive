# Jive 借鉴 MoneyThings 体系收口开发及验证记录

## 背景

MoneyThings 的核心启发是“交易入口体系”，不是单一页面：One Touch、Widget、快捷指令、URL Scheme 和交易编辑器共享同一套参数与执行语义。Jive 本轮采用低迁移风险路线：先收口协议层和体验层，不新增交易/分类/账户破坏性字段。

## 本轮实现

### Quick Action / One Touch 协议

- 新增 `QuickActionService`，以现有 `JiveTemplate` 作为兼容持久层，对外暴露 `QuickAction` 执行协议。
- 新增 `QuickActionExecutor`，统一处理三种模式：
  - `direct`：金额、账户、分类齐全时直接保存交易。
  - `confirm`：只缺金额时打开轻确认 sheet。
  - `edit`：字段不足或转账类复杂动作进入结构化交易编辑器。
- `QuickEntryHubSheet` 与首页 `TemplateQuickBar` 已改为统一调用 `QuickActionExecutor`，不再各自直接保存模板交易。
- `QuickAction` 增加 `toAccountId`、分类名称字段，便于 Widget/Deep Link/AppIntent 后续接入同一协议。

### 交易编辑器入口统一

- `TransactionEntryParams` 增加 `prefillSubCategoryKey`、`prefillToAccountId`、`highlightFields` 和 `copyWith()`。
- `TransactionFormScreen` 支持来源横幅、缺字段高亮、快速动作预填、转账目标账户补全。
- 交易编辑器新增“保存为快速动作”入口，复用现有模板保存能力，避免新增 quick action 数据表。
- 保存时对金额、账户、分类/转入账户进行显式校验，避免外部入口静默保存失败。

### 三层分类兼容

- 新增 `CategoryPathService`，基于现有 `JiveCategory.parentKey` 解析任意深度路径。
- 交易保存保持兼容：`categoryKey` 写顶层分类，`subCategoryKey` 写最终叶子分类。
- `TransactionFormScreen` 分类选择改为路径式列表，可选择“出行 / 私家车 / 加油”这类三层叶子。
- `TransactionDetailScreen` 展示完整分类路径，老两层分类继续正常展示。

### 子账户视图层

- 新增 `AccountGroupService`，按 `JiveAccount.groupName` 聚合为账户组。
- 子账户仍是独立 `JiveAccount`，交易仍指向具体 `accountId`，不改交易主外键。
- 服务层支持账户组汇总、币种集合、显示路径，为资产页折叠/展开预留接口。

### 对象级共享第一阶段

- 新增 `ObjectSharePolicyService`，提供私有、继承场景共享、共享三种可见性标签。
- 共享提示只做用户可见状态和风险文案，不引入第二套权限真相。
- 权限边界仍保持 `shared ledger/book`，避免当前阶段直接做对象级 RLS。

### SmartList 产品化

- `SmartListService` 增加默认视图偏好，使用 `SharedPreferences` 持久化默认 SmartList id。
- `SmartListScreen` 长按菜单增加“设为默认视图 / 取消默认视图”，列表显示“默认”标记。

## 暂不做

- 2026-05-05 后续波次已新增本地 `JiveQuickAction` shadow collection；仍不新增 Supabase migration，不改变 SaaS sync/payment/entitlement。
- 不新增 `tertiaryCategoryKey` 到交易模型。
- 不新增 `parentAccountKey` 到账户模型。
- 不实现完整对象级 RLS、离线权限冲突与审计日志。
- 不扩展 SaaS entitlement、payment、sync、migration、workflow。

## 验证计划

- `flutter analyze --no-fatal-infos`
- `flutter test test/moneythings_alignment_services_test.dart`
- 交易页面手工 smoke：
  - 首页快速模板点击直存。
  - 缺金额模板弹出轻确认 sheet。
  - 转账模板进入交易编辑器并高亮转入账户。
  - 创建三层分类后，在交易编辑器选择叶子分类并保存，详情页显示完整路径。
  - 在交易编辑器点击“保存为快速动作”，确认首页快捷入口可复用。
  - SmartList 长按设为默认视图，返回列表可看到默认标记。

## 风险与后续

- 当前 QuickAction 已有本地 shadow collection，但模板仍是兼容来源；后续如需 One Touch 独立排序、图标、跨端同步，应再设计独立云端 quick action 源和冲突策略。
- `AddTransactionScreen` 的计算器高频入口未改成三层路径式选择；本轮先把结构化编辑器打通，后续可逐步复用 `CategoryPathService`。
- 对象级共享本轮是提示层；真实权限仍要等 SaaS 同步/RLS 稳定后再设计服务端协议。
