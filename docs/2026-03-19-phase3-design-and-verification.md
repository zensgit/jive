# Phase 3 集成设计与验证方案

> 生成日期: 2026-03-19
> 基线分支: `codex/post-merge-verify` @ `28d218c`
> 对标分析: `docs/2026-03-17-feature-gap-analysis.md`

---

## 一、当前进度总览

### Phase 1 (P0 核心体验) — ✅ 全部完成

| 功能 | 状态 | 关键文件 | 说明 |
|------|------|----------|------|
| 统计图表增强 | ✅ Done | `feature/stats/` (5 files, 1101 lines) | 4-tab 视图：月度总览、分类分析、趋势图、详细统计 |
| 全局搜索 | ✅ Done | `feature/search/global_search_screen.dart` (462 lines) | 实时搜索、300ms debounce、分页、详情跳转 |
| CSV 导出 | ✅ Done | `core/service/csv_export_service.dart` + `feature/settings/csv_export_screen.dart` | 时间范围 + 分类筛选、BOM 编码、Share |

### Phase 2 (P1 竞争力) — ✅ 全部完成并合入 main

| 功能 | PR | 状态 |
|------|-----|------|
| 日历视图 | #60 | ✅ Merged |
| CSV 导出 | #59 | ✅ Merged |
| 退款管理 | #61 | ✅ Merged |
| 主题定制 | #62 | ✅ Merged |
| 分期管理 | #63 | ✅ Merged |

### 待处理遗留

| 项目 | 说明 |
|------|------|
| `codex/post-merge-verify` 分支 | 含 stats + search + csv 的 4 个 commit，尚未 merge 到 main |
| `main.dart` 未提交变更 | CSV 导出菜单入口 (18 行新增) |
| 5 个空特性分支 | app-lock, bill-attach, loan-mgmt, reimbursement, savings-goal — 均从 main 分叉但无独立 commit |

---

## 二、Phase 3 待开发功能清单

根据 gap analysis + 空分支规划，Phase 3 包含以下 **8 个功能模块**：

| # | 功能 | 优先级 | 预估工作量 | 对应分支 |
|---|------|--------|-----------|---------|
| 1 | 多账本 (AccountBook) | P1 | 大 (5-7天) | 新建 |
| 2 | 存钱目标 (SavingsGoal) | P2 | 中 (3-4天) | `codex/codex-savings-goal` |
| 3 | 应用锁 (AppLock) | P2 | 中 (2-3天) | `codex/codex-app-lock` |
| 4 | 贷款管理 (LoanMgmt) | P1 | 中 (3-4天) | `codex/codex-loan-mgmt` |
| 5 | 报销追踪 (Reimbursement) | P1 | 小 (1-2天) | `codex/codex-reimbursement` |
| 6 | 账单附件 (BillAttach) | P2 | 小 (1-2天) | `codex/codex-bill-attach` |
| 7 | 桌面小组件 (Widget) | P2 | 中 (3-4天) | 新建 |
| 8 | Markdown 笔记 (Note) | P2 | 中 (2-3天) | 新建 |

---

## 三、各功能详细集成设计

### 3.1 多账本 (AccountBook)

**需求**: 支持个人/家庭/旅行等多账本隔离，每个账本有独立的交易、预算、统计。

**数据模型设计**:
```dart
// lib/core/database/account_book_model.dart
@collection
class JiveAccountBook {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String key;            // UUID

  late String name;           // 账本名称
  String? description;
  String? iconName;           // 图标
  String? colorHex;           // 颜色
  String type = 'personal';   // personal | family | travel | business
  bool isDefault = false;     // 是否默认账本
  int sortOrder = 0;

  late DateTime createdAt;
  late DateTime updatedAt;
}
```

**时间戳约束**:
- `createdAt` / `updatedAt` 统一由 Service 层在写入数据库前赋值，不在模型定义中直接使用 `DateTime.now()` 作为默认值。

**集成点**:
1. **JiveTransaction** — 新增 `int? accountBookId` 字段 (索引)，关联到账本
2. **JiveBudget** — 新增 `int? accountBookId`，预算按账本隔离
3. **DatabaseService.schemas** — 添加 `JiveAccountBookSchema`
4. **main.dart** — 导航栏新增账本切换入口 (Drawer 或底部弹窗)
5. **全局状态** — `AccountBookService` 维护 `currentBookId`，所有查询基于当前账本过滤
6. **StatsAggregationService** — 聚合查询增加 accountBookId 过滤
7. **GlobalSearchScreen** — 搜索范围限定当前账本

