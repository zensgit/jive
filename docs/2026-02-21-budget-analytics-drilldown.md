# Jive 预算分析深化（三期）：洞察卡片一键钻取到账单

## 目标
在预算分析二期（Top 分类 + 异常支出日）的基础上，把“看到洞察”变为“直接行动”：
- Top 分类贡献：点击后直接打开对应账单列表。
- 异常支出日：点击后直接筛选到当天账单。

同时保证从预算页带入的筛选是临时态，不污染用户在“全部账单”页长期保存的筛选偏好。

## 实现内容

### 1) 账单页支持外部初始筛选（临时态）
`CategoryTransactionsScreen` 新增可选参数：
- `initialFilterState`
- `initialSearchQuery`
- `persistFilterState`（默认 `true`）

实现策略：
- 当存在初始筛选/搜索参数时，优先使用外部参数，不读取“全部账单”持久化筛选。
- 预算页钻取场景传 `persistFilterState: false`，确保退出后不写回本地偏好。

### 2) 预算管理页新增钻取入口
`BudgetManagerScreen` 中两处洞察区域改为可点击：
- `分类支出贡献 TopN`：点击某一行，按当前预算周期时间范围跳到交易列表，并携带分类约束。
- `异常支出日`：点击某一行，直接按该日范围跳到交易列表。

实现细节：
- 分类钻取支持父类与子类（子类使用 `filterSubCategoryKey`）。
- `__uncategorized__` 暂不支持精准钻取，点击时提示说明。

## 变更文件
- `lib/feature/budget/budget_manager_screen.dart`
- `lib/feature/category/category_transactions_screen.dart`
- `docs/2026-02-21-budget-analytics-drilldown.md`

## 验证结果

### 静态检查与测试
- `flutter analyze --no-fatal-infos` ✅
- `flutter test` ✅

### ADB 真机回归
- 设备：`EP0110MZ0BC110087W`
- 命令：`bash scripts/verify_dev_flow.sh com.jivemoney.app.dev` ✅
- 产物：`/tmp/jive-verify-20260221-005713`

说明：本次脚本重点覆盖“全部账单筛选 + 设置/预算主链路”稳定性；预算洞察钻取属于新增交互，建议合并后继续补 1 条针对性 ADB 用例（点击 Top 分类/异常日后断言账单页筛选已生效）。
