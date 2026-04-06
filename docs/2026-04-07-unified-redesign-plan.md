# Jive 统一改造开发计划

## 背景

本计划合并两个来源：
1. `2026-04-06-add-transaction-editor-onetouch-redesign-plan.md` — 记账页改造 + OneTouch
2. MoneyThings 竞品分析 6 个借鉴建议

目标：在不推翻现有能力的前提下，让 Jive 从"功能堆砌"进化为"有产品主张的记账体系"。

---

## 总览：3 层 10 步

```
第1层（低风险，立即执行）
  S1. 开箱即用场景模板
  S2. SmartList 保存视图
  S3. 快记体系统一入口

第2层（中风险，核心改造）
  S4. 快速动作接入（计划文档阶段2）
  S5. 来源统一入参（计划文档阶段3）
  S6. 页面UI拆分（计划文档阶段1）
  S7. Plan 统一预算/目标/未来交易

第3层（高风险，架构升级）
  S8. 场景层包装
  S9. 对象级共享边界
  S10. 系统级联动（计划文档阶段4）
```

---

## 第1层：低风险，立即执行

### S1. 开箱即用场景模板

**目标**：新用户引导时可选择预置场景，降低"从零开始"的认知负担。

**产出文件**：
- `lib/core/service/scene_template_service.dart`
- `lib/core/data/scene_templates.dart`
- `lib/feature/onboarding/scene_template_picker.dart`

**预置场景**（每个包含分类子集+默认标签+建议预算）：
| 场景 | 分类子集 | 标签 | 建议预算 |
|------|---------|------|---------|
| 日常生活 | 餐饮/交通/购物/住房/日常 | 无 | ¥5000 |
| 旅行出差 | 交通/住宿/餐饮/门票/购物 | 旅行 | ¥10000 |
| 装修 | 材料/人工/家电/家具/设计 | 装修 | ¥50000 |
| 情侣/家庭 | 餐饮/礼物/娱乐/日用/医疗 | 家庭 | ¥8000 |
| 宠物 | 食品/医疗/用品/洗护/寄养 | 宠物 | ¥2000 |
| 自由职业 | 设备/软件/办公/税费/收入 | 工作 | ¥3000 |

**集成点**：
- GuidedSetupScreen 第1步增加场景选择
- 选择场景后自动创建 Book + 对应分类/标签/预算
- 设置页可重新选择或新建场景

**验收**：
- 新安装选择"旅行出差"后，分类列表只显示旅行相关
- 预算自动创建
- 不影响已有用户数据

---

### S2. SmartList 保存视图

**目标**：用户可以保存搜索/筛选条件为命名视图，快速访问常用数据切面。

**产出文件**：
- `lib/core/database/smart_list_model.dart` — Isar 模型
- `lib/core/service/smart_list_service.dart`
- `lib/feature/smart_list/smart_list_screen.dart`
- `lib/feature/smart_list/smart_list_picker.dart`

**模型字段**：
```dart
class JiveSmartList {
  Id id = Isar.autoIncrement;
  String name = '';          // 用户命名："本月餐饮"、"大额支出"
  String? iconName;          // 图标
  String? colorHex;          // 颜色
  
  // 筛选条件（JSON 序列化）
  String? categoryKeys;      // 逗号分隔
  String? tagKeys;           // 逗号分隔
  int? accountId;
  int? bookId;
  String? transactionType;   // expense/income/transfer
  double? minAmount;
  double? maxAmount;
  String? dateRangeType;     // last7d/last30d/thisMonth/custom
  DateTime? customStartDate;
  DateTime? customEndDate;
  String? keyword;           // 备注关键词
  
  int sortOrder = 0;
  bool isPinned = false;
  DateTime createdAt = DateTime.now();
}
```

**交互**：
- 全部账单页筛选后，底部出现"保存为视图"按钮
- 首页菜单新增"我的视图"入口
- 视图列表支持排序/置顶/删除
- 点击视图 → 直接打开已筛选的交易列表

**验收**：
- 可保存"本月餐饮超过50元"的筛选条件
- 下次打开直接看到结果
- 不影响现有搜索功能

---

### S3. 快记体系统一入口

**目标**：把分散的快记入口（FAB/模板/语音/对话/分享/截图）统一为一个品牌化的"快记中心"。