**迁移策略**:
- 首次启动自动创建"默认账本"，所有现有交易归入默认账本
- `accountBookId == null` 视为默认账本 (向后兼容)

**文件清单**:
```
lib/core/database/account_book_model.dart      (NEW)
lib/core/service/account_book_service.dart      (NEW)
lib/feature/account_book/account_book_list_screen.dart  (NEW)
lib/feature/account_book/account_book_edit_screen.dart  (NEW)
lib/core/database/transaction_model.dart        (MODIFY - add accountBookId)
lib/core/database/budget_model.dart             (MODIFY - add accountBookId)
lib/core/service/database_service.dart          (MODIFY - add schema)
lib/core/service/transaction_service.dart       (MODIFY - add book filter)
lib/core/service/stats_aggregation_service.dart (MODIFY - add book filter)
lib/main.dart                                   (MODIFY - add book switcher)
```

---

### 3.2 存钱目标 (SavingsGoal)

**需求**: 设定存钱目标、进度追踪、提醒、关联账户。

**数据模型设计**:
```dart
// lib/core/database/savings_goal_model.dart
@collection
class JiveSavingsGoal {
  Id id = Isar.autoIncrement;

  late String name;            // 目标名称 (如"日本旅行基金")
  String? description;
  String? iconName;
  String? colorHex;

  late double targetAmount;    // 目标金额
  late String currency;        // 货币代码
  double currentAmount = 0;    // 当前已存金额

  DateTime? targetDate;        // 目标日期
  int? linkedAccountId;        // 关联存钱账户

  String status = 'active';    // active | completed | paused | cancelled
  bool autoTrack = false;      // 是否自动追踪关联账户余额变化

  late DateTime createdAt;
  late DateTime updatedAt;
}

@collection
class JiveSavingsRecord {
  Id id = Isar.autoIncrement;

  @Index()
  late int goalId;
  late double amount;          // 正数=存入, 负数=取出
  String? note;
  int? transactionId;          // 关联交易 (可选)

  late DateTime createdAt;
}
```

**集成点**:
1. **DatabaseService** — 添加 2 个新 schema
2. **main.dart** — Drawer 添加 "存钱目标" 入口
3. **TransactionService** — 交易创建后检查是否关联存钱账户，自动更新进度
4. **通知** — 达成目标时本地通知 (flutter_local_notifications)

**文件清单**:
```
lib/core/database/savings_goal_model.dart         (NEW)
lib/core/service/savings_goal_service.dart         (NEW)
lib/feature/savings/savings_goal_list_screen.dart   (NEW)
lib/feature/savings/savings_goal_detail_screen.dart (NEW)
lib/feature/savings/savings_goal_edit_screen.dart   (NEW)
lib/core/service/database_service.dart             (MODIFY)
lib/main.dart                                      (MODIFY)
```

---

### 3.3 应用锁 (AppLock)

**需求**: 手势密码 + 生物识别 (Face ID / 指纹)，APP 启动或切回前台时验证。

**技术选型**:
- `local_auth` (Flutter 官方) — 生物识别
- `shared_preferences` — 存储加密后的密码哈希
- 无需新 Isar 模型

**集成设计**:
```dart
// lib/core/service/app_lock_service.dart
class AppLockService {
  // SharedPreferences keys
  static const _kEnabled = 'app_lock_enabled';
  static const _kPinHash = 'app_lock_pin_hash';
  static const _kBiometricEnabled = 'app_lock_biometric';
  static const _kLockOnBackground = 'app_lock_on_background';
  static const _kAutoLockSeconds = 'app_lock_auto_seconds';

  Future<bool> isEnabled();
  Future<void> setPin(String pin);
  Future<bool> verifyPin(String pin);
  Future<bool> authenticateBiometric();
  Future<void> disable();
}
```

**集成点**:
1. **main.dart** — `WidgetsBindingObserver` 监听 `didChangeAppLifecycleState`
2. **JiveApp** — 在 MaterialApp 外包裹 LockScreen overlay
3. **SettingsScreen** — 添加安全设置入口 (开关、修改密码、生物识别开关)

**文件清单**:
```
lib/core/service/app_lock_service.dart           (NEW)
lib/feature/settings/app_lock_setup_screen.dart  (NEW)
lib/feature/settings/lock_screen.dart            (NEW)
lib/feature/settings/gesture_input_widget.dart   (NEW)
lib/feature/settings/settings_screen.dart        (MODIFY)
lib/main.dart                                    (MODIFY)
pubspec.yaml                                     (MODIFY - add local_auth)
```

**新增依赖**: `local_auth: ^2.2.0`, `crypto` (已有)

---

### 3.4 贷款管理 (LoanMgmt)

**需求**: 房贷/车贷/消费贷追踪，还款计划、剩余本金、利息计算。

**数据模型设计**:
```dart
// lib/core/database/loan_model.dart
@collection
class JiveLoan {
  Id id = Isar.autoIncrement;

  late String name;             // 贷款名称
  late double principalAmount;  // 贷款总额
  late double annualRate;       // 年利率 (%)
  late int totalMonths;         // 总期数
  String repaymentType = 'equal_installment'; // equal_installment | equal_principal
  late DateTime startDate;      // 首次还款日

  int? linkedAccountId;         // 关联还款账户
  String? categoryKey;          // 关联分类 (如"房贷")
  String? note;

  String status = 'active';     // active | completed | early_settled

  late DateTime createdAt;
  late DateTime updatedAt;
}

@collection
class JiveLoanPayment {
  Id id = Isar.autoIncrement;

  @Index()
  late int loanId;
  late int periodNumber;        // 期数
  late double principalPart;    // 本金部分
  late double interestPart;     // 利息部分
  late double totalPayment;     // 当期应还
  double? actualPayment;        // 实际还款金额
  bool isPaid = false;
  int? transactionId;           // 关联交易

  DateTime? dueDate;
  DateTime? paidDate;
}
```

**集成点**:
1. **DatabaseService** — 添加 2 个新 schema
2. **RecurringService** — 贷款到期日自动生成提醒
3. **TransactionService** — 还款交易自动关联 LoanPayment
4. **StatsScreen** — 新增贷款概况卡片

**文件清单**:
```
lib/core/database/loan_model.dart               (NEW)
lib/core/service/loan_service.dart              (NEW)
lib/core/service/loan_calculator.dart           (NEW - 等额本息/等额本金计算)
lib/feature/loan/loan_list_screen.dart          (NEW)
lib/feature/loan/loan_detail_screen.dart        (NEW)
lib/feature/loan/loan_edit_screen.dart          (NEW)
lib/feature/loan/loan_schedule_widget.dart      (NEW)
lib/core/service/database_service.dart          (MODIFY)
lib/main.dart                                   (MODIFY)
```

---

### 3.5 报销追踪 (Reimbursement)

**需求**: 标记交易为"待报销"，追踪报销状态，统计待报销总额。

**设计方案 (轻量级，复用 Tag 机制)**:

不新建 Isar 模型，而是利用现有 Tag 系统 + Transaction 扩展字段：

```dart
enum ReimbursementStatus { pending, partial, completed }

// 在 JiveTransaction 中增加:
ReimbursementStatus? reimbursementStatus;
double? reimbursedAmount;     // 已报销金额
DateTime? reimbursedDate;
```

**集成点**:
1. **TransactionDetailScreen** — 添加 "标记报销" 操作按钮
2. **StatsScreen/搜索** — 支持按报销状态筛选
3. **Drawer** — 添加 "待报销" 快捷入口，显示未报销总额

**文件清单**:
```
lib/core/database/transaction_model.dart            (MODIFY - 3 字段)
lib/core/service/reimbursement_service.dart          (NEW)
lib/feature/reimbursement/reimbursement_screen.dart  (NEW)
lib/feature/transactions/transaction_detail_screen.dart (MODIFY)
lib/main.dart                                        (MODIFY)
```

---

### 3.6 账单附件 (BillAttach)

**需求**: 交易关联图片/PDF 附件 (小票、发票、合同)。

**数据模型设计**:
```dart
// 在 JiveTransaction 中增加:
List<String> attachmentPaths = [];  // 本地文件路径列表
```

**集成点**:
1. **TransactionDetailScreen** — 附件预览区
2. **AddTransactionScreen** — 附件上传按钮 (image_picker 已有依赖)
3. **文件管理** — 附件存入 `applicationDocumentsDirectory/attachments/`
4. **DataBackupService** — 备份时包含附件

**文件清单**:
```
lib/core/service/attachment_service.dart                (NEW)
lib/core/widgets/attachment_preview_widget.dart          (NEW)
lib/core/database/transaction_model.dart                (MODIFY)
lib/feature/transactions/add_transaction_screen.dart     (MODIFY)
lib/feature/transactions/transaction_detail_screen.dart  (MODIFY)
```