**产出文件**：
- `lib/feature/quick_entry/quick_entry_hub_sheet.dart`

**交互**：
- 首页 FAB 长按 → 弹出快记中心 bottom sheet
- 短按 FAB → 直接进入默认记账页（保持现有行为）
- 快记中心内容：
  ```
  ┌─────────────────────────────┐
  │     快记中心                  │
  ├─────────────────────────────┤
  │ 📝 手动记账    🎤 语音记账    │
  │ 💬 对话记账    📸 截图识别    │
  │ 📋 从模板记    📥 从分享记    │
  ├─────────────────────────────┤
  │ ⚡ 常用快速动作               │
  │ [早餐 ¥15] [地铁 ¥3] [咖啡]  │
  │ [午餐] [打车] [更多...]       │
  └─────────────────────────────┘
  ```
- 常用快速动作 = 现有模板按使用频率排序

**验收**：
- 长按 FAB 弹出 6 种快记方式
- 短按 FAB 保持不变
- 常用动作可一键执行

---

## 第2层：中风险，核心改造

### S4. 快速动作接入（计划文档阶段2）

**目标**：模板升级为"快速动作"，支持直接提交/轻确认/编辑三种模式。

**产出文件**：
- `lib/core/model/quick_action.dart` — 快速动作数据类
- `lib/core/service/quick_action_service.dart`
- `lib/feature/quick_entry/quick_action_executor.dart`

**快速动作模型**：
```dart
class QuickAction {
  String id;
  String name;
  String? iconName;
  String? colorHex;
  
  // 预填字段
  String transactionType;      // expense/income/transfer
  int? bookId;
  int? accountId;
  String? categoryKey;
  List<String> tagKeys;
  double? defaultAmount;       // null = 需要输入
  String? defaultNote;
  
  // 执行模式
  QuickActionMode mode;        // direct/confirm/edit
  bool showOnHome;
  bool showInShortcuts;
  
  int usageCount = 0;
  DateTime? lastUsedAt;
}

enum QuickActionMode {
  direct,   // 金额已设，一键提交
  confirm,  // 只缺金额/备注，轻确认
  edit,     // 打开完整编辑器
}
```

**执行流程**：
```
用户点击快速动作
  ├── mode=direct → 直接保存交易 → toast "已记录"
  ├── mode=confirm → 弹出轻量确认sheet（只显示金额+备注输入）→ 保存
  └── mode=edit → 打开 AddTransactionScreen（预填字段）
```

**与现有模板的关系**：
- 阶段1：QuickAction 数据从 JiveTemplate 读取转换
- 阶段2：QuickAction 作为独立模型存储
- JiveTemplate 不删除，保持兼容

**集成点**：
- 首页模板快捷栏 → 使用 QuickAction
- 快记中心 → 常用快速动作列表
- 记账页底部 → "保存为快速动作"按钮
- Deep Link → `jive://quickaction?id=xxx`

**验收**：
- "早餐 ¥15" 一键直接入账
- "午餐" 弹出金额输入后入账
- "信用卡还款" 打开完整编辑器

---

### S5. 来源统一入参（计划文档阶段3）

**目标**：AddTransactionScreen 通过统一的入参结构识别来源和模式。

**产出文件**：
- `lib/feature/transactions/transaction_entry_params.dart`

**入参结构**：
```dart
class TransactionEntryParams {
  final TransactionEntrySource source;
  final String? sourceLabel;         // "来自快速动作「午餐」"
  final bool canDirectSubmit;        // 是否允许直接提交
  final List<String> highlightFields; // 待补字段高亮
  final String? quickActionId;       // 快速动作 ID
  
  // 预填字段
  final double? prefillAmount;
  final String? prefillType;         // expense/income/transfer
  final String? prefillCategoryKey;
  final int? prefillAccountId;
  final String? prefillNote;
  final DateTime? prefillDate;
  final List<String>? prefillTagKeys;
  
  // 编辑模式
  final JiveTransaction? editingTransaction;
}

enum TransactionEntrySource {
  manual,        // 手动新增
  quickAction,   // 快速动作
  voice,         // 语音输入
  conversation,  // 对话记账
  autoDraft,     // 自动草稿
  ocrScreenshot, // 截图识别
  shareReceive,  // 分享接收
  deepLink,      // Deep Link
  edit,          // 编辑已有交易
}
```