---

### 3.7 桌面小组件 (Android Widget)

**需求**: Android 桌面展示今日收支、快捷记账。

**技术选型**: `home_widget` package

**集成点**:
1. Android 原生 Widget (XML layout + BroadcastReceiver)
2. `HomeWidgetService` — 将每日收支数据推送给 Widget
3. **TransactionService** — 每次增删改后刷新 Widget 数据

**文件清单**:
```
lib/core/service/home_widget_service.dart                     (NEW)
android/app/src/main/java/.../JiveDailyWidget.kt             (NEW)
android/app/src/main/res/layout/widget_daily.xml             (NEW)
android/app/src/main/res/xml/widget_daily_info.xml           (NEW)
android/app/src/main/AndroidManifest.xml                     (MODIFY)
lib/core/service/transaction_service.dart                     (MODIFY)
pubspec.yaml                                                  (MODIFY - add home_widget)
```

---

### 3.8 Markdown 笔记 (Note)

**需求**: 与交易关联的 Markdown 笔记。

**数据模型设计**:
```dart
@collection
class JiveNote {
  Id id = Isar.autoIncrement;

  late String title;
  late String content;      // Markdown 内容
  int? transactionId;       // 关联交易 (可选)
  int? projectId;           // 关联项目 (可选)
  List<String> tagKeys = [];

  late DateTime createdAt;
  late DateTime updatedAt;
}
```

**技术选型**: `flutter_markdown` (渲染) + 基础文本编辑 (无需富文本编辑器)

**文件清单**:
```
lib/core/database/note_model.dart               (NEW)
lib/core/service/note_service.dart              (NEW)
lib/feature/note/note_list_screen.dart          (NEW)
lib/feature/note/note_edit_screen.dart          (NEW)
lib/feature/note/note_preview_widget.dart       (NEW)
lib/core/service/database_service.dart          (MODIFY)
lib/feature/transactions/transaction_detail_screen.dart (MODIFY)
pubspec.yaml                                    (MODIFY - add flutter_markdown)
```

---

## 四、推荐开发顺序

基于依赖关系和用户价值排序：

```
Wave 1 (高价值 + 低耦合，~1 周)
├── 3.5 报销追踪        → 轻量，复用现有字段，独立性强
├── 3.6 账单附件        → 利用已有 image_picker，独立性强
└── 3.3 应用锁          → 独立模块，安全基础

Wave 2 (核心扩展，~1.5 周)
├── 3.2 存钱目标        → 新模块，中等复杂度
└── 3.4 贷款管理        → 新模块，需要计算引擎

Wave 3 (架构级变更，~2 周)
├── 3.1 多账本          → 影响面最大，需全局查询改造
└── 3.8 Markdown 笔记   → 新模块 + UI 组件

Wave 4 (平台相关，~1 周)
└── 3.7 桌面小组件      → 需 Android 原生代码
```

---

## 五、集成验证方案

### 5.1 数据库迁移验证

| 验证项 | 方法 | 通过标准 |
|--------|------|---------|
| Schema 注册 | `DatabaseService.schemas` 包含所有新模型 | 编译通过，`flutter analyze` 0 错误 |
| 向后兼容 | 新字段均有默认值，nullable 或 `= default` | 老数据打开不崩溃 |
| build_runner | `dart run build_runner build` | 所有 `.g.dart` 生成成功 |
| 迁移测试 | 创建含老数据的数据库，升级后验证 | 数据完整，新字段为默认值 |

### 5.2 功能验证矩阵

#### Wave 1

| 功能 | 测试场景 | 预期结果 |
|------|---------|---------|
| **报销追踪** | 标记交易为待报销 → 报销列表查看 → 标记已报销 | 状态更新正确，金额统计准确 |
| **报销追踪** | 部分报销 | `reimbursedAmount < amount`，状态为 partial |
| **账单附件** | 添加交易时上传图片 → 详情页查看 | 图片正常保存和展示 |
| **账单附件** | 删除附件 → 确认文件从本地清理 | 文件物理删除 |
| **应用锁** | 设置 PIN → 切到后台 → 回前台 | 显示锁屏，正确 PIN 解锁 |
| **应用锁** | 启用生物识别 → 锁屏验证 | Face ID/指纹通过后解锁 |

#### Wave 2