**页面行为根据 source 变化**：
| source | 标题 | 主按钮 | 来源横幅 |
|--------|------|--------|---------|
| manual | 记一笔 | 保存 | 无 |
| quickAction | 快速记录 | 立即记录 | "来自快速动作「xxx」" |
| voice | 确认交易 | 确认入账 | "来自语音输入" |
| autoDraft | 确认交易 | 确认入账 | "来自自动识别" |
| edit | 编辑交易 | 保存修改 | 无 |

**验收**：
- 所有入口进入记账页时，顶部正确显示来源
- 按钮文案随来源变化
- 功能不回归

---

### S6. 页面 UI 拆分（计划文档阶段1）

**目标**：把 3800 行的 add_transaction_screen.dart 拆分为独立 widget 组件。

**产出文件**：
- `lib/feature/transactions/widgets/transaction_source_banner.dart`
- `lib/feature/transactions/widgets/transaction_core_fields.dart`
- `lib/feature/transactions/widgets/transaction_advanced_section.dart`
- `lib/feature/transactions/widgets/transaction_footer_bar.dart`
- `lib/feature/transactions/widgets/transaction_amount_display.dart`

**拆分策略**：
- 不改变状态管理方式（保留原有 State）
- 只把 build 方法中的 widget 树提取为独立文件
- 通过 callback 和参数传递与主页面通信
- 逐步拆分，每次只提取一个组件

**拆分顺序**（每步可独立验证）：
1. `transaction_source_banner.dart` — 来源横幅
2. `transaction_footer_bar.dart` — 底部固定提交区
3. `transaction_advanced_section.dart` — 高级选项折叠
4. `transaction_core_fields.dart` — 核心字段区
5. `transaction_amount_display.dart` — 金额+类型+日期区

**验收**：
- 拆分后功能完全不变
- 所有编辑/转账/多币种流程可用
- 测试全绿

---

### S7. Plan 统一预算/目标/未来交易

**目标**：用"计划"概念统一预算、储蓄目标、周期记账、旅行预算、分期付款。

**产出文件**：
- `lib/core/model/unified_plan.dart`
- `lib/core/service/unified_plan_service.dart`
- `lib/feature/plan/plan_hub_screen.dart`

**统一模型**：
```dart
class UnifiedPlan {
  String id;
  String name;
  PlanType type;              // budget/goal/recurring/travel/installment
  
  // 范围
  double? targetAmount;        // 目标金额
  double? limitAmount;         // 限制金额
  String? period;              // daily/weekly/monthly/yearly/custom
  DateTime startDate;
  DateTime? endDate;
  
  // 过滤条件
  String? categoryKey;
  int? projectId;
  int? bookId;
  List<String>? tagKeys;
  int? accountId;
  
  // 进度
  double currentAmount = 0;
  PlanStatus status;           // active/completed/exceeded/paused
  
  // 行为
  bool isRepeating = false;
  bool isShared = false;
}
```

**计划中心页面**：
```
┌─────────────────────────────┐
│ 计划中心                      │
├─────────────────────────────┤
│ 💰 预算 (3)                   │
│   本月生活预算 ¥3200/¥5000    │
│   餐饮预算 ¥890/¥1500        │
│                              │
│ 🎯 目标 (2)                   │
│   旅行基金 ¥12000/¥30000     │
│   应急储蓄 ¥8000/¥50000      │
│                              │
│ 🔄 定期 (1)                   │
│   房租 每月1号 ¥3500          │
│                              │
│ ✈️ 旅行 (1)                   │
│   日本旅行 进行中 ¥5200       │
└─────────────────────────────┘
```

**与现有模型的关系**：
- 不删除 JiveBudget / JiveSavingsGoal / JiveRecurringRule
- UnifiedPlan 作为**视图层聚合**，从各模型读取数据
- 首页菜单"计划中心"替代分散入口

**验收**：
- 一个页面看到所有"计划类"对象
- 不丢失任何现有功能
- 菜单入口精简

---

## 第3层：高风险，架构升级

### S8. 场景层包装

**目标**：用"场景"概念包装 账本 + 项目 + 标签过滤，作为一级产品对象。

**设计原则**：
- 场景 ≈ 账本 + 默认过滤器 + UI 偏好
- 不新建数据库表，复用 JiveBook
- 场景是 Book 的"产品包装"