| 功能 | 测试场景 | 预期结果 |
|------|---------|---------|
| **存钱目标** | 创建目标 → 手动存入 → 进度更新 | 百分比和余额正确 |
| **存钱目标** | 关联账户自动追踪 | 账户余额变化自动反映到目标进度 |
| **存钱目标** | 达成目标 | 状态自动变为 completed |
| **贷款管理** | 创建等额本息贷款 → 生成还款计划 | 每期金额计算正确 (精度 ≤0.01) |
| **贷款管理** | 创建等额本金贷款 → 验证逐月递减 | 本金部分相等，利息递减 |
| **贷款管理** | 标记还款 → 关联交易 | 还款记录和交易双向关联 |

#### Wave 3

| 功能 | 测试场景 | 预期结果 |
|------|---------|---------|
| **多账本** | 创建新账本 → 切换 → 添加交易 | 交易只在对应账本可见 |
| **多账本** | 切换账本后查看统计 | 统计数据隔离到当前账本 |
| **多账本** | 默认账本包含所有老数据 | 迁移后数据无丢失 |
| **多账本** | 删除账本 (含交易) | 提示确认，交易归入默认账本或删除 |
| **笔记** | 创建 Markdown 笔记 → 预览渲染 | Markdown 正确解析 |
| **笔记** | 笔记关联交易 → 交易详情显示 | 双向导航 |

#### Wave 4

| 功能 | 测试场景 | 预期结果 |
|------|---------|---------|
| **桌面小组件** | 添加小组件 → 记录交易 | 小组件实时刷新今日收支 |
| **桌面小组件** | 点击小组件 → 打开 APP | Deep link 跳转到主页 |

### 5.3 回归测试清单

每个 Wave 完成后必须验证：

- [ ] `flutter analyze` — 0 issues
- [ ] 全局搜索 — 功能正常
- [ ] CSV 导出 — 能导出新字段
- [ ] 统计图表 — 数据准确
- [ ] 预算管理 — 计算正确
- [ ] 日历视图 — 正常渲染
- [ ] 退款管理 — 功能正常
- [ ] 主题切换 — 新页面适配主题
- [ ] 分期管理 — 功能正常
- [ ] 多币种 — 新模块支持多币种 (如适用)

### 5.4 代码质量验证

```bash
# 1. 静态分析
flutter analyze

# 2. 代码生成
dart run build_runner build --delete-conflicting-outputs

# 3. 格式化
dart format lib/ --set-exit-if-changed

# 4. 依赖检查
flutter pub outdated

# 5. 测试 (如有)
flutter test
```

---

## 六、依赖变更汇总

| 新增 Package | 用途 | 对应功能 |
|-------------|------|---------|
| `local_auth` | 生物识别 | 应用锁 |
| `home_widget` | Android Widget | 桌面小组件 |
| `flutter_markdown` | Markdown 渲染 | 笔记 |

> 注: `image_picker`, `file_picker`, `crypto`, `shared_preferences` 已在 pubspec.yaml 中。

---

## 七、新增文件统计

| Wave | 新增文件 | 修改文件 | 新增模型 |
|------|---------|---------|---------|
| Wave 1 | ~9 | ~6 | 0 (复用/扩展) |
| Wave 2 | ~11 | ~4 | 4 (SavingsGoal, SavingsRecord, Loan, LoanPayment) |
| Wave 3 | ~8 | ~8 | 2 (AccountBook, Note) |
| Wave 4 | ~4 | ~3 | 0 |
| **合计** | **~32** | **~21** | **6** |

---

## 八、风险评估

| 风险 | 级别 | 缓解措施 |
|------|------|---------|
| 多账本改造影响面大 | 🔴 高 | 放在 Wave 3，其他功能验证通过后再动 |
| Isar schema 升级不可逆 | 🟡 中 | 只添加字段、不删改；数据备份后再升级 |
| Android Widget 需原生代码 | 🟡 中 | 放在最后，不影响核心功能 |
| 贷款利息计算精度 | 🔴 高 | 必须使用 Decimal 类型处理货币与利息计算，避免使用 double 引入累计精度误差 |
| `codex/post-merge-verify` 与 main 分叉 | 🟢 低 | 先 merge 到 main 再开始 Phase 3 |

---

## 九、开发前置准备

1. **合并 `codex/post-merge-verify` 到 main** — 含 stats/search/csv 的 4 个 commit
2. **提交 main.dart 未提交变更** — CSV 导出菜单入口
3. **运行 `flutter analyze`** — 确保基线 0 错误
4. **为每个 Wave 创建独立分支** — `codex/phase3-wave1`, `codex/phase3-wave2` ...
5. **每个功能一个 PR** — 方便 review 和 rollback