**产出文件**：
- `lib/core/model/scene.dart` — 场景视图模型
- `lib/core/service/scene_service.dart` — 场景管理
- `lib/feature/scene/scene_switcher.dart` — 场景切换器

**场景模型**：
```dart
class Scene {
  final JiveBook book;
  final String? iconEmoji;
  final List<String> defaultTagKeys;
  final List<String> defaultCategoryKeys;
  final int? defaultProjectId;
  
  // UI 偏好
  final String? accentColorHex;
  final bool showBudgetOnHome;
  final bool showGoalsOnHome;
}
```

**首页改造**：
- 顶部"访客"旁边 → 场景选择器
- 切换场景 → 自动切换账本 + 过滤分类/标签
- 底部 tab 不变（Home/Stats/Assets）

**验收**：
- 切换"旅行"场景后，分类只显示旅行相关
- 统计数据按场景过滤
- 不影响现有账本切换

---

### S9. 对象级共享边界

**目标**：让场景、账户、标签、分类都能独立设置共享权限。

**设计原则**：
- 借鉴 MoneyThings 的"每个对象可独立共享"
- 不照搬 CloudKit 实现，复用 Supabase RLS

**产出文件**：
- `lib/core/model/share_permission.dart`
- `lib/core/service/object_sharing_service.dart`

**共享粒度**：
```
场景（Book）  → 可共享给其他用户
  ├── 账户    → 跟随场景共享 or 私有
  ├── 分类    → 跟随场景共享 or 私有
  ├── 标签    → 跟随场景共享 or 私有
  └── 交易    → 跟随场景共享
```

**冲突约束提示**：
- "此账户属于共享场景，其他成员也能看到"
- "此分类仅你可见"
- "修改此交易将同步到其他成员"

**验收**：
- 共享场景中创建的交易，其他成员可见
- 私有账户不会出现在共享场景的成员视图中
- 有清晰的共享状态提示

---

### S10. 系统级联动（计划文档阶段4）

**目标**：为 Widget / App Intent / 快捷指令铺路。

**产出文件**：
- `lib/core/service/app_intent_service.dart`
- Android: Widget 数据更新逻辑增强
- iOS: App Intent 定义（未来）

**联动矩阵**：
| 入口 | 快速动作 | 场景切换 | 记账 | 查看 |
|------|---------|---------|------|------|
| Android Widget | ✅ | ❌ | ✅ | ✅ |
| iOS Widget | ✅ | ❌ | ✅ | ✅ |
| Deep Link | ✅ | ✅ | ✅ | ✅ |
| Share Target | ❌ | ❌ | ✅ | ❌ |
| Siri/Intent | ✅ | ✅ | ✅ | ✅ |

**验收**：
- Widget 可触发快速动作
- Deep Link 可切换场景
- 所有入口最终进入同一套记账页面

---

## 执行时间线建议

```
第1周：S1 + S2 + S3（低风险，并行开发）
第2周：S4 + S5（快速动作 + 来源统一）
第3周：S6（页面拆分，需要集中精力）
第4周：S7（Plan 统一，视图层）
第5周：S8（场景层，需要设计评审）
第6周：S9 + S10（共享边界 + 系统联动）
```

---

## 风险控制

1. **每步独立可验证** — 每个 S 都可以独立上线，不依赖后续步骤
2. **不删除现有模型** — 所有新概念都是"包装层"，不破坏底层数据
3. **回归测试** — 每步完成后跑 330+ 测试
4. **真机验证** — 每步构建 APK 验证
5. **Git 分支** — 每步独立分支，合并前 review

---

## Codex SaaS 并行计划

| Codex 任务 | 状态 | 与改造的关系 |
|-----------|------|------------|
| B0.1 边界设计 | ✅ 完成 | S8 场景层的设计基础 |
| B0.2 稳定云端标识 | ✅ 合并 | S9 共享边界的前提 |
| B1.1 同步 Schema | ✅ 合并 | S9 的 book_key 基础 |
| B1.2 去 local_id | ⏳ 执行中 | S9 的 syncKey 基础 |
| B2.1 订阅可信化 | 待做 | 独立于改造 |
| B3.1 登录收口 | 待做 | 独立于改造 |

Codex 继续推进 SaaS 化不受改造影响，两条线并行。
